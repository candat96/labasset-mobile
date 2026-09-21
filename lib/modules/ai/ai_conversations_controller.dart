import 'dart:async';

import 'package:get/get.dart';

import '../../core/ai/ai_models.dart';
import '../../core/routes/app_routes.dart';
import '../../data/repositories/ai_repository.dart';
import '../../data/repositories/equipment_repository.dart';

/// Danh sách hội thoại AI `/ai/conversations`: phân trang + tạo + xoá.
class AiConversationsController extends GetxController {
  AiConversationsController({
    required this.repo,
    this.equipment,
    Future<void> Function(String route)? navigate,
  }) : _navigate = navigate ?? ((r) async => Get.toNamed(r));

  final AiRepository repo;
  final EquipmentRepository? equipment;
  final Future<void> Function(String route) _navigate;

  final RxList<AiConversation> items = <AiConversation>[].obs;
  final RxInt total = 0.obs;
  final RxBool loading = true.obs;
  final RxBool loadingMore = false.obs;
  final Rxn<Object> error = Rxn<Object>();

  /// equipmentId → "mã — tên" (tra cache, best-effort).
  final Map<String, String> equipmentLabels = {};

  int _page = 1;
  bool get hasMore => items.length < total.value;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    _page = 1;
    try {
      final page = await repo.listConversations(page: 1, limit: 20);
      items.assignAll(page.items);
      total.value = page.total;
      unawaited(_resolveEquipment(page.items));
    } catch (e) {
      error.value = e;
    } finally {
      loading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (loadingMore.value || !hasMore) return;
    loadingMore.value = true;
    try {
      final page = await repo.listConversations(page: _page + 1, limit: 20);
      _page += 1;
      items.addAll(page.items);
      total.value = page.total;
      unawaited(_resolveEquipment(page.items));
    } catch (_) {
      // giữ danh sách hiện tại
    } finally {
      loadingMore.value = false;
    }
  }

  Future<void> _resolveEquipment(List<AiConversation> list) async {
    final repoEq = equipment;
    if (repoEq == null) return;
    for (final c in list) {
      final id = c.equipmentId;
      if (id == null || equipmentLabels.containsKey(id)) continue;
      try {
        final eq = await repoEq.byId(id);
        equipmentLabels[id] = '${eq.code} — ${eq.name}';
      } catch (_) {
        // bỏ qua
      }
    }
    if (list.isNotEmpty) items.refresh();
  }

  /// Tạo hội thoại mới rồi mở chat.
  Future<void> create({String? equipmentId}) async {
    try {
      final c = await repo.createConversation(equipmentId: equipmentId);
      items.insert(0, c);
      total.value += 1;
      await _navigate(Routes.aiChat(c.id));
    } catch (e) {
      error.value = e;
    }
  }

  Future<void> delete(AiConversation c) async {
    final idx = items.indexOf(c);
    if (idx < 0) return;
    items.removeAt(idx);
    total.value = total.value > 0 ? total.value - 1 : 0;
    try {
      await repo.deleteConversation(c.id);
    } catch (e) {
      items.insert(idx, c);
      total.value += 1;
      error.value = e;
    }
  }
}
