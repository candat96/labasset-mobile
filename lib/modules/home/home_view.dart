import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/format/format.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/kpi_tile.dart';
import '../../core/widgets/loading_list.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/status_badge.dart';
import '../notifications/notification_bell.dart';
import 'home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  static const _shortcuts = [
    (key: 'reportFault', icon: Icons.report_problem_outlined),
    (key: 'stockIssue', icon: Icons.outbox_outlined),
    (key: 'stockReceipt', icon: Icons.move_to_inbox_outlined),
    (key: 'stocktake', icon: Icons.fact_check_outlined),
    (key: 'calendar', icon: Icons.calendar_month_outlined),
    (key: 'equipmentNew', icon: Icons.add_box_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.hospitalName.value ?? 'app.name'.tr)),
        actions: [
          IconButton(
            tooltip: 'search.title'.tr,
            icon: const Icon(Icons.search),
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
                      title: 'home.task.repairsAssigned'.tr,
                      total: controller.repairsAssignedTotal,
                      route: '${Routes.repairs}?segment=mine',
                    ),
                    _WorkGroup(
                      title: 'home.task.repairsPendingResponse'.tr,
                      total: controller.repairsPendingResponse,
                      route: '${Routes.repairs}?segment=mine',
                    ),
                    _WorkGroup(
                      title: 'home.task.repairsOverdue'.tr,
                      total: controller.repairsOverdue,
                      route: '${Routes.repairs}?segment=mine',
                    ),
                    _WorkGroup(
                      title: 'home.task.stocktakesOpen'.tr,
                      total: controller.stocktakesOpenTotal,
                      route: Routes.stocktakes,
                    ),
                    _WorkGroup(
                      title: 'home.task.maintenanceDue'.tr,
                      total: controller.tasksDueTotal,
                      route: Routes.maintenanceTasks,
                    ),
                    _WorkGroup(
                      title: 'home.task.maintenanceOverdue'.tr,
                      total: controller.tasksOverdue,
                      route: Routes.maintenanceTasks,
                    ),
                    _WorkGroup(
                      title: 'home.task.requestsPending'.tr,
                      total: controller.requestsPendingTotal,
                      route: '${Routes.requests}?segment=pending',
                    ),
                    _WorkGroup(
                      title: 'home.task.requestsApproved'.tr,
                      total: controller.requestsApprovedTotal,
                      route: '${Routes.requests}?segment=toIssue',
                    ),
                    _WorkGroup(
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
                        label: 'home.alert.brokenUnassigned'.tr,
                        value: '${controller.brokenUnassigned}',
                        icon: Icons.report_problem_outlined,
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
                        label: 'home.alert.suppliesLow'.tr,
                        value: '${controller.suppliesAlert}',
                        icon: Icons.inventory_2_outlined,
                        tone: controller.suppliesAlert > 0
                            ? StatusTone.warning
                            : StatusTone.success,
                        onTap: () => Get.toNamed(Routes.stockAlerts),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: KpiTile(
                        label: 'home.alert.calibrationOverdue'.tr,
                        value: '${controller.calibrationOverdue}',
                        icon: Icons.verified_outlined,
                        tone: controller.calibrationOverdue > 0
                            ? StatusTone.danger
                            : StatusTone.success,
                        onTap: () => Get.toNamed(Routes.calibrations),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('home.shortcuts'.tr, style: theme.textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppSpacing.sm,
                crossAxisSpacing: AppSpacing.sm,
                childAspectRatio: 1.3,
                children: [
                  for (final s in _shortcuts)
                    Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
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
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(s.icon, color: theme.colorScheme.primary),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'placeholder.${s.key}'.tr,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.labelMedium,
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
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
    required this.title,
    required this.total,
    required this.route,
  });

  final String title;
  final int total;
  final String route;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (total == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$title ($total)',
                  style: theme.textTheme.labelLarge,
                ),
              ),
              TextButton(
                onPressed: () => Get.toNamed(route),
                child: Text('home.viewAll'.tr),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
