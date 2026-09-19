import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:labasset_mobile/core/i18n/app_translations.dart';
import 'package:labasset_mobile/data/models/calendar.dart';
import 'package:labasset_mobile/data/models/equipment.dart';
import 'package:labasset_mobile/data/repositories/calendar_repository.dart';
import 'package:labasset_mobile/modules/calendar/calendar_controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockCalendar extends Mock implements CalendarRepository {}

void main() {
  late _MockCalendar repo;
  late CalendarController c;
  late List<String> routes;

  setUp(() {
    Get.testMode = true;
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('vi', 'VN');
    repo = _MockCalendar();
    routes = [];
    c = CalendarController(calendar: repo, userId: 'u1');
    when(
      () => repo.list(
        from: any(named: 'from'),
        to: any(named: 'to'),
        types: any(named: 'types'),
        assigneeId: any(named: 'assigneeId'),
      ),
    ).thenAnswer(
      (_) async => CalendarPage(
        items: [
          CalendarItem(
            id: 'r1',
            type: 'repair',
            title: 'Sửa máy X',
            start: '2026-09-19T08:00:00Z',
            end: '2026-09-19T09:00:00Z',
            equipment: const EquipmentRef(id: 'e1', code: 'M1', name: 'Máy X'),
          ),
          CalendarItem(
            id: 't1',
            type: 'maintenance',
            title: 'Bảo dưỡng máy Y',
            start: '2026-09-20T08:00:00Z',
            end: '2026-09-20T09:00:00Z',
          ),
        ],
      ),
    );
  });

  tearDown(Get.reset);

  test('load nạp sự kiện theo tháng', () async {
    await c.load();
    expect(c.items, hasLength(2));
    expect(c.error.value, isNull);
  });

  test('eventsForDay lọc theo ngày', () async {
    await c.load();
    final day = DateTime(2026, 9, 19);
    final events = c.eventsForDay(day);
    expect(events.single.type, 'repair');
  });

  test('toggleType và mineOnly truyền tham số lọc', () async {
    await c.load();
    c.toggleType('repair', false);
    await Future<void>.delayed(Duration.zero);
    verify(
      () => repo.list(
        from: any(named: 'from'),
        to: any(named: 'to'),
        types: captureAny(named: 'types'),
        assigneeId: any(named: 'assigneeId'),
      ),
    ).captured.isNotEmpty;
    expect(c.activeTypes.contains('repair'), isFalse);

    c.setMineOnly(true);
    await Future<void>.delayed(Duration.zero);
    verify(
      () => repo.list(
        from: any(named: 'from'),
        to: any(named: 'to'),
        types: any(named: 'types'),
        assigneeId: 'u1',
      ),
    ).called(1);
  });

  test('open điều hướng theo loại', () async {
    final cc = CalendarController(
      calendar: repo,
      userId: 'u1',
      navigate: (r) async => routes.add(r),
    );
    await cc.load();
    await cc.open(cc.items.first);
    await cc.open(cc.items.last);
    expect(routes, ['/repairs/r1', '/placeholder/maintenance']);
  });
}
