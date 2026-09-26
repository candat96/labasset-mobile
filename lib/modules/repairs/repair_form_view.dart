import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:get/get.dart';

import '../../core/routes/app_routes.dart';
import '../../core/services/attachment_service.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/list_item_card.dart';
import '../../core/widgets/photo_grid.dart';
import '../../core/widgets/photo_picker.dart';
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
                leading: const Icon(LucideIcons.flaskConical),
                title: Text(
                  controller.equipmentRef.value == null
                      ? 'repairs.form.equipment'.tr
                      : '${controller.equipmentRef.value!.code} — ${controller.equipmentRef.value!.name}',
                ),
                subtitle: Text('repairs.form.pick'.tr),
                trailing: AppIconButton(
                  tooltip: 'repairs.form.scan'.tr,
                  icon: LucideIcons.scanQrCode,
                  onPressed: () async {
                    final codes =
                        (await Get.toNamed(
                              Routes.scan,
                              arguments: {'continuous': true},
                            ))
                            as List<String>?;
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
                    context,
                    title: 'repairs.form.pick'.tr,
                    kind: PickerKind.equipment,
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
              focusNode: controller.descriptionFocus,
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
                      label: Text(
                        controller.sla[s] == null
                            ? 'status.severity.$s'.tr
                            : '${'status.severity.$s'.tr} · SLA ${controller.sla[s]}h',
                      ),
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
                    ListItemCard(
                      title: [
                        s.fault.errorCode,
                        s.fault.title,
                      ].where((x) => x.isNotEmpty).join(' — '),
                      badge: StatusBadge(
                        tone: toneForRepairSeverity(s.fault.severity),
                        label: 'status.severity.${s.fault.severity}'.tr,
                      ),
                      metas: [
                        ListMeta(
                          LucideIcons.history,
                          'repairs.suggestion.times'.trParams({
                            'on': '${s.onEquipment}',
                            'model': '${s.sameModel}',
                          }),
                        ),
                      ],
                      onTap: () =>
                          controller.selectedFaultId.value = s.fault.id,
                    ),
                ],
              );
            }),
            Obx(() {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'repairs.form.photoTitle'.tr,
                    style: theme.textTheme.titleSmall,
                  ),
                  Text('repairs.form.photoHint'.tr),
                  const SizedBox(height: AppSpacing.sm),
                  PhotoGrid(
                    tiles: [
                      for (final p in controller.photos)
                        PhotoGridTile(
                          image: MemoryImage(p.bytes),
                          onTap: () => _previewPhoto(context, p),
                          onRemove: controller.submitting.value
                              ? null
                              : () => controller.removePhoto(p),
                          removeTooltip: 'attachment.removePhoto'.tr,
                        ),
                    ],
                    onAdd: controller.submitting.value
                        ? null
                        : () async {
                            final picked = await PhotoPicker.pickWithSource(
                              context,
                            );
                            controller.addPhotos(picked);
                          },
                    addLabel: 'attachment.addPhotos'.tr,
                  ),
                ],
              );
            }),
            const SizedBox(height: AppSpacing.sm),
            Obx(
              () => controller.error.value.isEmpty
                  ? const SizedBox.shrink()
                  : Text(
                      controller.error.value,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Obx(
            () => AppButton.primary(
              label: 'common.confirm'.tr,
              icon: LucideIcons.send,
              loading: controller.submitting.value,
              onPressed: controller.submit,
            ),
          ),
        ),
      ),
    );
  }
}

/// Xem ảnh đã chọn ở dạng toàn màn (zoom được) trước khi gửi.
Future<void> _previewPhoto(BuildContext context, PickedImage photo) =>
    showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InteractiveViewer(
              maxScale: 4,
              child: Image.memory(photo.bytes, fit: BoxFit.contain),
            ),
            OverflowBar(
              children: [
                AppButton.soft(
                  label: 'common.close'.tr,
                  tone: AppButtonTone.neutral,
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ],
        ),
      ),
    );
