import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:labasset_mobile/core/errors/api_error.dart';
import 'package:labasset_mobile/core/i18n/app_translations.dart';
import 'package:labasset_mobile/data/models/stock.dart';
import 'package:labasset_mobile/data/models/supply.dart';
import 'package:labasset_mobile/data/repositories/stock_repository.dart';
import 'package:labasset_mobile/data/repositories/supplies_repository.dart';
import 'package:labasset_mobile/modules/scan/lot_card_controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockStock extends Mock implements StockRepository {}

class _MockSupplies extends Mock implements SuppliesRepository {}

void main() {
  setUp(() {
    Get.testMode = true;
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('vi', 'VN');
  });

  tearDown(Get.reset);

  const lot = StockLotSummary(
    id: 'l1',
    supplyId: 's1',
    lotNo: 'LOT-01',
    available: '12.000',
  );

  test('loadSupply lấy code — name', () async {
    final supplies = _MockSupplies();
    when(() => supplies.byId('s1')).thenAnswer(
      (_) async => const SupplySummary(id: 's1', code: 'VT001', name: 'Găng'),
    );
    final c = LotCardController(
      lot: lot,
      supplies: supplies,
      stock: _MockStock(),
    );
    await c.loadSupply();
    expect(c.supplyLabel.value, 'VT001 — Găng');
  });

  test('loadSupply lỗi → fallback supplyId', () async {
    final supplies = _MockSupplies();
    when(() => supplies.byId('s1')).thenThrow(ApiError(404, 'NOT_FOUND', ''));
    final c = LotCardController(
      lot: lot,
      supplies: supplies,
      stock: _MockStock(),
    );
    await c.loadSupply();
    expect(c.supplyLabel.value, 's1');
  });

  test('openVial gọi API mở nắp', () async {
    final stock = _MockStock();
    when(() => stock.openLot('l1')).thenAnswer((_) async {});
    final c = LotCardController(
      lot: lot,
      supplies: _MockSupplies(),
      stock: stock,
      pop: () {},
    );
    await c.openVial();
    verify(() => stock.openLot('l1')).called(1);
    expect(c.opening.value, isFalse);
  });

  test('openVial lỗi → không ném ra, giữ opening=false', () async {
    final stock = _MockStock();
    when(() => stock.openLot('l1')).thenThrow(ApiError(409, 'CONFLICT', ''));
    final c = LotCardController(
      lot: lot,
      supplies: _MockSupplies(),
      stock: stock,
      pop: () {},
    );
    await c.openVial();
    expect(c.opening.value, isFalse);
  });

  test('viewSupply/issueThisLot điều hướng route thật', () async {
    final routes = <String>[];
    final c = LotCardController(
      lot: lot,
      supplies: _MockSupplies(),
      stock: _MockStock(),
      navigate: (r) async => routes.add(r),
      pop: () {},
    );
    await c.viewSupply();
    await c.issueThisLot();
    expect(routes, ['/supplies/s1', '/stock/issues/new?lotId=l1&supplyId=s1']);
  });
}
