import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/routes/app_routes.dart';
import '../../data/models/calendar.dart';
import '../../data/repositories/calendar_repository.dart';

/// Lịch `/calendar`: tháng/tuần, chấm màu theo loại, lọc việc của tôi.
class CalendarController extends GetxController {
  CalendarController({
    required this.calendar,
    this.userId = '',
    Future<void> Function(String route)? navigate,
  }) : _navigate = navigate ?? ((r) async => Get.toNamed(r));

  final CalendarRepository calendar;
  final String userId;
  final Future<void> Function(String route) _navigate;

  static const types = ['maintenance', 'calibration', 'repair'];

  final Rx<DateTime> focusedDay = DateTime.now().obs;
  final Rx<DateTime> selectedDay = DateTime.now().obs;
  final Rx<CalendarFormat> format = CalendarFormat.month.obs;
  final RxSet<String> activeTypes = {...types}.obs;
  final RxBool mineOnly = false.obs;
  final RxBool loading = true.obs;
  final Rxn<Object> error = Rxn<Object>();
  final RxList<CalendarItem> items = <CalendarItem>[].obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      final first = DateTime(
        focusedDay.value.year,
        focusedDay.value.month - 1,
        1,
      );
      final last = DateTime(
        focusedDay.value.year,
        focusedDay.value.month + 2,
        0,
      );
      final page = await calendar.list(
        from: first.toUtc().toIso8601String(),
        to: last.toUtc().toIso8601String(),
        types: activeTypes.toList(),
        assigneeId: mineOnly.value && userId.isNotEmpty ? userId : null,
      );
      items.assignAll(page.items);
    } catch (e) {
      error.value = e;
    } finally {
      loading.value = false;
    }
  }

  void onDaySelected(DateTime selected, DateTime focused) {
    selectedDay.value = selected;
    focusedDay.value = focused;
  }

  void onPageChanged(DateTime focused) {
    focusedDay.value = focused;
    load();
  }

  void toggleType(String type, bool on) {
    if (on) {
      activeTypes.add(type);
    } else {
      activeTypes.remove(type);
    }
    load();
  }

  void setMineOnly(bool v) {
    mineOnly.value = v;
    load();
  }

  List<CalendarItem> eventsForDay(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return items.where((i) {
      final start = DateTime.tryParse(i.start)?.toLocal();
      final end = DateTime.tryParse(i.end)?.toLocal();
      if (start == null) return false;
      final s = DateTime(start.year, start.month, start.day);
      final e = end == null ? s : DateTime(end.year, end.month, end.day);
      return !d.isBefore(s) && !d.isAfter(e);
    }).toList();
  }

  Future<void> open(CalendarItem item) async {
    switch (item.type) {
      case 'repair':
        await _navigate(Routes.repair(item.id));
      default:
        await _navigate(Routes.placeholderFor('maintenance'));
    }
  }
}
