import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:get/get.dart';

import '../../core/errors/api_error.dart';
import '../../core/services/attachment_service.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/app_sheet.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/form_focus.dart';
import '../../core/widgets/picker_sheet.dart';
import '../../data/models/department.dart';
import '../../data/models/equipment_detail.dart';
import '../../data/models/room.dart';
import '../../data/repositories/catalogs_repository.dart';
import '../../data/repositories/departments_repository.dart';
import '../../data/repositories/equipment_repository.dart';

/// Tiếp nhận máy mới tại chỗ: Khoa/Phòng ban → Phòng → Vị trí → tạo máy →
/// đính kèm ảnh/biên bản/chữ ký.
class NewEquipmentController extends GetxController {
  NewEquipmentController({
    required this.equipment,
    required this.departments,
    required this.catalogs,
    required this.attachments,
    this.canCreateRoom = true,
    void Function()? pop,
  }) : _pop = pop ?? (Get.back);

  final EquipmentRepository equipment;
  final DepartmentsRepository departments;
  final CatalogsRepository catalogs;
  final AttachmentService attachments;

  /// Cho phép "Thêm phòng mới" nhanh (ADM/EQUIPMENT_STAFF).
  final bool canCreateRoom;
  final void Function() _pop;

  final name = TextEditingController();
  final model = TextEditingController();
  final serial = TextEditingController();
  final circulationNo = TextEditingController();
  final location = TextEditingController();

  /// Focus ô tên khi thiếu (bàn phím không che ô lỗi).
  final nameFocus = FocusNode();

  final Rxn<DepartmentRef> department = Rxn<DepartmentRef>();
  final Rxn<RoomRef> room = Rxn<RoomRef>();
  final Rxn<DepartmentRef> group = Rxn<DepartmentRef>();
  final Rxn<DepartmentRef> manufacturer = Rxn<DepartmentRef>();

  final RxBool submitting = false.obs;
  final RxString error = ''.obs;
  final RxMap<String, String> fieldErrors = <String, String>{}.obs;

  ({Uint8List bytes, String name, String mime})? handover;
  Uint8List? signature;

  /// Chọn Khoa/Phòng ban → luôn bỏ Phòng (phòng thuộc khoa cũ).
  void setDepartment(DepartmentRef d) {
    department.value = d;
    room.value = null;
    fieldErrors.remove('departmentId');
  }

  void setGroup(DepartmentRef d) => group.value = d;

  void setManufacturer(DepartmentRef d) => manufacturer.value = d;

