import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/picker_sheet.dart';
import '../../core/widgets/status_badge.dart';
import '../../data/models/equipment.dart';
import '../../data/repositories/equipment_repository.dart';
import 'repair_form_controller.dart';

/// Báo hỏng `/repairs/new`.
class RepairFormView extends GetView<RepairFormController> {
  const RepairFormView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('repairs.form.title'.tr)),
      body: Form(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Obx(
              () => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.biotech_outlined),
                title: Text(
                  controller.equipmentRef.value == null
                      ? 'repairs.form.equipment'.tr
                      : '${controller.equipmentRef.value!.code} — ${controller.equipmentRef.value!.name}',
                ),
                subtitle: Text('repairs.form.pick'.tr),
                trailing: IconButton(
                  tooltip: 'repairs.form.scan'.tr,
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: () async {
                    final codes = await Get.toNamed<List<String>>(
                      Routes.scan,
                      arguments: {'continuous': true},
                    );
                    final code = codes?.firstOrNull;
                    if (code == null) return;
                    final repo = Get.find<EquipmentRepository>();
                    final page = await repo.search(code, limit: 5);
                    final match = page.items.firstOrNull;
                    if (match != null) {
                      controller.setEquipment(
                        EquipmentRef(
                          id: match.id,
                          code: match.code,
                          name: match.name,
                        ),
                      );
                    }
                  },
                ),
                onTap: () async {
                  final repo = Get.find<EquipmentRepository>();
                  final selection = await PickerSheet.show<String>(
                    title: 'repairs.form.pick'.tr,
                    loader: (q) async {
                      final page = await repo.search(q, limit: 20);
                      return [
                        for (final e in page.items)
                          PickerOption(value: e.id, code: e.code, name: e.name),
                      ];
                    },
                  );
                  final o = selection?.option;
                  if (o != null) {
                    controller.setEquipment(
                      EquipmentRef(id: o.value, code: o.code, name: o.name),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: controller.description,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'repairs.form.description'.tr,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: controller.errorCode,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'repairs.form.errorCode'.tr,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('repairs.form.severity'.tr, style: theme.textTheme.labelLarge),
            Obx(
              () => Wrap(
                spacing: AppSpacing.xs,
                children: [
                  for (final s in RepairFormController.severities)
                    ChoiceChip(
                      label: Text('status.severity.$s'.tr),
                      selected: controller.severity.value == s,
                      onSelected: (v) {
                        if (v) controller.severity.value = s;
                      },
                    ),
                ],
              ),
            ),
            Obx(
              () => SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('repairs.form.equipmentDown'.tr),
                value: controller.equipmentDown.value,
                onChanged: (v) => controller.equipmentDown.value = v,
              ),
            ),
            Obx(() {
              if (controller.suggestions.isEmpty) {
                return const SizedBox.shrink();
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'repairs.form.suggestions'.tr,
                    style: theme.textTheme.labelLarge,
                  ),
                  for (final s in controller.suggestions.take(5))
                    Card(
                      child: ListTile(
                        title: Text(
                          [
                            s.fault.errorCode,
                            s.fault.title,
                          ].where((x) => x.isNotEmpty).join(' — '),
                        ),
                        subtitle: Text(
                          'repairs.suggestion.times'.trParams({
                            'on': '${s.onEquipment}',
                            'model': '${s.sameModel}',
                          }),
                        ),
                        trailing: StatusBadge(
                          tone: toneForRepairSeverity(s.fault.severity),
                          label: 'status.severity.${s.fault.severity}'.tr,
                        ),
                        onTap: () =>
                            controller.selectedFaultId.value = s.fault.id,
                      ),
                    ),
                ],
              );
            }),
            Obx(() {
              if (controller.photos.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    for (final p in controller.photos)
                      Chip(
                        avatar: const Icon(Icons.photo_outlined, size: 16),
                        label: Text(p.name),
                      ),
                  ],
                ),
              );
            }),
            OutlinedButton.icon(
              onPressed: controller.addPhoto,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: Text('repairs.form.addPhoto'.tr),
            ),
            const SizedBox(height: AppSpacing.sm),
            Obx(
              () => controller.error.value.isEmpty
                  ? const SizedBox.shrink()
                  : Text(
                      controller.error.value,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
            ),
            const SizedBox(height: AppSpacing.md),
            Obx(
              () => FilledButton.icon(
                onPressed: controller.submitting.value
                    ? null
                    : controller.submit,
                icon: controller.submitting.value
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_outlined),
                label: Text('common.confirm'.tr),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
