import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/network/connectivity.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/pick_ref.dart';
import '../../core/widgets/picker_sheet.dart';
import '../../data/models/department.dart';
import '../../data/models/stock.dart';
import '../../data/repositories/catalogs_repository.dart';
import '../../data/repositories/stock_repository.dart';

/// Chuyển kho: quét liên tục từng lô → hỏi số lượng → gửi.
class TransferFormController extends GetxController {
  TransferFormController({
    required this.stock,
    required this.catalogs,
    void Function()? pop,
    Future<bool> Function()? connectivity,
  }) : _pop = pop ?? (Get.back),
       _hasNetwork = connectivity ?? hasNetwork;

  final StockRepository stock;
  final CatalogsRepository catalogs;
  final void Function() _pop;
  final Future<bool> Function() _hasNetwork;

  final Rxn<DepartmentRef> fromWarehouse = Rxn<DepartmentRef>();
  final Rxn<DepartmentRef> toWarehouse = Rxn<DepartmentRef>();
  final RxList<({String lotId, String lotNo, String quantity})> lines =
      <({String lotId, String lotNo, String quantity})>[].obs;
  final RxBool submitting = false.obs;
  final RxString error = ''.obs;

  bool get canSubmit =>
      fromWarehouse.value != null &&
      toWarehouse.value != null &&
      fromWarehouse.value!.id != toWarehouse.value!.id &&
      lines.isNotEmpty;

  Future<DepartmentRef?> pickWarehouse(BuildContext context, String title) =>
      pickRef(
        context,
        title: title,
        kind: PickerKind.warehouse,
        loader: () => catalogs.list('warehouses', limit: 50),
      );

  void setFrom(DepartmentRef d) => fromWarehouse.value = d;
  void setTo(DepartmentRef d) => toWarehouse.value = d;

  /// Tìm lô theo mã quét (best-effort) rồi hỏi số lượng.
  Future<StockLotSummary?> findLot(String code) async {
    try {
      final page = await stock.lots(q: code, limit: 5);
      for (final l in page.items) {
        if (l.lotNo.toUpperCase() == code.toUpperCase()) return l;
      }
      return page.items.length == 1 ? page.items.first : null;
    } catch (_) {
      return null;
    }
  }

  void addLine(StockLotSummary lot, String quantity) {
    lines.add((lotId: lot.id, lotNo: lot.lotNo, quantity: quantity));
  }

  void removeLine(int i) => lines.removeAt(i);

  Future<bool> submit() async {
    if (!canSubmit) {
      error.value = 'stock.transfer.needLines'.tr;
      return false;
    }
    if (!await _hasNetwork()) {
      AppSnackbar.info('sync.offline'.tr);
      return false;
    }
    submitting.value = true;
    try {
      await stock.createTransfer(
        fromWarehouseId: fromWarehouse.value!.id,
        toWarehouseId: toWarehouse.value!.id,
        items: [for (final l in lines) (lotId: l.lotId, quantity: l.quantity)],
      );
      AppSnackbar.success('stock.transfer.created'.tr);
      _pop();
      return true;
    } catch (e) {
      error.value = e.toString();
      AppSnackbar.error(e);
      return false;
    } finally {
      submitting.value = false;
    }
  }
}
