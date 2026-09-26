import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:get/get.dart';

import '../../core/format/format.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/app_sheet.dart';
import '../../core/widgets/date_field.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/form_focus.dart';
import '../../core/widgets/loading_list.dart';
import '../../core/widgets/money_field.dart';
import '../../core/widgets/picker_sheet.dart';
import '../../core/widgets/status_badge.dart';
import '../../data/models/maintenance.dart';
import 'calibrations_controller.dart';

/// Danh sách kiểm định + ghi kết quả.
class CalibrationsView extends GetView<CalibrationsController> {
  const CalibrationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('calibration.title'.tr)),
      body: Column(
        children: [
          Obx(
            () => Wrap(
              spacing: AppSpacing.xs,
              children: [
                ChoiceChip(
                  label: Text('repairs.segment.all'.tr),
                  selected:
                      controller.statusFilter.value == null &&
                      controller.dueSoonOnly.value == false,
                  onSelected: (_) => controller.setPreset(),
                ),
                ChoiceChip(
                  label: Text('calibration.preset.due30'.tr),
                  selected: controller.dueSoonOnly.value,
                  onSelected: (_) => controller.setPreset(dueSoon: true),
                ),
                ChoiceChip(
                  label: Text('calibration.preset.done'.tr),
                  selected: controller.statusFilter.value == 'done',
                  onSelected: (_) => controller.setPreset(status: 'done'),
                ),
              ],
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
                  icon: LucideIcons.badgeCheck,
                  title: 'calibration.empty'.tr,
                );
              }
              return RefreshIndicator(
                onRefresh: controller.load,
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: controller.items.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (_, i) {
                    final c = controller.items[i];
                    return Card(
                      child: ListTile(
                        title: Text(c.code),
                        subtitle: Text(
                          '${c.type == 'inspection' ? 'calibration.type.inspection'.tr : 'calibration.type.calibration'.tr}'
                          '${c.room == null ? '' : ' · ${c.room!.name}'}'
                          '${c.scheduledAt == null ? '' : ' · ${formatDate(c.scheduledAt)}'}'
                          '${c.nextDueAt == null ? '' : ' · ${'calibration.nextDue'.tr}: ${formatDate(c.nextDueAt)}'}',
                          style: theme.textTheme.bodySmall,
                        ),
                        trailing: c.status == 'done' && c.result != null
                            ? StatusBadge(
                                tone: switch (c.result) {
                                  'pass' => StatusTone.success,
                                  'fail' => StatusTone.danger,
                                  _ => StatusTone.warning,
                                },
                                label: 'calibration.result.${c.result}'.tr,
                              )
                            : StatusBadge(
                                tone: StatusTone.info,
                                label: 'status.task.scheduled'.tr,
                              ),
                        onTap: c.status == 'scheduled'
                            ? () => _completeSheet(context, controller, c)
                            : null,
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

Future<void> _completeSheet(
  BuildContext context,
  CalibrationsController c,
  Calibration calibration,
) async {
  var result = 'pass';
  String? agencyId;
  String? agencyLabel;
  String? certificateFileId;
  String? certificateName;
  final formKey = GlobalKey<FormState>();
  // Ô lỗi được focus + cuộn tới khi validate/hiện lỗi field (bàn phím không che).
  final performedAtFocus = FocusNode();
  final certificateNoFocus = FocusNode();
  final findingsFocus = FocusNode();
  final cycleFocus = FocusNode();
  final nextDueFocus = FocusNode();
  await AppSheet.show<void>(
    context,
    builder: (ctx) => SheetForm(
      initial: {'performedAt': formatDate(DateTime.now()), 'cycle': '12'},
      builder: (context, form) {
        final performedAt = form.field('performedAt');
        final certificateNo = form.field('certificateNo');
        final findings = form.field('findings');
        final cost = form.field('cost');
        final cycle = form.field('cycle');
        final nextDue = form.field('nextDue');
        void setState(VoidCallback fn) => form.refresh(fn);
        return SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SheetHeader(title: 'calibration.complete'.tr),
                Text(calibration.code),
                const SizedBox(height: AppSpacing.md),
                DateField(
                  controller: performedAt,
                  focusNode: performedAtFocus,
                  label: 'calibration.performedAt'.tr,
                  required: true,
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  children: [
                    for (final r in ['pass', 'fail', 'conditional'])
                      ChoiceChip(
                        label: Text('calibration.result.$r'.tr),
                        selected: result == r,
                        onSelected: (v) {
                          if (v) setState(() => result = r);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: () async {
                    final selected = await PickerSheet.show<String>(
                      context,
                      title: 'calibration.agency'.tr,
                      kind: PickerKind.supplier,
                      loader: c.loadAgencies,
                      showClear: true,
                    );
                    if (selected == null) return;
                    setState(() {
                      agencyId = selected.cleared
                          ? null
                          : selected.option?.value;
                      agencyLabel = selected.cleared
                          ? null
                          : selected.option?.label;
                    });
                  },
                  icon: const Icon(LucideIcons.building2),
                  label: Text(agencyLabel ?? 'calibration.agency.select'.tr),
                ),
                if (c.fieldErrors['agencyId'] case final message?)
                  Text(
                    message,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: certificateNo,
                  focusNode: certificateNoFocus,
                  decoration: InputDecoration(
                    labelText: 'calibration.certificateNo'.tr,
                    errorText: c.fieldErrors['certificateNo'],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: c.uploadingCertificate.value
                      ? null
                      : () async {
                          final id = await c.uploadCertificate(calibration);
                          if (id == null) return;
                          setState(() {
                            certificateFileId = id;
                            certificateName =
                                'calibration.certificate.attached'.tr;
                          });
                        },
                  icon: const Icon(LucideIcons.paperclip),
                  label: Text(
                    certificateName ?? 'calibration.certificate.select'.tr,
                  ),
                ),
                if (c.fieldErrors['certificateFileId'] case final message?)
                  Text(
                    message,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: findings,
                  focusNode: findingsFocus,
                  decoration: InputDecoration(
                    labelText: 'calibration.findings'.tr,
                    errorText: c.fieldErrors['findings'],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                MoneyField(controller: cost, label: 'calibration.cost'.tr),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: cycle,
                  focusNode: cycleFocus,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'calibration.cycleMonths'.tr,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                DateField(
                  controller: nextDue,
                  focusNode: nextDueFocus,
                  label: 'calibration.nextDue'.tr,
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: () async {
                    if (!(formKey.currentState?.validate() ?? false)) {
                      FormFocus.firstError([
                        performedAtFocus,
                        certificateNoFocus,
                        findingsFocus,
                        cycleFocus,
                        nextDueFocus,
                      ]);
                      return;
                    }
                    final ok = await c.complete(
                      calibration,
                      performedAt: _iso(performedAt.text) ?? performedAt.text,
                      result: result,
                      certificateNo: certificateNo.text.trim().isEmpty
                          ? null
                          : certificateNo.text.trim(),
                      certificateFileId: certificateFileId,
                      agencyId: agencyId,
                      findings: findings.text.trim().isEmpty
                          ? null
                          : findings.text.trim(),
                      cost: MoneyField.raw(cost.text).isEmpty
                          ? null
                          : MoneyField.raw(cost.text),
                      cycleMonths: num.tryParse(cycle.text.trim()),
                      nextDueAt: nextDue.text.trim().isEmpty
                          ? null
                          : _iso(nextDue.text),
                    );
                    if (ok) {
                      form.close();
                    } else if (c.fieldErrors['certificateNo'] != null) {
                      // Lỗi 400 gắn field → đưa ô lỗi lên trên bàn phím.
                      FormFocus.reveal(certificateNoFocus);
                    } else if (c.fieldErrors['findings'] != null) {
                      FormFocus.reveal(findingsFocus);
                    }
                  },
                  child: Text('common.save'.tr),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
  performedAtFocus.dispose();
  certificateNoFocus.dispose();
  findingsFocus.dispose();
  cycleFocus.dispose();
  nextDueFocus.dispose();
}

String? _iso(String display) {
  final parts = display.split('/');
  if (parts.length != 3) return null;
  return '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
}
