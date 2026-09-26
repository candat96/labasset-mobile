import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/format/format.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/action_grid_sheet.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_sheet.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/attachments_grid.dart';
import '../../core/widgets/detail_widgets.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/icon_chip.dart';
import '../../core/widgets/loading_list.dart';
import '../../core/widgets/picker_sheet.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/timeline_list.dart';
import '../../data/models/repair_detail.dart';
import 'repair_detail_controller.dart';
import 'tabs/costs_tab.dart';
import 'tabs/docs_tab.dart';
import 'tabs/parts_tab.dart';
import 'tabs/vendors_tab.dart';

/// Chi tiết phiếu sửa chữa: header + thanh hành động + tab Tổng quan/Nhật ký.
class RepairDetailView extends GetView<RepairDetailController> {
  const RepairDetailView({super.key});

  @override
  String? get tag => Get.parameters['id'];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.loading.value && controller.item.value == null) {
        return Scaffold(
          appBar: AppBar(title: Text('repairs.title'.tr)),
          body: const LoadingList(),
        );
      }
      final err = controller.error.value;
      if (err != null && controller.item.value == null) {
        return Scaffold(
          appBar: AppBar(title: Text('repairs.title'.tr)),
          body: ErrorState(error: err, onRetry: controller.load),
        );
      }
      final d = controller.item.value!;
      return DetailScaffold(
        title: d.code,
        header: _Header(d: d),
        onRefresh: controller.load,
        tabs: [
          'repairs.tab.overview'.tr,
          'repairs.tab.logs'.tr,
          'repairs.tab.parts'.tr,
          'repairs.tab.vendors'.tr,
          'repairs.tab.costs'.tr,
          'repairs.tab.docs'.tr,
          'repairs.tab.report'.tr,
        ],
        tabViews: [
          _Overview(d: d, controller: controller),
          _Logs(controller: controller),
          PartsTab(equipmentId: d.equipmentId),
          const VendorsTab(),
          const CostsTab(),
          DocsTab(ticketId: d.id),
          _ReportTab(ticketId: d.id),
        ],
        bottomBar: _ActionBar(controller: controller, d: d),
      );
    });
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.d});

  final RepairDetail d;

  @override
  Widget build(BuildContext context) {
    final overdue =
        d.isOverdue ||
        (d.dueAt != null &&
            (DateTime.tryParse(d.dueAt!)?.isBefore(DateTime.now()) ?? false));
    return DetailHeaderCard(
      icon: LucideIcons.wrench,
      title: d.equipmentLabel,
      onTitleTap: () => Get.toNamed(Routes.equipment(d.equipmentId)),
      code: d.code,
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      badges: [
        StatusBadge(
          tone: toneForRepairStatus(d.status),
          label: 'status.repair.${d.status}'.tr,
        ),
        StatusBadge(
          tone: toneForRepairSeverity(d.severity),
          label: 'status.severity.${d.severity}'.tr,
        ),
      ],
      stats: [
        if (d.dueAt != null)
          DetailStat(
            'repairs.overview.due'.tr,
            formatSla(d.dueAt),
            icon: overdue ? LucideIcons.clockAlert : LucideIcons.clock3,
            color: overdue ? context.status.danger : null,
          ),
        DetailStat(
          'equipment.staff'.tr,
          d.assignee?.fullName ?? 'repairs.assignee.none'.tr,
          icon: LucideIcons.userRound,
        ),
        if (d.equipmentDown)
          DetailStat(
            '',
            'repairs.down'.tr,
            icon: LucideIcons.powerOff,
            color: context.status.danger,
          ),
        if (d.costWarning)
          DetailStat(
            'repairs.overview.cost'.tr,
            formatVnd(d.totalCost),
            icon: LucideIcons.banknote,
            color: context.status.warning,
          ),
      ],
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.d, required this.controller});

  final RepairDetail d;
  final RepairDetailController controller;

  @override
  Widget build(BuildContext context) {
    Widget row(String label, String? value) =>
        InfoRow(label: label, value: value);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        AttachmentsGrid(
          key: ValueKey('repair-photos-${d.id}'),
          entityType: 'repair_ticket',
          entityId: d.id,
          photosOnly: true,
          title: '${'attachment.conditionTitle'.tr} — ${d.code}',
          canEdit:
              !['closed', 'cancelled'].contains(d.status) &&
              (d.reportedBy == controller.userId ||
                  controller.isAdmin ||
                  controller.isAssignee ||
                  controller.roles.contains('DEPT_HEAD') ||
                  controller.roles.contains('DEPT_USER')),
        ),
        const SizedBox(height: AppSpacing.md),
        SectionCard(
          title: 'repairs.tab.overview'.tr,
          child: Column(
            children: [
              row('repairs.overview.description'.tr, d.description),
              row('repairs.form.errorCode'.tr, d.errorCode),
              row('repairs.overview.diagnosis'.tr, d.diagnosis),
              row(
                'repairs.overview.resolutionType'.tr,
                d.resolutionType == null
                    ? null
                    : 'repairs.resolution.${d.resolutionType}'.tr,
              ),
              row('repairs.overview.resolution'.tr, d.resolutionSummary),
              row(
                'repairs.overview.warranty'.tr,
                formatDate(d.postRepairWarrantyUntil),
              ),
              row('repairs.overview.due'.tr, formatDateTime(d.dueAt)),
              row('repairs.overview.created'.tr, formatDateTime(d.createdAt)),
              InfoRow(
                label: 'repairs.overview.cost'.tr,
                value: formatVnd(d.totalCost),
                showDivider: false,
              ),
            ],
          ),
        ),
        if (d.calibrationRequired) ...[
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            color: context.status.warningBackground,
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: Icon(
                LucideIcons.badgeCheck,
                color: context.status.warning,
              ),
              title: Text('repairs.overview.calibration'.tr),
              subtitle: d.calibrationTicketId == null
                  ? null
                  : Text('calibration.preset.pending'.tr),
            ),
          ),
        ],
        if (d.rating != null) ...[
          const SizedBox(height: AppSpacing.sm),
          SectionCard(
            title: 'repairs.overview.rating'.tr,
            child: Row(
              children: [
                for (var i = 1; i <= 5; i++)
                  Icon(
                    i <= (d.rating ?? 0) ? LucideIcons.star : LucideIcons.star,
                    size: 18,
                    color: context.status.warning,
                  ),
                if (d.ratingNote != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(d.ratingNote!)),
                ],
              ],
            ),
          ),
        ],
        if (d.assignments.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          SectionCard(
            title: 'repairs.overview.assignment'.tr,
            child: Column(
              children: [
                for (final a in d.assignments)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const IconChip(
                      icon: LucideIcons.userRound,
                      size: 36,
                      iconSize: 18,
                    ),
                    title: Text(
                      _userLabel(a.userId, controller, detail: d) ??
                          'repairs.assignee.unknown'.tr,
                      style: context.appText.bodyStrong,
                    ),
                    subtitle: Text(
                      'repairs.role.${a.role}'.tr,
                      style: context.appText.label,
                    ),
                    trailing: StatusBadge(
                      tone: switch (a.response) {
                        'accepted' => StatusTone.success,
                        'declined' => StatusTone.danger,
                        _ => StatusTone.warning,
                      },
                      label: 'repairs.response.${a.response}'.tr,
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        SectionCard(
          title: 'repairs.tab.docs'.tr,
          child: AttachmentsGrid(
            entityType: 'repair_ticket',
            entityId: d.id,
            // Ảnh đã có mục "Ảnh tình trạng" ở tab Tổng quan → không hiện lặp.
            hidePhotos: true,
            kinds: const ['video', 'other'],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}

class _Logs extends StatelessWidget {
  const _Logs({required this.controller});

  final RepairDetailController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        final logs = controller.mergedLogs;
        if (logs.isEmpty) {
          return EmptyState(
            icon: LucideIcons.history,
            title: 'repairs.logs.empty'.tr,
          );
        }
        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              TimelineList(
                items: [
                  for (final l in logs)
                    TimelineEntry(
                      title: l.pending
                          ? '${repairLogLabel(l.action)} · ${'repairs.logs.pending'.tr}'
                          : repairLogLabel(l.action),
                      at: l.at,
                      summary: l.note,
                      by: _userLabel(l.byUserId, controller),
                      color: l.pending ? context.status.warning : null,
                      icon: l.pending
                          ? LucideIcons.cloudUpload
                          : LucideIcons.circleCheck,
                    ),
                ],
              ),
            ],
          ),
        );
      }),
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'addLog',
        tooltip: 'repairs.logs.add'.tr,
        onPressed: () => _addLog(context, controller),
        child: const Icon(LucideIcons.plus),
      ),
    );
  }
}

