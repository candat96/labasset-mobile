import 'dart:typed_data';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:labasset_mobile/core/i18n/app_translations.dart';
import 'package:labasset_mobile/core/services/attachment_service.dart';
import 'package:labasset_mobile/data/models/department.dart';
import 'package:labasset_mobile/data/models/stock.dart';
import 'package:labasset_mobile/data/models/stock_extra.dart';
import 'package:labasset_mobile/data/models/supply.dart';
import 'package:labasset_mobile/data/repositories/catalogs_repository.dart';
import 'package:labasset_mobile/data/repositories/departments_repository.dart';
import 'package:labasset_mobile/data/repositories/stock_repository.dart';
import 'package:labasset_mobile/data/repositories/supplies_repository.dart';
import 'package:labasset_mobile/modules/stock/receipt_form_controller.dart';
import 'package:labasset_mobile/modules/stock/supply_detail_controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockStock extends Mock implements StockRepository {}

class _MockSupplies extends Mock implements SuppliesRepository {}

class _MockDepartments extends Mock implements DepartmentsRepository {}

class _MockCatalogs extends Mock implements CatalogsRepository {}

class _MockAttachments extends Mock implements AttachmentService {}

void main() {
  setUp(() {
    Get.testMode = true;
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('vi', 'VN');
  });

  tearDown(Get.reset);

  group('ReceiptFormController', () {
    late _MockStock stock;
    late ReceiptFormController c;

    setUp(() {
      stock = _MockStock();
      c = ReceiptFormController(
        stock: stock,
        supplies: _MockSupplies(),
        departments: _MockDepartments(),
        catalogs: _MockCatalogs(),
        attachments: _MockAttachments(),
        popWithId: (_) {},
      );
    });

    test('tổng tiền tính bằng Decimal, không dùng double', () {
      c.addLine(
        ReceiptLine(
          supplyId: 's1',
          label: 'A',
          quantity: '0.1',
          unitCost: '0.2',
        ),
      );
      expect(c.total, Decimal.parse('0.02'));
      c.addLine(
        ReceiptLine(
          supplyId: 's2',
          label: 'B',
          quantity: '2',
          unitCost: '1500000',
        ),
      );
      expect(c.total, Decimal.parse('3000000.02'));
    });

    test('canNext: bước 1 cần kho, bước 2 cần dòng hàng', () {
      expect(c.canNext, isFalse);
      c.setWarehouse(const DepartmentRef(id: 'w1', code: 'K', name: 'Kho'));
      expect(c.canNext, isTrue);
      c.next();
      expect(c.step.value, 1);
      expect(c.canNext, isFalse);
      c.addLine(ReceiptLine(supplyId: 's1', label: 'A'));
      expect(c.canNext, isTrue);
    });

    test('cảnh báo hạn < 30 ngày', () {
      final soon = DateTime.now()
          .add(const Duration(days: 10))
          .toIso8601String();
      final far = DateTime.now()
          .add(const Duration(days: 100))
          .toIso8601String();
      expect(c.expiryWarning(soon), isTrue);
      expect(c.expiryWarning(far), isFalse);
      expect(c.expiryWarning(null), isFalse);
    });

    test('saveDraft gửi items + qcStatus và trả id', () async {
      var popped = '';
      final cc = ReceiptFormController(
        stock: stock,
        supplies: _MockSupplies(),
        departments: _MockDepartments(),
        catalogs: _MockCatalogs(),
        attachments: _MockAttachments(),
        popWithId: (id) => popped = id,
      );
      cc.setWarehouse(const DepartmentRef(id: 'w1', code: 'K', name: 'Kho'));
      cc.addLine(
        ReceiptLine(supplyId: 's1', label: 'A', quantity: '2', unitCost: '10'),
      );
      when(
        () => stock.createReceipt(
          type: any(named: 'type'),
          warehouseId: any(named: 'warehouseId'),
          supplierId: any(named: 'supplierId'),
          fromDepartmentId: any(named: 'fromDepartmentId'),
          invoiceNo: any(named: 'invoiceNo'),
          invoiceDate: any(named: 'invoiceDate'),
          receivedAt: any(named: 'receivedAt'),
          qcStatus: any(named: 'qcStatus'),
          qcNote: any(named: 'qcNote'),
          notes: any(named: 'notes'),
          items: any(named: 'items'),
        ),
      ).thenAnswer(
        (_) async =>
            const StockReceipt(id: 'r1', code: 'PN-1', warehouseId: 'w1'),
      );
      expect(await cc.saveDraft(), isTrue);
      expect(popped, 'r1');
      final items =
          verify(
                () => stock.createReceipt(
                  type: 'purchase',
                  warehouseId: 'w1',
                  supplierId: null,
                  fromDepartmentId: null,
                  invoiceNo: null,
                  invoiceDate: null,
                  receivedAt: null,
                  qcStatus: 'passed',
                  qcNote: null,
                  notes: null,
                  items: captureAny(named: 'items'),
                ),
              ).captured.single
              as List<ReceiptItem>;
      expect(items.single.quantity, '2');
    });

    test('scanManufacturerCode khớp chính xác mã', () async {
      final supplies = _MockSupplies();
      when(() => supplies.list(q: 'ABC', limit: 5)).thenAnswer(
        (_) async => const SupplyPage(
          items: [
            SupplySummary(id: 's1', code: 'ABC', name: 'A'),
            SupplySummary(id: 's2', code: 'ABX', name: 'B'),
          ],
          total: 2,
        ),
      );
      final cc = ReceiptFormController(
        stock: stock,
        supplies: supplies,
        departments: _MockDepartments(),
        catalogs: _MockCatalogs(),
        attachments: _MockAttachments(),
        popWithId: (_) {},
      );
      expect((await cc.scanManufacturerCode('ABC'))?.id, 's1');
    });
  });

  group('SupplyDetailController', () {
    test('load tồn/lô/máy + mở nắp + điều chỉnh', () async {
      final supplies = _MockSupplies();
      final stock = _MockStock();
      when(() => supplies.byId('s1')).thenAnswer(
        (_) async => const SupplySummary(id: 's1', code: 'VT1', name: 'Găng'),
      );
      when(() => supplies.stock('s1')).thenAnswer(
        (_) async => const SupplyStock(
          lots: [StockLotSummary(id: 'l1', supplyId: 's1', lotNo: 'L1')],
        ),
      );
      when(() => supplies.equipment('s1')).thenAnswer((_) async => []);
      when(() => stock.forecast('s1')).thenAnswer(
        (_) async => const StockForecast(supplyId: 's1', daysLeft: 12),
      );
      when(() => stock.openLot('l1')).thenAnswer((_) async {});
      when(
        () => stock.adjust(lotId: 'l1', newQty: '9', reason: 'kiểm kê'),
      ).thenAnswer((_) async {});

      final c = SupplyDetailController(
        supplies: supplies,
        stock: stock,
        id: 's1',
        isAdmin: true,
      );
      await c.load();
      expect(c.supply.value?.code, 'VT1');
      expect(c.stockInfo.value?.lots.single.lotNo, 'L1');
      expect(c.forecast.value?.daysLeft, 12);

      expect(await c.openLot(c.stockInfo.value!.lots.single), isTrue);
      verify(() => stock.openLot('l1')).called(1);
      expect(
        await c.adjustLot(
          c.stockInfo.value!.lots.single,
          newQty: '9',
          reason: 'kiểm kê',
        ),
        isTrue,
      );
    });
  });

  test('ReceiptItem/StockReceipt parse JSON', () {
    final r = StockReceipt.fromJson(const {
      'id': 'r1',
      'code': 'PN-1',
      'type': 'purchase',
      'warehouseId': 'w1',
      'items': [
        {'supplyId': 's1', 'quantity': '2.000', 'unitCost': '10.000'},
      ],
      'status': 'draft',
      'totalAmount': '20.000',
      'qcStatus': 'pending',
    });
    expect(r.items.single.quantity, '2.000');
    expect(r.totalAmount, '20.000');
  });

  test('AttachmentUploadResult dùng cho ảnh hoá đơn (không ném)', () {
    const result = AttachmentUploadResult(AttachmentUploadStatus.queued);
    expect(result.status, AttachmentUploadStatus.queued);
    expect(Uint8List(0), isEmpty);
  });
}
