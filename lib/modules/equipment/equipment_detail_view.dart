import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/errors/api_error.dart';
import '../../core/format/decimal_input.dart';
import '../../core/format/format.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/action_grid_sheet.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_sheet.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/attachments_grid.dart';
import '../../core/widgets/detail_widgets.dart';
import '../../core/widgets/icon_chip.dart';
import '../../core/widgets/confirm_sheet.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/picker_sheet.dart';
import '../../core/widgets/qty_field.dart';
import '../../core/widgets/status_badge.dart';
import '../../data/models/department.dart';
import '../../data/models/equipment_detail.dart';
import '../../data/repositories/departments_repository.dart';
import 'equipment_detail_controller.dart';
import 'tabs/accessories_tab.dart';
import 'tabs/components_tab.dart';
import 'tabs/faults_tab.dart';
import 'tabs/maintenance_tab.dart';
import 'tabs/network_tab.dart';
import 'tabs/repairs_tab.dart';
import 'tabs/software_tab.dart';
import 'tabs/specs_tab.dart';
import 'tabs/supplies_tab.dart';
import 'tabs/timeline_tab.dart';

/// Hồ sơ máy: thẻ tóm tắt + thao tác nhanh + 9 tab.
class EquipmentDetailView extends GetView<EquipmentDetailController> {
  const EquipmentDetailView({super.key});

  @override
  String? get tag => Get.parameters['id'];

