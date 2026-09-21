import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:labasset_mobile/core/i18n/app_translations.dart';
import 'package:labasset_mobile/data/models/repair_detail.dart';
import 'package:labasset_mobile/data/models/department.dart';
import 'package:labasset_mobile/data/repositories/catalogs_repository.dart';
import 'package:labasset_mobile/data/repositories/equipment_repository.dart';
import 'package:labasset_mobile/data/repositories/repairs_repository.dart';
import 'package:labasset_mobile/data/repositories/supplies_repository.dart';
import 'package:labasset_mobile/modules/repairs/tabs/costs_tab.dart';
import 'package:labasset_mobile/modules/repairs/tabs/parts_tab.dart';
import 'package:labasset_mobile/modules/repairs/tabs/vendors_tab.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepairs extends Mock implements RepairsRepository {}

class _MockSupplies extends Mock implements SuppliesRepository {}

class _MockEquipment extends Mock implements EquipmentRepository {}

class _MockCatalogs extends Mock implements CatalogsRepository {}

void main() {
  late _MockRepairs repairs;

  setUp(() {
    Get.testMode = true;
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('vi', 'VN');
    repairs = _MockRepairs();
    when(() => repairs.parts(any())).thenAnswer((_) async => []);
    when(() => repairs.costs(any())).thenAnswer((_) async => []);
    when(() => repairs.vendors(any())).thenAnswer((_) async => []);
  });

  tearDown(Get.reset);

  test('PartsTab: thêm vật tư từ kho gửi source=stock', () async {
    when(() => repairs.addPart(any(), any())).thenAnswer((_) async {});
    final c = PartsTabController(
      repairs: repairs,
      supplies: _MockSupplies(),
      equipment: _MockEquipment(),
      ticketId: 'r1',
      equipmentId: 'e1',
    );
    await c.load();
    final ok = await c.addStock(
      supplyId: 's1',
      name: 'VT1 — Găng tay',
      quantity: '2',
    );
    expect(ok, isTrue);
    final sent =
        verify(() => repairs.addPart('r1', captureAny())).captured.single
            as Map<String, dynamic>;
    expect(sent['source'], 'stock');
    expect(sent['supplyId'], 's1');
    expect(sent['quantity'], '2');
  });

  test('PartsTab: mua ngoài gửi đơn giá', () async {
    when(() => repairs.addPart(any(), any())).thenAnswer((_) async {});
    final c = PartsTabController(
      repairs: repairs,
      supplies: _MockSupplies(),
      equipment: _MockEquipment(),
      ticketId: 'r1',
      equipmentId: 'e1',
    );
    await c.load();
    await c.addPurchased(name: 'Bơm', quantity: '1', unitCost: '1500000');
    final sent =
        verify(() => repairs.addPart('r1', captureAny())).captured.single
            as Map<String, dynamic>;
    expect(sent['source'], 'purchased');
    expect(sent['unitCost'], '1500000');
  });

  test('VendorsTab: thêm thuê ngoài gửi supplier + báo giá', () async {
    final catalogs = _MockCatalogs();
    when(() => catalogs.list('suppliers', limit: 100)).thenAnswer(
      (_) async => const [
        DepartmentRef(id: 'sp1', code: 'NCC-01', name: 'Thiết bị Việt'),
      ],
    );
    when(() => repairs.addVendor(any(), any())).thenAnswer((_) async {});
    final c = VendorsTabController(
      repairs: repairs,
      catalogs: catalogs,
      ticketId: 'r1',
    );
    await c.load();
    expect(c.supplierNames['sp1'], 'Thiết bị Việt');
    await c.add(
      supplierId: 'sp1',
      quotationAmount: '500000',
      engineerName: 'A',
    );
    final sent =
        verify(() => repairs.addVendor('r1', captureAny())).captured.single
            as Map<String, dynamic>;
    expect(sent['supplierId'], 'sp1');
    expect(sent['quotationAmount'], '500000');
  });

  test('CostsTab: thêm chi phí gửi category + amount', () async {
    when(() => repairs.addCost(any(), any())).thenAnswer((_) async {});
    final c = CostsTabController(repairs: repairs, ticketId: 'r1');
    await c.load();
    await c.add(
      category: 'labor',
      description: 'Công thay bơm',
      amount: '200000',
    );
    final sent =
        verify(() => repairs.addCost('r1', captureAny())).captured.single
            as Map<String, dynamic>;
    expect(sent['category'], 'labor');
    expect(sent['amount'], '200000');
  });

  test('RepairPart/RepairCost parse JSON API', () {
    final part = RepairPart.fromJson(const {
      'id': 'p1',
      'source': 'stock',
      'name': 'Găng',
      'quantity': '2.000',
    });
    expect(part.quantity, '2.000');
    final cost = RepairCost.fromJson(const {
      'id': 'c1',
      'category': 'parts',
      'description': 'x',
      'amount': '10.000',
    });
    expect(cost.amount, '10.000');
  });
}
