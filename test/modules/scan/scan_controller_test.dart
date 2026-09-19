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
}
