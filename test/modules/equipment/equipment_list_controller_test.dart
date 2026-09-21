import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:labasset_mobile/core/i18n/app_translations.dart';
import 'package:labasset_mobile/data/models/department.dart';
import 'package:labasset_mobile/data/models/equipment.dart';
import 'package:labasset_mobile/data/models/room.dart';
import 'package:labasset_mobile/data/repositories/catalogs_repository.dart';
import 'package:labasset_mobile/data/repositories/departments_repository.dart';
import 'package:labasset_mobile/data/repositories/equipment_repository.dart';
import 'package:labasset_mobile/modules/equipment/equipment_list_controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockEquipment extends Mock implements EquipmentRepository {}

class _MockDepartments extends Mock implements DepartmentsRepository {}

class _MockCatalogs extends Mock implements CatalogsRepository {}

const _dept = DepartmentRef(id: 'd1', code: 'XN', name: 'Khoa Xét nghiệm');
const _room = RoomRef(
  id: 'r1',
  code: 'XN-P01',
  name: 'Phòng Huyết học',
  departmentId: 'd1',
);

EquipmentSummary _eq(String id) => EquipmentSummary(
  id: id,
  code: 'TB-$id',
  name: 'Máy $id',
  model: 'M1',
  status: 'active',
);

void main() {
  late _MockEquipment equipment;
  late _MockDepartments departments;
  late _MockCatalogs catalogs;

  setUp(() {
    Get.testMode = true;
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('vi', 'VN');
    equipment = _MockEquipment();
    departments = _MockDepartments();
    catalogs = _MockCatalogs();
  });

  tearDown(Get.reset);

  EquipmentListController make({String? status, String? departmentId}) =>
      EquipmentListController(
        equipment: equipment,
        departments: departments,
        catalogs: catalogs,
        initialStatus: status,
        initialDepartmentId: departmentId,
      );

  void stubList(Future<EquipmentPage> Function() page) {
    when(
      () => equipment.list(
        q: any(named: 'q'),
        status: any(named: 'status'),
        departmentId: any(named: 'departmentId'),
        roomId: any(named: 'roomId'),
        page: any(named: 'page'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) => page());
  }

  test('load nạp trang đầu + tổng số', () async {
    stubList(() async => EquipmentPage(items: [_eq('1'), _eq('2')], total: 2));
    final c = make()..onInit();
    await Future<void>.delayed(Duration.zero);
    expect(c.items.length, 2);
    expect(c.total.value, 2);
    expect(c.hasMore, isFalse);
    expect(c.loading.value, isFalse);
  });

  test('loadMore nạp thêm khi còn dữ liệu', () async {
    var calls = 0;
    when(
      () => equipment.list(
        q: any(named: 'q'),
        status: any(named: 'status'),
        departmentId: any(named: 'departmentId'),
        roomId: any(named: 'roomId'),
        page: any(named: 'page'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((inv) async {
      calls += 1;
      final page = inv.namedArguments[#page] as int;
      if (page == 1) {
        return EquipmentPage(
          items: [for (var i = 0; i < 20; i++) _eq('$i')],
          total: 25,
        );
      }
      return EquipmentPage(
        items: [for (var i = 20; i < 25; i++) _eq('$i')],
        total: 25,
      );
    });
    final c = make()..onInit();
    await Future<void>.delayed(Duration.zero);
    expect(c.items.length, 20);
    await c.loadMore();
    expect(c.items.length, 25);
    expect(c.hasMore, isFalse);
    expect(calls, 2);
  });

  test('setStatus lọc lại từ trang 1', () async {
    final statuses = <String?>[];
    when(
      () => equipment.list(
        q: any(named: 'q'),
        status: any(named: 'status'),
        departmentId: any(named: 'departmentId'),
        roomId: any(named: 'roomId'),
        page: any(named: 'page'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((inv) async {
      statuses.add(inv.namedArguments[#status] as String?);
      return EquipmentPage(items: [_eq('1')], total: 1);
    });
    final c = make()..onInit();
    await Future<void>.delayed(Duration.zero);
    c.setStatus('broken');
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(c.status.value, 'broken');
    expect(statuses.last, 'broken');
  });

  test('đổi khoa → reset phòng', () async {
    stubList(() async => EquipmentPage(items: [_eq('1')], total: 1));
    final c = make()..onInit();
    await Future<void>.delayed(Duration.zero);
    c.setDepartment(_dept);
    c.room.value = _room;
    expect(c.room.value, isNotNull);
    c.setDepartment(_dept);
    expect(c.room.value, isNull);
  });

  test('lỗi API → ghi error, giữ danh sách rỗng', () async {
    stubList(() async => throw Exception('boom'));
    final c = make()..onInit();
    await Future<void>.delayed(Duration.zero);
    expect(c.error.value, isNotNull);
    expect(c.items, isEmpty);
    expect(c.loading.value, isFalse);
  });

  test('clearFilters xoá tìm kiếm + lọc', () async {
    stubList(() async => EquipmentPage(items: [_eq('1')], total: 1));
    final c = make()..onInit();
    await Future<void>.delayed(Duration.zero);
    c.searchController.text = 'abc';
    c.q.value = 'abc';
    c.status.value = 'broken';
    c.room.value = _room;
    await c.clearFilters();
    expect(c.q.value, '');
    expect(c.status.value, '');
    expect(c.room.value, isNull);
    expect(c.searchController.text, '');
  });
}
