import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:labasset_mobile/core/i18n/app_translations.dart';
import 'package:labasset_mobile/data/models/request.dart';
import 'package:labasset_mobile/data/models/request_detail.dart';
import 'package:labasset_mobile/data/repositories/requests_repository.dart';
import 'package:labasset_mobile/modules/requests/request_detail_controller.dart';
import 'package:labasset_mobile/modules/requests/requests_list_controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockRequests extends Mock implements RequestsRepository {}

void main() {
  late _MockRequests repo;

  setUp(() {
    Get.testMode = true;
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('vi', 'VN');
    repo = _MockRequests();
  });

  tearDown(Get.reset);

  group('RequestsListController', () {
    test('segment Chờ duyệt → pendingFor=me; Chờ cấp phát → status', () async {
      when(() => repo.list(pendingForMe: true, limit: 30)).thenAnswer(
        (_) async => const RequestPage(
          items: [RequestSummary(id: 'q1', code: 'YC-1', status: 'submitted')],
          total: 1,
        ),
      );
      when(
        () => repo.list(status: 'approved,partially_approved', limit: 30),
      ).thenAnswer((_) async => const RequestPage(items: [], total: 0));

      final c = RequestsListController(requests: repo);
      await c.load();
      expect(c.items.single.code, 'YC-1');

      c.setSegment(RequestSegment.toIssue);
      await Future<void>.delayed(Duration.zero);
      verify(
        () => repo.list(status: 'approved,partially_approved', limit: 30),
      ).called(1);
    });

    test('approveBulk gửi ids đã chọn rồi reload', () async {
      when(() => repo.list(pendingForMe: true, limit: 30)).thenAnswer(
        (_) async => const RequestPage(
          items: [
            RequestSummary(id: 'q1', code: 'YC-1', status: 'submitted'),
            RequestSummary(id: 'q2', code: 'YC-2', status: 'submitted'),
          ],
          total: 2,
        ),
      );
      when(() => repo.approveBulk(any())).thenAnswer((_) async {});
      final c = RequestsListController(requests: repo);
      await c.load();
      c.toggleSelect('q1');
      c.toggleSelect('q2');
      expect(await c.approveBulk(), isTrue);
      verify(() => repo.approveBulk(['q1', 'q2'])).called(1);
      expect(c.selected, isEmpty);
    });
  });

  group('RequestDetailController', () {
    const detail = RequestDetail(
      id: 'q1',
      code: 'YC-1',
      status: 'submitted',
      items: [
        RequestItem(id: 'i1', supplyId: 's1', qtyRequested: '10'),
        RequestItem(id: 'i2', supplyId: 's2', qtyRequested: '5'),
      ],
    );

    test('approve gửi số lượng duyệt đã chỉnh + ghi chú', () async {
      when(() => repo.detail('q1')).thenAnswer((_) async => detail);
      when(
        () => repo.approve(
          'q1',
          items: any(named: 'items'),
          note: any(named: 'note'),
        ),
      ).thenAnswer((_) async {});
      final c = RequestDetailController(requests: repo, id: 'q1');
      await c.load();
      c.setApprovedQty('i1', '7');
      c.setApproverNote('i2', 'hết hàng');
      expect(await c.approve(), isTrue);
      final items =
          verify(
                () => repo.approve(
                  'q1',
                  items: captureAny(named: 'items'),
                  note: any(named: 'note'),
                ),
              ).captured.single
              as List<dynamic>;
      final first = items.first as dynamic;
      expect(first.qtyApproved, '7');
    });

    test('reject gửi lý do', () async {
      when(() => repo.detail('q1')).thenAnswer((_) async => detail);
      when(() => repo.reject('q1', 'trùng')).thenAnswer((_) async {});
      final c = RequestDetailController(requests: repo, id: 'q1');
      await c.load();
      expect(await c.reject('trùng'), isTrue);
      verify(() => repo.reject('q1', 'trùng')).called(1);
    });

    test('issue điều hướng phiếu xuất khi API trả issueId', () async {
      when(() => repo.detail('q1')).thenAnswer(
        (_) async =>
            const RequestDetail(id: 'q1', code: 'YC-1', status: 'approved'),
      );
      when(
        () => repo.issue(
          'q1',
          warehouseId: any(named: 'warehouseId'),
          itemIds: any(named: 'itemIds'),
        ),
      ).thenAnswer((_) async => 'x1');
      final routes = <String>[];
      final c = RequestDetailController(
        requests: repo,
        id: 'q1',
        navigate: (r) async => routes.add(r),
      );
      await c.load();
      expect(c.canIssue, isTrue);
      expect(await c.issue(), isTrue);
      expect(routes, ['/stock/issues/x1']);
    });
  });
}
