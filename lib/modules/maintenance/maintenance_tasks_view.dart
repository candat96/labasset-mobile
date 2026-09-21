import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/format/format.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/large_title_scaffold.dart';
import '../../core/widgets/list_item_card.dart';
import '../../core/widgets/loading_list.dart';
import '../../core/widgets/status_badge.dart';
import 'maintenance_tasks_controller.dart';

/// Danh sách công việc bảo dưỡng.
class MaintenanceTasksView extends GetView<MaintenanceTasksController> {
  const MaintenanceTasksView({super.key});

  @override
  Widget build(BuildContext context) {
    return LargeTitleScaffold(
      title: 'maintenance.title'.tr,
      actions: [
        CircleIconButton(
          icon: LucideIcons.badgeCheck,
          tooltip: 'calibration.title'.tr,
          onTap: () => Get.toNamed(Routes.calibrations),
        ),
      ],
      header: Row(
        children: [
          Obx(
            () => FilterChip(
              label: Text('maintenance.mine'.tr),
              selected: controller.mineOnly.value,
              onSelected: controller.setMineOnly,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Obx(
              () => DropdownButtonFormField<String>(
                initialValue: controller.statusFilter.value,
                isDense: true,
                decoration: InputDecoration(
                  labelText: 'maintenance.filter.status'.tr,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text('repairs.segment.all'.tr),
                  ),
                  for (final s in [
                    'scheduled',
                    'in_progress',
                    'done',
                    'skipped',
                    'overdue',
                  ])
                    DropdownMenuItem(
                      value: s,
                      child: Text('status.task.$s'.tr),
                    ),
                ],
                onChanged: controller.setStatus,
              ),
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.loading.value && controller.items.isEmpty) {
          return const LoadingList();
        }
        if (controller.error.value != null && controller.items.isEmpty) {
          return ErrorState(
            error: controller.error.value!,
            onRetry: controller.load,
          );
        }
        if (controller.items.isEmpty) {
          return EmptyState(
            icon: LucideIcons.calendarCheck,
            title: 'maintenance.empty'.tr,
          );
        }
        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.xxl * 2,
            ),
            itemCount: controller.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (_, i) {
              final t = controller.items[i];
              final tone = toneForTaskStatus(t.status);
              return ListItemCard(
                code: t.code,
                badge: StatusBadge(
                  tone: tone,
                  label: 'status.task.${t.status}'.tr,
                ),
                title: t.equipmentLabel,
                accentColor: paletteForTone(context, tone).color,
                metas: [
                  ListMeta(LucideIcons.calendarDays, formatDate(t.scheduledAt)),
                  if (t.dueAt != null)
                    ListMeta(
                      LucideIcons.clock3,
                      '${'maintenance.due'.tr}: ${formatDate(t.dueAt)}',
                      color: t.status == 'overdue'
                          ? context.status.danger
                          : null,
                    ),
                ],
                onTap: () async {
                  await Get.toNamed(Routes.maintenanceTask(t.id));
                  await controller.load();
                },
              );
            },
          ),
        );
      }),
    );
  }
}
