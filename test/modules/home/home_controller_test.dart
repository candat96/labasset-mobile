import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:labasset_mobile/core/cache/kv_cache.dart';
import 'package:labasset_mobile/core/errors/api_error.dart';
import 'package:labasset_mobile/core/i18n/app_translations.dart';
import 'package:labasset_mobile/data/models/equipment.dart';
import 'package:labasset_mobile/data/models/repair.dart';
import 'package:labasset_mobile/data/models/request.dart';
import 'package:labasset_mobile/data/models/stock.dart';
import 'package:labasset_mobile/data/models/task.dart';
import 'package:labasset_mobile/data/models/stocktake.dart';
import 'package:labasset_mobile/data/repositories/equipment_repository.dart';
import 'package:labasset_mobile/data/repositories/repairs_repository.dart';
import 'package:labasset_mobile/data/repositories/requests_repository.dart';
import 'package:labasset_mobile/data/repositories/settings_repository.dart';
import 'package:labasset_mobile/data/repositories/stock_repository.dart';
import 'package:labasset_mobile/data/repositories/stocktakes_repository.dart';
import 'package:labasset_mobile/data/repositories/tasks_repository.dart';
import 'package:labasset_mobile/modules/home/home_controller.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_helpers.dart';

class _MockRepairs extends Mock implements RepairsRepository {}

class _MockTasks extends Mock implements TasksRepository {}

class _MockRequests extends Mock implements RequestsRepository {}

class _MockEquipment extends Mock implements EquipmentRepository {}

class _MockStock extends Mock implements StockRepository {}

class _MockSettings extends Mock implements SettingsRepository {}

class _MockStocktakes extends Mock implements StocktakesRepository {}

