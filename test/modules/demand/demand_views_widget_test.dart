import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:labasset_mobile/core/widgets/detail_widgets.dart';
import 'package:labasset_mobile/data/models/demand.dart';
import 'package:labasset_mobile/data/repositories/demand_repository.dart';
import 'package:labasset_mobile/modules/demand/demand_controller.dart';
import 'package:labasset_mobile/modules/demand/demand_period_controller.dart';
import 'package:labasset_mobile/modules/demand/demand_period_view.dart';
import 'package:labasset_mobile/modules/demand/demand_request_controller.dart';
import 'package:labasset_mobile/modules/demand/demand_request_view.dart';
import 'package:labasset_mobile/modules/demand/demand_view.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_helpers.dart';

class _MockDemand extends Mock implements DemandRepository {}

DemandRequest _request() => const DemandRequest(
  id: 'r1',
  periodId: 'p1',
  status: 'submitted',
  totalEstimated: '1000000',
  period: DemandPeriodRef(id: 'p1', code: 'DT-2027', name: 'Dự trù 2027'),
  department: DemandDepartmentRef(
    id: 'd1',
    code: 'XN',
    name: 'Khoa Xét nghiệm',
  ),
  lines: [
    DemandLine(
      id: 'l1',
      requestId: 'r1',
      itemType: 'supply',
      itemName: 'Thuốc thử ALT',
      supplyCode: 'HC-COB-ALT',
      unit: 'Kit',
      qtyRequested: '336',
      unitPriceEst: '4200000',
      amountEst: '1411200000',
      reason: 'Tiêu hao lớn',
      priority: 'high',
    ),
    DemandLine(
      id: 'l2',
      requestId: 'r1',
      itemType: 'equipment',
      itemName: 'Máy ly tâm lạnh',
      spec: '15000 vòng/phút',
      qtyRequested: '2',
      unitPriceEst: '320000000',
      amountEst: '640000000',
    ),
  ],
);

void main() {
  late _MockDemand repo;

  setUp(() {
    Get.testMode = true;
    repo = _MockDemand();
  });

  tearDown(Get.reset);

  testWidgets('DemandView: danh sách Của tôi + tab Kỳ', (tester) async {
    when(
      () => repo.my(limit: 50),
    ).thenAnswer((_) async => DemandRequestPage(items: [_request()], total: 1));
    when(() => repo.periods(limit: 50)).thenAnswer(
      (_) async => const DemandPeriodPage(
        items: [
          DemandPeriod(
            id: 'p1',
            code: 'DT-2027',
            name: 'Dự trù tập trung năm 2027',
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
    Get.put(DemandController(demand: repo));
    await tester.pumpWidget(wrap(const DemandView()));
    await tester.pumpAndSettle();

    expect(find.text('DT-2027'), findsOneWidget);
    expect(find.text('Dự trù 2027'), findsOneWidget);
    expect(find.text('Chờ trưởng khoa duyệt'), findsOneWidget);

    await tester.tap(find.text('Kỳ'));
    await tester.pumpAndSettle();
    expect(find.text('Dự trù tập trung năm 2027'), findsOneWidget);
    expect(find.text('8/15 khoa đã nộp'), findsOneWidget);
  });

  testWidgets('DemandRequestView: nhóm dòng + thanh tiếp nhận (VT)', (
    tester,
  ) async {
    when(
      () => repo.request('r1'),
    ).thenAnswer((_) async => _request().copyWithStatus('dept_approved'));
    Get.put(DemandRequestController(demand: repo, id: 'r1', isStaff: true));
    await tester.pumpWidget(wrap(const DemandRequestView()));
    await tester.pumpAndSettle();

    expect(find.text('VẬT TƯ'), findsOneWidget);
    expect(find.text('THIẾT BỊ MỚI'), findsOneWidget);
    expect(find.text('Thuốc thử ALT · HC-COB-ALT'), findsOneWidget);
    expect(find.text('Máy ly tâm lạnh'), findsOneWidget);
    expect(find.byType(StickyActionBar), findsOneWidget);
    expect(find.text('Tiếp nhận'), findsOneWidget);
    expect(find.text('Trả lại'), findsOneWidget);
  });

  testWidgets('DemandPeriodView: KPI + tab Tổng hợp', (tester) async {
    when(() => repo.period('p1')).thenAnswer(
      (_) async => const DemandPeriod(
        id: 'p1',
        code: 'DT-2027',
        name: 'Dự trù tập trung năm 2027',
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
    );
    when(() => repo.summary('p1')).thenAnswer(
      (_) async => const DemandSummary(
        departmentsTotal: 15,
        departmentsSubmitted: 8,
        totalRequested: '62885040000',
        totalApproved: '104305200000',
      ),
    );
    when(() => repo.periodRequests('p1', limit: 50)).thenAnswer(
      (_) async => const DemandRequestSummaryPage(
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
      ),
    );
    when(() => repo.consolidation('p1')).thenAnswer(
      (_) async => const [
        DemandConsolidation(
          id: 'c1',
          periodId: 'p1',
          supplyCode: 'HC-COB-ALT',
          itemName: 'Thuốc thử ALT',
          unit: 'Kit',
          qtyRequested: '1824',
          qtyApproved: '1824',
          unitPricePlan: '4200000',
          amountPlan: '7660800000',
          decision: 'buy',
        ),
      ],
    );
    Get.put(DemandPeriodController(demand: repo, id: 'p1'));
    await tester.pumpWidget(wrap(const DemandPeriodView()));
    await tester.pumpAndSettle();

    expect(find.text('8/15'), findsOneWidget);
    expect(find.text('62,9 tỷ'), findsOneWidget);
    expect(find.text('Khoa Xét nghiệm'), findsOneWidget);

    await tester.tap(find.text('Tổng hợp'));
    await tester.pumpAndSettle();
    expect(find.text('Thuốc thử ALT'), findsOneWidget);
    expect(find.text('Mua mới'), findsOneWidget);
    expect(find.text('Chỉnh số duyệt trên web'), findsOneWidget);
  });

  testWidgets('DemandView: khoa thấy ghi chú lập phiếu trên web', (
    tester,
  ) async {
    when(
      () => repo.my(limit: 50),
    ).thenAnswer((_) async => DemandRequestPage(items: [_request()], total: 1));
    Get.put(DemandController(demand: repo, canSeePeriods: false, isDept: true));
    await tester.pumpWidget(wrap(const DemandView()));
    await tester.pumpAndSettle();

    expect(find.text('Lập phiếu trên web'), findsOneWidget);
    expect(find.text('DT-2027'), findsOneWidget);
  });
}

extension on DemandRequest {
  DemandRequest copyWithStatus(String status) => DemandRequest(
    id: id,
    periodId: periodId,
    departmentId: departmentId,
    status: status,
    totalEstimated: totalEstimated,
    period: period,
    department: department,
    lines: lines,
  );
}
