import 'package:flutter_test/flutter_test.dart';
import 'package:labasset_mobile/data/models/maintenance.dart';
import 'package:labasset_mobile/data/models/repair.dart';
import 'package:labasset_mobile/data/models/task.dart';
import 'package:labasset_mobile/data/repositories/calibrations_repository.dart';
import 'package:labasset_mobile/data/repositories/repairs_repository.dart';
import 'package:labasset_mobile/data/repositories/tasks_repository.dart';
import 'package:labasset_mobile/modules/equipment/tabs/maintenance_tab.dart';
import 'package:labasset_mobile/modules/equipment/tabs/repairs_tab.dart';
import 'package:mocktail/mocktail.dart';

class _Repairs extends Mock implements RepairsRepository {}

class _Tasks extends Mock implements TasksRepository {}

class _Calibrations extends Mock implements CalibrationsRepository {}

void main() {
  group('EquipmentRepairsTabController', () {
    test('tải phiếu sửa chữa theo equipmentId, limit 50', () async {
      final repo = _Repairs();
      when(
        () => repo.list(
          equipmentId: any(named: 'equipmentId'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer(
        (_) async => const RepairPage(
          items: [
            RepairSummary(id: 'r1', code: 'SC-1', equipmentId: 'e1'),
            RepairSummary(id: 'r2', code: 'SC-2', equipmentId: 'e1'),
          ],
          total: 2,
        ),
      );
      final c = EquipmentRepairsTabController(repairs: repo, equipmentId: 'e1');
      await c.load();
      expect(c.loading.value, isFalse);
      expect(c.error.value, isNull);
      expect(c.items.map((r) => r.code), ['SC-1', 'SC-2']);
      verify(() => repo.list(equipmentId: 'e1', limit: 50)).called(1);
    });

    test('lỗi API → error, danh sách rỗng', () async {
      final repo = _Repairs();
      when(
        () => repo.list(
          equipmentId: any(named: 'equipmentId'),
          limit: any(named: 'limit'),
        ),
      ).thenThrow(Exception('boom'));
      final c = EquipmentRepairsTabController(repairs: repo, equipmentId: 'e1');
      await c.load();
      expect(c.error.value, isNotNull);
      expect(c.items, isEmpty);
      expect(c.loading.value, isFalse);
    });
  });

  group('EquipmentMaintenanceTabController', () {
    test('tải song song công việc + kiểm định của máy', () async {
      final tasks = _Tasks();
      final cals = _Calibrations();
      when(
        () => tasks.list(
          equipmentId: any(named: 'equipmentId'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer(
        (_) async => const TaskPage(
          items: [
            TaskSummary(
              id: 't1',
              code: 'BD-1',
              equipmentId: 'e1',
              scheduledAt: '2026-09-01T00:00:00Z',
              status: 'overdue',
            ),
          ],
          total: 1,
        ),
      );
      when(
        () => cals.list(
          equipmentId: any(named: 'equipmentId'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer(
        (_) async => const CalibrationPage(
          items: [
            Calibration(id: 'c1', code: 'KD-1', equipmentId: 'e1'),
            Calibration(
              id: 'c2',
              code: 'KD-2',
              equipmentId: 'e1',
              result: 'pass',
            ),
          ],
          total: 2,
        ),
      );
      final c = EquipmentMaintenanceTabController(
        tasks: tasks,
        calibrations: cals,
        equipmentId: 'e1',
      );
      await c.load();
      expect(c.isEmpty, isFalse);
      expect(c.taskItems.single.code, 'BD-1');
      expect(c.calibrationItems.map((x) => x.code), ['KD-1', 'KD-2']);
      verify(() => tasks.list(equipmentId: 'e1', limit: 50)).called(1);
      verify(() => cals.list(equipmentId: 'e1', limit: 50)).called(1);
    });

    test('một nguồn lỗi → error, isEmpty', () async {
      final tasks = _Tasks();
      final cals = _Calibrations();
      when(
        () => tasks.list(
          equipmentId: any(named: 'equipmentId'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => const TaskPage(items: [], total: 0));
      when(
        () => cals.list(
          equipmentId: any(named: 'equipmentId'),
          limit: any(named: 'limit'),
        ),
      ).thenThrow(Exception('boom'));
      final c = EquipmentMaintenanceTabController(
        tasks: tasks,
        calibrations: cals,
        equipmentId: 'e1',
      );
      await c.load();
      expect(c.error.value, isNotNull);
      expect(c.isEmpty, isTrue);
    });
  });
}
