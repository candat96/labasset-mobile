import 'package:get/get.dart';

import '../../core/format/format.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../data/models/department.dart';
import '../../data/models/stock.dart';
import '../../data/models/stock_extra.dart';
import '../../data/models/stock_issue.dart';
import '../../data/models/supply.dart';
import '../../data/repositories/catalogs_repository.dart';
import '../../data/repositories/stock_repository.dart';
import '../../data/repositories/supplies_repository.dart';

/// Màn Vật tư `/supplies/:id`: hồ sơ chi tiết (pháp lý/BHYT/thầu/quy đổi/hạn
/// dùng, vật tư thay thế) + tồn theo kho/lô, mở nắp, điều chỉnh, máy tương thích.
class SupplyDetailController extends GetxController {
  SupplyDetailController({
    required this.supplies,
    required this.stock,
    required this.catalogs,
    required this.id,
    this.isAdmin = false,
  });

  final SuppliesRepository supplies;
  final StockRepository stock;
  final CatalogsRepository catalogs;
  final String id;
  final bool isAdmin;

  final Rxn<SupplySummary> supply = Rxn<SupplySummary>();
  final Rxn<SupplyStock> stockInfo = Rxn<SupplyStock>();
  final RxList<SupplyEquipment> machines = <SupplyEquipment>[].obs;
  final RxList<SupplySubstitute> substitutes = <SupplySubstitute>[].obs;
  final RxList<DepartmentRef> units = <DepartmentRef>[].obs;
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
      try {
        substitutes.assignAll(await supplies.substitutes(id));
      } catch (_) {
        substitutes.clear(); // hồ sơ thay thế best-effort
      }
      try {
        units.assignAll(await catalogs.list('units', limit: 200));
      } catch (_) {
        units.clear(); // tên đơn vị best-effort
      }
    } catch (e) {
      error.value = e;
    } finally {
      loading.value = false;
    }
  }

  /// Tên đơn vị theo id (tra từ danh mục đơn vị).
  String? unitName(String? unitId) {
    if (unitId == null || unitId.isEmpty) return null;
    for (final u in units) {
      if (u.id == unitId) return u.name;
    }
    return null;
  }

  /// Diễn giải quy đổi mua ↔ dùng, ví dụ "1 Thùng = 100 Cái".
  String? get conversionLabel {
    final s = supply.value;
    final factor = s?.conversionFactor;
    if (s == null || factor == null || factor.isEmpty) return null;
    final buy = unitName(s.purchaseUnitId) ?? 'stock.supply.purchaseUnit'.tr;
    final use = unitName(s.unitId) ?? 'stock.supply.usageUnit'.tr;
    return '1 $buy = ${formatDecimal(factor)} $use';
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
