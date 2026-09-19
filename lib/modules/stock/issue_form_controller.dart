import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/widgets/app_snackbar.dart';
import '../../data/models/department.dart';
import '../../data/models/stock_issue.dart';
import '../../data/models/supply.dart';
import '../../data/repositories/catalogs_repository.dart';
import '../../data/repositories/departments_repository.dart';
import '../../data/repositories/stock_repository.dart';
import '../../data/repositories/supplies_repository.dart';

/// Tạo phiếu xuất kho (draft): nguồn, khoa/máy nhận, dòng hàng + cảnh báo FEFO.
class IssueFormController extends GetxController {
  IssueFormController({
    required this.stock,
    required this.supplies,
    required this.departments,
    required this.catalogs,
    void Function(String id)? popWithId,
    String? initialType,
    String? equipmentId,
    String? repairTicketId,
    String? maintenanceTaskId,
    String? lotId,
    String? supplyId,
  }) : _popWithId = popWithId ?? ((id) => Get.back(result: id)),
       initialEquipmentId = equipmentId,
       initialRepairTicketId = repairTicketId,
       initialMaintenanceTaskId = maintenanceTaskId {
    if (initialType != null) type.value = initialType;
    if (lotId != null) {
      lines.add(
        IssueLine(
          supplyId: supplyId ?? '',
          label: supplyId ?? '',
          lotId: lotId,
          quantity: '1',
        ),
      );
    }
  }

  final StockRepository stock;
  final SuppliesRepository supplies;
  final DepartmentsRepository departments;
  final CatalogsRepository catalogs;
  final void Function(String id) _popWithId;
  final String? initialEquipmentId;
  final String? initialRepairTicketId;
  final String? initialMaintenanceTaskId;

  static const types = [
    'to_department',
    'for_repair',
    'for_maintenance',
    'dispose',
    'return_to_supplier',
  ];

  final RxString type = 'to_department'.obs;
  final Rxn<DepartmentRef> warehouse = Rxn<DepartmentRef>();
  final Rxn<DepartmentRef> toDepartment = Rxn<DepartmentRef>();
  final Rxn<DepartmentRef> equipment = Rxn<DepartmentRef>();
  final receiverName = TextEditingController();
  final reason = TextEditingController();
  final RxList<IssueLine> lines = <IssueLine>[].obs;
  final RxBool submitting = false.obs;
  final RxString error = ''.obs;

  bool get reasonRequired =>
      type.value == 'dispose' || type.value == 'return_to_supplier';

  bool get canSave =>
      warehouse.value != null &&
      lines.isNotEmpty &&
      (!reasonRequired || reason.text.trim().isNotEmpty);

  @override
  void onInit() {
    super.onInit();
    if (initialEquipmentId != null) {
      equipment.value = DepartmentRef(
        id: initialEquipmentId!,
        code: '',
        name: initialEquipmentId!,
      );
    }
  }

  Future<void> pickWarehouse() async {
    final list = await catalogs.list('warehouses', limit: 50);
    final d = await _pick(list, 'stock.receipt.warehouse'.tr);
    if (d != null) warehouse.value = d;
  }

  Future<void> pickToDepartment() async {
    final list = await departments.list(limit: 50);
    final d = await _pick(list, 'stock.issue.toDepartment'.tr);
    if (d != null) toDepartment.value = d;
  }

  Future<DepartmentRef?> _pick(List<DepartmentRef> list, String title) async {
    if (list.isEmpty) return null;
    return Get.bottomSheet<DepartmentRef>(
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

  /// Thêm dòng theo vật tư: tự gợi ý lô FEFO nếu có kho nguồn.
  Future<void> addSupplyLine(SupplySummary supply, String quantity) async {
    final line = IssueLine(
      supplyId: supply.id,
      label: '${supply.code} — ${supply.name}',
      quantity: quantity,
    );
    await _applyFefo(line);
    lines.add(line);
  }

  /// Gắn lô quét được; cảnh báo nếu không theo FEFO.
  Future<void> attachLot(IssueLine line, String lotId, String lotNo) async {
    line.lotId = lotId;
    line.lotNo = lotNo;
    await _applyFefo(line, explicitLotId: lotId);
  }

  Future<void> _applyFefo(IssueLine line, {String? explicitLotId}) async {
    final w = warehouse.value;
    if (w == null || line.supplyId.isEmpty) return;
    try {
      final suggestions = await stock.suggestLots(
        supplyId: line.supplyId,
        warehouseId: w.id,
        quantity: line.quantity,
      );
      if (suggestions.isEmpty) return;
      final fefo = suggestions.first;
      if (explicitLotId == null) {
        line.lotId = fefo.lotId;
        line.lotNo = fefo.lotNo;
        line.available = fefo.available;
        line.fefoWarning = false;
      } else {
        line.fefoWarning = explicitLotId != fefo.lotId;
      }
    } catch (_) {
      // gợi ý lô là best-effort
    }
  }

  void removeLine(int i) => lines.removeAt(i);

  Future<bool> save() async {
    if (!canSave) {
      error.value = 'stock.issue.needLines'.tr;
      return false;
    }
    submitting.value = true;
    try {
      final issue = await stock.createIssue(
        type: type.value,
        warehouseId: warehouse.value!.id,
        toDepartmentId: toDepartment.value?.id,
        equipmentId: equipment.value?.id,
        repairTicketId: initialRepairTicketId,
        maintenanceTaskId: initialMaintenanceTaskId,
        receiverName: receiverName.text.trim().isEmpty
            ? null
            : receiverName.text.trim(),
        reason: reason.text.trim().isEmpty ? null : reason.text.trim(),
        items: lines.map((l) => l.toItem()).toList(),
      );
      AppSnackbar.success('stock.issue.created'.tr);
      _popWithId(issue.id);
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
    receiverName.dispose();
    reason.dispose();
    super.onClose();
  }
}
