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
import '../../data/models/report.dart';
import 'reports_controller.dart';

class ReportsView extends GetView<ReportsController> {
  const ReportsView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('reports.title'.tr)),
    body: Obx(() {
      if (controller.loading.value && controller.cards.isEmpty) {
        return const LoadingList();
      }
      if (controller.error.value != null && controller.cards.isEmpty) {
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
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppSpacing.sm,
                  mainAxisSpacing: AppSpacing.sm,
                  childAspectRatio: 1.55,
                ),
                itemCount: controller.cards.length,
                itemBuilder: (_, index) {
                  final card = controller.cards[index];
                  return KpiTile(
                    label: card.title,
                    value: _value(card),
                    icon: _icon(card.key),
                    tone: _tone(card),
                    onTap: _route(card.link) == null
                        ? null
                        : () => Get.toNamed(_route(card.link)!),
                  );
                },
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
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
                  for (final machine in controller.machines.where(
                    (item) =>
                        controller.machinesSearch.text.isEmpty ||
                        item.code.toLowerCase().contains(
                          controller.machinesSearch.text.toLowerCase(),
                        ) ||
                        item.name.toLowerCase().contains(
                          controller.machinesSearch.text.toLowerCase(),
                        ),
                  ))
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text('${machine.code} — ${machine.name}'),
                      subtitle: Text(
                        [
                          machine.location,
                          machine.departmentLabel,
                        ].whereType<String>().join(' · '),
                      ),
                      trailing: StatusBadge(
                        tone: toneForEquipmentStatus(machine.status),
                        label: 'status.${machine.status}'.tr,
                      ),
                      onTap: () => Get.toNamed(Routes.equipment(machine.id)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SectionCard(
              title: 'reports.export'.tr,
              child: Column(
                children: [
                  for (final report in controller.reportList)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.table_chart_outlined),
                      title: Text(report.title),
                      trailing: controller.exportingKey.value == report.key
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.download_outlined),
                      onTap: controller.exportingKey.value == null
                          ? () => controller.chooseExport(report)
                          : null,
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

  static String _value(DashboardCard card) => card.unit == 'VND'
      ? formatVnd(card.value.toString())
      : '${card.value}${card.unit == null ? '' : ' ${card.unit}'}';

  static IconData _icon(String key) {
    if (key.startsWith('equipment.')) return Icons.biotech_outlined;
    if (key.startsWith('repair.')) return Icons.build_outlined;
    if (key.startsWith('maintenance.')) return Icons.event_available_outlined;
    if (key.startsWith('calibration.')) return Icons.verified_outlined;
    if (key.startsWith('stock.')) return Icons.inventory_2_outlined;
    return Icons.description_outlined;
  }

  static StatusTone _tone(DashboardCard card) =>
      card.key.contains('broken') || card.key.contains('overdue')
      ? StatusTone.danger
      : card.key.contains('expiring') || card.key.contains('lowStock')
      ? StatusTone.warning
      : StatusTone.success;

  static String? _route(String link) {
    if (link.startsWith('/repairs')) return link;
    if (link.startsWith('/maintenance/tasks')) return link;
    if (link.startsWith('/calibrations')) return link;
    if (link.startsWith('/stock/alerts')) return link;
    if (link.startsWith('/requests')) return link;
    return null;
  }
}
