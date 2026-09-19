import 'package:get/get.dart';

import '../../core/routes/app_routes.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../data/models/stock.dart';
import '../../data/repositories/stock_repository.dart';
import '../../data/repositories/supplies_repository.dart';

/// Thẻ lô vật tư (bottom sheet sau khi quét mã lô): mở nắp, xem vật tư, xuất lô.
class LotCardController extends GetxController {
  LotCardController({
    required this.lot,
    required this.supplies,
    required this.stock,
    Future<void> Function(String route)? navigate,
    void Function()? pop,
  }) : _navigate = navigate ?? ((r) async => Get.toNamed(r)),
       _pop = pop ?? (Get.back);

  final StockLotSummary lot;
  final SuppliesRepository supplies;
  final StockRepository stock;
  final Future<void> Function(String route) _navigate;
  final void Function() _pop;

  final RxnString supplyLabel = RxnString();
  final RxBool opening = false.obs;
  final Rxn<Object> error = Rxn<Object>();

  @override
  void onInit() {
    super.onInit();
    loadSupply();
  }

  Future<void> loadSupply() async {
    try {
      final s = await supplies.byId(lot.supplyId);
      supplyLabel.value = '${s.code} — ${s.name}';
    } catch (_) {
      supplyLabel.value = lot.supplyId;
    }
  }

  Future<void> openVial() async {
    if (opening.value) return;
    opening.value = true;
    try {
      await stock.openLot(lot.id);
      AppSnackbar.success('scan.lot.opened'.tr);
      _pop(); // đóng thẻ sau khi mở nắp
    } catch (e) {
      AppSnackbar.error(e);
    } finally {
      opening.value = false;
    }
  }

  Future<void> viewSupply() async {
    _pop();
    await _navigate(Routes.placeholderFor('stock'));
  }

  Future<void> issueThisLot() async {
    _pop();
    await _navigate(Routes.placeholderFor('stockIssue'));
  }
}
