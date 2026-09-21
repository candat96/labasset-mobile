import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/format/format.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/attachments_grid.dart';
import '../../core/widgets/detail_widgets.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
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
      return DefaultTabController(
        length: 7,
        child: Scaffold(
          appBar: AppBar(title: Text(d.code)),
          body: Column(
            children: [
              _Header(d: d),
              PillTabBar(
                tabs: [
                  'repairs.tab.overview'.tr,
                  'repairs.tab.logs'.tr,
                  'repairs.tab.parts'.tr,
                  'repairs.tab.vendors'.tr,
                  'repairs.tab.costs'.tr,
                  'repairs.tab.docs'.tr,
                  'repairs.tab.report'.tr,
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _Overview(d: d),
                    _Logs(controller: controller),
                    PartsTab(equipmentId: d.equipmentId),
                    const VendorsTab(),
                    const CostsTab(),
                    DocsTab(ticketId: d.id),
                    _ReportTab(ticketId: d.id),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: _ActionBar(controller: controller, d: d),
        ),
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
  const _Overview({required this.d});

  final RepairDetail d;

  @override
  Widget build(BuildContext context) {
    Widget row(String label, String? value) =>
        InfoRow(label: label, value: value);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
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
          Card(
            color: context.status.warning.withValues(alpha: 0.12),
            child: ListTile(
              leading: Icon(
                Icons.verified_outlined,
                color: context.status.warning,
              ),
              title: Text('repairs.overview.calibration'.tr),
              subtitle: Text(d.calibrationTicketId ?? ''),
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
                    i <= (d.rating ?? 0)
                        ? Icons.star
                        : Icons.star_border_outlined,
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
                    title: Text(a.userId ?? '—'),
                    subtitle: Text('repairs.role.${a.role}'.tr),
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
            kinds: const ['photo', 'video', 'other'],
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
            icon: Icons.history,
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
                          ? '${l.action} · ${'repairs.logs.pending'.tr}'
                          : l.action,
                      at: l.at,
                      summary: l.note,
                      by: l.byUserId,
                      color: l.pending ? context.status.warning : null,
                      icon: l.pending
                          ? Icons.cloud_upload_outlined
                          : Icons.check_circle_outline,
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
        onPressed: () => _addLog(controller),
        child: const Icon(Icons.add),
      ),
    );
  }
}

Future<void> _addLog(RepairDetailController c) async {
  final action = TextEditingController();
  final note = TextEditingController();
  final minutes = TextEditingController();
  await Get.bottomSheet<void>(
    SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.viewInsetsOf(Get.context!).bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('repairs.logs.add'.tr, style: Get.theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: action,
              decoration: InputDecoration(labelText: 'repairs.logs.action'.tr),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: note,
              decoration: InputDecoration(labelText: 'repairs.logs.note'.tr),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: minutes,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'repairs.logs.minutes'.tr),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: () async {
                if (action.text.trim().isEmpty) return;
                Get.back();
                await c.addLog(
                  action: action.text.trim(),
                  note: note.text.trim().isEmpty ? null : note.text.trim(),
                  durationMinutes: num.tryParse(minutes.text.trim()),
                );
              },
              child: Text('common.save'.tr),
            ),
          ],
        ),
      ),
    ),
    isScrollControlled: true,
    backgroundColor: Get.theme.colorScheme.surface,
  );
  action.dispose();
  note.dispose();
  minutes.dispose();
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
            label: 'common.more'.tr,
            icon: LucideIcons.ellipsis,
            onPressed: () => _moreSheet(context, more),
          ),
      ],
    );
  }

  Future<void> _moreSheet(BuildContext context, List<_RepairAction> items) =>
      Get.bottomSheet<void>(
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final a in items)
                  ListTile(
                    leading: Icon(
                      a.icon,
                      color: a.key == 'repairs.action.cancel'
                          ? context.status.danger
                          : null,
                    ),
                    title: Text(
                      a.key.tr,
                      style: context.appText.bodyStrong.copyWith(
                        color: a.key == 'repairs.action.cancel'
                            ? context.status.danger
                            : null,
                      ),
                    ),
                    onTap: () {
                      Get.back();
                      a.run();
                    },
                  ),
              ],
            ),
          ),
        ),
        backgroundColor: Get.theme.colorScheme.surface,
      );
}

Future<void> _assign(
  BuildContext context,
  RepairDetailController c,
  RepairDetail d,
) async {
  final repo = c.repairs;
  final suggest = await repo.assignSuggest(d.equipmentId);
  final selection = await PickerSheet.show<String>(
    title: 'repairs.assign.title'.tr,
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
  final text = TextEditingController(text: d.diagnosis ?? '');
  var resolutionType = d.resolutionType;
  await Get.bottomSheet<void>(
    SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.viewInsetsOf(Get.context!).bottom + AppSpacing.lg,
        ),
        child: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'repairs.diagnose.title'.tr,
                style: Get.theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: text,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'repairs.diagnose.text'.tr,
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
                onChanged: (v) => setState(() => resolutionType = v),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () async {
                  if (text.text.trim().isEmpty) return;
                  final ok = await c.diagnose(
                    diagnosis: text.text.trim(),
                    resolutionType: resolutionType,
                  );
                  if (ok) Get.back();
                },
                child: Text('common.save'.tr),
              ),
            ],
          ),
        ),
      ),
    ),
    isScrollControlled: true,
    backgroundColor: Get.theme.colorScheme.surface,
  );
  text.dispose();
}

