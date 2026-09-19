import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/format/format.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_list.dart';
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
                  icon: Icons.verified_outlined,
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
                        title: Text('${c.code} — ${c.equipmentId}'),
                        subtitle: Text(
                          '${c.type == 'inspection' ? 'calibration.type.inspection'.tr : 'calibration.type.calibration'.tr}'
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
                            ? () => _completeSheet(controller, c)
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
  CalibrationsController c,
  Calibration calibration,
) async {
  var result = 'pass';
  final performedAt = TextEditingController(text: formatDate(DateTime.now()));
  final certificateNo = TextEditingController();
  final findings = TextEditingController();
  final cost = TextEditingController();
  final cycle = TextEditingController(text: '12');
  final nextDue = TextEditingController();
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
          builder: (context, setState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'calibration.complete'.tr,
                  style: Get.theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(calibration.code),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: performedAt,
                  readOnly: true,
                  onTap: () async {
                    final d = await showDatePicker(
                      context: Get.context!,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (d != null) performedAt.text = formatDate(d);
                  },
                  decoration: InputDecoration(
                    labelText: 'calibration.performedAt'.tr,
                    suffixIcon: const Icon(Icons.event_outlined),
                  ),
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
                TextField(
                  controller: certificateNo,
                  decoration: InputDecoration(
                    labelText: 'calibration.certificateNo'.tr,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: findings,
                  decoration: InputDecoration(
                    labelText: 'calibration.findings'.tr,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: cost,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'calibration.cost'.tr),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: cycle,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'calibration.cycleMonths'.tr,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: nextDue,
                  readOnly: true,
                  onTap: () async {
                    final d = await showDatePicker(
                      context: Get.context!,
                      initialDate: DateTime.now().add(
                        Duration(days: 30 * (int.tryParse(cycle.text) ?? 12)),
                      ),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (d != null) nextDue.text = formatDate(d);
                  },
                  decoration: InputDecoration(
                    labelText: 'calibration.nextDue'.tr,
                    suffixIcon: const Icon(Icons.event_outlined),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: () async {
                    final ok = await c.complete(
                      calibration,
                      performedAt: _iso(performedAt.text) ?? performedAt.text,
                      result: result,
                      certificateNo: certificateNo.text.trim().isEmpty
                          ? null
                          : certificateNo.text.trim(),
                      findings: findings.text.trim().isEmpty
                          ? null
                          : findings.text.trim(),
                      cost: cost.text.trim().isEmpty ? null : cost.text.trim(),
                      cycleMonths: num.tryParse(cycle.text.trim()),
                      nextDueAt: nextDue.text.trim().isEmpty
                          ? null
                          : _iso(nextDue.text),
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
    ),
    isScrollControlled: true,
    backgroundColor: Get.theme.colorScheme.surface,
  );
  performedAt.dispose();
  certificateNo.dispose();
  findings.dispose();
  cost.dispose();
  cycle.dispose();
  nextDue.dispose();
}

String? _iso(String display) {
  final parts = display.split('/');
  if (parts.length != 3) return null;
  return '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
}