void main() {
  late _MockRepairs repairs;
  late _MockTasks tasks;
  late _MockRequests requests;
  late _MockEquipment equipment;
  late _MockStock stock;
  late _MockSettings settings;
  late _MockStocktakes stocktakes;
  late FakeKvCache cache;
  late HomeController c;

  setUp(() {
    Get.testMode = true;
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('vi', 'VN');
    repairs = _MockRepairs();
    tasks = _MockTasks();
    requests = _MockRequests();
    equipment = _MockEquipment();
    stock = _MockStock();
    settings = _MockSettings();
    stocktakes = _MockStocktakes();
    cache = FakeKvCache();
    when(
      () => settings.hospitalName(),
    ).thenAnswer((_) async => 'Bệnh viện Demo');
    c = HomeController(
      store: fakeStore(),
      settings: settings,
      repairs: repairs,
      tasks: tasks,
      requests: requests,
      equipment: equipment,
      stock: stock,
      stocktakes: stocktakes,
      cache: cache,
    );
  });

  tearDown(Get.reset);

  void stubHappy() {
    when(
      () => repairs.list(
        assigneeId: 'me',
        status: any(named: 'status'),
        limit: 3,
      ),
    ).thenAnswer(
      (_) async => const RepairPage(
        items: [
          RepairSummary(
            id: 'r1',
            code: 'SC-001',
            equipmentId: 'e1',
            status: 'in_progress',
            equipment: EquipmentRef(id: 'e1', code: 'M1', name: 'Máy X'),
          ),
        ],
        total: 4,
      ),
    );
    when(
      () => repairs.list(status: 'new', limit: 1),
    ).thenAnswer((_) async => const RepairPage(items: [], total: 2));
    when(
      () => tasks.list(
        assigneeId: 'me',
        status: any(named: 'status'),
        to: any(named: 'to'),
        limit: 3,
      ),
    ).thenAnswer(
      (_) async => const TaskPage(
        items: [
          TaskSummary(
            id: 't1',
            code: 'BD-001',
            equipmentId: 'e1',
            scheduledAt: '2026-09-20T08:00:00Z',
            status: 'scheduled',
          ),
        ],
        total: 1,
      ),
    );
    when(() => requests.list(pendingForMe: true, limit: 3)).thenAnswer(
      (_) async => const RequestPage(
        items: [
          RequestSummary(
            id: 'q1',
            code: 'YC-001',
            reason: 'Bổ sung găng tay',
            status: 'submitted',
          ),
        ],
        total: 1,
      ),
    );
    when(
      () => requests.list(status: 'approved,partially_approved', limit: 3),
    ).thenAnswer(
      (_) async => const RequestPage(
        items: [
          RequestSummary(
            id: 'q2',
            code: 'YC-002',
            reason: 'Cấp hoá chất',
            status: 'approved',
          ),
        ],
        total: 3,
      ),
    );
    when(
      () => stock.alerts(resolved: false, limit: 1),
    ).thenAnswer((_) async => const StockAlertPage(items: [], total: 5));
    when(
      () => equipment.count(calibrationOverdue: true),
    ).thenAnswer((_) async => 2);
    when(() => stocktakes.list(status: 'counting', limit: 5)).thenAnswer(
      (_) async => const StocktakePage(
        items: [
          StocktakeSession(
            id: 'st1',
            code: 'KK-001',
            name: 'Kiểm kê tháng 9',
            status: 'counting',
          ),
        ],
        total: 1,
      ),
    );
  }

  test('ghép dữ liệu 4 nhóm việc + 3 cảnh báo', () async {
    stubHappy();
    await c.load();
    expect(c.repairsAssigned.single.code, 'SC-001');
    expect(c.repairsAssignedTotal.value, 4);
    expect(c.tasksDue.single.code, 'BD-001');
    expect(c.requestsPending.single.code, 'YC-001');
    expect(c.requestsApproved.single.code, 'YC-002');
    expect(c.brokenUnassigned.value, 2);
    expect(c.suppliesAlert.value, 5);
    expect(c.calibrationOverdue.value, 2);
    expect(c.stocktakesOpen.single.code, 'KK-001');
    expect(c.showStocktakes.value, isTrue);
    expect(c.error.value, isNull);
    expect(c.cachedAt.value, isNull);
    expect(cache.store.containsKey(HomeController.cacheKey), isTrue);
  });

  test(
    'một nguồn lỗi → các nguồn khác vẫn có dữ liệu, không rơi vào cache',
    () async {
      stubHappy();
      when(
        () => tasks.list(
          assigneeId: 'me',
          status: any(named: 'status'),
          to: any(named: 'to'),
          limit: 3,
        ),
      ).thenThrow(ApiError(500, 'INTERNAL_ERROR', ''));
      await c.load();
      expect(c.repairsAssigned, hasLength(1));
      expect(c.tasksDue, isEmpty);
      expect(c.error.value, isNull);
      expect(c.cachedAt.value, isNull);
    },
  );

  test('kiểm kê 403 được ẩn, các nhóm khác vẫn hoạt động', () async {
    stubHappy();
    when(
      () => stocktakes.list(status: 'counting', limit: 5),
    ).thenThrow(ApiError(403, 'FORBIDDEN', ''));
    await c.load();
    expect(c.showStocktakes.value, isFalse);
    expect(c.stocktakesOpen, isEmpty);
    expect(c.repairsAssigned, hasLength(1));
    expect(c.error.value, isNull);
  });

  test('tất cả nguồn lỗi → dùng cache kèm nhãn thời gian', () async {
    cache.store[HomeController.cacheKey] = CachedValue({
      'repairsAssigned': [
        {
          'id': 'r9',
          'code': 'SC-999',
          'equipmentId': 'e9',
          'status': 'in_progress',
        },
      ],
      'repairsAssignedTotal': 1,
      'brokenUnassigned': 3,
      'suppliesAlert': 4,
      'calibrationOverdue': 1,
    }, DateTime(2026, 9, 19, 8, 30));

    final err = ApiError(0, 'NETWORK_ERROR', '');
    when(
      () => repairs.list(
        assigneeId: 'me',
        status: any(named: 'status'),
        limit: 3,
      ),
    ).thenThrow(err);
    when(() => repairs.list(status: 'new', limit: 1)).thenThrow(err);
    when(
      () => tasks.list(
        assigneeId: 'me',
        status: any(named: 'status'),
        to: any(named: 'to'),
        limit: 3,
      ),
    ).thenThrow(err);
    when(() => requests.list(pendingForMe: true, limit: 3)).thenThrow(err);
    when(
      () => requests.list(status: 'approved,partially_approved', limit: 3),
    ).thenThrow(err);
    when(() => stock.alerts(resolved: false, limit: 1)).thenThrow(err);
    when(() => equipment.count(calibrationOverdue: true)).thenThrow(err);

    await c.load();
    expect(c.error.value, isNotNull);
    expect(c.cachedAt.value, isNotNull);
    expect(c.repairsAssigned.single.code, 'SC-999');
    expect(c.brokenUnassigned.value, 3);
    expect(c.suppliesAlert.value, 4);
    expect(c.calibrationOverdue.value, 1);
  });

  test('không có cache và tất cả lỗi → error, cachedAt null', () async {
    final err = ApiError(0, 'NETWORK_ERROR', '');
    when(
      () => repairs.list(
        assigneeId: 'me',
        status: any(named: 'status'),
        limit: 3,
      ),
    ).thenThrow(err);
    when(() => repairs.list(status: 'new', limit: 1)).thenThrow(err);
    when(
      () => tasks.list(
        assigneeId: 'me',
        status: any(named: 'status'),
        to: any(named: 'to'),
        limit: 3,
      ),
    ).thenThrow(err);
    when(() => requests.list(pendingForMe: true, limit: 3)).thenThrow(err);
    when(
      () => requests.list(status: 'approved,partially_approved', limit: 3),
    ).thenThrow(err);
    when(() => stock.alerts(resolved: false, limit: 1)).thenThrow(err);
    when(() => equipment.count(calibrationOverdue: true)).thenThrow(err);
    await c.load();
    expect(c.error.value, isNotNull);
    expect(c.cachedAt.value, isNull);
    expect(c.loading.value, isFalse);
  });
}
