import 'dart:typed_data';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/format/decimal_input.dart';
import '../../core/network/connectivity.dart';
import '../../core/services/attachment_service.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../data/models/department.dart';
import '../../data/models/stock_extra.dart';
import '../../data/models/supply.dart';
import '../../data/repositories/catalogs_repository.dart';
import '../../data/repositories/departments_repository.dart';
import '../../data/repositories/stock_repository.dart';
import '../../data/repositories/supplies_repository.dart';

/// Dòng hàng nhập (đã có tên hiển thị).
class ReceiptLine {
  ReceiptLine({
    required this.supplyId,
    required this.label,
    this.lotNo,
    this.expiresAt,
    this.quantity = '1',
    this.unitCost = '0',
    this.invoice,
  });

  final String supplyId;
  final String label;
  String? lotNo;
  String? expiresAt;
  String quantity;
  String unitCost;
  ({Uint8List bytes, String name, String mime})? invoice;

  ReceiptItem toItem() => ReceiptItem(
    supplyId: supplyId,
    lotNo: lotNo,
    expiresAt: expiresAt,
    quantity: quantity,
    unitCost: unitCost,
  );
}

/// Tạo phiếu nhập kho (stepper 3 bước): thông tin → dòng hàng → QC.
class ReceiptFormController extends GetxController {
  ReceiptFormController({
    required this.stock,
    required this.supplies,
    required this.departments,
    required this.catalogs,
    required this.attachments,
    void Function(String id)? popWithId,
    Future<bool> Function()? connectivity,
  }) : _popWithId = popWithId ?? ((id) => Get.back(result: id)),
       _hasNetwork = connectivity ?? hasNetwork;

  final StockRepository stock;
  final SuppliesRepository supplies;
  final DepartmentsRepository departments;
  final CatalogsRepository catalogs;
  final AttachmentService attachments;
  final void Function(String id) _popWithId;
  final Future<bool> Function() _hasNetwork;

  static const types = ['purchase', 'return_from_dept', 'adjust_in'];
  static const expiryWarnDays = 30;

  final RxInt step = 0.obs;
  final RxString type = 'purchase'.obs;
  final Rxn<DepartmentRef> warehouse = Rxn<DepartmentRef>();
  final Rxn<DepartmentRef> supplier = Rxn<DepartmentRef>();
  final Rxn<DepartmentRef> fromDepartment = Rxn<DepartmentRef>();
  final invoiceNo = TextEditingController();
  final invoiceDate = TextEditingController();
  final RxList<ReceiptLine> lines = <ReceiptLine>[].obs;
  final RxString qcStatus = 'passed'.obs;
  final qcNote = TextEditingController();
  final RxBool submitting = false.obs;
  final RxString error = ''.obs;

  Decimal get total => lines.fold(
    Decimal.zero,
    (sum, l) =>
        sum +
        ((parseDecimalInput(l.quantity) ?? Decimal.zero) *
            (parseDecimalInput(l.unitCost) ?? Decimal.zero)),
  );

  bool get canNext {
    switch (step.value) {
      case 0:
        return warehouse.value != null;
      case 1:
        return lines.isNotEmpty;
      default:
        return true;
    }
  }

  void next() {
    if (step.value < 2 && canNext) step.value++;
  }

  void back() {
    if (step.value > 0) step.value--;
  }

  void setWarehouse(DepartmentRef d) => warehouse.value = d;
  void setSupplier(DepartmentRef d) => supplier.value = d;
  void setFromDepartment(DepartmentRef d) => fromDepartment.value = d;

  Future<void> pickWarehouse() async {
    final d = await _pickCatalog('warehouses', 'stock.receipt.warehouse'.tr);
    if (d != null) warehouse.value = d;
  }

  Future<void> pickSupplier() async {
    final d = await _pickCatalog('suppliers', 'stock.receipt.supplier'.tr);
    if (d != null) supplier.value = d;
  }

  Future<void> pickFromDepartment() async {
    final selection = await _pick(
      title: 'stock.receipt.fromDepartment'.tr,
      loader: () async {
        final list = await departments.list(limit: 50);
        return list;
      },
    );
    if (selection != null) fromDepartment.value = selection;
  }

  Future<DepartmentRef?> _pickCatalog(String slug, String title) =>
      _pick(title: title, loader: () => catalogs.list(slug, limit: 50));

  Future<DepartmentRef?> _pick({
    required String title,
    required Future<List<DepartmentRef>> Function() loader,
  }) async {
    final list = await loader();
    if (list.isEmpty) return null;
    return await Get.bottomSheet<DepartmentRef>(
      SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(title, style: Get.textTheme.titleMedium),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final d in list)
                    ListTile(
                      title: Text('${d.code} — ${d.name}'),
                      onTap: () => Get.back(result: d),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Get.theme.colorScheme.surface,
    );
  }

  /// Quét mã hãng: tìm vật tư theo `manufacturerCode` (fallback `q`).
  Future<SupplySummary?> scanManufacturerCode(String code) async {
    try {
      final page = await supplies.list(q: code, limit: 5);
      for (final s in page.items) {
        if (s.code.toUpperCase() == code.toUpperCase()) return s;
      }
      return page.items.length == 1 ? page.items.first : null;
    } catch (_) {
      return null;
    }
  }

  void addLine(ReceiptLine line) => lines.add(line);

  void removeLine(int index) => lines.removeAt(index);

  bool expiryWarning(String? iso) {
    final d = iso == null ? null : DateTime.tryParse(iso);
    if (d == null) return false;
    return d.isBefore(DateTime.now().add(const Duration(days: expiryWarnDays)));
  }

  Future<bool> saveDraft() async {
    if (!canNext || lines.isEmpty || warehouse.value == null) {
      error.value = 'stock.receipt.needItems'.tr;
      return false;
    }
    if (!await _hasNetwork()) {
      AppSnackbar.info('sync.offline'.tr);
      return false;
    }
    submitting.value = true;
    try {
      final receipt = await stock.createReceipt(
        type: type.value,
        warehouseId: warehouse.value!.id,
        supplierId: supplier.value?.id,
        fromDepartmentId: fromDepartment.value?.id,
        invoiceNo: invoiceNo.text.trim().isEmpty ? null : invoiceNo.text.trim(),
        invoiceDate: invoiceDate.text.trim().isEmpty
            ? null
            : invoiceDate.text.trim(),
        qcStatus: qcStatus.value,
        qcNote: qcNote.text.trim().isEmpty ? null : qcNote.text.trim(),
        items: lines.map((l) => l.toItem()).toList(),
      );
      // Ảnh hoá đơn (best-effort, có thể vào outbox).
      for (final l in lines) {
        if (l.invoice == null) continue;
        try {
          await attachments.uploadBytes(
            entityType: 'stock_receipt',
            entityId: receipt.id,
            kind: 'invoice',
            name: l.invoice!.name,
            mime: l.invoice!.mime,
            bytes: l.invoice!.bytes,
          );
        } catch (_) {}
      }
      AppSnackbar.success('stock.receipt.created'.tr);
      _popWithId(receipt.id);
      return true;
    } catch (e) {
      error.value = e.toString();
      AppSnackbar.error(e);
      return false;
    } finally {
      submitting.value = false;
    }
  }

  @override
  void onClose() {
    invoiceNo.dispose();
    invoiceDate.dispose();
    qcNote.dispose();
    super.onClose();
  }
}
