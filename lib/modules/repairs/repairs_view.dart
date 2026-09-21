import 'dart:async';

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
import '../../core/widgets/app_sheet.dart';
import '../../core/widgets/picker_sheet.dart';
import '../../core/widgets/segment_tabs.dart';
import '../../core/widgets/status_badge.dart';
import '../../data/models/repair.dart';
import '../../data/repositories/departments_repository.dart';
import 'repairs_controller.dart';

/// Tab "Sửa chữa": segment + bộ lọc + danh sách phiếu.
class RepairsView extends GetView<RepairsController> {
  const RepairsView({super.key});

  @override
  Widget build(BuildContext context) {
    return LargeTitleScaffold(
      title: 'repairs.title'.tr,
      actions: [
        Obx(
          () => CircleIconButton(
            icon: LucideIcons.slidersHorizontal,
            tooltip: 'repairs.filter'.tr,
            badge: controller.filterActive.value,
            onTap: () => _filters(context, controller),
          ),
        ),
      ],
      header: Obx(
        () => SegmentTabs<RepairsSegment>(
          tabs: [
            SegmentTab(
              value: RepairsSegment.mine,
              label: 'repairs.segment.mine'.tr,
            ),
            SegmentTab(
              value: RepairsSegment.unassigned,
              label: 'repairs.segment.unassigned'.tr,
            ),
            SegmentTab(
              value: RepairsSegment.all,
              label: 'repairs.segment.all'.tr,
            ),
          ],
          selected: controller.segment.value,
          onChanged: controller.setSegment,
        ),
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
            icon: LucideIcons.wrench,
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
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.xxl * 3,
              ),
              itemCount: controller.items.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (_, i) => _RepairCard(
                r: controller.items[i],
                onTap: () async {
                  await Get.toNamed(Routes.repair(controller.items[i].id));
                  await controller.load();
                },
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _RepairCard extends StatelessWidget {
  const _RepairCard({required this.r, required this.onTap});

  final RepairSummary r;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final overdue =
        r.isOverdue ||
        (r.dueAt != null &&
            (DateTime.tryParse(r.dueAt!)?.isBefore(DateTime.now()) ?? false));
    final severity = paletteForTone(context, toneForRepairSeverity(r.severity));
    return ListItemCard(
      code: r.code,
      badge: StatusBadge(
        tone: toneForRepairStatus(r.status),
        label: 'status.repair.${r.status}'.tr,
      ),
      title: r.equipmentLabel,
      accentColor: severity.color,
      metas: [
        ListMeta(LucideIcons.fileText, r.description),
        if (r.dueAt != null)
          ListMeta(
            overdue ? LucideIcons.clockAlert : LucideIcons.clock3,
            formatSla(r.dueAt),
            color: overdue ? context.status.danger : null,
          ),
      ],
      onTap: onTap,
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

  await AppSheet.show<void>(
    context,
    builder: (ctx) => Padding(
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
                  final sel = await _pickDepartment(context, repo);
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
                        AppSheet.close(context);
                        c.applyFilters(statuses: const {}, overdue: false);
                      },
                      child: Text('repairs.filter.clear'.tr),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        AppSheet.close(context);
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
  );
}

Future<String?> _pickDepartment(
  BuildContext context,
  DepartmentsRepository repo,
) async {
  final selection = await PickerSheet.show<String>(
    context,
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
