import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:labasset_mobile/core/cache/kv_cache.dart';
import 'package:labasset_mobile/data/models/department.dart';
import 'package:labasset_mobile/data/models/stock_extra.dart';
import 'package:labasset_mobile/data/models/supply.dart';
import 'package:labasset_mobile/data/repositories/catalogs_repository.dart';
import 'package:labasset_mobile/data/repositories/stock_repository.dart';
import 'package:labasset_mobile/data/repositories/supplies_repository.dart';
import 'package:labasset_mobile/modules/feature_pages.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_helpers.dart';

class _MockSupplies extends Mock implements SuppliesRepository {}

class _MockStock extends Mock implements StockRepository {}

class _MockCatalogs extends Mock implements CatalogsRepository {}

void main() {
  testWidgets('chi tiết vật tư: khối hồ sơ, cảnh báo hết hiệu lực, thay thế', (
    tester,
  ) async {
    final supplies = _MockSupplies();
    final stock = _MockStock();
    final catalogs = _MockCatalogs();
    when(() => supplies.byId('s1')).thenAnswer(
      (_) async => const SupplySummary(
        id: 's1',
        code: 'VT1',
        name: 'Găng tay',
        unitId: 'u1',
        purchaseUnitId: 'u2',
        conversionFactor: '100.0000',
        circulationNumber: 'DK10-123',
        circulationValidTo: '2020-01-01',
        riskClass: 'B',
        countryOfOrigin: 'Việt Nam',
        insuranceCode: 'BHYT01',
        insuranceRate: '80.00',
        insurancePrice: '120000',
        bidPackage: 'Gói 1',
        bidPrice: '110000',
        bidValidTo: '2020-02-02',
        minShelfLifeDays: 180,
      ),
    );
    when(
      () => supplies.stock('s1'),
    ).thenAnswer((_) async => const SupplyStock());
    when(() => supplies.equipment('s1')).thenAnswer((_) async => []);
    when(() => supplies.substitutes('s1')).thenAnswer(
      (_) async => const [
        SupplySubstitute(
          id: 's2',
          code: 'VT2',
          name: 'Bơm tiêm',
          unitName: 'Cái',
        ),
      ],
    );
    when(() => stock.forecast('s1')).thenThrow(Exception('no forecast'));
    when(() => catalogs.list('units', limit: 200)).thenAnswer(
      (_) async => const [
        DepartmentRef(id: 'u1', code: 'CAI', name: 'Cái'),
        DepartmentRef(id: 'u2', code: 'THUNG', name: 'Thùng'),
      ],
    );

    final store = fakeStore()
      ..accessToken = 'A'
      ..user.value = fakeUser();
    Get.put(store);
    Get.put<SuppliesRepository>(supplies);
    Get.put<StockRepository>(stock);
    Get.put<CatalogsRepository>(catalogs);
    Get.put<KvCache>(FakeKvCache());

    // Màn dài: nới viewport để mọi khối hồ sơ được dựng.
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrap(const SizedBox(), pages: featurePages()));
    await tester.pumpAndSettle();

    unawaited(Get.toNamed('/supplies/s1'));
    await tester.pumpAndSettle();

    expect(find.text('PHÁP LÝ & LƯU HÀNH'), findsOneWidget);
    expect(find.text('BHYT'), findsOneWidget);
    expect(find.text('THẦU'), findsOneWidget);
    expect(find.text('QUY ĐỔI ĐƠN VỊ'), findsOneWidget);
    expect(find.text('1 Thùng = 100 Cái'), findsOneWidget);
    // Số lưu hành và hợp đồng thầu đều đã hết hiệu lực.
    expect(find.textContaining('đã hết hiệu lực'), findsNWidgets(2));
    expect(find.text('VẬT TƯ THAY THẾ'), findsOneWidget);
    expect(find.text('Bơm tiêm'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
