import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:labasset_mobile/core/errors/api_error.dart';
import 'package:labasset_mobile/core/i18n/app_translations.dart';
import 'package:labasset_mobile/data/models/demand.dart';
import 'package:labasset_mobile/data/repositories/demand_repository.dart';
import 'package:labasset_mobile/modules/demand/demand_controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockDemand extends Mock implements DemandRepository {}

DemandRequest _request({
  String id = 'r1',
  String status = 'submitted',
  int lines = 1,
}) => DemandRequest(
  id: id,
  periodId: 'p1',
  status: status,
  period: const DemandPeriodRef(id: 'p1', code: 'DT-2027', name: 'Dự trù 2027'),
  department: const DemandDepartmentRef(
    id: 'd1',
    code: 'XN',
    name: 'Khoa Xét nghiệm',
  ),
  lines: List.generate(
    lines,
    (i) => DemandLine(id: 'l$i', requestId: id, itemName: 'VT $i'),
  ),
);

void main() {
  late _MockDemand repo;

  setUp(() {
    Get.testMode = true;
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('vi', 'VN');
    repo = _MockDemand();
  });

  tearDown(Get.reset);

  test('load Của tôi: ẩn phiếu rỗng do API tự tạo', () async {
    when(() => repo.my(limit: 50)).thenAnswer(
      (_) async => DemandRequestPage(
        items: [
          _request(id: 'r1', status: 'submitted', lines: 2),
          _request(id: 'r2', status: 'accepted', lines: 0),
          _request(id: 'r3', status: 'draft', lines: 0),
        ],
        total: 3,
      ),
    );
    final c = DemandController(demand: repo);
    await c.load();
    expect(c.mine.map((r) => r.id), ['r1']);
    expect(c.error.value, isNull);
    expect(c.loading.value, isFalse);
  });

  test('đổi tab Kỳ nạp danh sách kỳ', () async {
    when(
      () => repo.my(limit: 50),
    ).thenAnswer((_) async => const DemandRequestPage(items: [], total: 0));
    when(() => repo.periods(limit: 50)).thenAnswer(
      (_) async => const DemandPeriodPage(
        items: [
          DemandPeriod(
            id: 'p1',
            code: 'DT-2027',
            name: 'Dự trù 2027',
            kind: 'annual',
            year: 2027,
            status: 'consolidating',
            progress: DemandProgress(
              total: 15,
              submitted: 8,
              deptApproved: 8,
              accepted: 8,
            ),
          ),
        ],
        total: 1,
      ),
    );
    final c = DemandController(demand: repo);
    await c.load();
    c.setSegment(DemandSegment.periods);
    await Future<void>.delayed(Duration.zero);
    expect(c.periods.single.code, 'DT-2027');
    expect(c.periods.single.progress!.submitted, 8);
  });

  test('load lỗi ghi error và giữ danh sách rỗng', () async {
    when(
      () => repo.my(limit: 50),
    ).thenThrow(ApiError(500, 'INTERNAL_ERROR', ''));
    final c = DemandController(demand: repo);
    await c.load();
    expect(c.error.value, isNotNull);
    expect(c.mine, isEmpty);
  });
}
