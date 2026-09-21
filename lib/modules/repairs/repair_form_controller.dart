import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../core/errors/api_error.dart';
import '../../core/services/attachment_service.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../data/models/equipment.dart';
import '../../data/models/repair_detail.dart';
import '../../data/repositories/equipment_repository.dart';
import '../../data/repositories/faults_repository.dart';
import '../../data/repositories/repairs_repository.dart';
import '../../data/repositories/settings_repository.dart';

/// Báo hỏng `/repairs/new`: máy + mô tả + mức khẩn + gợi ý thư viện lỗi + ảnh.
class RepairFormController extends GetxController {
  RepairFormController({
    required this.repairs,
    required this.equipment,
    required this.faults,
    required this.attachments,
    this.settings,
    Future<void> Function(String id)? popWithId,
    String? equipmentId,
  }) : _popWithId = popWithId ?? ((id) => Get.back(result: id)),
       initialEquipmentId = equipmentId;

  final RepairsRepository repairs;
  final EquipmentRepository equipment;
  final FaultsRepository faults;
  final AttachmentService attachments;
  final SettingsRepository? settings;
  final void Function(String id) _popWithId;
  final String? initialEquipmentId;

  static const severities = ['low', 'medium', 'high', 'critical'];

  final Rxn<EquipmentRef> equipmentRef = Rxn<EquipmentRef>();
  final description = TextEditingController();
  final errorCode = TextEditingController();
  final RxString severity = 'medium'.obs;
  final RxBool equipmentDown = false.obs;
  final RxnString selectedFaultId = RxnString();
  final RxList<FaultSuggestionMatch> suggestions = <FaultSuggestionMatch>[].obs;
  final RxList<({Uint8List bytes, String name, String mime})> photos =
      <({Uint8List bytes, String name, String mime})>[].obs;
  final RxBool submitting = false.obs;
  final RxString error = ''.obs;

  /// SLA theo mức khẩn (giờ) từ `settings/public` (C14-C17).
  final RxMap<String, int> sla = <String, int>{}.obs;

  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();
    final id = initialEquipmentId;
    if (id != null && id.isNotEmpty) {
      unawaited(_loadEquipment(id));
    }
    unawaited(_loadSla());
    errorCode.addListener(_onInputChanged);
    description.addListener(_onInputChanged);
  }

  Future<void> _loadSla() async {
    try {
      final values = await settings?.repairSla();
      if (values != null) sla.assignAll(values);
    } catch (_) {
      // SLA best-effort
    }
  }

  Future<void> _loadEquipment(String id) async {
    try {
      final e = await equipment.byId(id);
      equipmentRef.value = EquipmentRef(id: e.id, code: e.code, name: e.name);
      _onInputChanged();
    } catch (_) {
      // để người dùng chọn lại
    }
  }

  void setEquipment(EquipmentRef e) {
    equipmentRef.value = e;
    _onInputChanged();
  }

  void _onInputChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), loadSuggestions);
  }

  Future<void> loadSuggestions() async {
    final e = equipmentRef.value;
    if (e == null) return;
    final code = errorCode.text.trim();
    final q = description.text.trim();
    if (code.isEmpty && q.length < 3) {
      suggestions.clear();
      return;
    }
    try {
      suggestions.assignAll(
        await faults.suggest(
          equipmentId: e.id,
          errorCode: code.isEmpty ? null : code,
          q: q.isEmpty ? null : q,
        ),
      );
    } catch (_) {
      suggestions.clear(); // gợi ý là best-effort
    }
  }

  Future<void> addPhoto() async {
    final picked = await attachments.pickImageBytes();
    if (picked == null) return;
    photos.add(picked);
  }

  Future<bool> submit() async {
    final e = equipmentRef.value;
    if (e == null) {
      error.value = 'repairs.form.equipmentRequired'.tr;
      return false;
    }
    if (description.text.trim().isEmpty) {
      error.value = 'repairs.form.descriptionRequired'.tr;
      return false;
    }
    error.value = '';
    submitting.value = true;
    try {
      final created = await repairs.create(
        equipmentId: e.id,
        description: description.text.trim(),
        errorCode: errorCode.text.trim().isEmpty ? null : errorCode.text.trim(),
        severity: severity.value,
        equipmentDown: equipmentDown.value,
        faultId: selectedFaultId.value,
      );
      for (final p in photos) {
        try {
          await attachments.uploadBytes(
            entityType: 'repair_ticket',
            entityId: created.id,
            kind: 'photo',
            name: p.name,
            mime: p.mime,
            bytes: p.bytes,
          );
        } catch (_) {
          // ảnh lỗi không chặn phiếu
        }
      }
      AppSnackbar.success('repairs.form.created'.tr);
      _popWithId(created.id);
      return true;
    } catch (err) {
      error.value = ApiError.messageFor(err);
      AppSnackbar.error(err);
      return false;
    } finally {
      submitting.value = false;
    }
  }

  @override
  void onClose() {
    _debounce?.cancel();
    errorCode.removeListener(_onInputChanged);
    description.removeListener(_onInputChanged);
    description.dispose();
    errorCode.dispose();
    super.onClose();
  }
}
