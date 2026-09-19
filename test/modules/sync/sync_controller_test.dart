import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:labasset_mobile/core/i18n/app_translations.dart';
import 'package:labasset_mobile/core/sync/outbox_item.dart';
import 'package:labasset_mobile/core/sync/outbox_service.dart';
import 'package:labasset_mobile/modules/sync/sync_controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockOutbox extends Mock implements OutboxService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('vi', 'VN');
  });

  tearDown(Get.reset);

  test('load danh sách chờ từ outbox', () async {
    final outbox = _MockOutbox();
    final items = [
      OutboxItem(
        id: 'o1',
        type: 'repair_log',
        payload: const {'clientId': 'c1'},
        createdAt: DateTime(2026, 9, 19, 8),
      ),
      OutboxItem(
        id: 'o2',
        type: 'attachment',
        payload: const {},
        createdAt: DateTime(2026, 9, 19, 9),
        attempts: 2,
        lastError: 'INTERNAL_ERROR',
      ),
    ];
    when(() => outbox.items()).thenAnswer((_) async => items);
    when(() => outbox.refreshCounts()).thenAnswer((_) async {});
    final c = SyncController(outbox: outbox);
    await c.load();
    expect(c.items, hasLength(2));
    expect(c.error.value, isNull);
    expect(c.loading.value, isFalse);
  });

  test('load lỗi giữ error', () async {
    final outbox = _MockOutbox();
    when(() => outbox.items()).thenThrow(Exception('boom'));
    final c = SyncController(outbox: outbox);
    await c.load();
    expect(c.error.value, isNotNull);
  });

  test('runNow/retryAll gọi service rồi tải lại', () async {
    final outbox = _MockOutbox();
    when(() => outbox.items()).thenAnswer((_) async => []);
    when(() => outbox.refreshCounts()).thenAnswer((_) async {});
    when(() => outbox.run(manual: true)).thenAnswer((_) async => true);
    when(() => outbox.retryAll()).thenAnswer((_) async => true);
    final c = SyncController(outbox: outbox);
    await c.runNow();
    await c.retryAll();
    verify(() => outbox.run(manual: true)).called(1);
    verify(() => outbox.retryAll()).called(1);
  });

  test('offline → hiện thông báo, không lỗi', () async {
    final outbox = _MockOutbox();
    when(() => outbox.items()).thenAnswer((_) async => []);
    when(() => outbox.refreshCounts()).thenAnswer((_) async {});
    when(() => outbox.run(manual: true)).thenAnswer((_) async => false);
    final c = SyncController(outbox: outbox);
    await c.runNow();
    expect(c.error.value, isNull);
  });
}
