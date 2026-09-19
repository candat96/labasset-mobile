import 'package:get/get.dart';

import '../../core/stocktake/stocktake_local_store.dart';
import '../../core/sync/outbox_service.dart';
import '../../core/widgets/app_snackbar.dart';

/// Quản lý dữ liệu offline (Cá nhân): đợt đã tải + xoá.
class OfflineDataController extends GetxController {
  OfflineDataController({required this.store, required this.outbox});

  final StocktakeLocalStore store;
  final OutboxService outbox;

  final RxList<(StocktakeLocalMeta, int)> sessions =
      <(StocktakeLocalMeta, int)>[].obs;
  final RxBool loading = true.obs;
  final Rxn<Object> error = Rxn<Object>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      final metas = await store.downloadedSessions();
      final rows = <(StocktakeLocalMeta, int)>[];
      for (final m in metas) {
        rows.add((m, await store.pendingCount(m.sessionId)));
      }
      sessions.assignAll(rows);
    } catch (e) {
      error.value = e;
    } finally {
      loading.value = false;
    }
  }

  Future<bool> remove(StocktakeLocalMeta meta) async {
    final pending = await store.pendingCount(meta.sessionId);
    if (pending > 0) {
      AppSnackbar.info('offline.deleteBlocked'.trParams({'n': '$pending'}));
      return false;
    }
    await store.deleteSession(meta.sessionId);
    AppSnackbar.success('offline.deleted'.tr);
    await load();
    return true;
  }
}
