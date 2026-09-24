import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../data/models/room.dart';
import '../../data/repositories/catalogs_repository.dart';
import '../../data/repositories/departments_repository.dart';
import '../../data/repositories/reports_repository.dart';

/// Nhóm phòng theo khoa/phòng ban ([departmentId] null = phòng dùng chung).
class RoomGroup {
  const RoomGroup({
    required this.departmentId,
    required this.title,
    required this.rooms,
  });

  final String? departmentId;
  final String title;
  final List<RoomRef> rooms;
}

/// Màn "Phòng" `/rooms`: tìm kiếm + nhóm theo khoa/phòng ban; bấm một phòng để
/// xem danh sách máy của phòng đó.
class RoomsController extends GetxController {
  RoomsController({
    required this.catalogs,
    required this.departments,
    this.reports,
    this.autoLoad = true,
  });

  /// Tag khi dùng làm mode "Theo phòng" trong trang hồ sơ thiết bị.
  static const tagEquipment = 'equipment-rooms';

  final CatalogsRepository catalogs;
  final DepartmentsRepository departments;

  /// Báo cáo đếm máy theo phòng (best-effort — không có thì ẩn số máy).
  final ReportsRepository? reports;

  /// Tự nạp khi khởi tạo (màn riêng); false khi dùng làm mode trong trang khác.
  final bool autoLoad;

  final TextEditingController searchController = TextEditingController();

  /// Từ khoá tìm kiếm (đã debounce).
  final RxString q = ''.obs;
  final RxList<RoomRef> rooms = <RoomRef>[].obs;
  final RxBool loading = true.obs;
  final Rxn<Object> error = Rxn<Object>();

  /// mã phòng → tổng số máy (từ `equipment.byRoom`).
  final RxMap<String, int> roomCounts = <String, int>{}.obs;

  /// id khoa → tên (tiêu đề nhóm).
  final RxMap<String, String> departmentNames = <String, String>{}.obs;

  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();
    if (!autoLoad) {
      loading.value = false;
      return;
    }
    unawaited(_loadDepartments());
    unawaited(load());
  }

  @override
  void onClose() {
    _debounce?.cancel();
    searchController.dispose();
    super.onClose();
  }

  void setQuery(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (value.trim() == q.value) return;
      q.value = value.trim();
      unawaited(load());
    });
  }

  Future<void> _loadDepartments() async {
    try {
      final list = await departments.list(limit: 100);
      departmentNames.assignAll({for (final d in list) d.id: d.name});
    } catch (_) {
      // Tên khoa là best-effort — không có thì hiện mã khoa.
    }
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      rooms.assignAll(await catalogs.rooms(q: q.value));
    } catch (e) {
      error.value = e;
      rooms.clear();
    } finally {
      loading.value = false;
    }
    unawaited(_loadDepartments());
    unawaited(_loadCounts());
  }

  Future<void> _loadCounts() async {
    final repo = reports;
    if (repo == null) return;
    try {
      roomCounts.assignAll(await repo.equipmentByRoom());
    } catch (_) {
      // đếm máy là best-effort — lỗi thì coi như chưa có số
    }
  }

  /// Phòng theo khoa (tên khoa A→Z, phòng dùng chung xuống cuối).
  List<RoomGroup> get groups {
    final byDept = <String?, List<RoomRef>>{};
    for (final r in rooms) {
      byDept.putIfAbsent(r.departmentId, () => []).add(r);
    }
    final keys = byDept.keys.toList()
      ..sort((a, b) {
        if (a == null) return 1;
        if (b == null) return -1;
        return (_deptName(a) ?? a).compareTo(_deptName(b) ?? b);
      });
    return [
      for (final key in keys)
        RoomGroup(
          departmentId: key,
          title: key == null
              ? 'equipment.room.shared'.tr
              : (_deptName(key) ?? key),
          rooms: byDept[key]!,
        ),
    ];
  }

  String? _deptName(String id) => departmentNames[id];
}
