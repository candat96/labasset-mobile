import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/format/format.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/kpi_tile.dart';
import '../../core/widgets/loading_list.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/status_badge.dart';
import 'reports_controller.dart';

/// Báo cáo nhanh `/reports`.
class ReportsView extends GetView<ReportsController> {
  const ReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('reports.title'.tr)),
      body: Obx(() {
        if (controller.loading.value && controller.equipmentByStatus.isEmpty) {
          return const LoadingList();
        }
        if (controller.error.value != null &&
            controller.equipmentByStatus.isEmpty) {
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
              SectionCard(
                title: 'reports.kpi'.tr,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: KpiTile(
                            label: 'reports.tickets'.tr,
                            value:
                                '${controller.monthStats.value?.tickets.toInt() ?? 0}',
                            icon: Icons.build_outlined,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: KpiTile(
                            label: 'reports.completed'.tr,
                            value:
                                '${controller.monthStats.value?.completed.toInt() ?? 0}',
                            icon: Icons.check_circle_outline,
                            tone: StatusTone.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: KpiTile(
                            label: 'reports.cost'.tr,
                            value: formatVnd(controller.monthStats.value?.cost),
                            icon: Icons.payments_outlined,
                            tone: StatusTone.warning,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: KpiTile(
                            label: 'reports.alerts'.tr,
                            value: '${controller.alertsTotal.value}',
                            icon: Icons.warning_amber_outlined,
                            tone: controller.alertsTotal.value > 0
                                ? StatusTone.danger
                                : StatusTone.success,
                            onTap: () => Get.toNamed(Routes.stockAlerts),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SectionCard(
                title: 'reports.equipmentByStatus'.tr,
                child: SizedBox(
                  height: 180,
                  child: BarChart(
                    BarChartData(
                      barGroups: [
                        for (
                          var i = 0;
                          i < ReportsController.statuses.length;
                          i++
                        )
                          BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY:
                                    (controller.equipmentByStatus[ReportsController
                                                .statuses[i]] ??
                                            0)
                                        .toDouble(),
                                color: theme.colorScheme.primary,
                                width: 18,
                              ),
                            ],
                          ),
                      ],
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v, meta) => Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'status.${ReportsController.statuses[v.toInt()]}'
                                    .tr,
                                style: theme.textTheme.labelSmall,
                              ),
                            ),
                          ),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SectionCard(
                title: 'reports.workload'.tr,
                child: Column(
                  children: [
                    for (final w in controller.workload)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(w.fullName),
                        subtitle: Text(
                          '${'reports.workload.open'.tr}: ${w.open}'
                          ' · ${'reports.workload.overdue'.tr}: ${w.overdue}',
                          style: theme.textTheme.bodySmall,
                        ),
                        trailing: StatusBadge(
                          tone: w.overdue > 0
                              ? StatusTone.danger
                              : StatusTone.success,
                          label: '${w.open}',
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SectionCard(
                title: 'reports.machinesByDepartment'.tr,
                actions: [
                  TextButton(
                    onPressed: controller.pickDepartment,
                    child: Text(
                      controller.departmentName.value ?? 'common.pick'.tr,
                    ),
                  ),
                ],
                child: Column(
                  children: [
                    if (controller.machinesCachedAt.value != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'home.cachedAt'.trParams({
                            'time': formatDateTime(
                              controller.machinesCachedAt.value,
                            ),
                          }),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: context.status.warning,
                          ),
                        ),
                      ),
                    TextField(
                      controller: controller.machinesSearch,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: 'stock.searchHint'.tr,
                      ),
                    ),
                    for (final m in controller.machines.where(
                      (m) =>
                          controller.machinesSearch.text.isEmpty ||
                          m.code.contains(
                            controller.machinesSearch.text.toUpperCase(),
                          ) ||
                          m.name.toLowerCase().contains(
                            controller.machinesSearch.text.toLowerCase(),
                          ),
                    ))
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text('${m.code} — ${m.name}'),
                        subtitle: Text(
                          [
                            m.location,
                            m.departmentLabel,
                          ].whereType<String>().join(' · '),
                          style: theme.textTheme.bodySmall,
                        ),
                        trailing: StatusBadge(
                          tone: toneForEquipmentStatus(m.status),
                          label: 'status.${m.status}'.tr,
                        ),
                        onTap: () => Get.toNamed(Routes.equipment(m.id)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SectionCard(
                title: 'reports.export'.tr,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final r in ReportsController.reportKeys)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.table_chart_outlined),
                        title: Text(r.$2.tr),
                        trailing: const Icon(Icons.download_outlined),
                        onTap: () => AppSnackbar.info('reports.apiMissing'.tr),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        );
      }),
    );
  }
}