Future<void> _addLog(BuildContext context, RepairDetailController c) async {
  await AppSheet.show<void>(
    context,
    builder: (ctx) => SheetForm(
      builder: (context, form) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(title: 'repairs.logs.add'.tr),
          TextField(
            controller: form.field('action'),
            focusNode: form.focusNode('action'),
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'repairs.logs.action'.tr,
              errorText: form.error('action'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: form.field('note'),
            decoration: InputDecoration(labelText: 'repairs.logs.note'.tr),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: form.field('minutes'),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'repairs.logs.minutes'.tr),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton.primary(
            label: 'common.save'.tr,
            onPressed: form.busy
                ? null
                : () async {
                    if (form.text('action').isEmpty) {
                      form.setError('action', 'common.required'.tr);
                      return;
                    }
                    form.setBusy(true);
                    await c.addLog(
                      action: form.text('action'),
                      note: form.textOrNull('note'),
                      durationMinutes: num.tryParse(form.text('minutes')),
                    );
                    form.close();
                  },
          ),
        ],
      ),
    ),
  );
}

typedef _RepairAction = ({
  String key,
  IconData icon,
  VoidCallback run,
  bool outlined,
});

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.controller, required this.d});

  final RepairDetailController controller;
  final RepairDetail d;

  @override
  Widget build(BuildContext context) {
    // (khoá i18n, icon, hành động, phụ?) — nút chính = mục đầu không phụ.
    final actions =
        <({String key, IconData icon, VoidCallback run, bool outlined})>[
          if (controller.canAccept)
            (
              key: 'repairs.action.accept',
              icon: LucideIcons.check,
              run: () => controller.accept(),
              outlined: false,
            ),
          if (controller.canRespond) ...[
            (
              key: 'repairs.action.respondYes',
              icon: LucideIcons.check,
              run: () => controller.respond(accepted: true),
              outlined: false,
            ),
            (
              key: 'repairs.action.respondNo',
              icon: LucideIcons.x,
              run: () => controller.respond(accepted: false),
              outlined: true,
            ),
          ],
          if (controller.canAssign)
            (
              key: 'repairs.action.assign',
              icon: LucideIcons.userPlus,
              run: () => _assign(context, controller, d),
              outlined: false,
            ),
          if (controller.canDiagnose)
            (
              key: 'repairs.action.diagnose',
              icon: LucideIcons.stethoscope,
              run: () => _diagnose(context, controller, d),
              outlined: false,
            ),
          if (controller.canChangeStatus)
            (
              key: 'repairs.action.changeStatus',
              icon: LucideIcons.refreshCw,
              run: () => _changeStatus(context, controller),
              outlined: false,
            ),
          if (controller.canComplete)
            (
              key: 'repairs.action.complete',
              icon: LucideIcons.circleCheck,
              run: () => _complete(context, controller),
              outlined: false,
            ),
          if (controller.canAcceptance)
            (
              key: 'repairs.action.acceptance',
              icon: LucideIcons.clipboardCheck,
              run: () => _acceptance(context, controller),
              outlined: false,
            ),
          if (controller.canClose)
            (
              key: 'repairs.action.close',
              icon: LucideIcons.lock,
              run: () => controller.close(),
              outlined: true,
            ),
          if (controller.canCancel)
            (
              key: 'repairs.action.cancel',
              icon: LucideIcons.ban,
              run: () => _cancel(context, controller),
              outlined: true,
            ),
        ];
    if (actions.isEmpty) return const SizedBox.shrink();
    final primaryIndex = actions.indexWhere((a) => !a.outlined);
    final primary = primaryIndex >= 0 ? actions[primaryIndex] : null;
    final rest = [
      for (var i = 0; i < actions.length; i++)
        if (i != primaryIndex) actions[i],
    ];
    // Tối đa một nút phụ cạnh nút chính; nhiều hơn → gom vào "Thêm".
    final fitsInline = rest.length <= (primary == null ? 2 : 1);
    final inline = fitsInline ? rest : <_RepairAction>[];
    final more = fitsInline ? <_RepairAction>[] : rest;
    return StickyActionBar(
      primary: primary == null
          ? null
          : GradientButton(
              label: primary.key.tr,
              icon: primary.icon,
              onPressed: primary.run,
            ),
      secondary: [
        for (final a in inline)
          StickySecondaryButton(
            label: a.key.tr,
            icon: a.icon,
            onPressed: a.run,
            danger: a.key == 'repairs.action.cancel',
          ),
        if (more.isNotEmpty)
          StickySecondaryButton(
            label: 'common.actions'.tr,
            icon: LucideIcons.layoutGrid,
            onPressed: () => _moreSheet(context, more),
          ),
      ],
    );
  }

  Future<void> _moreSheet(BuildContext context, List<_RepairAction> items) =>
      ActionGridSheet.show(
        context,
        title: 'common.actions'.tr,
        groups: [
          SheetActionGroup(
            actions: [
              for (final a in items)
                SheetAction(
                  label: a.key.tr,
                  icon: a.icon,
                  onTap: a.run,
                  danger: a.key == 'repairs.action.cancel',
                ),
            ],
          ),
        ],
      );
}

