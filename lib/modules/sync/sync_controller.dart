import 'package:get/get.dart';

import '../../core/sync/outbox_item.dart';
import '../../core/sync/outbox_service.dart';
import '../../core/widgets/app_snackbar.dart';

/// Màn "Đồng bộ": danh sách thao tác chờ, chạy ngay, thử lại.
class SyncController extends GetxController {
  SyncController({required this.outbox});

  final OutboxService outbox;

  final RxList<OutboxItem> items = <OutboxItem>[].obs;
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
      items.assignAll(await outbox.items());
      await outbox.refreshCounts();
    } catch (e) {
      error.value = e;
    } finally {
      loading.value = false;
    }
  }

  Future<void> runNow() async {
    final ok = await outbox.run(manual: true);
    if (!ok) AppSnackbar.info('sync.offline'.tr);
    await load();
  }

  Future<void> retryAll() async {
    final ok = await outbox.retryAll();
    if (!ok) AppSnackbar.info('sync.offline'.tr);
    await load();
  }
}
