import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:labasset_mobile/core/i18n/app_translations.dart';
import 'package:labasset_mobile/data/models/department.dart';
import 'package:labasset_mobile/data/models/room.dart';
import 'package:labasset_mobile/data/repositories/catalogs_repository.dart';
import 'package:labasset_mobile/data/repositories/departments_repository.dart';
import 'package:labasset_mobile/data/repositories/reports_repository.dart';
import 'package:labasset_mobile/modules/rooms/rooms_controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockCatalogs extends Mock implements CatalogsRepository {}

class _MockDepartments extends Mock implements DepartmentsRepository {}

class _MockReports extends Mock implements ReportsRepository {}

const _dept = DepartmentRef(id: 'd1', code: 'XN', name: 'Khoa Xét nghiệm');

const _rooms = [
  RoomRef(
    id: 'r1',
    code: 'XN-P01',
    name: 'Phòng Huyết học',
    departmentId: 'd1',
    building: 'A',
    floor: '2',
  ),
  RoomRef(id: 'r2', code: 'HT', name: 'Hội trường'),
  RoomRef(id: 'r3', code: 'XN-P02', name: 'Phòng Sinh hoá', departmentId: 'd1'),
];

void main() {
  late _MockCatalogs catalogs;
  late _MockDepartments departments;

  setUp(() {
    Get.testMode = true;
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('vi', 'VN');
    catalogs = _MockCatalogs();
    departments = _MockDepartments();
    when(
      () => departments.list(limit: any(named: 'limit')),
    ).thenAnswer((_) async => [_dept]);
  });

  tearDown(Get.reset);

  void stubRooms(List<RoomRef> Function(String? q) list) {
    when(
      () => catalogs.rooms(
        departmentId: any(named: 'departmentId'),
        q: any(named: 'q'),
        includeShared: any(named: 'includeShared'),
      ),
    ).thenAnswer((inv) async {
      final q = inv.namedArguments[#q] as String?;
      return list(q);
    });
  }

  test(
    'load nạp phòng và nhóm theo khoa, phòng dùng chung xuống cuối',
    () async {
      stubRooms((_) => _rooms);
      final c = RoomsController(catalogs: catalogs, departments: departments)
        ..onInit();
      await Future<void>.delayed(Duration.zero);

      expect(c.rooms.length, 3);
      expect(c.loading.value, isFalse);
      final groups = c.groups;
      expect(groups.map((g) => g.title), ['Khoa Xét nghiệm', 'Dùng chung']);
      expect(groups.first.rooms.map((r) => r.code), ['XN-P01', 'XN-P02']);
      expect(groups.last.rooms.single.id, 'r2');
    },
  );

  test('setQuery tìm theo mã/tên (debounce) rồi nạp lại', () async {
    final queries = <String?>[];
    stubRooms((q) {
      queries.add(q);
      if (q == null || q.isEmpty) return _rooms;
      return _rooms
          .where((r) => r.name.toLowerCase().contains(q.toLowerCase()))
          .toList();
    });
    final c = RoomsController(catalogs: catalogs, departments: departments)
      ..onInit();
    await Future<void>.delayed(Duration.zero);

    c.setQuery('huyết');
    await Future<void>.delayed(const Duration(milliseconds: 350));
    expect(c.q.value, 'huyết');
    expect(c.rooms.single.name, 'Phòng Huyết học');
    expect(queries.last, 'huyết');
  });

  test('lỗi API → ghi error, danh sách rỗng', () async {
    when(
      () => catalogs.rooms(
        departmentId: any(named: 'departmentId'),
        q: any(named: 'q'),
        includeShared: any(named: 'includeShared'),
      ),
    ).thenThrow(Exception('boom'));
    final c = RoomsController(catalogs: catalogs, departments: departments)
      ..onInit();
    await Future<void>.delayed(Duration.zero);

    expect(c.error.value, isNotNull);
    expect(c.rooms, isEmpty);
    expect(c.loading.value, isFalse);
  });

  test('nạp tổng số máy theo phòng từ báo cáo equipment.byRoom', () async {
    stubRooms((_) => _rooms);
    final reports = _MockReports();
    when(
      () => reports.equipmentByRoom(),
    ).thenAnswer((_) async => {'XN-P01': 3, 'HT': 1});
    final c = RoomsController(
      catalogs: catalogs,
      departments: departments,
      reports: reports,
    )..onInit();
    await Future<void>.delayed(Duration.zero);

    expect(c.roomCounts['XN-P01'], 3);
    expect(c.roomCounts['HT'], 1);
    expect(c.roomCounts['XN-P02'], isNull); // chưa có máy → không hiện số
  });

  test(
    'autoLoad=false (mode trong trang khác): chỉ nạp khi gọi load()',
    () async {
      stubRooms((_) => _rooms);
      final c = RoomsController(
        catalogs: catalogs,
        departments: departments,
        autoLoad: false,
      )..onInit();
      await Future<void>.delayed(Duration.zero);
      expect(c.rooms, isEmpty);
      expect(c.loading.value, isFalse);

      await c.load();
      expect(c.rooms.length, 3);
    },
  );
}