Future<void> _assign(
  BuildContext context,
  RepairDetailController c,
  RepairDetail d,
) async {
  final repo = c.repairs;
  final suggest = await repo.assignSuggest(d.equipmentId);
  if (!context.mounted) return;
  final selection = await PickerSheet.show<String>(
    context,
    title: 'repairs.assign.title'.tr,
    kind: PickerKind.user,
    loader: (q) async {
      final list = q.isEmpty
          ? suggest
          : suggest
                .where(
                  (s) => s.fullName.toLowerCase().contains(q.toLowerCase()),
                )
                .toList();
      return [
        for (final s in list)
          PickerOption(
            value: s.id,
            code: '',
            name: s.fullName,
            subtitle: 'repairs.assign.openTickets'.trParams({
              'n': '${s.openTickets}',
            }),
          ),
      ];
    },
  );
  final o = selection?.option;
  if (o == null) return;
  await c.assign(primaryUserId: o.value);
}

Future<void> _diagnose(
  BuildContext context,
  RepairDetailController c,
  RepairDetail d,
) async {
  var resolutionType = d.resolutionType;
  await AppSheet.show<void>(
    context,
    builder: (ctx) => SheetForm(
      initial: {'text': d.diagnosis},
      builder: (context, form) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(title: 'repairs.diagnose.title'.tr),
          TextField(
            controller: form.field('text'),
            focusNode: form.focusNode('text'),
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'repairs.diagnose.text'.tr,
              errorText: form.error('text'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<String>(
            initialValue: resolutionType,
            decoration: InputDecoration(
              labelText: 'repairs.diagnose.resolutionType'.tr,
            ),
            items: [
              for (final t in [
                'internal',
                'vendor',
                'warranty',
                'spare_equipment',
              ])
                DropdownMenuItem(
                  value: t,
                  child: Text('repairs.resolution.$t'.tr),
                ),
            ],
            onChanged: (v) => form.refresh(() => resolutionType = v),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton.primary(
            label: 'common.save'.tr,
            onPressed: form.busy
                ? null
                : () async {
                    if (form.text('text').isEmpty) {
                      form.setError('text', 'common.required'.tr);
                      return;
                    }
                    form.setBusy(true);
                    final ok = await c.diagnose(
                      diagnosis: form.text('text'),
                      resolutionType: resolutionType,
                    );
                    form.setBusy(false);
                    if (ok) form.close();
                  },
          ),
        ],
      ),
    ),
  );
}

Future<void> _changeStatus(
  BuildContext context,
  RepairDetailController c,
) async {
  var target = RepairDetailController.statusTargets.first;
  await AppSheet.show<void>(
    context,
    builder: (ctx) => SheetForm(
      builder: (context, form) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(title: 'repairs.status.title'.tr),
          DropdownButtonFormField<String>(
            initialValue: target,
            decoration: InputDecoration(labelText: 'repairs.status.target'.tr),
            items: [
              for (final s in RepairDetailController.statusTargets)
                DropdownMenuItem(value: s, child: Text('status.repair.$s'.tr)),
            ],
            onChanged: (v) => form.refresh(() => target = v ?? target),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: form.field('note'),
            decoration: InputDecoration(labelText: 'repairs.status.note'.tr),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton.success(
            label: 'common.confirm'.tr,
            onPressed: form.busy
                ? null
                : () async {
                    form.setBusy(true);
                    final ok = await c.changeStatus(target, form.text('note'));
                    form.setBusy(false);
                    if (ok) form.close();
                  },
          ),
        ],
      ),
    ),
  );
}

