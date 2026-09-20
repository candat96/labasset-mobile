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
        final empty =
            controller.repairsAssigned.isEmpty &&
            controller.tasksDue.isEmpty &&
            controller.requestsPending.isEmpty &&
            controller.requestsApproved.isEmpty;
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
                      total: controller.repairsAssignedTotal.value,
                      route: '${Routes.repairs}?segment=mine',
                      children: [
                        for (final r in controller.repairsAssigned)
                          _WorkRow(
                            title: '${r.code} — ${r.equipmentLabel}',
                            status: 'status.repair.${r.status}'.tr,
                            icon: Icons.build_outlined,
                            onTap: () => Get.toNamed(Routes.repair(r.id)),
                          ),
                      ],
                    ),
                    _WorkGroup(
                      title: 'home.task.maintenanceDue'.tr,
                      total: controller.tasksDueTotal.value,
                      route: Routes.maintenanceTasks,
                      children: [
                        for (final t in controller.tasksDue)
                          _WorkRow(
                            title: t.code,
                            status:
                                '${'status.task.${t.status}'.tr} · ${formatDate(t.scheduledAt)}',
                            icon: Icons.event_available_outlined,
                            onTap: () =>
                                Get.toNamed(Routes.maintenanceTask(t.id)),
                          ),
                      ],
                    ),
                    _WorkGroup(
                      title: 'home.task.requestsPending'.tr,
                      total: controller.requestsPendingTotal.value,
                      route: '${Routes.requests}?segment=pending',
                      children: [
                        for (final r in controller.requestsPending)
                          _WorkRow(
                            title: '${r.code} — ${r.reason}',
                            status: 'status.request.${r.status}'.tr,
                            icon: Icons.description_outlined,
                            onTap: () => Get.toNamed(Routes.request(r.id)),
                          ),
                      ],
                    ),
                    _WorkGroup(
                      title: 'home.task.requestsApproved'.tr,
                      total: controller.requestsApprovedTotal.value,
                      route: '${Routes.requests}?segment=toIssue',
                      children: [
                        for (final r in controller.requestsApproved)
                          _WorkRow(
                            title: '${r.code} — ${r.reason}',
                            status: 'status.request.${r.status}'.tr,
                            icon: Icons.inventory_outlined,
                            onTap: () => Get.toNamed(Routes.request(r.id)),
                          ),
                      ],
                    ),
                    if (empty)
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
                        value: '${controller.brokenUnassigned.value}',
                        icon: Icons.report_problem_outlined,
                        tone: controller.brokenUnassigned.value > 0
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
                        value: '${controller.suppliesAlert.value}',
                        icon: Icons.inventory_2_outlined,
                        tone: controller.suppliesAlert.value > 0
                            ? StatusTone.warning
                            : StatusTone.success,
                        onTap: () => Get.toNamed(Routes.stockAlerts),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: KpiTile(
                        label: 'home.alert.calibrationOverdue'.tr,
                        value: '${controller.calibrationOverdue.value}',
                        icon: Icons.verified_outlined,
                        tone: controller.calibrationOverdue.value > 0
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
    required this.children,
  });

  final String title;
  final int total;
  final String route;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (children.isEmpty) return const SizedBox.shrink();
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
              if (total > children.length)
                TextButton(
                  onPressed: () => Get.toNamed(route),
                  child: Text('home.viewAll'.tr),
                ),
            ],
          ),
          ...children,
        ],
      ),
    );
  }
}

class _WorkRow extends StatelessWidget {
  const _WorkRow({
    required this.title,
    required this.status,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String status;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.bodyMedium),
                  Text(status, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
