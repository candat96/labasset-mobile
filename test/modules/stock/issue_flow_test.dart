import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:labasset_mobile/core/i18n/app_translations.dart';
import 'package:labasset_mobile/data/models/department.dart';
import 'package:labasset_mobile/data/models/stock.dart';
import 'package:labasset_mobile/data/models/stock_issue.dart';
import 'package:labasset_mobile/data/models/supply.dart';
import 'package:labasset_mobile/data/repositories/catalogs_repository.dart';
import 'package:labasset_mobile/data/repositories/departments_repository.dart';
import 'package:labasset_mobile/data/repositories/stock_repository.dart';
import 'package:labasset_mobile/data/repositories/supplies_repository.dart';
import 'package:labasset_mobile/modules/stock/issue_form_controller.dart';
import 'package:labasset_mobile/modules/stock/stock_alerts_view.dart';
import 'package:labasset_mobile/modules/stock/transfer_form_controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockStock extends Mock implements StockRepository {}

class _MockSupplies extends Mock implements SuppliesRepository {}

class _MockDepartments extends Mock implements DepartmentsRepository {}

class _MockCatalogs extends Mock implements CatalogsRepository {}

void main() {
  setUp(() {
    Get.testMode = true;
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('vi', 'VN');
  });

  tearDown(Get.reset);

  group('IssueFormController', () {
    late _MockStock stock;
    late IssueFormController c;

    setUp(() {
      stock = _MockStock();
      c = IssueFormController(
        stock: stock,
        supplies: _MockSupplies(),
        departments: _MockDepartments(),
        catalogs: _MockCatalogs(),
        popWithId: (_) {},
      );
    });

    test('canSave cần kho + dòng; dispose bắt buộc lý do', () {
      expect(c.canSave, isFalse);
      c.warehouse.value = const DepartmentRef(id: 'w1', code: 'K', name: 'Kho');
      c.lines.add(IssueLine(supplyId: 's1', label: 'A'));
      expect(c.canSave, isTrue);

      c.type.value = 'dispose';
      expect(c.canSave, isFalse);
      c.reason.text = 'hết hạn';
      expect(c.canSave, isTrue);
    });

    test('addSupplyLine tự gợi ý lô FEFO', () async {
      c.warehouse.value = const DepartmentRef(id: 'w1', code: 'K', name: 'Kho');
      when(
        () =>
            stock.suggestLots(supplyId: 's1', warehouseId: 'w1', quantity: '2'),
      ).thenAnswer(
        (_) async => const [
          LotSuggestion(
            lotId: 'l1',
            lotNo: 'L1',
            quantity: '2',
            available: '10',
          ),
        ],
      );
      await c.addSupplyLine(
        const SupplySummary(id: 's1', code: 'VT1', name: 'Găng'),
        '2',
      );
      expect(c.lines.single.lotId, 'l1');
      expect(c.lines.single.fefoWarning, isFalse);
    });

    test('quét lô hạn xa hơn FEFO → cảnh báo vàng', () async {
      c.warehouse.value = const DepartmentRef(id: 'w1', code: 'K', name: 'Kho');
      when(
        () =>
            stock.suggestLots(supplyId: 's1', warehouseId: 'w1', quantity: '1'),
      ).thenAnswer(
        (_) async => const [LotSuggestion(lotId: 'l1', lotNo: 'L1')],
      );
      final line = IssueLine(supplyId: 's1', label: 'A', quantity: '1');
      await c.attachLot(line, 'l9', 'L9');
      expect(line.fefoWarning, isTrue);
      await c.attachLot(line, 'l1', 'L1');
      expect(line.fefoWarning, isFalse);
    });

    test('save gửi type + items', () async {
      c.warehouse.value = const DepartmentRef(id: 'w1', code: 'K', name: 'Kho');
      c.lines.add(
        IssueLine(supplyId: 's1', label: 'A', lotId: 'l1', quantity: '2'),
      );
      when(
        () => stock.createIssue(
          type: any(named: 'type'),
          warehouseId: any(named: 'warehouseId'),
          toDepartmentId: any(named: 'toDepartmentId'),
          equipmentId: any(named: 'equipmentId'),
          repairTicketId: any(named: 'repairTicketId'),
          maintenanceTaskId: any(named: 'maintenanceTaskId'),
          receiverUserId: any(named: 'receiverUserId'),
          receiverName: any(named: 'receiverName'),
          reason: any(named: 'reason'),
          notes: any(named: 'notes'),
          items: any(named: 'items'),
        ),
      ).thenAnswer(
        (_) async =>
            const StockIssue(id: 'i1', code: 'PX-1', warehouseId: 'w1'),
      );
      expect(await c.save(), isTrue);
      final items =
          verify(
                () => stock.createIssue(
                  type: 'to_department',
                  warehouseId: 'w1',
                  toDepartmentId: null,
                  equipmentId: null,
                  repairTicketId: null,
                  maintenanceTaskId: null,
                  receiverUserId: null,
                  receiverName: null,
                  reason: null,
                  notes: null,
                  items: captureAny(named: 'items'),
                ),
              ).captured.single
              as List<IssueItem>;
      expect(items.single.lotId, 'l1');
      expect(items.single.quantity, '2');
    });
  });

  group('TransferFormController', () {
    test('canSubmit cần 2 kho khác nhau + dòng', () async {
      final stock = _MockStock();
      final c = TransferFormController(
        stock: stock,
        catalogs: _MockCatalogs(),
        pop: () {},
      );
      c.setFrom(const DepartmentRef(id: 'w1', code: 'A', name: 'Kho A'));
      c.setTo(const DepartmentRef(id: 'w1', code: 'A', name: 'Kho A'));
      expect(c.canSubmit, isFalse);
      c.setTo(const DepartmentRef(id: 'w2', code: 'B', name: 'Kho B'));
      expect(c.canSubmit, isFalse);
      c.addLine(
        const StockLotSummary(id: 'l1', supplyId: 's1', lotNo: 'L1'),
        '2',
      );
      expect(c.canSubmit, isTrue);

      when(
        () => stock.createTransfer(
          fromWarehouseId: 'w1',
          toWarehouseId: 'w2',
          items: any(named: 'items'),
        ),
      ).thenAnswer((_) async {});
      expect(await c.submit(), isTrue);
    });

    test('findLot khớp lotNo chính xác', () async {
      final stock = _MockStock();
      when(() => stock.lots(q: 'L9', limit: 5)).thenAnswer(
        (_) async => const StockLotPage(
          items: [
            StockLotSummary(id: 'l1', supplyId: 's1', lotNo: 'L1'),
            StockLotSummary(id: 'l9', supplyId: 's1', lotNo: 'L9'),
          ],
          total: 2,
        ),
      );
      final c = TransferFormController(
        stock: stock,
        catalogs: _MockCatalogs(),
        pop: () {},
      );
      expect((await c.findLot('L9'))?.id, 'l9');
    });
  });

  group('StockAlertsController', () {
    test('load theo type + resolve stale', () async {
      final stock = _MockStock();
      when(
        () =>
            stock.alerts(resolved: false, type: any(named: 'type'), limit: 50),
      ).thenAnswer(
        (_) async => const StockAlertPage(
          items: [
            StockAlertSummary(
              id: 'a1',
              type: 'stale',
              supplyId: 's1',
              message: 'Tồn lâu',
            ),
          ],
          total: 1,
        ),
      );
      when(() => stock.resolveAlert('a1')).thenAnswer((_) async {});
      final c = StockAlertsController(stock: stock, initialType: 'stale');
      await c.load();
      expect(c.items.single.type, 'stale');
      await c.resolve(c.items.single);
      verify(() => stock.resolveAlert('a1')).called(1);
    });
  });
}