Future<void> _changeStatus(
  BuildContext context,
  RepairDetailController c,
) async {
  var target = RepairDetailController.statusTargets.first;
  final note = TextEditingController();
  await Get.bottomSheet<void>(
    SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.viewInsetsOf(Get.context!).bottom + AppSpacing.lg,
        ),
        child: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'repairs.status.title'.tr,
                style: Get.theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: target,
                decoration: InputDecoration(
                  labelText: 'repairs.status.target'.tr,
                ),
                items: [
                  for (final s in RepairDetailController.statusTargets)
                    DropdownMenuItem(
                      value: s,
                      child: Text('status.repair.$s'.tr),
                    ),
                ],
                onChanged: (v) => setState(() => target = v ?? target),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: note,
                decoration: InputDecoration(
                  labelText: 'repairs.status.note'.tr,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () async {
                  final ok = await c.changeStatus(target, note.text.trim());
                  if (ok) Get.back();
                },
                child: Text('common.confirm'.tr),
              ),
            ],
          ),
        ),
      ),
    ),
    isScrollControlled: true,
    backgroundColor: Get.theme.colorScheme.surface,
  );
  note.dispose();
}

Future<void> _complete(BuildContext context, RepairDetailController c) async {
  final summary = TextEditingController();
  var calibration = false;
  await Get.bottomSheet<void>(
    SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.viewInsetsOf(Get.context!).bottom + AppSpacing.lg,
        ),
        child: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'repairs.complete.title'.tr,
                style: Get.theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: summary,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'repairs.complete.summary'.tr,
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('repairs.complete.calibration'.tr),
                value: calibration,
                onChanged: (v) => setState(() => calibration = v),
              ),
              const SizedBox(height: AppSpacing.sm),
              FilledButton(
                onPressed: () async {
                  if (summary.text.trim().isEmpty) return;
                  final ok = await c.complete(
                    resolutionSummary: summary.text.trim(),
                    calibrationRequired: calibration,
                  );
                  if (ok) Get.back();
                },
                child: Text('common.confirm'.tr),
              ),
            ],
          ),
        ),
      ),
    ),
    isScrollControlled: true,
    backgroundColor: Get.theme.colorScheme.surface,
  );
  summary.dispose();
}

Future<void> _acceptance(BuildContext context, RepairDetailController c) async {
  var accepted = true;
  var rating = 5;
  final note = TextEditingController();
  await Get.bottomSheet<void>(
    SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.viewInsetsOf(Get.context!).bottom + AppSpacing.lg,
        ),
        child: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'repairs.acceptance.title'.tr,
                style: Get.theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('repairs.acceptance.accepted'.tr),
                value: accepted,
                onChanged: (v) => setState(() => accepted = v),
              ),
              if (accepted)
                Row(
                  children: [
                    Text('repairs.acceptance.rating'.tr),
                    const Spacer(),
                    for (var i = 1; i <= 5; i++)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () => setState(() => rating = i),
                        icon: Icon(
                          i <= rating ? Icons.star : Icons.star_border_outlined,
                          color: context.status.warning,
                        ),
                      ),
                  ],
                ),
              TextField(
                controller: note,
                decoration: InputDecoration(
                  labelText: 'repairs.acceptance.note'.tr,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () async {
                  final ok = await c.acceptance(
                    accepted: accepted,
                    rating: accepted ? rating : null,
                    note: note.text.trim().isEmpty ? null : note.text.trim(),
                  );
                  if (ok) Get.back();
                },
                child: Text('common.confirm'.tr),
              ),
            ],
          ),
        ),
      ),
    ),
    isScrollControlled: true,
    backgroundColor: Get.theme.colorScheme.surface,
  );
  note.dispose();
}

Future<void> _cancel(BuildContext context, RepairDetailController c) async {
  final reason = TextEditingController();
  await Get.dialog<void>(
    AlertDialog(
      title: Text('repairs.cancel.title'.tr),
      content: TextField(
        controller: reason,
        decoration: InputDecoration(labelText: 'repairs.cancel.reason'.tr),
      ),
      actions: [
        TextButton(onPressed: Get.back, child: Text('common.cancel'.tr)),
        FilledButton(
          onPressed: () async {
            if (reason.text.trim().isEmpty) return;
            Get.back();
            await c.cancel(reason.text.trim());
          },
          child: Text('common.confirm'.tr),
        ),
      ],
    ),
  );
  reason.dispose();
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
              Icons.picture_as_pdf_outlined,
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
            FilledButton.icon(
              onPressed: () async {
                try {
                  await exportRepairPdf(ticketId);
                } catch (e) {
                  AppSnackbar.error(e);
                }
              },
              icon: const Icon(Icons.open_in_new),
              label: Text('repairs.report.open'.tr),
            ),
          ],
        ),
      ),
    );
  }
}
