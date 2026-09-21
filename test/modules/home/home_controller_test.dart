import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:labasset_mobile/core/cache/kv_cache.dart';
import 'package:labasset_mobile/core/errors/api_error.dart';
import 'package:labasset_mobile/data/models/demand.dart';
import 'package:labasset_mobile/data/models/my_tasks.dart';
import 'package:labasset_mobile/data/repositories/me_repository.dart';
import 'package:labasset_mobile/data/repositories/settings_repository.dart';
import 'package:labasset_mobile/modules/home/home_controller.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_helpers.dart';

class _Me extends Mock implements MeRepository {}

class _Settings extends Mock implements SettingsRepository {}

const response = MyTasksResponse(
  repairs: RepairTasks(assigned: 2, pendingResponse: 1, overdue: 1),
  maintenance: MaintenanceTasks(due7d: 3, overdue: 2),
  requests: RequestTasks(
    pendingApproval: 4,
    pendingIssue: 5,
    pendingReceive: 6,
  ),
  stocktakes: StocktakeTasks(counting: 7),
  alerts: TaskAlerts(
    repairsNew: 8,
    stock: StockAlertCounts(
      lowStock: 1,
      expiring: 2,
      expired: 3,
      openVialExpiring: 4,
      stale: 5,
    ),
    calibrationOverdue: 9,
  ),
);

void main() {
  late _Me me;
  late FakeKvCache cache;
  late HomeController controller;

  setUp(() {
    Get.testMode = true;
    me = _Me();
    cache = FakeKvCache();
    controller = HomeController(me: me, settings: _Settings(), cache: cache);
  });
  tearDown(Get.reset);

  test('một call trả đủ nhóm việc và cảnh báo rồi lưu cache', () async {
    when(me.tasks).thenAnswer((_) async => response);
    await controller.load();

    expect(controller.repairsAssignedTotal, 2);
    expect(controller.repairsPendingResponse, 1);
    expect(controller.tasksDueTotal, 3);
    expect(controller.requestsPendingReceive, 6);
    expect(controller.stocktakesOpenTotal, 7);
    expect(controller.brokenUnassigned, 8);
    expect(controller.suppliesAlert, 15);
    expect(controller.calibrationOverdue, 9);
    verify(me.tasks).called(1);
    expect(cache.store, contains(HomeController.cacheKey));
  });

  test('lỗi mạng dùng snapshot sqflite và giữ nhãn thời gian', () async {
    final at = DateTime(2026, 9, 21, 8);
    cache.store[HomeController.cacheKey] = CachedValue(response.toJson(), at);
    when(me.tasks).thenThrow(ApiError(0, 'NETWORK_ERROR', ''));

    await controller.load();

    expect(controller.data.value, isNotNull);
    expect(controller.cachedAt.value, at);
    expect(controller.error.value, isNotNull);
  });

  test('đếm việc dự trù từ /v1/me/tasks', () async {
    when(me.tasks).thenAnswer(
      (_) async => const MyTasksResponse(
        repairs: RepairTasks(assigned: 0, pendingResponse: 0, overdue: 0),
        maintenance: MaintenanceTasks(due7d: 0, overdue: 0),
        requests: RequestTasks(
          pendingApproval: 0,
          pendingIssue: 0,
          pendingReceive: 0,
        ),
        stocktakes: StocktakeTasks(counting: 0),
        alerts: TaskAlerts(
          repairsNew: 0,
          stock: StockAlertCounts(
            lowStock: 0,
            expiring: 0,
            expired: 0,
            openVialExpiring: 0,
            stale: 0,
          ),
          calibrationOverdue: 0,
        ),
        demand: DemandTasks(toSubmit: 1, toApprove: 2, toAccept: 3),
      ),
    );
    await controller.load();
    expect(controller.demandToSubmit, 1);
    expect(controller.demandToApprove, 2);
    expect(controller.demandToAccept, 3);
    expect(controller.hasWork, isTrue);
  });

  test('lỗi không có cache hiển thị error', () async {
    when(me.tasks).thenThrow(ApiError(500, 'INTERNAL_ERROR', ''));
    await controller.load();
    expect(controller.data.value, isNull);
    expect(controller.error.value, isNotNull);
    expect(controller.loading.value, isFalse);
  });

  test('snapshot rỗng không báo có việc', () async {
    when(me.tasks).thenAnswer(
      (_) async => const MyTasksResponse(
        repairs: RepairTasks(assigned: 0, pendingResponse: 0, overdue: 0),
        maintenance: MaintenanceTasks(due7d: 0, overdue: 0),
        requests: RequestTasks(
          pendingApproval: 0,
          pendingIssue: 0,
          pendingReceive: 0,
        ),
        stocktakes: StocktakeTasks(counting: 0),
        alerts: TaskAlerts(
          repairsNew: 0,
          stock: StockAlertCounts(
            lowStock: 0,
            expiring: 0,
            expired: 0,
            openVialExpiring: 0,
            stale: 0,
          ),
          calibrationOverdue: 0,
        ),
      ),
    );
    await controller.load();
    expect(controller.hasWork, isFalse);
    expect(controller.suppliesAlert, 0);
  });
}
