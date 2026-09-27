import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:labasset_mobile/core/i18n/app_translations.dart';
import 'package:labasset_mobile/data/models/department.dart';
import 'package:labasset_mobile/data/models/stock_extra.dart';
import 'package:labasset_mobile/data/models/supply.dart';
import 'package:labasset_mobile/data/repositories/catalogs_repository.dart';
import 'package:labasset_mobile/data/repositories/stock_repository.dart';
import 'package:labasset_mobile/data/repositories/supplies_repository.dart';
import 'package:labasset_mobile/modules/stock/supply_detail_controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockSupplies extends Mock implements SuppliesRepository {}

class _MockStock extends Mock implements StockRepository {}

class _MockCatalogs extends Mock implements CatalogsRepository {}

void main() {
  setUp(() {
    Get.testMode = true;
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('vi', 'VN');
  });

  tearDown(Get.reset);

  group('SupplySummary.fromJson', () {
    test('đọc đủ trường hồ sơ vật tư', () {
      final s = SupplySummary.fromJson(const {
        'id': 's1',
        'code': 'VT1',
        'name': 'Găng tay',
        'circulationNumber': 'DK10-123',
        'circulationValidTo': '2026-10-01',
        'riskClass': 'B',
        'countryOfOrigin': 'Việt Nam',
        'insuranceCode': 'BHYT01',
        'insuranceName': 'Găng tay y tế',
        'insuranceRate': '80.00',
        'insurancePrice': '120000',
        'bidPackage': 'Gói 1',
        'bidDecisionNo': 'QĐ-99',
        'bidPrice': '110000',
        'bidValidTo': '2027-01-01',
        'purchaseUnitId': 'u2',
        'conversionFactor': '100.0000',
        'minShelfLifeDays': 180,
      });
      expect(s.circulationNumber, 'DK10-123');
      expect(s.riskClass, 'B');
      expect(s.insuranceRate, '80.00');
      expect(s.bidPrice, '110000');
      expect(s.conversionFactor, '100.0000');
      expect(s.minShelfLifeDays, 180);
    });

    test('bỏ trống cũng không lỗi (dữ liệu cũ)', () {
      final s = SupplySummary.fromJson(const {
        'id': 's1',
        'code': 'VT1',
        'name': 'Găng',
      });
      expect(s.circulationNumber, isNull);
      expect(s.conversionFactor, isNull);
      expect(s.minShelfLifeDays, isNull);
    });
  });

  test('SupplySubstitute parse JSON', () {
    final sub = SupplySubstitute.fromJson(const {
      'id': 's2',
      'code': 'VT2',
      'name': 'Bơm tiêm',
      'unitName': 'Cái',
      'notes': 'dùng thay khi thiếu',
    });
    expect(sub.id, 's2');
    expect(sub.unitName, 'Cái');
    expect(sub.notes, 'dùng thay khi thiếu');
  });

  group('SupplyDetailController', () {
    test('nạp hồ sơ, vật tư thay thế và diễn giải quy đổi', () async {
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
      when(() => catalogs.list('units', limit: 200)).thenAnswer(
        (_) async => const [
          DepartmentRef(id: 'u1', code: 'CAI', name: 'Cái'),
          DepartmentRef(id: 'u2', code: 'THUNG', name: 'Thùng'),
        ],
      );
      when(() => stock.forecast('s1')).thenThrow(Exception('no forecast'));

      final c = SupplyDetailController(
        supplies: supplies,
        stock: stock,
        catalogs: catalogs,
        id: 's1',
      );
      await c.load();

      expect(c.substitutes.single.code, 'VT2');
      expect(c.conversionLabel, '1 Thùng = 100 Cái');
    });
  });
}
