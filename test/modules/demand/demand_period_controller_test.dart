import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:labasset_mobile/core/i18n/app_translations.dart';
import 'package:labasset_mobile/data/models/demand.dart';
import 'package:labasset_mobile/data/repositories/demand_repository.dart';
import 'package:labasset_mobile/modules/demand/demand_period_controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockDemand extends Mock implements DemandRepository {}

DemandPeriod _period(String status) => DemandPeriod(
  id: 'p1',
  code: 'DT-2027',
  name: 'Dự trù 2027',
  kind: 'annual',
  year: 2027,
  status: status,
  progress: const DemandProgress(
    total: 15,
    submitted: 8,
    deptApproved: 8,
    accepted: 8,
  ),
);

DemandRequestSummaryPage _requests() => const DemandRequestSummaryPage(
  items: [
    DemandRequestSummary(
      requestId: 'r1',
      departmentId: 'd1',
      departmentCode: 'XN',
      departmentName: 'Khoa Xét nghiệm',
      status: 'accepted',
      lineCount: 7,
      totalEstimated: '44369280000',
    ),
  ],
  total: 1,
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

  test('kỳ consolidating: nạp KPI + phiếu khoa + tổng hợp', () async {
    when(
      () => repo.period('p1'),
    ).thenAnswer((_) async => _period('consolidating'));
    when(() => repo.summary('p1')).thenAnswer(
      (_) async => const DemandSummary(
        departmentsTotal: 15,
        departmentsSubmitted: 8,
        totalRequested: '62885040000',
        totalApproved: '104305200000',
      ),
    );
    when(
      () => repo.periodRequests('p1', limit: 50),
    ).thenAnswer((_) async => _requests());
    when(() => repo.consolidation('p1')).thenAnswer(
      (_) async => const [
        DemandConsolidation(
          id: 'c1',
          periodId: 'p1',
          itemName: 'Thuốc thử ALT',
          qtyRequested: '1824',
          qtyApproved: '1824',
          decision: 'buy',
          breakdown: [
            DemandBreakdownEntry(
              departmentId: 'd1',
              requestId: 'r1',
              lineId: 'l1',
              qtyRequested: '336',
              qtyApproved: '336',
            ),
          ],
        ),
      ],
    );

    final c = DemandPeriodController(demand: repo, id: 'p1');
    await c.load();
    expect(c.period.value!.code, 'DT-2027');
    expect(c.summary.value!.departmentsSubmitted, 8);
    expect(c.requests.single.departmentCode, 'XN');
    expect(c.showConsolidation, isTrue);
    expect(c.consolidation.single.itemName, 'Thuốc thử ALT');
    expect(c.deptName('d1'), 'Khoa Xét nghiệm');
    expect(c.deptName('missing'), 'Khoa/Phòng ban');
  });

  test('kỳ collecting: không gọi tổng hợp', () async {
    when(
      () => repo.period('p1'),
    ).thenAnswer((_) async => _period('collecting'));
    when(
      () => repo.summary('p1'),
    ).thenAnswer((_) async => const DemandSummary());
    when(() => repo.periodRequests('p1', limit: 50)).thenAnswer(
      (_) async => const DemandRequestSummaryPage(items: [], total: 0),
    );

    final c = DemandPeriodController(demand: repo, id: 'p1');
    await c.load();
    expect(c.showConsolidation, isFalse);
    expect(c.consolidation, isEmpty);
    verifyNever(() => repo.consolidation('p1'));
  });

  test('đổi tab sang Tổng hợp chỉ đổi segment', () async {
    when(() => repo.period('p1')).thenAnswer((_) async => _period('approved'));
    when(
      () => repo.summary('p1'),
    ).thenAnswer((_) async => const DemandSummary());
    when(() => repo.periodRequests('p1', limit: 50)).thenAnswer(
      (_) async => const DemandRequestSummaryPage(items: [], total: 0),
    );
    when(() => repo.consolidation('p1')).thenAnswer((_) async => const []);
    final c = DemandPeriodController(demand: repo, id: 'p1');
    await c.load();
    c.setSegment(DemandPeriodSegment.consolidation);
    expect(c.segment.value, DemandPeriodSegment.consolidation);
  });

  test('load lỗi ghi error', () async {
    when(() => repo.period('p1')).thenThrow(Exception('boom'));
    final c = DemandPeriodController(demand: repo, id: 'p1');
    await c.load();
    expect(c.error.value, isNotNull);
    expect(c.period.value, isNull);
    expect(c.loading.value, isFalse);
  });
}
