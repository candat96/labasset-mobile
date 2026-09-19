import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/format/format.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_list.dart';
import '../../core/widgets/picker_sheet.dart';
import '../../core/widgets/status_badge.dart';
import '../../data/models/repair.dart';
import '../../data/repositories/departments_repository.dart';
import 'repairs_controller.dart';

/// Tab "Sửa chữa": segment + bộ lọc + danh sách phiếu.
class RepairsView extends GetView<RepairsController> {
  const RepairsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('repairs.title'.tr),
        actions: [
          IconButton(
            tooltip: 'repairs.filter'.tr,
            icon: Obx(
              () => Badge(
                isLabelVisible: controller.filterActive.value,
                child: const Icon(Icons.filter_list),
              ),
            ),
            onPressed: () => _filters(context, controller),
          ),
        ],
      ),
      body: Column(
        children: [
          Obx(
            () => Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: SegmentedButton<RepairsSegment>(
                segments: [
                  ButtonSegment(
                    value: RepairsSegment.mine,
                    label: Text('repairs.segment.mine'.tr),
                  ),
                  ButtonSegment(
                    value: RepairsSegment.unassigned,
                    label: Text('repairs.segment.unassigned'.tr),
                  ),
                  ButtonSegment(
                    value: RepairsSegment.all,
                    label: Text('repairs.segment.all'.tr),
                  ),
                ],
                selected: {controller.segment.value},
                onSelectionChanged: (s) => controller.setSegment(s.first),
              ),
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
                  icon: Icons.build_outlined,
                  title: 'repairs.empty'.tr,
                );
              }
              return RefreshIndicator(
                onRefresh: controller.load,
                child: NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (n.metrics.extentAfter < 300) {
                      unawaited(controller.loadMore());
                    }
                    return false;
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: controller.items.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, i) => _RepairCard(
                      r: controller.items[i],
                      onTap: () async {
                        await Get.toNamed(
                          Routes.repair(controller.items[i].id),
                        );
                        await controller.load();
                      },
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'repairNew',
        tooltip: 'repairs.new'.tr,
        onPressed: () async {
          final id = await Get.toNamed<String>(Routes.repairNew);
          if (id != null) await Get.toNamed(Routes.repair(id));
          await controller.load();
        },
        child: const Icon(Icons.add_alert_outlined),
      ),
    );
  }
}

class _RepairCard extends StatelessWidget {
  const _RepairCard({required this.r, required this.onTap});

  final RepairSummary r;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final overdue =
        r.isOverdue ||
        (r.dueAt != null &&
            (DateTime.tryParse(r.dueAt!)?.isBefore(DateTime.now()) ?? false));
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (r.equipmentDown)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs),
                      child: Tooltip(
                        message: 'repairs.down'.tr,
                        child: Icon(
                          Icons.power_off_outlined,
                          size: 18,
                          color: context.status.danger,
                        ),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      '${r.code} — ${r.equipmentLabel}',
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  StatusBadge(
                    tone: toneForRepairSeverity(r.severity),
                    label: 'status.severity.${r.severity}'.tr,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                r.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  StatusBadge(
                    tone: toneForRepairStatus(r.status),
                    label: 'status.repair.${r.status}'.tr,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  if (r.dueAt != null)
                    Text(
                      formatSla(r.dueAt),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: overdue ? context.status.danger : null,
                        fontWeight: overdue ? FontWeight.w600 : null,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _filters(BuildContext context, RepairsController c) async {
  final allStatuses = [
    'new',
    'accepted',
    'in_progress',
    'awaiting_parts',
    'awaiting_vendor',
    'completed',
    'acceptance',
    'closed',
    'cancelled',
  ];
  final selected = {...c.statuses};
  var severity = c.severity.value;
  var departmentId = c.departmentId.value;
  var overdue = c.overdue.value;

  await Get.bottomSheet<void>(
    SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'repairs.filter'.tr,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'repairs.filter.status'.tr,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                Wrap(
                  spacing: AppSpacing.xs,
                  children: [
                    for (final s in allStatuses)
                      FilterChip(
                        label: Text('status.repair.$s'.tr),
                        selected: selected.contains(s),
                        onSelected: (v) => setState(() {
                          if (v) {
                            selected.add(s);
                          } else {
                            selected.remove(s);
                          }
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'repairs.filter.severity'.tr,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                Wrap(
                  spacing: AppSpacing.xs,
                  children: [
                    for (final s in ['low', 'medium', 'high', 'critical'])
                      ChoiceChip(
                        label: Text('status.severity.$s'.tr),
                        selected: severity == s,
                        onSelected: (v) =>
                            setState(() => severity = v ? s : null),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    departmentId == null
                        ? 'repairs.filter.department'.tr
                        : '${'repairs.filter.department'.tr} ✓',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final repo = Get.find<DepartmentsRepository>();
                    final sel = await _pickDepartment(repo);
                    if (sel != null) setState(() => departmentId = sel);
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('repairs.filter.overdue'.tr),
                  value: overdue,
                  onChanged: (v) => setState(() => overdue = v),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Get.back();
                          c.applyFilters(statuses: const {}, overdue: false);
                        },
                        child: Text('repairs.filter.clear'.tr),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          Get.back();
                          c.applyFilters(
                            statuses: selected,
                            severity: severity,
                            departmentId: departmentId,
                            overdue: overdue,
                          );
                        },
                        child: Text('repairs.filter.apply'.tr),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    isScrollControlled: true,
    backgroundColor: Get.theme.colorScheme.surface,
  );
}

Future<String?> _pickDepartment(DepartmentsRepository repo) async {
  final selection = await PickerSheet.show<String>(
    title: 'repairs.filter.department'.tr,
    showClear: true,
    loader: (q) async {
      final list = await repo.list(q: q, limit: 20);
      return [
        for (final d in list)
          PickerOption(value: d.id, code: d.code, name: d.name),
      ];
    },
  );
  if (selection == null) return null;
  if (selection.cleared) return '';
  return selection.option?.value;
}
