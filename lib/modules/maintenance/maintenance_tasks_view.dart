import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/format/format.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_list.dart';
import '../../core/widgets/status_badge.dart';
import 'maintenance_tasks_controller.dart';

/// Danh sách công việc bảo dưỡng.
class MaintenanceTasksView extends GetView<MaintenanceTasksController> {
  const MaintenanceTasksView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('maintenance.title'.tr),
        actions: [
          IconButton(
            tooltip: 'calibration.title'.tr,
            icon: const Icon(Icons.verified_outlined),
            onPressed: () => Get.toNamed(Routes.calibrations),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Row(
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
          ),
          Expanded(
            child: Obx(() {
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
                  icon: Icons.event_available_outlined,
                  title: 'maintenance.empty'.tr,
                );
              }
              return RefreshIndicator(
                onRefresh: controller.load,
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: controller.items.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (_, i) {
                    final t = controller.items[i];
                    return Card(
                      child: ListTile(
                        title: Text('${t.code} — ${t.equipmentLabel}'),
                        subtitle: Text(
                          '${formatDate(t.scheduledAt)}'
                          '${t.dueAt == null ? '' : ' · ${'maintenance.due'.tr}: ${formatDate(t.dueAt)}'}',
                          style: theme.textTheme.bodySmall,
                        ),
                        trailing: StatusBadge(
                          tone: toneForTaskStatus(t.status),
                          label: 'status.task.${t.status}'.tr,
                        ),
                        onTap: () async {
                          await Get.toNamed(Routes.maintenanceTask(t.id));
                          await controller.load();
                        },
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
