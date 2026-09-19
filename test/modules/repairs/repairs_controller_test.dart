import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:labasset_mobile/core/i18n/app_translations.dart';
import 'package:labasset_mobile/data/models/repair.dart';
import 'package:labasset_mobile/data/repositories/repairs_repository.dart';
import 'package:labasset_mobile/modules/repairs/repairs_controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepairs extends Mock implements RepairsRepository {}

void main() {
  late _MockRepairs repo;
  late RepairsController c;

  setUp(() {
    Get.testMode = true;
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('vi', 'VN');
    repo = _MockRepairs();
    c = RepairsController(repairs: repo, userId: 'u1');
  });

  tearDown(Get.reset);

  void stubPage({List<RepairSummary> items = const [], num total = 0}) {
    when(
      () => repo.list(
        assigneeId: any(named: 'assigneeId'),
        status: any(named: 'status'),
        severity: any(named: 'severity'),
        departmentId: any(named: 'departmentId'),
        overdue: any(named: 'overdue'),
        page: any(named: 'page'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => RepairPage(items: items, total: total));
  }

  test('segment Của tôi → assigneeId=me + statuses đang mở', () async {
    stubPage(
      items: const [RepairSummary(id: 'r1', code: 'SC-1', equipmentId: 'e1')],
      total: 1,
    );
    await c.load();
    final captured = verify(
      () => repo.list(
        assigneeId: captureAny(named: 'assigneeId'),
        status: captureAny(named: 'status'),
        severity: any(named: 'severity'),
        departmentId: any(named: 'departmentId'),
        overdue: any(named: 'overdue'),
        page: any(named: 'page'),
        limit: any(named: 'limit'),
      ),
    ).captured;
    expect(captured[0], 'me');
    expect(captured[1], RepairsController.openStatuses);
    expect(c.items, hasLength(1));
    expect(c.total.value, 1);
  });

  test('segment Chưa phân công → status=new, không assignee', () async {
    stubPage();
    c.setSegment(RepairsSegment.unassigned);
    await Future<void>.delayed(Duration.zero);
    final captured = verify(
      () => repo.list(
        assigneeId: captureAny(named: 'assigneeId'),
        status: captureAny(named: 'status'),
        severity: any(named: 'severity'),
        departmentId: any(named: 'departmentId'),
        overdue: any(named: 'overdue'),
        page: any(named: 'page'),
        limit: any(named: 'limit'),
      ),
    ).captured;
    expect(captured[0], isNull);
    expect(captured[1], 'new');
  });

  test('bộ lọc severity/overdue/status truyền vào API', () async {
    stubPage();
    c.applyFilters(
      statuses: {'awaiting_parts', 'in_progress'},
      severity: 'high',
      overdue: true,
    );
    await Future<void>.delayed(Duration.zero);
    verify(
      () => repo.list(
        assigneeId: any(named: 'assigneeId'),
        status: 'awaiting_parts,in_progress',
        severity: 'high',
        departmentId: any(named: 'departmentId'),
        overdue: true,
        page: any(named: 'page'),
        limit: any(named: 'limit'),
      ),
    ).called(1);
    expect(c.filterActive.value, isTrue);
  });

  test('loadMore nối trang và dừng khi hết', () async {
    when(
      () => repo.list(
        assigneeId: any(named: 'assigneeId'),
        status: any(named: 'status'),
        severity: any(named: 'severity'),
        departmentId: any(named: 'departmentId'),
        overdue: any(named: 'overdue'),
        page: any(named: 'page'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((invocation) async {
      final page = invocation.namedArguments[#page] as int;
      return RepairPage(
        items: [
          RepairSummary(id: 'r$page', code: 'SC-$page', equipmentId: 'e1'),
        ],
        total: 2,
      );
    });
    await c.load();
    await c.loadMore();
    expect(c.items.map((e) => e.id), ['r1', 'r2']);
    await c.loadMore(); // đã đủ total → không gọi thêm
    expect(c.items, hasLength(2));
  });

  test('loadMyOpenCount cập nhật badge', () async {
    stubPage(total: 7);
    await c.loadMyOpenCount();
    expect(c.myOpenCount.value, 7);
  });
}