  /// Chọn phòng trong khoa đã chọn (kèm phòng dùng chung).
  Future<void> pickRoom(BuildContext context) async {
    final dep = department.value;
    if (dep == null) {
      AppSnackbar.info('equipment.new.roomPlaceholder'.tr);
      return;
    }
    final list = await catalogs.rooms(departmentId: dep.id);
    if (!context.mounted) return;
    final selection = await PickerSheet.show<RoomRef>(
      context,
      title: 'equipment.new.room'.tr,
      kind: PickerKind.equipment,
      showClear: true,
      selected: room.value,
      footer: canCreateRoom
          ? (ctx) => Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () async {
                  final created = await _promptNewRoom(ctx, dep);
                  if (created != null && ctx.mounted) {
                    AppSheet.close<PickerSelection<RoomRef>>(
                      ctx,
                      PickerSelection<RoomRef>(
                        PickerOption(
                          value: created,
                          code: created.code,
                          name: created.name,
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(LucideIcons.plus, size: 18),
                label: Text('equipment.room.new'.tr),
              ),
            )
          : null,
      loader: (query) async {
        final needle = query.trim().toLowerCase();
        return [
          for (final r in list)
            if (needle.isEmpty ||
                r.code.toLowerCase().contains(needle) ||
                r.name.toLowerCase().contains(needle))
              PickerOption(
                value: r,
                code: r.code,
                name: r.name,
                subtitle:
                    r.placeText ??
                    (r.departmentId == null
                        ? 'equipment.room.shared'.tr
                        : null),
              ),
        ];
      },
    );
    if (selection == null) return;
    room.value = selection.cleared ? null : selection.option?.value;
    if (room.value != null) fieldErrors.remove('roomId');
  }

  /// Tạo phòng nhanh trong khoa đang chọn rồi chọn luôn.
  Future<RoomRef?> quickCreateRoom({
    required String name,
    String? code,
    String? building,
    String? floor,
  }) async {
    final dep = department.value;
    if (dep == null) return null;
    final created = await catalogs.createRoom(
      code: code,
      name: name,
      departmentId: dep.id,
      building: building,
      floor: floor,
    );
    room.value = created;
    return created;
  }

  Future<RoomRef?> _promptNewRoom(
    BuildContext context,
    DepartmentRef dep,
  ) async {
    final created = await AppSheet.show<RoomRef>(
      context,
      builder: (ctx) => SheetForm(
        builder: (ctx, form) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SheetHeader(title: 'equipment.room.new'.tr),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Text(
                dep.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                children: [
                  TextField(
                    controller: form.field('name'),
                    focusNode: form.focusNode('name'),
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: 'equipment.room.nameLabel'.tr,
                      errorText: form.error('name'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: form.field('code'),
                    decoration: InputDecoration(
                      labelText: 'equipment.room.codeLabel'.tr,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: form.field('building'),
                          decoration: InputDecoration(
                            labelText: 'equipment.room.building'.tr,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: TextField(
                          controller: form.field('floor'),
                          decoration: InputDecoration(
                            labelText: 'equipment.room.floor'.tr,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: form.busy
                          ? null
                          : () async {
                              final n = form.text('name');
                              if (n.isEmpty) {
                                form.setError('name', 'common.required'.tr);
                                return;
                              }
                              form.setBusy(true);
                              try {
                                final created = await quickCreateRoom(
                                  name: n,
                                  code: form.textOrNull('code'),
                                  building: form.textOrNull('building'),
                                  floor: form.textOrNull('floor'),
                                );
                                AppSnackbar.success(
                                  'equipment.room.created'.tr,
                                );
                                form.close<RoomRef>(created);
                              } catch (e) {
                                form.setBusy(false);
                                AppSnackbar.error(e);
                              }
                            },
                      child: Text('common.save'.tr),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return created;
  }

  Future<bool> submit() async {
    final n = name.text.trim();
    fieldErrors.clear();
    if (n.isEmpty) {
      fieldErrors['name'] = 'equipment.new.nameRequired'.tr;
      error.value = 'equipment.new.nameRequired'.tr;
      FormFocus.reveal(nameFocus);
      return false;
    }
    if (department.value == null) {
      fieldErrors['departmentId'] = 'equipment.new.departmentRequired'.tr;
      error.value = 'equipment.new.departmentRequired'.tr;
      return false;
    }
    if (room.value == null) {
      fieldErrors['roomId'] = 'equipment.new.roomRequired'.tr;
      error.value = 'equipment.new.roomRequired'.tr;
      return false;
    }
    error.value = '';
    submitting.value = true;
    try {
      final created = await equipment.create({
        'name': n,
        if (model.text.trim().isNotEmpty) 'model': model.text.trim(),
        if (serial.text.trim().isNotEmpty) 'serial': serial.text.trim(),
        if (circulationNo.text.trim().isNotEmpty)
          'circulationNo': circulationNo.text.trim(),
        'departmentId': department.value!.id,
        'roomId': room.value!.id,
        if (group.value != null) 'groupId': group.value!.id,
        if (manufacturer.value != null)
          'manufacturerId': manufacturer.value!.id,
        if (location.text.trim().isNotEmpty) 'location': location.text.trim(),
      });
      // Đính kèm best-effort (offline sẽ vào outbox).
      await _attachAll(created);
      AppSnackbar.success('equipment.new.created'.tr);
      _pop();
      return true;
    } catch (e) {
      final fields = ApiError.from(e).fieldErrors();
      if (fields.isNotEmpty) fieldErrors.addAll(fields);
      error.value = ApiError.messageFor(e);
      AppSnackbar.error(e);
      return false;
    } finally {
      submitting.value = false;
    }
  }

  Future<void> _attachAll(EquipmentDetail created) async {
    if (handover != null) {
      await _tryUpload(
        created.id,
        handover!.bytes,
        handover!.name,
        handover!.mime,
        'handover',
      );
    }
    if (signature != null) {
      await _tryUpload(
        created.id,
        signature!,
        'chu-ky-${created.code}.png',
        'image/png',
        'handover',
      );
    }
  }

  Future<void> _tryUpload(
    String id,
    Uint8List bytes,
    String name,
    String mime,
    String kind,
  ) async {
    try {
      await attachments.uploadBytes(
        entityType: 'equipment',
        entityId: id,
        kind: kind,
        name: name,
        mime: mime,
        bytes: bytes,
      );
    } catch (_) {
      // đã xếp outbox (offline) hoặc lỗi — không chặn tạo máy
    }
  }

  @override
  void onClose() {
    name.dispose();
    model.dispose();
    serial.dispose();
    circulationNo.dispose();
    location.dispose();
    nameFocus.dispose();
    super.onClose();
  }
}
