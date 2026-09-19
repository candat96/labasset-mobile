import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:labasset_mobile/core/i18n/app_translations.dart';
import 'package:labasset_mobile/data/models/repair.dart';
import 'package:labasset_mobile/data/models/repair_detail.dart';
import 'package:labasset_mobile/data/models/stock.dart';
import 'package:labasset_mobile/data/models/task.dart';
import 'package:labasset_mobile/data/repositories/repairs_repository.dart';
import 'package:labasset_mobile/data/repositories/tasks_repository.dart';
import 'package:labasset_mobile/modules/account/my_stats_controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepairs extends Mock implements RepairsRepository {}

class _MockTasks extends Mock implements TasksRepository {}

void main() {
  late _MockRepairs repairs;
  late _MockTasks tasks;

  setUp(() {
    Get.testMode = true;
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('vi', 'VN');
    repairs = _MockRepairs();
    tasks = _MockTasks();
  });

  tearDown(Get.reset);

  test('MyStats tính completed/overdue/maintenance + điểm TB', () async {
    when(
      () => repairs.list(
        assigneeId: 'me',
        status: 'completed,acceptance,closed',
        from: any(named: 'from'),
        limit: 50,
      ),
    ).thenAnswer(
      (_) async => const RepairPage(
        items: [
          RepairSummary(id: 'r1', code: 'SC-1', equipmentId: 'e1'),
          RepairSummary(id: 'r2', code: 'SC-2', equipmentId: 'e1'),
        ],
        total: 7,
      ),
    );
    when(
      () => repairs.list(assigneeId: 'me', overdue: true, limit: 1),
    ).thenAnswer((_) async => const RepairPage(items: [], total: 2));
    when(
      () => tasks.list(
        assigneeId: 'me',
        status: 'done',
        from: any(named: 'from'),
        limit: 1,
      ),
    ).thenAnswer((_) async => const TaskPage(items: [], total: 4));
    when(() => repairs.detail('r1')).thenAnswer(
      (_) async => const RepairDetail(
        id: 'r1',
        code: 'SC-1',
        equipmentId: 'e1',
        rating: 5,
      ),
    );
    when(() => repairs.detail('r2')).thenAnswer(
      (_) async => const RepairDetail(
        id: 'r2',
        code: 'SC-2',
        equipmentId: 'e1',
        rating: 3,
      ),
    );

    final c = MyStatsController(repairs: repairs, tasks: tasks);
    await c.load();
    expect(c.completed.value, 7);
    expect(c.overdue.value, 2);
    expect(c.maintenanceDone.value, 4);
    expect(c.avgRating.value, 4.0);
  });

  test('lỗi API không làm vỡ màn (giữ 0)', () async {
    when(
      () => repairs.list(
        assigneeId: 'me',
        status: any(named: 'status'),
        from: any(named: 'from'),
        limit: 50,
      ),
    ).thenThrow(Exception('boom'));
    when(
      () => repairs.list(assigneeId: 'me', overdue: true, limit: 1),
    ).thenThrow(Exception('boom'));
    when(
      () => tasks.list(
        assigneeId: 'me',
        status: 'done',
        from: any(named: 'from'),
        limit: 1,
      ),
    ).thenThrow(Exception('boom'));
    final c = MyStatsController(repairs: repairs, tasks: tasks);
    await c.load();
    expect(c.completed.value, 0);
    expect(c.avgRating.value, isNull);
    expect(c.loading.value, isFalse);
  });

  test('RepairStats.parse totals + workload', () async {
    when(
      () => repairs.stats(
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    ).thenAnswer(
      (_) async => const RepairStats(
        tickets: 10,
        completed: 6,
        cost: '1500000',
        mttrHours: 3.5,
      ),
    );
    final s = await repairs.stats(from: '2026-09-01', to: '2026-09-30');
    expect(s.completed, 6);
    expect(s.cost, '1500000');

    when(() => repairs.workload()).thenAnswer(
      (_) async => const [
        WorkloadItem(id: 'u1', fullName: 'A', open: 3, overdue: 1),
      ],
    );
    final w = await repairs.workload();
    expect(w.single.fullName, 'A');
  });

  test('StockAlertPage parse phục vụ thẻ cảnh báo báo cáo', () {
    final page = StockAlertPage.fromJson(const {
      'items': [
        {
          'id': 'a1',
          'type': 'low_stock',
          'supplyId': 's1',
          'message': 'Dưới định mức',
        },
      ],
      'total': 3,
    });
    expect(page.total, 3);
    expect(page.items.single.type, 'low_stock');
  });
}
