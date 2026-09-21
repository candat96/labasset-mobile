import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:labasset_mobile/data/repositories/demand_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

const _detailJson = {
  'id': 'r1',
  'periodId': 'p1',
  'status': 'submitted',
  'totalEstimated': '1000',
  'lines': <dynamic>[],
};

Response<Map<String, dynamic>> _ok(String path, Map<String, dynamic> data) =>
    Response<Map<String, dynamic>>(
      requestOptions: RequestOptions(path: path),
      data: data,
    );

void main() {
  late _MockDio dio;
  late DemandRepository repo;

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: '/'));
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    dio = _MockDio();
    repo = DemandRepository(dio);
  });

  test('dept-approve POST đúng path, không body', () async {
    when(
      () =>
          dio.post<Map<String, dynamic>>('/v1/demand/requests/r1/dept-approve'),
    ).thenAnswer(
      (_) async => _ok('/v1/demand/requests/r1/dept-approve', {
        ..._detailJson,
        'status': 'dept_approved',
      }),
    );
    final r = await repo.deptApprove('r1');
    expect(r.status, 'dept_approved');
    verify(
      () =>
          dio.post<Map<String, dynamic>>('/v1/demand/requests/r1/dept-approve'),
    ).called(1);
  });

  test('return POST body {reason}', () async {
    when(
      () => dio.post<Map<String, dynamic>>(
        '/v1/demand/requests/r1/return',
        data: {'reason': 'thiếu căn cứ'},
      ),
    ).thenAnswer(
      (_) async => _ok('/v1/demand/requests/r1/return', {
        ..._detailJson,
        'status': 'returned',
      }),
    );
    final r = await repo.returnRequest('r1', 'thiếu căn cứ');
    expect(r.status, 'returned');
  });

  test('accept không lines → body rỗng (duyệt toàn bộ)', () async {
    when(
      () => dio.post<Map<String, dynamic>>(
        '/v1/demand/requests/r1/accept',
        data: <String, dynamic>{},
      ),
    ).thenAnswer(
      (_) async => _ok('/v1/demand/requests/r1/accept', {
        ..._detailJson,
        'status': 'accepted',
      }),
    );
    final r = await repo.accept('r1');
    expect(r.status, 'accepted');
  });

  test(
    'accept có lines → body {lines:[{id,qtyApproved,approverNote}]}',
    () async {
      when(
        () => dio.post<Map<String, dynamic>>(
          '/v1/demand/requests/r1/accept',
          data: {
            'lines': [
              {'id': 'l1', 'qtyApproved': '7', 'approverNote': 'đủ'},
            ],
          },
        ),
      ).thenAnswer(
        (_) async => _ok('/v1/demand/requests/r1/accept', {
          ..._detailJson,
          'status': 'accepted',
        }),
      );
      final r = await repo.accept(
        'r1',
        lines: [(id: 'l1', qtyApproved: '7', approverNote: 'đủ')],
      );
      expect(r.status, 'accepted');
    },
  );

  test('my/periods/summary/consolidation parse DTO', () async {
    Future<Response<Map<String, dynamic>>> handler(Invocation inv) async {
      final path = inv.positionalArguments.first as String;
      if (path == '/v1/demand/my') {
        return _ok(path, {
          'items': [_detailJson],
          'total': 1,
          'page': 1,
          'limit': 50,
        });
      }
      if (path == '/v1/demand/periods') {
        return _ok(path, {
          'items': [
            {
              'id': 'p1',
              'code': 'DT-2027',
              'name': 'Dự trù 2027',
              'kind': 'annual',
              'year': 2027,
              'buckets': 12,
              'status': 'consolidating',
            },
          ],
          'total': 1,
          'page': 1,
          'limit': 30,
        });
      }
      if (path == '/v1/demand/periods/p1/summary') {
        return _ok(path, {
          'departmentsTotal': 15,
          'departmentsSubmitted': 8,
          'totalRequested': '100',
          'totalApproved': '90',
          'byItemType': <dynamic>[],
        });
      }
      return _ok(path, {
        'items': [
          {
            'id': 'c1',
            'periodId': 'p1',
            'itemName': 'Thuốc thử ALT',
            'qtyRequested': '1824',
            'qtyApproved': '1824',
            'unitPricePlan': '4200000',
            'amountPlan': '7660800000',
            'decision': 'buy',
            'breakdown': <dynamic>[],
          },
        ],
      });
    }

    when(
      () => dio.get<Map<String, dynamic>>(
        any(),
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(handler);
    when(() => dio.get<Map<String, dynamic>>(any())).thenAnswer(handler);

    expect((await repo.my()).items.single.id, 'r1');
    expect((await repo.periods()).items.single.code, 'DT-2027');
    expect((await repo.summary('p1')).departmentsSubmitted, 8);
    expect((await repo.consolidation('p1')).single.itemName, 'Thuốc thử ALT');
  });
}
