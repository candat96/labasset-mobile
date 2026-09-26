import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:labasset_mobile/data/models/kpi.dart';
import 'package:labasset_mobile/data/repositories/kpi_repository.dart';
import 'package:labasset_mobile/modules/kpi/kpi_controller.dart';
import 'package:labasset_mobile/modules/kpi/kpi_view.dart';

import '../../helpers/test_helpers.dart';

class _FakeKpiRepo implements KpiRepository {
  String lastType = '';
  num? rank = 8;
  num? total = 82.5;
  int items = 12;

  KpiPerson _person(String type, {KpiTaskPage? tasks}) => KpiPerson(
    userId: 'u1',
    fullName: 'Nguyễn Văn An',
    type: type,
    start: '2026-09-01',
    end: '2026-09-30',
    total: total,
    rank: rank,
    credits: 12,
    items: items,
    onTime: 91.7,
    areas: KpiAreas(
      repair: const KpiAreaScore(
        score: 88,
        volume: 100,
        onTime: 92,
        speed: 74,
        quality: 80,
        credits: 8,
        items: 8,
      ),
      maintenance: const KpiAreaScore(
        score: 70,
        volume: 62,
        onTime: 88,
        speed: 80,
        quality: 90,
        credits: 3,
        items: 3,
      ),
      calibration: const KpiAreaScore(
        score: 64,
        volume: 50,
        onTime: 100,
        quality: 75,
        credits: 1,
        items: 1,
      ),
    ),
    periods: const [
      KpiPoint(type: 'month', start: '2026-04-01', end: '2026-04-30'),
      KpiPoint(type: 'month', start: '2026-05-01', end: '2026-05-31'),
      KpiPoint(type: 'month', start: '2026-06-01', end: '2026-06-30'),
      KpiPoint(type: 'month', start: '2026-07-01', end: '2026-07-31'),
      KpiPoint(type: 'month', start: '2026-08-01', end: '2026-08-31'),
      KpiPoint(type: 'month', start: '2026-09-01', end: '2026-09-30'),
    ],
    tasks: tasks,
  );

  KpiTaskPage _tasks(int page, int limit) => KpiTaskPage(
    items: const [
      KpiTaskItem(
        area: 'repair',
        id: 'r1',
        code: 'SC-001',
        title: 'Máy ly tâm',
        equipmentName: 'Máy ly tâm',
        departmentName: 'Khoa Xét nghiệm',
        completedAt: '2026-09-20T10:00:00.000Z',
        onTime: true,
        quality: 100,
      ),
    ],
    total: 1,
    page: page,
    limit: limit,
  );

  @override
  Future<KpiPerson> me({required String type, String? start}) async {
    lastType = type;
    return _person(type);
  }

  @override
  Future<KpiPerson> user(
    String id, {
    required String type,
    String? start,
    int page = 1,
    int limit = 20,
  }) async => _person(type, tasks: _tasks(page, limit));

  @override
  Future<KpiBoard> board({required String type, String? start}) async =>
      KpiBoard(
        type: type,
        start: '2026-09-01',
        end: '2026-09-30',
        totals: const KpiTotals(
          items: 40,
          credits: 30,
          onTime: 90,
          avgHandleHours: 6.5,
          avgQuality: 82,
        ),
        staff: const [
          KpiStaffRow(
            userId: 'u1',
            fullName: 'Nguyễn Văn An',
            total: 82.5,
            rank: 1,
            credits: 12,
            items: 12,
            onTime: 91.7,
          ),
          KpiStaffRow(
            userId: 'u2',
            fullName: 'Trần Thị B',
            total: 65,
            rank: 2,
            credits: 5,
            items: 5,
            onTime: 80,
          ),
          KpiStaffRow(
            userId: 'u3',
            fullName: 'Lê Văn C',
            total: 40,
            insufficient: true,
            credits: 1,
            items: 1,
            onTime: 100,
          ),
        ],
      );

  @override
  Future<KpiPeriods> periods({required String type}) async =>
      KpiPeriods(type: type);
}

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1200, 3200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(wrap(const KpiView()));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    Get.testMode = true;
  });
  tearDown(Get.reset);

  testWidgets('KpiView: thẻ điểm tổng, huy hiệu hạng, ba mảng + bốn chỉ số', (
    tester,
  ) async {
    final repo = _FakeKpiRepo();
    Get.put(KpiController(repo: repo, userId: 'u1'));
    await _pump(tester);

    expect(find.text('82,5'), findsOneWidget);
    expect(find.text('Hạng 8'), findsOneWidget);
    expect(find.text('Sửa chữa'), findsWidgets);
    expect(find.text('Bảo dưỡng'), findsWidgets);
    expect(find.text('Kiểm định'), findsWidgets);
    expect(find.text('Khối lượng'), findsOneWidget);
    expect(find.text('Đúng hạn'), findsWidgets);
    expect(find.text('Tốc độ'), findsOneWidget);
    expect(find.text('Chất lượng'), findsOneWidget);
  });

  testWidgets('KpiView: ẩn huy hiệu hạng khi API không trả rank', (
    tester,
  ) async {
    final repo = _FakeKpiRepo()..rank = null;
    Get.put(KpiController(repo: repo, userId: 'u1'));
    await _pump(tester);

    expect(find.textContaining('Hạng'), findsNothing);
    expect(find.text('82,5'), findsOneWidget);
  });

  testWidgets('KpiView: kỳ không có việc hiện thông báo, không lỗi', (
    tester,
  ) async {
    final repo = _FakeKpiRepo()
      ..total = null
      ..items = 0;
    Get.put(KpiController(repo: repo, userId: 'u1'));
    await _pump(tester);

    expect(find.text('Kỳ này chưa có đầu việc nào'), findsOneWidget);
  });

  testWidgets('KpiView: quản trị viện thấy tab Toàn viện + bảng xếp hạng', (
    tester,
  ) async {
    final repo = _FakeKpiRepo();
    Get.put(KpiController(repo: repo, isAdmin: true, userId: 'u1'));
    await _pump(tester);

    expect(find.text('Toàn viện'), findsOneWidget);
    await tester.tap(find.text('Toàn viện'));
    await tester.pumpAndSettle();

    expect(find.text('Đầu việc hoàn tất'), findsOneWidget);
    expect(find.text('Tỷ lệ đúng hạn'), findsOneWidget);
    expect(find.text('Chưa đủ mẫu'), findsOneWidget);
    expect(find.text('Trần Thị B'), findsOneWidget);
  });

  testWidgets('KpiView: bấm việc hoàn tất mở phiếu sửa chữa', (tester) async {
    final repo = _FakeKpiRepo();
    final routes = <String>[];
    Get.put(
      KpiController(
        repo: repo,
        userId: 'u1',
        navigate: (r) async => routes.add(r),
      ),
    );
    await _pump(tester);

    await tester.tap(find.text('SC-001'));
    await tester.pumpAndSettle();
    expect(routes, ['/repairs/r1']);
  });

  testWidgets('KpiView: đổi loại kỳ sang tuần gọi lại API', (tester) async {
    final repo = _FakeKpiRepo();
    Get.put(KpiController(repo: repo, userId: 'u1'));
    await _pump(tester);

    await tester.tap(find.text('Tuần'));
    await tester.pumpAndSettle();
    expect(repo.lastType, 'week');
  });
}