Future<void> _complete(BuildContext context, RepairDetailController c) async {
  var calibration = false;
  await AppSheet.show<void>(
    context,
    builder: (ctx) => SheetForm(
      builder: (context, form) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(title: 'repairs.complete.title'.tr),
          TextField(
            controller: form.field('summary'),
            focusNode: form.focusNode('summary'),
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'repairs.complete.summary'.tr,
              errorText: form.error('summary'),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('repairs.complete.calibration'.tr),
            value: calibration,
            onChanged: (v) => form.refresh(() => calibration = v),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton.success(
            label: 'common.confirm'.tr,
            onPressed: form.busy
                ? null
                : () async {
                    if (form.text('summary').isEmpty) {
                      form.setError('summary', 'common.required'.tr);
                      return;
                    }
                    form.setBusy(true);
                    final ok = await c.complete(
                      resolutionSummary: form.text('summary'),
                      calibrationRequired: calibration,
                    );
                    form.setBusy(false);
                    if (ok) form.close();
                  },
          ),
        ],
      ),
    ),
  );
}

Future<void> _acceptance(BuildContext context, RepairDetailController c) async {
  var accepted = true;
  var rating = 5;
  await AppSheet.show<void>(
    context,
    builder: (ctx) => SheetForm(
      builder: (context, form) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(title: 'repairs.acceptance.title'.tr),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('repairs.acceptance.accepted'.tr),
            value: accepted,
            onChanged: (v) => form.refresh(() => accepted = v),
          ),
          if (accepted)
            Row(
              children: [
                Text('repairs.acceptance.rating'.tr),
                const Spacer(),
                for (var i = 1; i <= 5; i++)
                  AppIconButton(
                    icon: LucideIcons.star,
                    tone: AppButtonTone.warning,
                    size: 32,
                    iconSize: 20,
                    onPressed: () => form.refresh(() => rating = i),
                  ),
              ],
            ),
          TextField(
            controller: form.field('note'),
            decoration: InputDecoration(
              labelText: 'repairs.acceptance.note'.tr,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton.success(
            label: 'common.confirm'.tr,
            onPressed: form.busy
                ? null
                : () async {
                    form.setBusy(true);
                    final ok = await c.acceptance(
                      accepted: accepted,
                      rating: accepted ? rating : null,
                      note: form.textOrNull('note'),
                    );
                    form.setBusy(false);
                    if (ok) form.close();
                  },
          ),
        ],
      ),
    ),
  );
}

