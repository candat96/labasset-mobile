import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:labasset_mobile/core/i18n/app_translations.dart';
import 'package:labasset_mobile/data/models/demand.dart';
import 'package:labasset_mobile/data/repositories/demand_repository.dart';
import 'package:labasset_mobile/modules/demand/demand_request_controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockDemand extends Mock implements DemandRepository {}

DemandRequest _detail(String status) => DemandRequest(
  id: 'r1',
  periodId: 'p1',
  status: status,
  totalEstimated: '1000',
  period: const DemandPeriodRef(id: 'p1', code: 'DT-2027', name: 'Dự trù 2027'),
  department: const DemandDepartmentRef(
    id: 'd1',
    code: 'XN',
    name: 'Khoa Xét nghiệm',
  ),
  lines: const [DemandLine(id: 'l1', requestId: 'r1', itemName: 'Vật tư')],
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

  Future<DemandRequestController> load(
    String status, {
    bool head = false,
    bool staff = false,
    bool admin = false,
  }) async {
    when(() => repo.request('r1')).thenAnswer((_) async => _detail(status));
    final c = DemandRequestController(
      demand: repo,
      id: 'r1',
      isDeptHead: head,
      isStaff: staff,
      isAdmin: admin,
    );
    await c.load();
    return c;
  }

  test('DEPT_HEAD duyệt được phiếu submitted, không tiếp nhận', () async {
    final c = await load('submitted', head: true);
    expect(c.canDeptApprove, isTrue);
    expect(c.canAccept, isFalse);
    expect(c.canReturn, isTrue);
  });

  test('VT/ADM tiếp nhận được phiếu dept_approved', () async {
    final c = await load('dept_approved', staff: true);
    expect(c.canAccept, isTrue);
    expect(c.canDeptApprove, isFalse);
    expect(c.canReturn, isTrue);
  });

  test('phiếu accepted không còn hành động', () async {
    final c = await load('accepted', staff: true, admin: true);
    expect(c.canAccept, isFalse);
    expect(c.canDeptApprove, isFalse);
    expect(c.canReturn, isFalse);
  });

  test('deptApprove gọi đúng endpoint rồi reload', () async {
    final c = await load('submitted', admin: true);
    when(
      () => repo.deptApprove('r1'),
    ).thenAnswer((_) async => _detail('dept_approved'));
    expect(await c.deptApprove(), isTrue);
    verify(() => repo.deptApprove('r1')).called(1);
    // reload sau hành động: request() được gọi lần 2.
    verify(() => repo.request('r1')).called(2);
    expect(c.busy.value, isFalse);
  });

  test('returnRequest gửi lý do đã trim', () async {
    final c = await load('dept_approved', staff: true);
    when(
      () => repo.returnRequest('r1', 'thiếu căn cứ'),
    ).thenAnswer((_) async => _detail('returned'));
    expect(await c.returnRequest('  thiếu căn cứ  '), isTrue);
    verify(() => repo.returnRequest('r1', 'thiếu căn cứ')).called(1);
  });

  test('accept gọi endpoint không kèm lines (duyệt toàn bộ)', () async {
    final c = await load('dept_approved', staff: true);
    when(() => repo.accept('r1')).thenAnswer((_) async => _detail('accepted'));
    expect(await c.accept(), isTrue);
    verify(() => repo.accept('r1')).called(1);
  });

  test('lỗi API trả false và không đổi trạng thái', () async {
    final c = await load('submitted', admin: true);
    when(() => repo.deptApprove('r1')).thenThrow(Exception('boom'));
    expect(await c.deptApprove(), isFalse);
    expect(c.item.value!.status, 'submitted');
    expect(c.busy.value, isFalse);
  });
}
