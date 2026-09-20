import 'package:get/get.dart';

import '../../core/stocktake/stocktake_local_store.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../data/models/stocktake.dart';
import '../../data/repositories/stocktakes_repository.dart';

/// Danh sách đợt kiểm kê được phân công + tải package về máy.
class StocktakesController extends GetxController {
  StocktakesController({
    required this.repo,
    required this.store,
    this.userId = '',
    this.isAdmin = false,
  });

  final StocktakesRepository repo;
  final StocktakeLocalStore store;
  final String userId;
  final bool isAdmin;

  final RxList<StocktakeSession> items = <StocktakeSession>[].obs;
  final RxMap<String, StocktakeLocalMeta> metas =
      <String, StocktakeLocalMeta>{}.obs;
  final RxBool loading = true.obs;
  final Rxn<Object> error = Rxn<Object>();
  final RxSet<String> downloading = <String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      final page = await repo.list(status: 'open,counting');
      items.assignAll(
        isAdmin
            ? page.items
            : page.items.where((s) => s.assignedTo(userId)).toList(),
      );
      final metas = await store.downloadedSessions();
      this.metas.assignAll({for (final m in metas) m.sessionId: m});
    } catch (e) {
      error.value = e;
    } finally {
      loading.value = false;
    }
  }

  /// Tải package (ETag): 304 → giữ nguyên; 200 → lưu cục bộ.
  Future<void> download(StocktakeSession session) async {
    if (downloading.contains(session.id)) return;
    downloading.add(session.id);
    try {
      final meta = metas[session.id];
      final result = await repo.package(session.id, etag: meta?.etag);
      if (result.notModified) {
        AppSnackbar.info('stocktake.upToDate'.tr);
      } else {
        await store.savePackage(
          sessionId: session.id,
          code: session.code,
          name: session.name,
          type: session.type,
          etag: result.etag,
          items: [
            for (final i in result.items)
              StocktakeLocalItem(
                itemId: i.itemId,
                sessionId: session.id,
                code: i.code,
                name: i.name,
                equipmentId: i.equipmentId,
                lotId: i.lotId,
                supplyId: i.supplyId,
                location: i.location,
                lotNo: i.lotNo,
                qrToken: i.qrToken,
                manufacturerCode: i.manufacturerCode,
                bookQty: i.bookQty,
              ),
          ],
        );
        AppSnackbar.success('stocktake.downloaded'.tr);
      }
      await load();
    } catch (e) {
      AppSnackbar.error(e);
    } finally {
      downloading.remove(session.id);
    }
  }
}
