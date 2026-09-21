import 'package:get/get.dart';

import '../../core/errors/api_error.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../data/models/equipment_detail.dart';
import '../../data/repositories/equipment_repository.dart';
import '../../data/repositories/tasks_repository.dart';

/// Ma trận chuyển trạng thái hợp lệ (theo API `equipment-status.ts`).
const Map<String, List<String>> kStatusTransitions = {
  'active': ['broken', 'awaiting_parts', 'suspended', 'retired'],
  'broken': ['active', 'awaiting_parts', 'retired'],
  'awaiting_parts': ['active', 'broken', 'retired'],
  'suspended': ['active', 'retired'],
  'retired': ['disposed', 'active'],
  'disposed': <String>[],
};

/// Hồ sơ máy: thẻ tóm tắt + thao tác nhanh (đổi trạng thái, bộ đếm, ghi chú…).
class EquipmentDetailController extends GetxController {
  EquipmentDetailController({
    required this.equipment,
    required this.tasks,
    required this.id,
    String? userId,
  }) : userId = userId ?? '';

  final EquipmentRepository equipment;
  final TasksRepository tasks;
  final String id;

  /// Người dùng hiện tại (gán bảo dưỡng đột xuất cho chính mình).
  final String userId;

  final Rxn<EquipmentDetail> item = Rxn<EquipmentDetail>();
  final RxBool loading = true.obs;
  final Rxn<Object> error = Rxn<Object>();

  /// Nút ghi chỉ cho ADM/VT — màn gọi truyền vào theo role.
  bool get canWrite => true;

  List<String> allowedTransitions(String from) =>
      kStatusTransitions[from] ?? const [];

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      item.value = await equipment.detail(id);
    } catch (e) {
      error.value = e;
    } finally {
      loading.value = false;
    }
  }

  Future<bool> changeStatus(String status, String reason) async {
    try {
      await equipment.changeStatus(id, status, reason);
      AppSnackbar.success('equipment.status.changed'.tr);
      await load();
      return true;
    } catch (e) {
      AppSnackbar.error(e);
      return false;
    }
  }

  Future<bool> addCounters({
    String? runHours,
    num? testCount,
    String? note,
  }) async {
    try {
      await equipment.addCounters(
        id,
        runHours: runHours,
        testCount: testCount,
        note: note,
      );
      AppSnackbar.success('equipment.counters.saved'.tr);
      await load();
      return true;
    } catch (e) {
      AppSnackbar.error(e);
      return false;
    }
  }

  Future<bool> addNote(String text) async {
    try {
      await equipment.addNote(id, text);
      AppSnackbar.success('equipment.note.saved'.tr);
      return true;
    } catch (e) {
      AppSnackbar.error(e);
      return false;
    }
  }

  Future<bool> reprintLabel() => addNote('Yêu cầu in lại tem QR');

  Future<bool> saveLocation(String location) async {
    try {
      await equipment.patch(id, {'location': location});
      AppSnackbar.success('equipment.location.saved'.tr);
      await load();
      return true;
    } catch (e) {
      AppSnackbar.error(e);
      return false;
    }
  }

  Future<bool> saveNetwork({String? ip, String? mac}) async {
    try {
      final current = await equipment.network(id);
      await equipment.putNetwork(id, current.copyWith(ip: ip, mac: mac));
      AppSnackbar.success('equipment.network.saved'.tr);
      return true;
    } catch (e) {
      AppSnackbar.error(e);
      return false;
    }
  }

  /// Bảo dưỡng đột xuất: `scheduledAt = now`, gán cho chính mình.
  Future<bool> createAdhocMaintenance({String? notes}) async {
    try {
      await tasks.create(
        equipmentId: id,
        scheduledAt: DateTime.now().toUtc().toIso8601String(),
        assigneeId: userId.isEmpty ? null : userId,
        notes: notes,
      );
      AppSnackbar.success('equipment.adhoc.created'.tr);
      return true;
    } catch (e) {
      AppSnackbar.error(e);
      return false;
    }
  }

  Future<bool> createTransfer({
    required String toDepartmentId,
    String? toRoomId,
    String? toLocation,
    required String reason,
  }) async {
    try {
      await equipment.createTransfer(
        id,
        toDepartmentId: toDepartmentId,
        toRoomId: toRoomId,
        toLocation: toLocation,
        reason: reason,
      );
      AppSnackbar.success('equipment.transfer.created'.tr);
      return true;
    } catch (e) {
      final code = ApiError.from(e).code;
      if (code == 'TRANSFER_PENDING_EXISTS') {
        AppSnackbar.info('equipment.transfer.pendingExists'.tr);
      } else {
        AppSnackbar.error(e);
      }
      return false;
    }
  }
}
