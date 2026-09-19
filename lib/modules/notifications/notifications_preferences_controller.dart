import 'package:get/get.dart';

import '../../core/widgets/app_snackbar.dart';
import '../../data/models/notification_preference.dart';
import '../../data/repositories/notifications_repository.dart';

/// Màn `/notifications/preferences`: bật/tắt push/in-app theo loại thông báo.
class NotificationsPreferencesController extends GetxController {
  NotificationsPreferencesController({required this.repo});

  final NotificationsRepository repo;

  final RxList<NotificationPreference> items = <NotificationPreference>[].obs;
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
      items.assignAll(await repo.preferences());
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
