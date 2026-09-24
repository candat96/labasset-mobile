import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../core/widgets/pick_ref.dart';
import '../../core/widgets/picker_sheet.dart';
import '../../data/models/department.dart';
import '../../data/models/equipment.dart';
import '../../data/models/room.dart';
import '../../data/repositories/catalogs_repository.dart';
import '../../data/repositories/departments_repository.dart';
import '../../data/repositories/equipment_repository.dart';

/// Danh sách máy `/equipment`: ô tìm (debounce 300 ms), segment trạng thái,
/// lọc Khoa/Phòng ban + Phòng, phân trang cuộn vô hạn.
class EquipmentListController extends GetxController {
  EquipmentListController({
    required this.equipment,
    required this.departments,
    required this.catalogs,
    String? initialStatus,
    String? initialDepartmentId,
    RoomRef? initialRoom,
  }) : status = (initialStatus ?? '').obs,
       _initialDepartmentId = initialDepartmentId,
       _initialRoom = initialRoom;

  final EquipmentRepository equipment;
  final DepartmentsRepository departments;
  final CatalogsRepository catalogs;

  final TextEditingController searchController = TextEditingController();

  /// Từ khoá tìm kiếm (đã debounce).
  final RxString q = ''.obs;
  final RxString status;
  final Rxn<DepartmentRef> department = Rxn<DepartmentRef>();
  final Rxn<RoomRef> room = Rxn<RoomRef>();

  final RxList<EquipmentSummary> items = <EquipmentSummary>[].obs;
  final RxInt total = 0.obs;
  final RxBool loading = true.obs;
  final RxBool loadingMore = false.obs;
  final Rxn<Object> error = Rxn<Object>();

  /// Mode "Theo phòng": hiện danh sách phòng (kèm tổng số máy) thay vì danh sách máy.
  final RxBool roomMode = false.obs;

  int _page = 1;
  Timer? _debounce;
  final String? _initialDepartmentId;
  final RoomRef? _initialRoom;

  bool get hasMore => items.length < total.value;

  @override
  void onInit() {
    super.onInit();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Lọc sẵn theo phòng khi mở từ màn "Phòng" (kèm cả khoa của phòng đó).
    final initial = _initialRoom;
    if (initial != null) {
      await _applyRoom(initial);
      return;
    }
    final id = _initialDepartmentId;
    if (id != null && id.isNotEmpty) {
      try {
        final list = await departments.list(limit: 100);
        department.value = list.where((d) => d.id == id).firstOrNull;
      } catch (_) {
        // bỏ qua — vẫn tải danh sách
      }
    }
    await load();
  }

  /// Bật/tắt mode "Theo phòng".
  void setRoomMode(bool on) {
    if (roomMode.value == on) return;
    roomMode.value = on;
  }

  /// Mở danh sách máy của [room] (kèm khoa của phòng) và thoát mode phòng.
  Future<void> openRoom(RoomRef value) async {
    roomMode.value = false;
    await _applyRoom(value);
  }

  /// Lọc theo phòng + nạp khoa của phòng đó rồi tải lại danh sách.
  Future<void> _applyRoom(RoomRef value) async {
    room.value = value;
    final deptId = value.departmentId;
    if (deptId != null && deptId.isNotEmpty) {
      try {
        final list = await departments.list(limit: 100);
        department.value = list.where((d) => d.id == deptId).firstOrNull;
      } catch (_) {
        // bỏ qua — vẫn tải danh sách theo phòng
      }
    }
    await load();
  }

  void setQuery(String value) {
    _debounce?.cancel();
    if (value.trim() == q.value) return;
    _debounce = Timer(const Duration(milliseconds: 300), () {
      q.value = value.trim();
      load();
    });
  }

  void setStatus(String value) {
    if (status.value == value) return;
    status.value = value;
    load();
  }

  /// Gán Khoa/Phòng ban và bỏ phòng (phòng thuộc khoa cũ).
  void setDepartment(DepartmentRef? d) {
    department.value = d;
    room.value = null;
  }

  Future<void> pickDepartment(BuildContext context) async {
    final selected = await pickRef(
      context,
      title: 'equipment.list.filterDepartment'.tr,
      loader: () => departments.list(limit: 100),
    );
    setDepartment(selected);
    await load();
  }

  Future<void> clearDepartment() async {
    department.value = null;
    room.value = null;
    await load();
  }

  Future<void> pickRoom(BuildContext context) async {
    final list = await catalogs.rooms(departmentId: department.value?.id);
    if (list.isEmpty || !context.mounted) return;
    final selection = await PickerSheet.show<RoomRef>(
      context,
      title: 'equipment.list.filterRoom'.tr,
      kind: PickerKind.equipment,
      showClear: true,
      selected: room.value,
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
    await load();
  }

  void clearRoom() {
    room.value = null;
    load();
  }

  Future<void> clearFilters() async {
    _debounce?.cancel();
    searchController.clear();
    q.value = '';
    status.value = '';
    department.value = null;
    room.value = null;
    await load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    _page = 1;
    try {
      final page = await equipment.list(
        q: q.value,
        status: status.value.isEmpty ? null : status.value,
        departmentId: department.value?.id,
        roomId: room.value?.id,
        page: 1,
        limit: 20,
      );
      items.assignAll(page.items);
      total.value = page.total.toInt();
    } catch (e) {
      error.value = e;
    } finally {
      loading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (loadingMore.value || !hasMore) return;
    loadingMore.value = true;
    try {
      final page = await equipment.list(
        q: q.value,
        status: status.value.isEmpty ? null : status.value,
        departmentId: department.value?.id,
        roomId: room.value?.id,
        page: _page + 1,
        limit: 20,
      );
      _page += 1;
      items.addAll(page.items);
      total.value = page.total.toInt();
    } catch (_) {
      // giữ danh sách hiện tại
    } finally {
      loadingMore.value = false;
    }
  }

  @override
  void onClose() {
    _debounce?.cancel();
    searchController.dispose();
    super.onClose();
  }
}
