import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../core/services/attachment_service.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../data/models/department.dart';
import '../../data/models/equipment_detail.dart';
import '../../data/repositories/departments_repository.dart';
import '../../data/repositories/equipment_repository.dart';

/// Tiếp nhận máy mới tại chỗ: form ngắn → tạo máy → đính kèm ảnh/biên bản/chữ ký.
class NewEquipmentController extends GetxController {
  NewEquipmentController({
    required this.equipment,
    required this.departments,
    required this.attachments,
    void Function()? pop,
  }) : _pop = pop ?? (Get.back);

  final EquipmentRepository equipment;
  final DepartmentsRepository departments;
  final AttachmentService attachments;
  final void Function() _pop;

  final name = TextEditingController();
  final model = TextEditingController();
  final serial = TextEditingController();
  final location = TextEditingController();

  final Rxn<DepartmentRef> department = Rxn<DepartmentRef>();
  final RxBool submitting = false.obs;
  final RxString error = ''.obs;

  ({Uint8List bytes, String name, String mime})? handover;
  Uint8List? signature;

  void setDepartment(DepartmentRef d) => department.value = d;

  Future<bool> submit() async {
    final n = name.text.trim();
    if (n.isEmpty) {
      error.value = 'equipment.new.nameRequired'.tr;
      return false;
    }
    error.value = '';
    submitting.value = true;
    try {
      final created = await equipment.create({
        'name': n,
        if (model.text.trim().isNotEmpty) 'model': model.text.trim(),
        if (serial.text.trim().isNotEmpty) 'serial': serial.text.trim(),
        if (department.value != null) 'departmentId': department.value!.id,
        if (location.text.trim().isNotEmpty) 'location': location.text.trim(),
      });
      // Đính kèm best-effort (offline sẽ vào outbox).
      await _attachAll(created);
      AppSnackbar.success('equipment.new.created'.tr);
      _pop();
      return true;
    } catch (e) {
      error.value = e.toString();
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
    location.dispose();
    super.onClose();
  }
}
