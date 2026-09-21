import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/format/format.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/app_list_tile.dart';
import '../../core/widgets/kpi_tile.dart';
import '../../core/widgets/loading_list.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/shortcut_tile.dart';
import '../../core/widgets/status_badge.dart';
import '../notifications/notification_bell.dart';
import 'home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  static const _shortcuts = [
    (key: 'reportFault', icon: LucideIcons.triangleAlert),
    (key: 'stockIssue', icon: LucideIcons.packageMinus),
    (key: 'stockReceipt', icon: LucideIcons.packagePlus),
    (key: 'stocktake', icon: LucideIcons.clipboardCheck),
    (key: 'calendar', icon: LucideIcons.calendarDays),
    (key: 'equipmentNew', icon: LucideIcons.monitorUp),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/brand/logo-512.png', width: 28, height: 28),
            const SizedBox(width: AppSpacing.sm),
            Text('app.name'.tr),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'search.title'.tr,
            icon: const Icon(LucideIcons.search),
            onPressed: () => Get.toNamed(Routes.search),
          ),
          const NotificationBell(),
        ],
      ),
      body: Obx(() {
        final empty = controller.data.value == null;
        if (controller.loading.value &&
            empty &&
            controller.cachedAt.value == null) {
          return const LoadingList(rows: 6);
        }
        if (controller.error.value != null &&
            empty &&
            controller.cachedAt.value == null) {
          return ErrorState(
            error: controller.error.value!,
            onRetry: controller.load,
          );
        }
        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              if (controller.cachedAt.value != null)
                _OfflineBanner(cachedAt: controller.cachedAt.value!),
              SectionCard(
                title: 'home.myTasks'.tr,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _WorkGroup(
                      icon: LucideIcons.wrench,
                      title: 'home.task.repairsAssigned'.tr,
                      total: controller.repairsAssignedTotal,
                      route: '${Routes.repairs}?segment=mine',
                    ),
                    _WorkGroup(
                      icon: LucideIcons.messageCircleWarning,
                      title: 'home.task.repairsPendingResponse'.tr,
                      total: controller.repairsPendingResponse,
                      route: '${Routes.repairs}?segment=mine',
                    ),
                    _WorkGroup(
                      icon: LucideIcons.clockAlert,
                      title: 'home.task.repairsOverdue'.tr,
                      total: controller.repairsOverdue,
                      route: '${Routes.repairs}?segment=mine',
                    ),
                    _WorkGroup(
                      icon: LucideIcons.clipboardCheck,
                      title: 'home.task.stocktakesOpen'.tr,
                      total: controller.stocktakesOpenTotal,
                      route: Routes.stocktakes,
                    ),
                    _WorkGroup(
                      icon: LucideIcons.calendarClock,
                      title: 'home.task.maintenanceDue'.tr,
                      total: controller.tasksDueTotal,
                      route: Routes.maintenanceTasks,
                    ),
                    _WorkGroup(
                      icon: LucideIcons.clockAlert,
                      title: 'home.task.maintenanceOverdue'.tr,
                      total: controller.tasksOverdue,
                      route: Routes.maintenanceTasks,
                    ),
                    _WorkGroup(
                      icon: LucideIcons.fileCheck,
                      title: 'home.task.requestsPending'.tr,
                      total: controller.requestsPendingTotal,
                      route: '${Routes.requests}?segment=pending',
                    ),
                    _WorkGroup(
                      icon: LucideIcons.packageCheck,
                      title: 'home.task.requestsApproved'.tr,
                      total: controller.requestsApprovedTotal,
                      route: '${Routes.requests}?segment=toIssue',
                    ),
                    _WorkGroup(
                      icon: LucideIcons.inbox,
                      title: 'home.task.requestsPendingReceive'.tr,
                      total: controller.requestsPendingReceive,
                      route: '${Routes.requests}?segment=mine',
                    ),
                    if (!controller.hasWork)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                        ),
                        child: Text(
                          'home.noWork'.tr,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SectionCard(
                title: 'home.alerts'.tr,
                child: Row(
                  children: [
                    Expanded(
                      child: KpiTile(
                        label: 'home.alert.brokenShort'.tr,
                        value: '${controller.brokenUnassigned}',
                        icon: LucideIcons.triangleAlert,
                        tone: controller.brokenUnassigned > 0
                            ? StatusTone.danger
                            : StatusTone.success,
                        onTap: () =>
                            Get.toNamed('${Routes.repairs}?segment=unassigned'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: KpiTile(
                        label: 'home.alert.suppliesLowShort'.tr,
                        value: '${controller.suppliesAlert}',
                        icon: LucideIcons.packageSearch,
                        tone: controller.suppliesAlert > 0
                            ? StatusTone.warning
                            : StatusTone.success,
                        onTap: () => Get.toNamed(Routes.stockAlerts),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: KpiTile(
                        label: 'home.alert.calibrationOverdueShort'.tr,
                        value: '${controller.calibrationOverdue}',
                        icon: LucideIcons.badgeCheck,
                        tone: controller.calibrationOverdue > 0
                            ? StatusTone.danger
                            : StatusTone.success,
                        onTap: () => Get.toNamed(Routes.calibrations),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SectionCard(
                title: 'home.shortcuts'.tr,
                padding: const EdgeInsets.all(AppSpacing.md),
                child: GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: AppSpacing.sm,
                  crossAxisSpacing: AppSpacing.sm,
                  childAspectRatio: 1.05,
                  children: [
                    for (final s in _shortcuts)
                      ShortcutTile(
                        icon: s.icon,
                        label: 'placeholder.${s.key}'.tr,
                        onTap: () => Get.toNamed(switch (s.key) {
                          'equipmentNew' => Routes.equipmentNew,
                          'calendar' => Routes.calendar,
                          'stocktake' => Routes.stocktakes,
                          'reports' => Routes.reports,
                          'assistant' => Routes.ai,
                          'reportFault' => Routes.repairNew,
                          'stockIssue' => Routes.stockIssueNew,
                          'stockReceipt' => Routes.stockReceiptNew,
                          _ => Routes.stock,
                        }),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl * 2),
            ],
          ),
        );
      }),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.cachedAt});

  final DateTime cachedAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: context.status.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 18,
            color: context.status.warning,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'home.cachedAt'.trParams({'time': formatDateTime(cachedAt)}),
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkGroup extends StatelessWidget {
  const _WorkGroup({
    required this.icon,
    required this.title,
    required this.total,
    required this.route,
  });

  final IconData icon;
  final String title;
  final int total;
  final String route;

  @override
  Widget build(BuildContext context) {
    if (total == 0) return const SizedBox.shrink();
    return AppListTile(
      icon: icon,
      title: title,
      trailing: StatusBadge(tone: StatusTone.info, label: '$total'),
      onTap: () => Get.toNamed(route),
      showDivider: true,
    );
  }
}
