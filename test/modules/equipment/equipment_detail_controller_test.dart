import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:labasset_mobile/core/errors/api_error.dart';
import 'package:labasset_mobile/core/i18n/app_translations.dart';
import 'package:labasset_mobile/data/models/equipment_detail.dart';
import 'package:labasset_mobile/data/models/task.dart';
import 'package:labasset_mobile/data/repositories/equipment_repository.dart';
import 'package:labasset_mobile/data/repositories/tasks_repository.dart';
import 'package:labasset_mobile/modules/equipment/equipment_detail_controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockEquipment extends Mock implements EquipmentRepository {}

class _MockTasks extends Mock implements TasksRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(const EquipmentNetwork());
  });

  late _MockEquipment equipment;
  late _MockTasks tasks;
  late EquipmentDetailController c;

  setUp(() {
    Get.testMode = true;
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('vi', 'VN');
    equipment = _MockEquipment();
    tasks = _MockTasks();
    c = EquipmentDetailController(
      equipment: equipment,
      tasks: tasks,
      id: 'e1',
      userId: 'u1',
    );
  });

  tearDown(Get.reset);

  const detail = EquipmentDetail(
    id: 'e1',
    code: 'M1',
    name: 'Máy X',
    status: 'active',
    currentRunHours: '120.5',
    currentTestCount: 30,
  );

  test('load nạp chi tiết máy', () async {
    when(() => equipment.detail('e1')).thenAnswer((_) async => detail);
    await c.load();
    expect(c.item.value?.code, 'M1');
    expect(c.loading.value, isFalse);
    expect(c.error.value, isNull);
  });

  test('load lỗi giữ error', () async {
    when(
      () => equipment.detail('e1'),
    ).thenThrow(ApiError(404, 'NOT_FOUND', ''));
    await c.load();
    expect(c.error.value, isNotNull);
  });

  test('allowedTransitions theo ma trận API', () {
    expect(c.allowedTransitions('active'), contains('broken'));
    expect(c.allowedTransitions('retired'), contains('disposed'));
    expect(c.allowedTransitions('disposed'), isEmpty);
    expect(c.allowedTransitions('unknown'), isEmpty);
  });

  test('changeStatus gửi API rồi reload', () async {
    when(() => equipment.detail('e1')).thenAnswer((_) async => detail);
    when(
      () => equipment.changeStatus('e1', 'broken', 'hỏng bơm'),
    ).thenAnswer((_) async {});
    final ok = await c.changeStatus('broken', 'hỏng bơm');
    expect(ok, isTrue);
    verify(() => equipment.changeStatus('e1', 'broken', 'hỏng bơm')).called(1);
  });

  test('changeStatus lỗi → trả false, không ném', () async {
    when(
      () => equipment.changeStatus(any(), any(), any()),
    ).thenThrow(ApiError(400, 'EQUIPMENT_INVALID_STATUS_TRANSITION', ''));
    expect(await c.changeStatus('disposed', 'x'), isFalse);
  });

  test('addCounters gửi số giờ dạng chuỗi (không double)', () async {
    when(() => equipment.detail('e1')).thenAnswer((_) async => detail);
    when(
      () => equipment.addCounters(
        'e1',
        runHours: any(named: 'runHours'),
        testCount: any(named: 'testCount'),
        note: any(named: 'note'),
      ),
    ).thenAnswer((_) async {});
    final ok = await c.addCounters(
      runHours: '120.5',
      testCount: 31,
      note: 'sau bảo dưỡng',
    );
    expect(ok, isTrue);
    final captured = verify(
      () => equipment.addCounters(
        'e1',
        runHours: captureAny(named: 'runHours'),
        testCount: captureAny(named: 'testCount'),
        note: any(named: 'note'),
      ),
    ).captured;
    expect(captured[0], isA<String>());
  });

  test('reprintLabel ghi đúng nội dung yêu cầu in tem', () async {
    when(() => equipment.addNote('e1', any())).thenAnswer((_) async {});
    await c.reprintLabel();
    verify(() => equipment.addNote('e1', 'Yêu cầu in lại tem QR')).called(1);
  });

  test('createAdhocMaintenance gán cho chính mình + scheduledAt now', () async {
    when(
      () => tasks.create(
        equipmentId: 'e1',
        scheduledAt: any(named: 'scheduledAt'),
        assigneeId: 'u1',
        notes: any(named: 'notes'),
      ),
    ).thenAnswer(
      (_) async => const TaskSummary(
        id: 't1',
        code: 'BD-1',
        equipmentId: 'e1',
        scheduledAt: '2026-09-19T00:00:00Z',
      ),
    );
    expect(await c.createAdhocMaintenance(), isTrue);
  });

  test(
    'createTransfer lỗi TRANSFER_PENDING_EXISTS → false, không ném',
    () async {
      when(
        () => equipment.createTransfer(
          any(),
          toDepartmentId: any(named: 'toDepartmentId'),
          toLocation: any(named: 'toLocation'),
          reason: any(named: 'reason'),
        ),
      ).thenThrow(ApiError(409, 'TRANSFER_PENDING_EXISTS', ''));
      expect(
        await c.createTransfer(toDepartmentId: 'd1', reason: 'chuyển khoa'),
        isFalse,
      );
    },
  );

  test('saveLocation PATCH location', () async {
    when(() => equipment.detail('e1')).thenAnswer((_) async => detail);
    when(() => equipment.patch('e1', any())).thenAnswer((_) async {});
    expect(await c.saveLocation('Khoa XN'), isTrue);
    verify(() => equipment.patch('e1', {'location': 'Khoa XN'})).called(1);
  });

  test('saveNetwork đọc rồi PUT toàn bộ', () async {
    when(() => equipment.network('e1')).thenAnswer(
      (_) async => const EquipmentNetwork(ip: '10.0.0.1', port: 9100),
    );
    when(() => equipment.putNetwork('e1', any())).thenAnswer((_) async {});
    expect(await c.saveNetwork(mac: 'AA:BB'), isTrue);
    final sent =
        verify(() => equipment.putNetwork('e1', captureAny())).captured.single
            as EquipmentNetwork;
    expect(sent.ip, '10.0.0.1');
    expect(sent.mac, 'AA:BB');
  });
}
