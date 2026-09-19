import 'package:get/get.dart';

import '../../core/widgets/app_snackbar.dart';
import '../../data/models/stock.dart';
import '../../data/models/stock_extra.dart';
import '../../data/models/stock_issue.dart';
import '../../data/models/supply.dart';
import '../../data/repositories/stock_repository.dart';
import '../../data/repositories/supplies_repository.dart';

/// Màn Vật tư `/supplies/:id`: tồn theo kho/lô, mở nắp, điều chỉnh, máy tương thích.
class SupplyDetailController extends GetxController {
  SupplyDetailController({
    required this.supplies,
    required this.stock,
    required this.id,
    this.isAdmin = false,
  });

  final SuppliesRepository supplies;
  final StockRepository stock;
  final String id;
  final bool isAdmin;

  final Rxn<SupplySummary> supply = Rxn<SupplySummary>();
  final Rxn<SupplyStock> stockInfo = Rxn<SupplyStock>();
  final RxList<SupplyEquipment> machines = <SupplyEquipment>[].obs;
  final Rxn<StockForecast> forecast = Rxn<StockForecast>();
  final RxBool loading = true.obs;
  final RxBool busy = false.obs;
  final Rxn<Object> error = Rxn<Object>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      supply.value = await supplies.byId(id);
      stockInfo.value = await supplies.stock(id);
      machines.assignAll(await supplies.equipment(id));
      try {
        forecast.value = await stock.forecast(id);
      } catch (_) {
        forecast.value = null; // dự báo best-effort
      }
    } catch (e) {
      error.value = e;
    } finally {
      loading.value = false;
    }
  }

  Future<bool> openLot(StockLotSummary lot) async {
    busy.value = true;
    try {
      await stock.openLot(lot.id);
      AppSnackbar.success('scan.lot.opened'.tr);
      await load();
      return true;
    } catch (e) {
      AppSnackbar.error(e);
      return false;
    } finally {
      busy.value = false;
    }
  }

  Future<bool> adjustLot(
    StockLotSummary lot, {
    required String newQty,
    required String reason,
  }) async {
    busy.value = true;
    try {
      await stock.adjust(lotId: lot.id, newQty: newQty, reason: reason);
      AppSnackbar.success('stock.adjust.saved'.tr);
      await load();
      return true;
    } catch (e) {
      AppSnackbar.error(e);
      return false;
    } finally {
      busy.value = false;
    }
  }

  /// Xuất nhanh 1 bước từ lô (POST /quick).
  Future<bool> quickIssue({
    required StockLotSummary lot,
    required String toDepartmentId,
    required String quantity,
  }) async {
    if (lot.warehouseId == null) {
      AppSnackbar.error('stock.issue.noWarehouse'.tr);
      return false;
    }
    busy.value = true;
    try {
      await stock.quickIssue(
        type: 'to_department',
        warehouseId: lot.warehouseId!,
        toDepartmentId: toDepartmentId,
        items: [
          IssueItem(supplyId: lot.supplyId, lotId: lot.id, quantity: quantity),
        ],
      );
      AppSnackbar.success('stock.issue.quickDone'.tr);
      await load();
      return true;
    } catch (e) {
      AppSnackbar.error(e);
      return false;
    } finally {
      busy.value = false;
    }
  }
}
