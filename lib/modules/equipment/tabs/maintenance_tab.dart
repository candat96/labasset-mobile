import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/format/format.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/list_item_card.dart';
import '../../../core/widgets/loading_list.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/maintenance.dart';
import '../../../data/models/task.dart';
import '../../../data/repositories/calibrations_repository.dart';
import '../../../data/repositories/tasks_repository.dart';

/// Tab "Bảo dưỡng" trong hồ sơ máy: công việc bảo dưỡng + kiểm định của máy.
class EquipmentMaintenanceTabController extends GetxController {
  EquipmentMaintenanceTabController({
    required this.tasks,
    required this.calibrations,
    required this.equipmentId,
  });

  final TasksRepository tasks;
  final CalibrationsRepository calibrations;
  final String equipmentId;

  final RxList<TaskSummary> taskItems = <TaskSummary>[].obs;
  final RxList<Calibration> calibrationItems = <Calibration>[].obs;
  final RxBool loading = true.obs;
  final Rxn<Object> error = Rxn<Object>();

  bool get isEmpty => taskItems.isEmpty && calibrationItems.isEmpty;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      final results = await Future.wait([
        tasks.list(equipmentId: equipmentId, limit: 50),
        calibrations.list(equipmentId: equipmentId, limit: 50),
      ]);
      taskItems.assignAll((results[0] as TaskPage).items);
      calibrationItems.assignAll((results[1] as CalibrationPage).items);
    } catch (e) {
      error.value = e;
    } finally {
      loading.value = false;
    }
  }
}

class MaintenanceTab extends GetView<EquipmentMaintenanceTabController> {
  const MaintenanceTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.loading.value && controller.isEmpty) {
        return const LoadingList();
      }
      if (controller.error.value != null && controller.isEmpty) {
        return ErrorState(
          error: controller.error.value!,
          onRetry: controller.load,
        );
      }
      if (controller.isEmpty) {
        return EmptyState(
          icon: LucideIcons.calendarCheck,
          title: 'equipment.maintenance.empty'.tr,
        );
      }
      return RefreshIndicator(
        onRefresh: controller.load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          children: [
            if (controller.taskItems.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.xs,
                  bottom: AppSpacing.sm,
                ),
                child: SectionTitle('maintenance.title'.tr),
              ),
              for (final t in controller.taskItems) ...[
                _TaskCard(t: t, onReload: controller.load),
                const SizedBox(height: AppSpacing.md),
              ],
            ],
            if (controller.calibrationItems.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.xs,
                  top: AppSpacing.sm,
                  bottom: AppSpacing.sm,
                ),
                child: SectionTitle('calibration.title'.tr),
              ),
              for (final c in controller.calibrationItems) ...[
                _CalibrationCard(c: c),
                const SizedBox(height: AppSpacing.md),
              ],
            ],
          ],
        ),
      );
    });
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.t, required this.onReload});

  final TaskSummary t;
  final Future<void> Function() onReload;

  @override
  Widget build(BuildContext context) {
    final tone = toneForTaskStatus(t.status);
    return ListItemCard(
      code: t.code,
      badge: StatusBadge(tone: tone, label: 'status.task.${t.status}'.tr),
      title: t.type == 'adhoc'
          ? 'maintenance.type.adhoc'.tr
          : 'maintenance.type.periodic'.tr,
      accentColor: paletteForTone(context, tone).color,
      metas: [
        ListMeta(LucideIcons.calendarDays, formatDate(t.scheduledAt)),
        if (t.dueAt != null)
          ListMeta(
            LucideIcons.clock3,
            '${'maintenance.due'.tr}: ${formatDate(t.dueAt)}',
            color: t.status == 'overdue' ? context.status.danger : null,
          ),
      ],
      onTap: () async {
        await Get.toNamed(Routes.maintenanceTask(t.id));
        await onReload();
      },
    );
  }
}

class _CalibrationCard extends StatelessWidget {
  const _CalibrationCard({required this.c});

  final Calibration c;

  @override
  Widget build(BuildContext context) {
    final done = c.result != null;
    final tone = done
        ? switch (c.result) {
            'pass' => StatusTone.success,
            'fail' => StatusTone.danger,
            _ => StatusTone.warning,
          }
        : StatusTone.info;
    return ListItemCard(
      code: c.code,
      badge: StatusBadge(
        tone: tone,
        label: done
            ? 'calibration.result.${c.result}'.tr
            : 'status.task.scheduled'.tr,
      ),
      title: c.type == 'inspection'
          ? 'calibration.type.inspection'.tr
          : 'calibration.type.calibration'.tr,
      accentColor: paletteForTone(context, tone).color,
      metas: [
        if (c.performedAt != null)
          ListMeta(
            LucideIcons.calendarCheck,
            '${'calibration.performedAt'.tr}: ${formatDate(c.performedAt)}',
          )
        else if (c.scheduledAt != null)
          ListMeta(LucideIcons.calendarDays, formatDate(c.scheduledAt)),
        if (c.nextDueAt != null)
          ListMeta(
            LucideIcons.clock3,
            '${'calibration.nextDue'.tr}: ${formatDate(c.nextDueAt)}',
          ),
        if (c.performerName != null && c.performerName!.isNotEmpty)
          ListMeta(LucideIcons.userRound, c.performerName!),
      ],
      // Chưa có màn chi tiết kiểm định riêng → mở danh sách kiểm định.
      onTap: () => Get.toNamed(Routes.calibrations),
    );
  }
}
