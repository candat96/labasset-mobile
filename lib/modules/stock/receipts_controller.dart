import 'package:get/get.dart';

import '../../data/models/stock_extra.dart';
import '../../data/repositories/stock_repository.dart';

/// Danh sách phiếu nhập kho.
class ReceiptsController extends GetxController {
  ReceiptsController({required this.stock});

  final StockRepository stock;

  final RxnString statusFilter = RxnString();
  final RxList<StockReceipt> items = <StockReceipt>[].obs;
  final RxInt total = 0.obs;
  final RxBool loading = true.obs;
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
      final page = await stock.receipts(status: statusFilter.value, limit: 30);
      items.assignAll(page.items);
      total.value = page.total.toInt();
    } catch (e) {
      error.value = e;
    } finally {
      loading.value = false;
    }
  }

  void setStatus(String? s) {
    statusFilter.value = s;
    load();
  }
}
