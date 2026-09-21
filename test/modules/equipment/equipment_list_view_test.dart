import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:labasset_mobile/data/models/equipment.dart';
import 'package:labasset_mobile/data/models/room.dart';
import 'package:labasset_mobile/data/repositories/catalogs_repository.dart';
import 'package:labasset_mobile/data/repositories/departments_repository.dart';
import 'package:labasset_mobile/data/repositories/equipment_repository.dart';
import 'package:labasset_mobile/modules/equipment/equipment_list_controller.dart';
import 'package:labasset_mobile/modules/equipment/equipment_list_view.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_helpers.dart';

class _MockEquipment extends Mock implements EquipmentRepository {}

class _MockDepartments extends Mock implements DepartmentsRepository {}

class _MockCatalogs extends Mock implements CatalogsRepository {}

void main() {
  late _MockEquipment equipment;

  setUp(() {
    equipment = _MockEquipment();
  });

  tearDown(Get.reset);

  void stub(EquipmentPage page) {
    when(
      () => equipment.list(
        q: any(named: 'q'),
        status: any(named: 'status'),
        departmentId: any(named: 'departmentId'),
        roomId: any(named: 'roomId'),
        page: any(named: 'page'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => page);
  }

  testWidgets('render danh sách máy có phòng', (tester) async {
    stub(
      EquipmentPage(
        items: [
          const EquipmentSummary(
            id: 'e1',
            code: 'TB-1',
            name: 'Máy ly tâm',
            model: 'M1',
            location: 'Bàn 1',
            status: 'active',
            departmentName: 'Khoa Xét nghiệm',
            room: RoomRef(id: 'r1', code: 'XN-P01', name: 'Phòng Huyết học'),
          ),
        ],
        total: 1,
      ),
    );
    Get.put<EquipmentRepository>(equipment);
    Get.put<DepartmentsRepository>(_MockDepartments());
    Get.put<CatalogsRepository>(_MockCatalogs());
    Get.put(
      EquipmentListController(
        equipment: equipment,
        departments: Get.find<DepartmentsRepository>(),
        catalogs: Get.find<CatalogsRepository>(),
      ),
    );

    await tester.pumpWidget(wrap(const EquipmentListView()));
    await tester.pumpAndSettle();

    expect(find.text('Máy ly tâm'), findsOneWidget);
    expect(find.text('TB-1 · M1'), findsOneWidget);
    expect(
      find.text('Khoa Xét nghiệm · Phòng Huyết học · Bàn 1'),
      findsOneWidget,
    );
    expect(find.text('Hoạt động'), findsWidgets);
    expect(find.text('Thiết bị'), findsWidgets);
  });

  testWidgets('rỗng → EmptyState có nút xoá lọc', (tester) async {
    stub(const EquipmentPage(items: [], total: 0));
    Get.put<EquipmentRepository>(equipment);
    Get.put<DepartmentsRepository>(_MockDepartments());
    Get.put<CatalogsRepository>(_MockCatalogs());
    Get.put(
      EquipmentListController(
        equipment: equipment,
        departments: Get.find<DepartmentsRepository>(),
        catalogs: Get.find<CatalogsRepository>(),
      ),
    );

    await tester.pumpWidget(wrap(const EquipmentListView()));
    await tester.pumpAndSettle();

    expect(find.text('Không có máy nào'), findsOneWidget);
    expect(find.text('Xoá lọc'), findsOneWidget);
  });
}
