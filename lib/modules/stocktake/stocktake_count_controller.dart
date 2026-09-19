import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../core/stocktake/stocktake_counts_handler.dart';
import '../../core/stocktake/stocktake_local_store.dart';
import '../../core/sync/outbox_service.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../data/models/stocktake.dart';
import '../../data/repositories/stocktakes_repository.dart';

enum StocktakeTab { uncounted, counted, extras }

/// Đếm kiểm kê offline: local store + gửi batch qua outbox.
class StocktakeCountController extends GetxController {
  StocktakeCountController({
    required this.repo,
    required this.store,
    required this.outbox,
    required this.id,
  });

  final StocktakesRepository repo;
  final StocktakeLocalStore store;
  final OutboxService outbox;
  final String id;

  final Rxn<StocktakeLocalMeta> meta = Rxn<StocktakeLocalMeta>();
  final RxList<StocktakeLocalItem> items = <StocktakeLocalItem>[].obs;
  final RxList<StocktakeLocalExtra> extras = <StocktakeLocalExtra>[].obs;
  final Rx<StocktakeTab> tab = StocktakeTab.uncounted.obs;
  final RxInt pending = 0.obs;
  final Rxn<StocktakeProgress> progress = Rxn<StocktakeProgress>();
  final RxBool loading = true.obs;
  final RxBool sending = false.obs;
  final Rxn<Object> error = Rxn<Object>();
  final search = TextEditingController();

  List<StocktakeLocalItem> get uncounted =>
      items.where((i) => !i.counted).toList();

  List<StocktakeLocalItem> get counted =>
      items.where((i) => i.counted).toList();

  List<StocktakeLocalItem> get visible {
    final q = search.text.trim().toUpperCase();
    Iterable<StocktakeLocalItem> list = switch (tab.value) {
      StocktakeTab.uncounted => uncounted,
      StocktakeTab.counted => counted,
      StocktakeTab.extras => const [],
    };
    if (q.isNotEmpty) {
      list = list.where(
        (i) =>
            i.code.toUpperCase().contains(q) ||
            i.name.toUpperCase().contains(q) ||
            (i.lotNo ?? '').toUpperCase().contains(q),
      );
    }
    return list.toList();
  }

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      meta.value = await store.meta(id);
      items.assignAll(await store.items(id));
      extras.assignAll(await store.extras(id));
      pending.value = await store.pendingCount(id);
      unawaited(_loadProgress());
    } catch (e) {
      error.value = e;
    } finally {
      loading.value = false;
    }
  }

  Future<void> _loadProgress() async {
    try {
      progress.value = await repo.progress(id);
    } catch (_) {
      // tiến độ online là best-effort
    }
  }

  void setTab(StocktakeTab t) => tab.value = t;

  void onSearchChanged(String _) => items.refresh();

  /// Tìm trong local theo qrToken/code/lotNo (package chưa trả qrToken).
  StocktakeLocalItem? resolve(String raw) {
    final code = raw.trim().toUpperCase();
    if (code.isEmpty) return null;
    for (final i in items) {
      if (i.code.toUpperCase() == code) return i;
    }
    for (final i in items) {
      if ((i.lotNo ?? '').toUpperCase() == code) return i;
    }
    for (final i in items) {
      if (i.code.toUpperCase().contains(code) ||
          i.name.toUpperCase().contains(code)) {
        return i;
      }
    }
    return null;
  }

  /// Lưu kết quả đếm (ghi đè local, clientId mới).
  Future<void> saveCount(
    StocktakeLocalItem item, {
    required String qty,
    String? status,
    String? location,
    String? note,
    String? photoFileId,
  }) async {
    item
      ..countedQty = qty
      ..countedStatus = status
      ..countedLocation = location
      ..note = note
      ..photoFileId = photoFileId
      ..countedAt = DateTime.now().toUtc().toIso8601String()
      ..clientId = _clientId()
      ..synced = false
      ..conflict = false;
    await store.upsertCount(item);
    await load();
  }

  Future<void> addExtra({
    required String code,
    required String qty,
    String? note,
  }) async {
    await store.addExtra(
      StocktakeLocalExtra(
        id: _clientId(),
        sessionId: id,
        code: code,
        qty: qty,
        note: note,
        countedAt: DateTime.now().toUtc().toIso8601String(),
      ),
    );
    await load();
  }

  /// Gom ≤ 200 dòng chưa gửi → outbox batch → chạy.
  Future<bool> send() async {
    sending.value = true;
    try {
      final unsynced = items
          .where(
            (i) => i.counted && !i.synced && !i.conflict && i.clientId != null,
          )
          .take(200)
          .toList();
      final unsyncedExtras = extras.where((e) => !e.synced).toList();
      if (unsynced.isEmpty && unsyncedExtras.isEmpty) {
        AppSnackbar.info('stocktake.nothingToSend'.tr);
        return true;
      }
      await outbox.enqueue(StocktakeCountsOutboxHandler.typeName, {
        'sessionId': id,
        'counts': [
          for (final i in unsynced)
            {
              'clientId': i.clientId,
              'itemId': i.itemId,
              'countedQty': i.countedQty,
              'countedStatus': ?i.countedStatus,
              'countedLocation': ?i.countedLocation,
              'photoFileId': ?i.photoFileId,
              'note': ?i.note,
              'countedAt': i.countedAt,
            },
          for (final e in unsyncedExtras)
            {
              'clientId': e.id,
              'qrToken': e.code,
              'lotNo': e.code,
              'countedQty': e.qty,
              'note': ?e.note,
              'photoFileId': ?e.photoFileId,
              'countedAt': e.countedAt,
            },
        ],
      });
      final online = await outbox.run();
      if (!online) {
        AppSnackbar.info('sync.offline'.tr);
      } else {
        AppSnackbar.success('stocktake.sent'.tr);
      }
      await load();
      return true;
    } catch (e) {
      AppSnackbar.error(e);
      return false;
    } finally {
      sending.value = false;
    }
  }

  static String _clientId() =>
      'st-${DateTime.now().microsecondsSinceEpoch}-${Object().hashCode & 0xffff}';

  @override
  void onClose() {
    search.dispose();
    super.onClose();
  }
}
