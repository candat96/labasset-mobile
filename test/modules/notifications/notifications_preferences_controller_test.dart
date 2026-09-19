import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:labasset_mobile/core/i18n/app_translations.dart';
import 'package:labasset_mobile/data/models/notification_preference.dart';
import 'package:labasset_mobile/data/repositories/notifications_repository.dart';
import 'package:labasset_mobile/modules/notifications/notifications_preferences_controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements NotificationsRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockRepo repo;

  setUp(() {
    Get.testMode = true;
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('vi', 'VN');
    repo = _MockRepo();
  });

  tearDown(Get.reset);

  test('load preferences', () async {
    when(() => repo.preferences()).thenAnswer(
      (_) async => [
        NotificationPreference(
          type: 'repair_assigned',
          push: true,
          inapp: true,
        ),
        NotificationPreference(type: 'stock_alert', push: false, inapp: true),
      ],
    );
    final c = NotificationsPreferencesController(repo: repo);
    await c.load();
    expect(c.items, hasLength(2));
    expect(c.items.first.type, 'repair_assigned');
    expect(c.error.value, isNull);
    expect(c.loading.value, isFalse);
  });

  test('load lỗi → giữ error để hiện ErrorState', () async {
    when(() => repo.preferences()).thenThrow(Exception('boom'));
    final c = NotificationsPreferencesController(repo: repo);
    await c.load();
    expect(c.error.value, isNotNull);
  });

  test('save gửi toàn bộ danh sách đã sửa', () async {
    when(() => repo.preferences()).thenAnswer(
      (_) async => [
        NotificationPreference(
          type: 'repair_assigned',
          push: true,
          inapp: true,
        ),
      ],
    );
    when(() => repo.savePreferences(any())).thenAnswer((_) async {});
    final c = NotificationsPreferencesController(repo: repo);
    await c.load();
    c.items.first.push = false;
    await c.save();
    final captured =
        verify(() => repo.savePreferences(captureAny())).captured.single
            as List<NotificationPreference>;
    expect(captured.single.push, isFalse);
    expect(c.saving.value, isFalse);
  });

  test('save lỗi → không ném ra ngoài', () async {
    when(() => repo.preferences()).thenAnswer(
      (_) async => [NotificationPreference(type: 'x', push: true, inapp: true)],
    );
    when(() => repo.savePreferences(any())).thenThrow(Exception('boom'));
    final c = NotificationsPreferencesController(repo: repo);
    await c.load();
    await c.save();
    expect(c.saving.value, isFalse);
  });
}