Future<void> _cancel(BuildContext context, RepairDetailController c) async {
  await AppSheet.show<void>(
    context,
    builder: (ctx) => SheetForm(
      builder: (context, form) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(title: 'repairs.cancel.title'.tr),
          TextField(
            controller: form.field('reason'),
            focusNode: form.focusNode('reason'),
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'repairs.cancel.reason'.tr,
              errorText: form.error('reason'),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton.danger(
            label: 'common.confirm'.tr,
            onPressed: form.busy
                ? null
                : () async {
                    if (form.text('reason').isEmpty) {
                      form.setError('reason', 'common.required'.tr);
                      return;
                    }
                    form.setBusy(true);
                    final ok = await c.cancel(form.text('reason'));
                    form.setBusy(false);
                    if (ok) form.close();
                  },
          ),
        ],
      ),
    ),
  );
}

/// Tab "Biên bản": mở/chia sẻ PDF.
class _ReportTab extends StatelessWidget {
  const _ReportTab({required this.ticketId});

  final String ticketId;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.fileText,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'repairs.report.hint'.tr,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton.primary(
              label: 'repairs.report.open'.tr,
              icon: LucideIcons.externalLink,
              onPressed: () async {
                try {
                  await exportRepairPdf(ticketId);
                } catch (e) {
                  AppSnackbar.error(e);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Nhãn tiếng Việt cho `action` của nhật ký sửa chữa (API ghi mã enum:
/// `created`, `accepted`, `assigned`, `assignment:<response>`, `diagnosis`,
/// `status:<status>`, `completed`, `acceptance`, `acceptance_rejected`,
/// `closed`, `cancelled`); chuỗi tự nhập từ app giữ nguyên.
String repairLogLabel(String action) {
  final a = action.trim();
  if (a.startsWith('status:')) {
    final v = a.substring('status:'.length);
    return 'repairs.log.status'.trParams({'value': 'status.repair.$v'.tr});
  }
  if (a.startsWith('assignment:')) {
    final v = a.substring('assignment:'.length);
    return 'repairs.log.assignment'.trParams({
      'value': 'repairs.response.$v'.tr,
    });
  }
  final key = 'repairs.log.$a';
  final label = key.tr;
  return label == key ? action : label;
}

/// Tên người dùng thay cho UUID: bạn / NV phụ trách của phiếu; không rõ → null.
String? _userLabel(
  String? userId,
  RepairDetailController c, {
  RepairDetail? detail,
}) {
  if (userId == null || userId.isEmpty) return null;
  if (userId == c.userId) return 'repairs.log.you'.tr;
  final d = detail ?? c.item.value;
  final assignee = d?.assignee;
  if (assignee != null && assignee.id == userId) return assignee.fullName;
  return null;
}
