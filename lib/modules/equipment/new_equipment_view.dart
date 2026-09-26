import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/routes/app_routes.dart';
import '../../core/services/attachment_service.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/picker_sheet.dart';
import '../../core/widgets/signature_pad.dart';
import '../../data/models/department.dart';
import '../../data/repositories/catalogs_repository.dart';
import '../../data/repositories/departments_repository.dart';
import 'new_equipment_controller.dart';

/// Tiếp nhận máy mới tại chỗ `/equipment/new-quick`.
class NewEquipmentView extends GetView<NewEquipmentController> {
  const NewEquipmentView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('equipment.new.title'.tr)),
      body: Form(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Obx(
              () => TextField(
                controller: controller.name,
                focusNode: controller.nameFocus,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'equipment.new.name'.tr,
                  hintText: 'Máy ly tâm…',
                  errorText: controller.fieldErrors['name'],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: controller.model,
              decoration: InputDecoration(labelText: 'equipment.model'.tr),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller.serial,
                    decoration: InputDecoration(
                      labelText: 'equipment.serial'.tr,
                    ),
                  ),
                ),
                AppIconButton(
                  tone: AppButtonTone.primary,
                  tooltip: 'equipment.new.scanSerial'.tr,
                  icon: LucideIcons.scanQrCode,
                  onPressed: () async {
                    final codes =
                        (await Get.toNamed(
                              Routes.scan,
                              arguments: {'continuous': true},
                            ))
                            as List<String>?;
                    final code = codes?.firstOrNull;
                    if (code != null) controller.serial.text = code;
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: controller.circulationNo,
              decoration: InputDecoration(
                labelText: 'equipment.circulationNo'.tr,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            // Nhóm máy.
            Obx(
              () => _PickerTile(
                icon: LucideIcons.shapes,
                label: 'equipment.group'.tr,
                value: controller.group.value?.name,
                onTap: () => _pickCatalog(
                  context,
                  slug: 'equipment-groups',
                  title: 'equipment.group'.tr,
                  onPicked: controller.setGroup,
                ),
              ),
            ),
            // Hãng.
            Obx(
              () => _PickerTile(
                icon: LucideIcons.factory,
                label: 'equipment.manufacturer'.tr,
                value: controller.manufacturer.value?.name,
                onTap: () => _pickCatalog(
                  context,
                  slug: 'manufacturers',
                  title: 'equipment.manufacturer'.tr,
                  onPicked: controller.setManufacturer,
                ),
              ),
            ),
            // Khoa/Phòng ban.
            Obx(
              () => _PickerTile(
                icon: LucideIcons.building2,
                label: 'equipment.new.department'.tr,
                value: controller.department.value?.name,
                error: controller.fieldErrors['departmentId'],
                onTap: () async {
                  final departments = Get.find<DepartmentsRepository>();
                  final selection = await PickerSheet.show<String>(
                    context,
                    title: 'equipment.new.department'.tr,
                    kind: PickerKind.department,
                    loader: (q) async {
                      final list = await departments.list(q: q, limit: 20);
                      return [
                        for (final DepartmentRef d in list)
                          PickerOption(value: d.id, code: d.code, name: d.name),
                      ];
                    },
                  );
                  final d = selection?.option;
                  if (d != null) {
                    controller.setDepartment(
                      DepartmentRef(id: d.value, code: d.code, name: d.name),
                    );
                  }
                },
              ),
            ),
            // Phòng (disabled khi chưa chọn khoa).
            Obx(
              () => _PickerTile(
                icon: LucideIcons.doorOpen,
                label: 'equipment.new.room'.tr,
                value: controller.room.value?.name,
                placeholder: 'equipment.new.roomPlaceholder'.tr,
                enabled: controller.department.value != null,
                error: controller.fieldErrors['roomId'],
                onTap: () => controller.pickRoom(context),
              ),
            ),
            TextField(
              controller: controller.location,
              decoration: InputDecoration(
                labelText: 'equipment.new.locationInRoom'.tr,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _AttachRow(
              label: 'equipment.new.handover'.tr,
              bytes: controller.handover?.bytes,
              onPick: () async {
                final service = Get.find<AttachmentService>();
                final picked = await service.pickImageBytes(
                  source: ImageSource.camera,
                );
                if (picked != null) controller.handover = picked;
                controller.update();
              },
            ),
            _AttachRow(
              label: 'equipment.new.signature'.tr,
              bytes: controller.signature,
              onPick: () async {
                final png = await SignaturePad.show(context);
                if (png != null) controller.signature = png;
                controller.update();
              },
            ),
            Obx(
              () => controller.error.value.isEmpty
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Text(
                        controller.error.value,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Obx(
              () => AppButton.primary(
                icon: LucideIcons.save,
                label: 'equipment.new.submit'.tr,
                loading: controller.submitting.value,
                onPressed: controller.submitting.value
                    ? null
                    : controller.submit,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'equipment.new.mustChangeHint'.tr,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCatalog(
    BuildContext context, {
    required String slug,
    required String title,
    required void Function(DepartmentRef) onPicked,
  }) async {
    final catalogs = Get.find<CatalogsRepository>();
    final selection = await PickerSheet.show<String>(
      context,
      title: title,
      loader: (q) async {
        final list = await catalogs.list(slug, q: q, limit: 20);
        return [
          for (final DepartmentRef d in list)
            PickerOption(value: d.id, code: d.code, name: d.name),
        ];
      },
    );
    final d = selection?.option;
    if (d != null) {
      onPicked(DepartmentRef(id: d.value, code: d.code, name: d.name));
    }
  }
}

/// Dòng chọn tham chiếu dạng tile (giá trị + lỗi field).
class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.placeholder,
    this.error,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final String? value;
  final String? placeholder;
  final String? error;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          enabled: enabled,
          leading: Icon(icon),
          title: Text(
            value ?? (enabled ? label : (placeholder ?? label)),
            style: value == null && !enabled
                ? TextStyle(color: theme.disabledColor)
                : null,
          ),
          subtitle: value != null ? Text(label) : null,
          trailing: const Icon(LucideIcons.chevronRight),
          onTap: enabled ? onTap : null,
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 4),
            child: Text(
              error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }
}

class _AttachRow extends StatelessWidget {
  const _AttachRow({
    required this.label,
    required this.bytes,
    required this.onPick,
  });

  final String label;
  final Uint8List? bytes;
  final Future<void> Function() onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: bytes == null
          ? const Icon(LucideIcons.paperclip)
          : Image.memory(bytes!, width: 40, height: 40, fit: BoxFit.cover),
      title: Text(label),
      subtitle: Text(
        bytes == null ? 'common.add'.tr : 'common.done'.tr,
        style: theme.textTheme.bodySmall,
      ),
      trailing: const Icon(LucideIcons.chevronRight),
      onTap: onPick,
    );
  }
}
