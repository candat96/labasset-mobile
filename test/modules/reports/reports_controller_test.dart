import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:labasset_mobile/data/models/report.dart';
import 'package:labasset_mobile/data/repositories/departments_repository.dart';
import 'package:labasset_mobile/data/repositories/equipment_repository.dart';
import 'package:labasset_mobile/data/repositories/reports_repository.dart';
import 'package:labasset_mobile/modules/reports/reports_controller.dart';
import 'package:mocktail/mocktail.dart';

class _Reports extends Mock implements ReportsRepository {}

class _Equipment extends Mock implements EquipmentRepository {}

class _Departments extends Mock implements DepartmentsRepository {}

const report = ReportMeta(
  key: 'equipment.byStatus',
  title: 'Hiện trạng thiết bị',
  group: 'equipment',
  params: {'type': 'object'},
  columns: [],
);

void main() {
  late _Reports repository;
  late List<String> actions;
  late ReportsController controller;

  setUp(() {
    Get.testMode = true;
    repository = _Reports();
    actions = [];
    controller = ReportsController(
      reports: repository,
      equipment: _Equipment(),
      departments: _Departments(),
      writeFile: (_) async => File('/tmp/report.xlsx'),
      openFile: (file) async => actions.add('open:${file.path}'),
      shareFile: (file) async => actions.add('share:${file.path}'),
    );
  });
  tearDown(Get.reset);

  test('load lấy dashboard và danh sách báo cáo D1', () async {
    when(repository.dashboard).thenAnswer(
      (_) async => const DashboardResponse(
        generatedAt: '2026-09-21T00:00:00Z',
        cards: [
          DashboardCard(
            key: 'equipment.total',
            title: 'Tổng thiết bị',
            value: 12,
            link: '/equipment',
          ),
        ],
      ),
    );
    when(repository.list).thenAnswer((_) async => const [report]);
    await controller.load();
    expect(controller.cards.single.value, 12);
    expect(controller.reportList.single.key, report.key);
    verify(repository.dashboard).called(1);
    verify(repository.list).called(1);
  });

  test('xuất báo cáo mở hoặc chia sẻ tệp API trả về', () async {
    when(
      () => repository.export(
        report.key,
        format: 'xlsx',
        departmentId: null,
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    ).thenAnswer(
      (_) async => const ReportExport(bytes: [1, 2], fileName: 'report.xlsx'),
    );
    expect(
      await controller.export(report, format: 'xlsx', share: true),
      isTrue,
    );
    expect(actions, ['share:/tmp/report.xlsx']);
  });

  test('xuất báo cáo truyền khoa đang chọn và mở tệp', () async {
    controller.departmentId.value = 'dept-1';
    when(
      () => repository.export(
        report.key,
        format: 'pdf',
        departmentId: 'dept-1',
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    ).thenAnswer(
      (_) async => const ReportExport(bytes: [1], fileName: 'report.pdf'),
    );
    expect(
      await controller.export(report, format: 'pdf', share: false),
      isTrue,
    );
    expect(actions, ['open:/tmp/report.xlsx']);
  });

  test('dashboard thành công vẫn hiển thị nếu danh sách báo cáo lỗi', () async {
    when(repository.dashboard).thenAnswer(
      (_) async => const DashboardResponse(
        generatedAt: '2026-09-21T00:00:00Z',
        cards: [],
      ),
    );
    when(repository.list).thenThrow(Exception('reports'));
    await controller.load();
    expect(controller.error.value, isNull);
    expect(controller.generatedAt.value, isNotNull);
  });

  test('cả dashboard và danh sách lỗi thì controller có error', () async {
    when(repository.dashboard).thenThrow(Exception('dashboard'));
    when(repository.list).thenThrow(Exception('reports'));
    await controller.load();
    expect(controller.error.value, isNotNull);
    expect(controller.loading.value, isFalse);
  });
}
