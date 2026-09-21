import 'dart:async';

import 'package:get/get.dart';

import '../../core/cache/kv_cache.dart';
import '../../data/models/my_tasks.dart';
import '../../data/repositories/me_repository.dart';
import '../../data/repositories/settings_repository.dart';

/// Trang chủ lấy toàn bộ nhóm việc và cảnh báo bằng một call `/v1/me/tasks`.
class HomeController extends GetxController {
  HomeController({required this.me, required this.settings, this.cache});

  final MeRepository me;
  final SettingsRepository settings;
  final KvCache? cache;

  static const cacheKey = 'home.snapshot';

  final RxnString hospitalName = RxnString();
  final RxBool loading = true.obs;
  final Rxn<Object> error = Rxn<Object>();
  final Rxn<DateTime> cachedAt = Rxn<DateTime>();
  final Rxn<MyTasksResponse> data = Rxn<MyTasksResponse>();

  int get repairsAssignedTotal => data.value?.repairs.assigned.toInt() ?? 0;
  int get repairsPendingResponse =>
      data.value?.repairs.pendingResponse.toInt() ?? 0;
  int get repairsOverdue => data.value?.repairs.overdue.toInt() ?? 0;
  int get tasksDueTotal => data.value?.maintenance.due7d.toInt() ?? 0;
  int get tasksOverdue => data.value?.maintenance.overdue.toInt() ?? 0;
  int get requestsPendingTotal =>
      data.value?.requests.pendingApproval.toInt() ?? 0;
  int get requestsApprovedTotal =>
      data.value?.requests.pendingIssue.toInt() ?? 0;
  int get requestsPendingReceive =>
      data.value?.requests.pendingReceive.toInt() ?? 0;
  int get stocktakesOpenTotal => data.value?.stocktakes.counting.toInt() ?? 0;
  int get demandToSubmit => data.value?.demand.toSubmit.toInt() ?? 0;
  int get demandToApprove => data.value?.demand.toApprove.toInt() ?? 0;
  int get demandToAccept => data.value?.demand.toAccept.toInt() ?? 0;
  int get brokenUnassigned => data.value?.alerts.repairsNew.toInt() ?? 0;
  int get suppliesAlert => data.value?.alerts.stock.total ?? 0;
  int get calibrationOverdue =>
      data.value?.alerts.calibrationOverdue.toInt() ?? 0;

  bool get hasWork =>
      repairsAssignedTotal +
          repairsPendingResponse +
          repairsOverdue +
          tasksDueTotal +
          tasksOverdue +
          requestsPendingTotal +
          requestsApprovedTotal +
          requestsPendingReceive +
          stocktakesOpenTotal +
          demandToSubmit +
          demandToApprove +
          demandToAccept >
      0;

  @override
  void onInit() {
    super.onInit();
    unawaited(_loadHospitalName());
    unawaited(load());
  }

  Future<void> _loadHospitalName() async {
    hospitalName.value = await settings.hospitalName();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      data.value = await me.tasks();
      cachedAt.value = null;
      unawaited(cache?.put(cacheKey, data.value!.toJson()));
    } catch (e) {
      error.value = e;
      await _loadCache();
    } finally {
      loading.value = false;
    }
  }

  Future<void> _loadCache() async {
    try {
      final cached = await cache?.get(cacheKey);
      if (cached == null) return;
      data.value = MyTasksResponse.fromJson(cached.value);
      cachedAt.value = cached.updatedAt;
    } catch (_) {
      // Cache hỏng được coi như không có cache.
    }
  }
}
