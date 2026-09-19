import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:labasset_mobile/core/errors/api_error.dart';
import 'package:labasset_mobile/core/i18n/app_translations.dart';
import 'package:labasset_mobile/data/models/equipment.dart';
import 'package:labasset_mobile/data/repositories/equipment_repository.dart';
import 'package:labasset_mobile/modules/scan/scan_controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements EquipmentRepository {}

void main() {
  late _MockRepo repo;
  late ScanController c;
  late List<String> routes;

  setUp(() {
    Get.testMode = true;
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('vi', 'VN');
    repo = _MockRepo();
    routes = [];
    c = ScanController(equipment: repo, navigate: (r) async => routes.add(r));
  });

  tearDown(Get.reset);

  test('QR token → equipment route', () async {
    when(() => repo.byQr('tok')).thenAnswer(
      (_) async => const QrEquipment(
        id: 'e1',
        code: 'M1',
        name: 'Máy',
        status: 'active',
      ),
    );
    expect(await c.lookup('tok'), 'e1');
    expect(routes, ['/equipment/e1']);
  });

  test('QR payload labasset://eq/<token> → tách token', () async {
    when(() => repo.byQr('abc-123')).thenAnswer(
      (_) async => const QrEquipment(
        id: 'e9',
        code: 'M9',
        name: 'Máy 9',
        status: 'active',
      ),
    );
    expect(await c.lookup('labasset://eq/abc-123'), 'e9');
    expect(routes, ['/equipment/e9']);
  });

  test('404 on QR → fallback search by code (case-insensitive)', () async {
    when(
      () => repo.byQr('m1'),
    ).thenThrow(ApiError(404, 'QR_TOKEN_NOT_FOUND', ''));
    when(() => repo.search('m1', limit: 5)).thenAnswer(
      (_) async => const EquipmentPage(
        items: [
          EquipmentSummary(id: 'x', code: 'M10', name: 'a', status: 'active'),
          EquipmentSummary(id: 'e2', code: 'M1', name: 'b', status: 'broken'),
        ],
        total: 2,
      ),
    );
    expect(await c.lookup('m1'), 'e2');
    expect(routes, ['/equipment/e2']);
  });

  test('not found → message, no navigation', () async {
    when(
      () => repo.byQr('zz'),
    ).thenThrow(ApiError(404, 'QR_TOKEN_NOT_FOUND', ''));
    when(
      () => repo.search('zz', limit: 5),
    ).thenAnswer((_) async => const EquipmentPage(items: [], total: 0));
    expect(await c.lookup('zz'), isNull);
    expect(c.message.value, 'Không tìm thấy máy với mã này');
    expect(routes, isEmpty);
  });

  test('network error → mapped message', () async {
    when(() => repo.byQr('a')).thenThrow(ApiError(0, 'NETWORK_ERROR', ''));
    expect(await c.lookup('a'), isNull);
    expect(c.message.value, 'Không kết nối được máy chủ');
  });

  group('chế độ quét liên tục', () {
    late ScanController cc;
    late List<String> codes;
    late Object? popped;

    setUp(() {
      codes = [];
      popped = 'sentinel';
      cc = ScanController(
        equipment: repo,
        continuous: true,
        onCode: (c) async => codes.add(c),
        pop: (r) => popped = r,
      );
    });

    test('gom mã, đếm, không gọi API và không điều hướng', () async {
      await cc.addCode('A1');
      await cc.addCode('A2');
      await cc.addCode('A3');
      expect(codes, ['A1', 'A2', 'A3']);
      expect(cc.scanCount.value, 3);
      expect(cc.recentCodes, ['A3', 'A2', 'A1']);
      expect(routes, isEmpty);
      verifyZeroInteractions(repo);
    });

    test('mã trùng được đưa lên đầu, không nhân đôi danh sách', () async {
      await cc.addCode('A1');
      await cc.addCode('A2');
      await cc.addCode('A1');
      expect(cc.recentCodes, ['A1', 'A2']);
      expect(cc.scanCount.value, 3);
    });

    test('giữ tối đa 10 mã gần nhất', () async {
      for (var i = 0; i < 12; i++) {
        await cc.addCode('M$i');
      }
      expect(cc.recentCodes, hasLength(10));
      expect(cc.recentCodes.first, 'M11');
      expect(cc.recentCodes.contains('M1'), isFalse);
    });

    test('onDetected chống lặp trong 1,5 s', () async {
      await cc.onDetected('B1');
      await cc.onDetected('B2'); // quá nhanh → bỏ qua
      expect(codes, ['B1']);
    });

    test('finish trả danh sách mã cho màn gọi', () async {
      await cc.addCode('C1');
      await cc.addCode('C2');
      cc.finish();
      expect(popped, ['C2', 'C1']);
    });

    test('xem lại mã đã quét (removeCode)', () async {
      await cc.addCode('D1');
      cc.removeCode('D1');
      expect(cc.recentCodes, isEmpty);
    });
  });
}
