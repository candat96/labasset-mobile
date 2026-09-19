import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../data/models/calendar.dart';
import 'calendar_controller.dart';

/// Màn Lịch: bảo dưỡng / kiểm định / sửa chữa theo ngày.
class CalendarView extends GetView<CalendarController> {
  const CalendarView({super.key});

  static Color colorFor(BuildContext context, String type) => switch (type) {
    'maintenance' => context.status.info,
    'calibration' => const Color(0xFF7C3AED),
    'repair' => context.status.danger,
    _ => context.status.warning,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('calendar.title'.tr)),
      body: Column(
        children: [
          Obx(
            () => Wrap(
              spacing: AppSpacing.xs,
              children: [
                for (final t in CalendarController.types)
                  FilterChip(
                    label: Text('calendar.type.$t'.tr),
                    selected: controller.activeTypes.contains(t),
                    onSelected: (v) => controller.toggleType(t, v),
                  ),
                FilterChip(
                  label: Text('calendar.mine'.tr),
                  selected: controller.mineOnly.value,
                  onSelected: controller.setMineOnly,
                ),
              ],
            ),
          ),
          Obx(
            () => TableCalendar<CalendarItem>(
              locale: 'vi_VN',
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: controller.focusedDay.value,
              calendarFormat: controller.format.value,
              selectedDayPredicate: (d) =>
                  isSameDay(d, controller.selectedDay.value),
              eventLoader: controller.eventsForDay,
              onDaySelected: controller.onDaySelected,
              onFormatChanged: (f) => controller.format.value = f,
              onPageChanged: controller.onPageChanged,
              availableCalendarFormats: const {
                CalendarFormat.month: 'Tháng',
                CalendarFormat.week: 'Tuần',
              },
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, events) {
                  if (events.isEmpty) return null;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final e in events.take(4))
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: colorFor(context, e.type),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Obx(() {
              if (controller.loading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.error.value != null) {
                return ErrorState(
                  error: controller.error.value!,
                  onRetry: controller.load,
                );
              }
              final events = controller.eventsForDay(
                controller.selectedDay.value,
              );
              if (events.isEmpty) {
                return EmptyState(
                  icon: Icons.event_busy_outlined,
                  title: 'calendar.emptyDay'.tr,
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: events.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final e = events[i];
                  return ListTile(
                    leading: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: colorFor(context, e.type),
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Text(e.title),
                    subtitle: Text(
                      [
                        e.equipment?.name,
                        e.assigneeName,
                        e.status.isEmpty ? null : 'status.task.${e.status}'.tr,
                      ].whereType<String>().join(' · '),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => controller.open(e),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
