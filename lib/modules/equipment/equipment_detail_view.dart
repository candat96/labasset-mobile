import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/errors/api_error.dart';
import '../../core/format/decimal_input.dart';
import '../../core/format/format.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/attachments_grid.dart';
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
import 'tabs/network_tab.dart';
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
      return DefaultTabController(
        length: 9,
        child: Scaffold(
          appBar: AppBar(
            title: Text(e.code),
            bottom: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                Tab(text: 'equipment.tab.specs'.tr),
                Tab(text: 'equipment.tab.network'.tr),
                Tab(text: 'equipment.tab.accessories'.tr),
                Tab(text: 'equipment.tab.software'.tr),
                Tab(text: 'equipment.tab.components'.tr),
                Tab(text: 'equipment.tab.supplies'.tr),
                Tab(text: 'equipment.tab.documents'.tr),
                Tab(text: 'equipment.tab.timeline'.tr),
                Tab(text: 'equipment.tab.faults'.tr),
              ],
            ),
          ),
          body: Column(
            children: [
              _SummaryCard(e: e),
              _QuickActions(controller: controller, e: e),
              const Divider(height: 1),
              Expanded(
                child: TabBarView(
                  children: [
                    SpecsTab(e: e),
                    const NetworkTab(),
                    const AccessoriesTab(),
                    const SoftwareTab(),
                    const ComponentsTab(),
                    const SuppliesTab(),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: SingleChildScrollView(
                        child: AttachmentsGrid(
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
                      ),
                    ),
                    const TimelineTab(),
                    FaultsTab(model: e.model),
                  ],
                ),
              ),
            ],
          ),
        ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(e.name, style: theme.textTheme.titleMedium)),
              StatusBadge(
                tone: toneForEquipmentStatus(e.status),
                label: 'status.${e.status}'.tr,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            [
              e.model,
              e.serial == null ? null : 'SN ${e.serial}',
              [e.department?.name, e.location].whereType<String>().join(' · '),
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
            const SizedBox(height: AppSpacing.xs),
            Row(
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isOverdue ? Icons.warning_amber_outlined : Icons.event_outlined,
          size: 14,
          color: isOverdue
              ? context.status.danger
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          '$label: ${d == null ? '—' : formatDate(d)}',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: isOverdue ? context.status.danger : null,
          ),
        ),
      ],
    );
  }

  Widget _count(BuildContext context, String label, num value) => Padding(
    padding: const EdgeInsets.only(right: AppSpacing.md),
    child: Text(
      '$label: $value',
      style: Theme.of(context).textTheme.labelMedium,
    ),
  );
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.controller, required this.e});

  final EquipmentDetailController controller;
  final EquipmentDetail e;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        children: [
          for (final a in EquipmentDetailView._actionKeys)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: ActionChip(
                avatar: Icon(a.icon, size: 18),
                label: Text('equipment.action.${a.key}'.tr),
                onPressed: () => _run(context, a.key),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _run(BuildContext context, String key) async {
    switch (key) {
      case 'reportFault':
        await Get.toNamed('${Routes.repairNew}?equipmentId=${e.id}');
      case 'adhocMaintenance':
        await _adhoc();
      case 'issueSupplies':
        await Get.toNamed(
          Routes.stockIssueNew,
          arguments: {'equipmentId': e.id},
        );
      case 'counters':
        await _counters();
      case 'updateStatus':
        await _status();
      case 'addPhoto':
        await _photos();
      case 'location':
        await _location();
      case 'note':
        await _note();
      case 'transfer':
        await _transfer();
      case 'assistant':
        await Get.toNamed(Routes.ai);
      case 'reprint':
        await _reprint();
    }
  }

  Future<void> _adhoc() async {
    final note = TextEditingController();
    await Get.dialog<void>(
      AlertDialog(
        title: Text('equipment.action.adhocMaintenance'.tr),
        content: TextField(
          controller: note,
          decoration: InputDecoration(labelText: 'equipment.note.hint'.tr),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: Text('common.cancel'.tr)),
          FilledButton(
            onPressed: () async {
              Get.back();
              await controller.createAdhocMaintenance(
                notes: note.text.trim().isEmpty ? null : note.text.trim(),
              );
            },
            child: Text('common.confirm'.tr),
          ),
        ],
      ),
    );
    note.dispose();
  }

  Future<void> _counters() async {
    final hours = TextEditingController(text: e.currentRunHours ?? '');
    final tests = TextEditingController(
      text: e.currentTestCount?.toString() ?? '',
    );
    final note = TextEditingController();
    await Get.bottomSheet<void>(
      SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
            bottom:
                MediaQuery.viewInsetsOf(Get.context!).bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'equipment.counters.title'.tr,
                style: Get.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              QtyField(
                controller: hours,
                label: 'equipment.counters.runHours'.tr,
              ),
              const SizedBox(height: AppSpacing.sm),
              QtyField(
                controller: tests,
                label: 'equipment.counters.testCount'.tr,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: note,
                decoration: InputDecoration(
                  labelText: 'equipment.counters.note'.tr,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () async {
                  final ok = await controller.addCounters(
                    runHours: parseDecimalInput(hours.text)?.toString(),
                    testCount: int.tryParse(tests.text.trim()),
                    note: note.text.trim().isEmpty ? null : note.text.trim(),
                  );
                  if (ok) Get.back();
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
    hours.dispose();
    tests.dispose();
    note.dispose();
  }

  Future<void> _status() async {
    final allowed = controller.allowedTransitions(e.status);
    if (allowed.isEmpty) {
      AppSnackbar.info('equipment.status.noTransition'.tr);
      return;
    }
    var selected = allowed.first;
    final reason = TextEditingController();
    await Get.bottomSheet<void>(
      SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
            bottom:
                MediaQuery.viewInsetsOf(Get.context!).bottom + AppSpacing.lg,
          ),
          child: StatefulBuilder(
            builder: (context, setState) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'equipment.status.title'.tr,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: selected,
                  decoration: InputDecoration(
                    labelText: 'equipment.status.to'.tr,
                  ),
                  items: [
                    for (final s in allowed)
                      DropdownMenuItem(value: s, child: Text('status.$s'.tr)),
                  ],
                  onChanged: (v) => setState(() => selected = v ?? selected),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: reason,
                  decoration: InputDecoration(
                    labelText: 'equipment.status.reason'.tr,
                    hintText: 'equipment.status.reasonHint'.tr,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: () async {
                    if (reason.text.trim().isEmpty) return;
                    final ok = await controller.changeStatus(
                      selected,
                      reason.text.trim(),
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
    reason.dispose();
  }

  Future<void> _photos() => Get.dialog<void>(
    Dialog(
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

  Future<void> _location() async {
    final location = TextEditingController(text: e.location ?? '');
    final ip = TextEditingController();
    final mac = TextEditingController();
    await Get.bottomSheet<void>(
      SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
            bottom:
                MediaQuery.viewInsetsOf(Get.context!).bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'equipment.location.title'.tr,
                style: Get.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: location,
                decoration: InputDecoration(
                  labelText: 'equipment.location.label'.tr,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: ip,
                decoration: InputDecoration(
                  labelText: 'equipment.location.ip'.tr,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: mac,
                decoration: InputDecoration(
                  labelText: 'equipment.location.mac'.tr,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () async {
                  await controller.saveLocation(location.text.trim());
                  if (ip.text.trim().isNotEmpty || mac.text.trim().isNotEmpty) {
                    await controller.saveNetwork(
                      ip: ip.text.trim(),
                      mac: mac.text.trim(),
                    );
                  }
                  Get.back();
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
    location.dispose();
    ip.dispose();
    mac.dispose();
  }

  Future<void> _note() async {
    final text = TextEditingController();
    await Get.dialog<void>(
      AlertDialog(
        title: Text('equipment.note.title'.tr),
        content: TextField(
          controller: text,
          maxLines: 3,
          decoration: InputDecoration(hintText: 'equipment.note.hint'.tr),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: Text('common.cancel'.tr)),
          FilledButton(
            onPressed: () async {
              final v = text.text;
              Get.back();
              if (v.trim().isNotEmpty) await controller.addNote(v.trim());
            },
            child: Text('common.save'.tr),
          ),
        ],
      ),
    );
    text.dispose();
  }

  Future<void> _transfer() async {
    final departments = Get.find<DepartmentsRepository>();
    final selection = await PickerSheet.show<String>(
      title: 'equipment.transfer.toDepartment'.tr,
      loader: (q) async {
        final list = await departments.list(q: q, limit: 20);
        return [
          for (final DepartmentRef d in list)
            PickerOption(value: d.id, code: d.code, name: d.name),
        ];
      },
    );
    final dept = selection?.option;
    if (dept == null) return;
    final location = TextEditingController();
    final reason = TextEditingController();
    await Get.bottomSheet<void>(
      SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
            bottom:
                MediaQuery.viewInsetsOf(Get.context!).bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'equipment.transfer.title'.tr,
                style: Get.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(dept.label),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: location,
                decoration: InputDecoration(
                  labelText: 'equipment.transfer.toLocation'.tr,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: reason,
                decoration: InputDecoration(
                  labelText: 'equipment.transfer.reason'.tr,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () async {
                  if (reason.text.trim().isEmpty) return;
                  final ok = await controller.createTransfer(
                    toDepartmentId: dept.value,
                    toLocation: location.text.trim().isEmpty
                        ? null
                        : location.text.trim(),
                    reason: reason.text.trim(),
                  );
                  if (ok) Get.back();
                },
                child: Text('common.confirm'.tr),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Get.theme.colorScheme.surface,
    );
    location.dispose();
    reason.dispose();
  }

  Future<void> _reprint() async {
    final ok = await ConfirmSheet.show(
      title: 'scan.reprint'.tr,
      confirmLabel: 'common.confirm'.tr,
    );
    if (!ok) return;
    final done = await controller.reprintLabel();
    if (done) AppSnackbar.success('scan.reprint.sent'.tr);
  }
}
