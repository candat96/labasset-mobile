import 'package:get/get.dart';

import '../../core/widgets/app_snackbar.dart';
import '../../data/models/notification_preference.dart';
import '../../data/repositories/notifications_repository.dart';

/// Màn `/notifications/preferences`: bật/tắt push/in-app theo loại thông báo.
/// Loại lấy từ `GET /v1/notifications/types` (B6-B13), ghép với preferences
/// người dùng; loại chưa có dòng → mặc định bật cả hai.
class NotificationsPreferencesController extends GetxController {
  NotificationsPreferencesController({required this.repo});

  final NotificationsRepository repo;

  final RxList<NotificationPreference> items = <NotificationPreference>[].obs;
  final RxMap<String, String> labels = <String, String>{}.obs;
  final RxBool loading = true.obs;
  final RxBool saving = false.obs;
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
      final prefs = await repo.preferences();
      List<NotificationType> types = const [];
      try {
        types = await repo.types();
      } catch (_) {
        // registry là best-effort (API cũ chưa có)
      }
      labels.assignAll({for (final t in types) t.type: t.label});
      final byType = {for (final p in prefs) p.type: p};
      final merged = <NotificationPreference>[];
      for (final t in types) {
        merged.add(
          byType.remove(t.type) ??
              NotificationPreference(type: t.type, push: true, inapp: true),
        );
      }
      merged.addAll(byType.values); // loại còn lại (registry thiếu)
      items.assignAll(merged);
    } catch (e) {
      error.value = e;
    } finally {
      loading.value = false;
    }
  }

  Future<void> save() async {
    saving.value = true;
    try {
      await repo.savePreferences(items.toList());
      AppSnackbar.success('notifications.preferences.saved'.tr);
    } catch (e) {
      AppSnackbar.error(e);
    } finally {
      saving.value = false;
    }
  }
}
