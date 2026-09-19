import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:labasset_mobile/core/errors/api_error.dart';
import 'package:labasset_mobile/core/i18n/app_translations.dart';
import 'package:labasset_mobile/core/sync/outbox_service.dart';
import 'package:labasset_mobile/data/models/maintenance.dart';
import 'package:labasset_mobile/data/repositories/tasks_repository.dart';
import 'package:labasset_mobile/modules/maintenance/maintenance_task_controller.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_helpers.dart';

class _MockTasks extends Mock implements TasksRepository {}

class _MockOutbox extends Mock implements OutboxService {}

void main() {
  late _MockTasks tasks;
  late _MockOutbox outbox;
  late FakeKvCache cache;
  late MaintenanceTaskController c;

  const detail = MaintenanceTask(
    id: 't1',
    code: 'BD-1',
    equipmentId: 'e1',
    scheduledAt: '2026-09-19T08:00:00Z',
    status: 'in_progress',
    clientVersion: 3,
    templateItems: [
      ChecklistItem(key: 'k1', label: 'Kiểm tra bơm', type: 'check'),
      ChecklistItem(
        key: 'k2',
        label: 'Đo áp suất',
        type: 'measure',
        unit: 'bar',
        min: 1,
        max: 3,
      ),
      ChecklistItem(key: 'k3', label: 'Ghi chú', type: 'text'),
      ChecklistItem(key: 'k4', label: 'Vệ sinh', type: 'check', optional: true),
    ],
    results: [TaskResult(key: 'k1', pass: true)],
  );

  setUp(() {
    Get.testMode = true;
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('vi', 'VN');
    tasks = _MockTasks();
    outbox = _MockOutbox();
    cache = FakeKvCache();
    when(() => tasks.detail('t1')).thenAnswer((_) async => detail);
    when(() => outbox.enqueue(any(), any())).thenAnswer((_) async => 'o1');
    when(() => outbox.run()).thenAnswer((_) async => true);
    c = MaintenanceTaskController(
      tasks: tasks,
      outbox: outbox,
      cache: cache,
      id: 't1',
      userId: 'u1',
      roles: const ['EQUIPMENT_STAFF'],
    );
  });

  tearDown(Get.reset);

  test('load nạp checklist + kết quả server', () async {
    await c.load();
    expect(c.item.value?.code, 'BD-1');
    expect(c.results['k1']?.pass, isTrue);
    expect(c.canWork, isTrue);
    expect(c.canFinish, isTrue);
  });

  test('khôi phục nháp từ cache', () async {
    await cache.put('maintenance.draft.t1', {
      'results': [
        {'key': 'k2', 'value': '2,5', 'pass': true},
      ],
    });
    await c.load();
    expect(c.draftRestored.value, isTrue);
    expect(c.results['k2']?.value, '2,5');
  });

  test('setValue đo tự đánh dấu pass theo min–max', () async {
    await c.load();
    c.setValue('k2', '2');
    expect(c.results['k2']?.pass, isTrue);
    c.setValue('k2', '5');
    expect(c.results['k2']?.pass, isFalse);
  });

  test('setCheck và N/A cho mục optional', () async {
    await c.load();
    c.setCheck('k1', false);
    expect(c.results['k1']?.pass, isFalse);
    c.setValue('k4', 'na');
    expect(c.results['k4']?.value, 'na');
  });

  test('persistDraft ghi cache + enqueue outbox task_result', () async {
    await c.load();
    c.setCheck('k1', true);
    await c.persistDraft();
    expect(cache.store.containsKey('maintenance.draft.t1'), isTrue);
    final payload =
        verify(
              () => outbox.enqueue('task_result', captureAny()),
            ).captured.single
            as Map<String, dynamic>;
    expect(payload['taskId'], 't1');
    expect(payload['clientVersion'], 3);
    expect((payload['results'] as List), isNotEmpty);
  });

  test('finish 409 stale → bật staleVersion, không xoá nháp', () async {
    await c.load();
    when(
      () => tasks.finish(
        't1',
        overallPass: any(named: 'overallPass'),
        notes: any(named: 'notes'),
      ),
    ).thenThrow(ApiError(409, 'MAINT_STALE_VERSION', ''));
    expect(await c.finish(overallPass: true), isFalse);
    expect(c.staleVersion.value, isTrue);
  });

  test('finish thiếu mục → highlight details.keys', () async {
    await c.load();
    when(
      () => tasks.finish(
        't1',
        overallPass: any(named: 'overallPass'),
        notes: any(named: 'notes'),
      ),
    ).thenThrow(
      ApiError(400, 'VALIDATION_ERROR', '', {
        'keys': ['k2', 'k3'],
      }),
    );
    expect(await c.finish(overallPass: true), isFalse);
    expect(c.missingKeys, {'k2', 'k3'});
  });

  test('start gửi token QR; lỗi MAINT_QR_MISMATCH trả false', () async {
    when(
      () => tasks.start('t1', equipmentQrToken: 'tok'),
    ).thenAnswer((_) async {});
    expect(await c.start(qrToken: 'tok'), isTrue);

    when(
      () => tasks.start('t1', equipmentQrToken: 'sai'),
    ).thenThrow(ApiError(400, 'MAINT_QR_MISMATCH', ''));
    expect(await c.start(qrToken: 'sai'), isFalse);
  });

  test('TaskResultOutboxHandler gửi đúng taskId + clientVersion', () async {
    when(
      () => tasks.saveResults(
        't1',
        clientVersion: any(named: 'clientVersion'),
        results: any(named: 'results'),
      ),
    ).thenAnswer((_) async {});
    final handler = TaskResultOutboxHandler(tasks);
    expect(handler.type, 'task_result');
    await handler.send({
      'taskId': 't1',
      'clientVersion': 4,
      'results': [
        {'key': 'k1', 'pass': true},
      ],
    });
    verify(
      () => tasks.saveResults(
        't1',
        clientVersion: 4,
        results: any(named: 'results'),
      ),
    ).called(1);
  });
}