  static const _actionKeys = [
    (key: 'reportFault', icon: Icons.report_problem_outlined),
    (key: 'adhocMaintenance', icon: Icons.build_circle_outlined),
    (key: 'issueSupplies', icon: Icons.outbox_outlined),
    (key: 'counters', icon: Icons.speed_outlined),
    (key: 'updateStatus', icon: Icons.sync_alt_outlined),
    (key: 'addPhoto', icon: Icons.add_a_photo_outlined),
    (key: 'location', icon: Icons.router_outlined),
    (key: 'note', icon: Icons.note_add_outlined),
    (key: 'transfer', icon: Icons.swap_horiz_outlined),
    (key: 'assistant', icon: Icons.smart_toy_outlined),
    (key: 'reprint', icon: Icons.print_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.loading.value) {
        return Scaffold(
          appBar: AppBar(title: Text('equipment.title'.tr)),
          body: const Center(child: CircularProgressIndicator()),
        );
      }
      final err = controller.error.value;
      if (err != null) {
        if (ApiError.from(err).status == 404) {
          return Scaffold(
            appBar: AppBar(title: Text('equipment.title'.tr)),
            body: EmptyState(
              icon: Icons.search_off,
              title: 'equipment.notFound'.tr,
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(title: Text('equipment.title'.tr)),
          body: ErrorState(error: err, onRetry: controller.load),
        );
      }
      final e = controller.item.value!;
      return DetailScaffold(
        title: e.code,
        onRefresh: controller.load,
        header: _SummaryCard(e: e),
        bottomBar: _QuickActions(controller: controller, e: e),
        tabs: [
          'equipment.tab.specs'.tr,
          'equipment.tab.repairs'.tr,
          'equipment.tab.maintenance'.tr,
          'equipment.tab.network'.tr,
          'equipment.tab.accessories'.tr,
          'equipment.tab.software'.tr,
          'equipment.tab.components'.tr,
          'equipment.tab.supplies'.tr,
          'equipment.tab.documents'.tr,
          'equipment.tab.timeline'.tr,
          'equipment.tab.faults'.tr,
        ],
        tabViews: [
          SpecsTab(e: e),
          const RepairsTab(),
          const MaintenanceTab(),
          const NetworkTab(),
          const AccessoriesTab(),
          const SoftwareTab(),
          const ComponentsTab(),
          const SuppliesTab(),
          ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              AttachmentsGrid(
                entityType: 'equipment',
                entityId: e.id,
                kinds: const [
                  'photo',
                  'manual',
                  'catalogue',
                  'co_cq',
                  'license',
                  'calibration_cert',
                  'handover',
                  'maintenance_contract',
                  'diagram',
                  'other',
                ],
                downloadable: true,
              ),
            ],
          ),
          const TimelineTab(),
          FaultsTab(model: e.model),
        ],
      );
    });
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.e});

  final EquipmentDetail e;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final overdue =
        e.calibrationOverdue ||
        (e.nextCalibrationAt != null &&
            (DateTime.tryParse(
                  e.nextCalibrationAt!,
                )?.isBefore(DateTime.now()) ??
                false));
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        0,
      ),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const IconChip(
                  icon: LucideIcons.monitorCog,
                  size: 48,
                  iconSize: 24,
                  radius: 14,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.name, style: context.appText.title),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            e.code,
                            style: context.appText.label.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          StatusBadge(
                            tone: toneForEquipmentStatus(e.status),
                            label: 'status.${e.status}'.tr,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              [
                e.model,
                e.serial == null ? null : 'SN ${e.serial}',
                [
                  e.department?.name,
                  e.location,
                ].whereType<String>().join(' · '),
              ].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.md,
              children: [
                _due(
                  context,
                  'equipment.nextMaintenance'.tr,
                  e.nextMaintenanceAt,
                ),
                _due(
                  context,
                  'equipment.nextCalibration'.tr,
                  e.nextCalibrationAt,
                  force: overdue,
                ),
                _due(context, 'equipment.warranty'.tr, e.warrantyUntil),
              ],
            ),
            if (e.counts != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _count(
                    context,
                    'equipment.counts.accessories'.tr,
                    e.counts!.accessories,
                  ),
                  _count(
                    context,
                    'equipment.counts.componentsDue'.tr,
                    e.counts!.componentsDue,
                  ),
                  _count(
                    context,
                    'equipment.counts.openRepairs'.tr,
                    e.counts!.openRepairs,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _due(
    BuildContext context,
    String label,
    String? iso, {
    bool force = false,
  }) {
    final d = iso == null ? null : DateTime.tryParse(iso);
    final isOverdue = force || (d != null && d.isBefore(DateTime.now()));
    return _chip(
      context,
      icon: isOverdue ? LucideIcons.triangleAlert : LucideIcons.calendarDays,
      label: label,
      value: d == null ? '—' : formatDate(d),
      color: isOverdue ? context.status.danger : null,
    );
  }

  Widget _count(BuildContext context, String label, num value) =>
      _chip(context, label: label, value: '$value');

  Widget _chip(
    BuildContext context, {
    IconData? icon,
    required String label,
    required String value,
    Color? color,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.appText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color?.withValues(alpha: 0.1) ?? scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.tile),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color ?? text.label.color),
            const SizedBox(width: 4),
          ],
          Text(
            '$label: ',
            style: text.caption.copyWith(color: color ?? text.label.color),
          ),
          Text(
            value,
            style: text.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: color ?? scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

/// Thanh hành động dính đáy: "Báo hỏng" (chính) + "Thao tác" mở sheet lưới
/// chứa toàn bộ thao tác nhanh theo nhóm (thay hàng chip cuộn ngang).
class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.controller, required this.e});

  final EquipmentDetailController controller;
  final EquipmentDetail e;

  static const _groups = [
    (
      title: 'equipment.actionGroup.incident',
      keys: ['reportFault', 'adhocMaintenance', 'updateStatus', 'counters'],
    ),
    (title: 'equipment.actionGroup.stock', keys: ['issueSupplies']),
    (
      title: 'equipment.actionGroup.profile',
      keys: ['addPhoto', 'location', 'note', 'transfer'],
    ),
    (title: 'equipment.actionGroup.other', keys: ['assistant', 'reprint']),
  ];

  @override
  Widget build(BuildContext context) {
    return StickyActionBar(
      primary: GradientButton(
        label: 'equipment.action.reportFault'.tr,
        icon: LucideIcons.triangleAlert,
        onPressed: () => _run(context, 'reportFault'),
      ),
      secondary: [
        StickySecondaryButton(
          label: 'common.actions'.tr,
          icon: LucideIcons.layoutGrid,
          onPressed: () => _openSheet(context),
        ),
      ],
    );
  }

  Future<void> _openSheet(BuildContext context) {
    final icons = {
      for (final a in EquipmentDetailView._actionKeys) a.key: a.icon,
    };
    return ActionGridSheet.show(
      context,
      title: 'common.actions'.tr,
      groups: [
        for (final g in _groups)
          SheetActionGroup(
            title: g.title.tr,
            actions: [
              for (final k in g.keys)
                SheetAction(
                  label: 'equipment.action.$k'.tr,
                  icon: icons[k]!,
                  onTap: () => _run(context, k),
                ),
            ],
          ),
      ],
    );
  }

  Future<void> _run(BuildContext context, String key) async {
    switch (key) {
      case 'reportFault':
        await Get.toNamed('${Routes.repairNew}?equipmentId=${e.id}');
      case 'adhocMaintenance':
        await _adhoc(context);
      case 'issueSupplies':
        await Get.toNamed(
          Routes.stockIssueNew,
          arguments: {'equipmentId': e.id},
        );
      case 'counters':
        await _counters(context);
      case 'updateStatus':
        await _status(context);
      case 'addPhoto':
        await _photos(context);
      case 'location':
        await _location(context);
      case 'note':
        await _note(context);
      case 'transfer':
        await _transfer(context);
      case 'assistant':
        await Get.toNamed(Routes.ai);
      case 'reprint':
        await _reprint(context);
    }
  }

  Future<void> _adhoc(BuildContext context) async {
    await AppSheet.show<void>(
      context,
      builder: (ctx) => SheetForm(
        builder: (context, form) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeader(title: 'equipment.action.adhocMaintenance'.tr),
            TextField(
              controller: form.field('note'),
              autofocus: true,
              maxLines: 2,
              decoration: InputDecoration(labelText: 'equipment.note.hint'.tr),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: form.busy
                  ? null
                  : () async {
                      form.setBusy(true);
                      final ok = await controller.createAdhocMaintenance(
                        notes: form.textOrNull('note'),
                      );
                      form.setBusy(false);
                      if (ok) form.close();
                    },
              child: Text('common.confirm'.tr),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _counters(BuildContext context) async {
    await AppSheet.show<void>(
      context,
      builder: (ctx) => SheetForm(
        initial: {
          'hours': e.currentRunHours,
          'tests': e.currentTestCount?.toString(),
        },
        builder: (context, form) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeader(title: 'equipment.counters.title'.tr),
            QtyField(
              controller: form.field('hours'),
              label: 'equipment.counters.runHours'.tr,
            ),
            const SizedBox(height: AppSpacing.sm),
            QtyField(
              controller: form.field('tests'),
              label: 'equipment.counters.testCount'.tr,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: form.field('note'),
              decoration: InputDecoration(
                labelText: 'equipment.counters.note'.tr,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: form.busy
                  ? null
                  : () async {
                      form.setBusy(true);
                      final ok = await controller.addCounters(
                        runHours: parseDecimalInput(
                          form.text('hours'),
                        )?.toString(),
                        testCount: int.tryParse(form.text('tests')),
                        note: form.textOrNull('note'),
                      );
                      form.setBusy(false);
                      if (ok) form.close();
                    },
              child: Text('common.save'.tr),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _status(BuildContext context) async {
    final allowed = controller.allowedTransitions(e.status);
    if (allowed.isEmpty) {
      AppSnackbar.info('equipment.status.noTransition'.tr);
      return;
    }
    var selected = allowed.first;
    await AppSheet.show<void>(
      context,
      builder: (ctx) => SheetForm(
        builder: (context, form) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeader(title: 'equipment.status.title'.tr),
            DropdownButtonFormField<String>(
              initialValue: selected,
              decoration: InputDecoration(labelText: 'equipment.status.to'.tr),
              items: [
                for (final s in allowed)
                  DropdownMenuItem(value: s, child: Text('status.$s'.tr)),
              ],
              onChanged: (v) => form.refresh(() => selected = v ?? selected),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: form.field('reason'),
              decoration: InputDecoration(
                labelText: 'equipment.status.reason'.tr,
                hintText: 'equipment.status.reasonHint'.tr,
                errorText: form.error('reason'),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: form.busy
                  ? null
                  : () async {
                      if (form.text('reason').isEmpty) {
                        form.setError('reason', 'common.required'.tr);
                        return;
                      }
                      form.setBusy(true);
                      final ok = await controller.changeStatus(
                        selected,
                        form.text('reason'),
                      );
                      form.setBusy(false);
                      if (ok) form.close();
                    },
              child: Text('common.confirm'.tr),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _photos(BuildContext context) => showDialog<void>(
    context: context,
    useRootNavigator: true,
    builder: (ctx) => Dialog(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SingleChildScrollView(
          child: AttachmentsGrid(
            entityType: 'equipment',
            entityId: e.id,
            kinds: const ['photo'],
          ),
        ),
      ),
    ),
  );

  Future<void> _location(BuildContext context) async {
    await AppSheet.show<void>(
      context,
      builder: (ctx) => SheetForm(
        initial: {'location': e.location},
        builder: (context, form) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeader(title: 'equipment.location.title'.tr),
            TextField(
              controller: form.field('location'),
              decoration: InputDecoration(
                labelText: 'equipment.location.label'.tr,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: form.field('ip'),
              decoration: InputDecoration(
                labelText: 'equipment.location.ip'.tr,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: form.field('mac'),
              decoration: InputDecoration(
                labelText: 'equipment.location.mac'.tr,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: form.busy
                  ? null
                  : () async {
                      form.setBusy(true);
                      await controller.saveLocation(form.text('location'));
                      if (form.text('ip').isNotEmpty ||
                          form.text('mac').isNotEmpty) {
                        await controller.saveNetwork(
                          ip: form.text('ip'),
                          mac: form.text('mac'),
                        );
                      }
                      form.close();
                    },
              child: Text('common.save'.tr),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _note(BuildContext context) async {
    final v = await AppDialog.prompt(
      context,
      title: 'equipment.note.title'.tr,
      label: 'equipment.note.hint'.tr,
      maxLines: 3,
    );
    if (v != null && v.isNotEmpty) await controller.addNote(v);
  }

  Future<void> _transfer(BuildContext context) async {
    final departments = Get.find<DepartmentsRepository>();
    final selection = await PickerSheet.show<String>(
      context,
      title: 'equipment.transfer.toDepartment'.tr,
      kind: PickerKind.department,
      loader: (q) async {
        final list = await departments.list(q: q, limit: 20);
        return [
          for (final DepartmentRef d in list)
            PickerOption(value: d.id, code: d.code, name: d.name),
        ];
      },
    );
    final dept = selection?.option;
    if (dept == null || !context.mounted) return;
    await AppSheet.show<void>(
      context,
      builder: (ctx) => SheetForm(
        builder: (context, form) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeader(title: 'equipment.transfer.title'.tr),
            Text(dept.label),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: form.field('location'),
              decoration: InputDecoration(
                labelText: 'equipment.transfer.toLocation'.tr,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: form.field('reason'),
              decoration: InputDecoration(
                labelText: 'equipment.transfer.reason'.tr,
                errorText: form.error('reason'),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: form.busy
                  ? null
                  : () async {
                      if (form.text('reason').isEmpty) {
                        form.setError('reason', 'common.required'.tr);
                        return;
                      }
                      form.setBusy(true);
                      final ok = await controller.createTransfer(
                        toDepartmentId: dept.value,
                        toLocation: form.textOrNull('location'),
                        reason: form.text('reason'),
                      );
                      form.setBusy(false);
                      if (ok) form.close();
                    },
              child: Text('common.confirm'.tr),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _reprint(BuildContext context) async {
    final ok = await ConfirmSheet.show(
      context,
      title: 'scan.reprint'.tr,
      confirmLabel: 'common.confirm'.tr,
    );
    if (!ok) return;
    final done = await controller.reprintLabel();
    if (done) AppSnackbar.success('scan.reprint.sent'.tr);
  }
}
