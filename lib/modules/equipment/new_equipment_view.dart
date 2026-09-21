import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/routes/app_routes.dart';
import '../../core/services/attachment_service.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/picker_sheet.dart';
import '../../core/widgets/signature_pad.dart';
import '../../data/models/department.dart';
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
            TextField(
              controller: controller.name,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'equipment.new.name'.tr,
                hintText: 'Máy ly tâm…',
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
                IconButton(
                  tooltip: 'equipment.new.scanSerial'.tr,
                  icon: const Icon(Icons.qr_code_scanner),
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
            Obx(
              () => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.apartment_outlined),
                title: Text(
                  controller.department.value == null
                      ? 'equipment.new.department'.tr
                      : controller.department.value!.name,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final departments = Get.find<DepartmentsRepository>();
                  final selection = await PickerSheet.show<String>(
                    title: 'equipment.new.department'.tr,
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
            TextField(
              controller: controller.location,
              decoration: InputDecoration(
                labelText: 'equipment.new.location'.tr,
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
                final png = await SignaturePad.show();
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
                    : const Icon(Icons.save_outlined),
                label: Text('equipment.new.submit'.tr),
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
          ? const Icon(Icons.attach_file_outlined)
          : Image.memory(bytes!, width: 40, height: 40, fit: BoxFit.cover),
      title: Text(label),
      subtitle: Text(
        bytes == null ? 'common.add'.tr : 'common.done'.tr,
        style: theme.textTheme.bodySmall,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onPick,
    );
  }
}
