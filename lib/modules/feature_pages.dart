import 'package:get/get.dart';

import '../core/routes/app_routes.dart';
import '../core/routes/middlewares.dart';
import '../core/sync/outbox_service.dart';
import '../data/repositories/equipment_repository.dart';
import '../data/repositories/notifications_repository.dart';
import '../data/repositories/repairs_repository.dart';
import '../data/repositories/requests_repository.dart';
import '../data/repositories/supplies_repository.dart';
import 'account/lock_view.dart';
import 'equipment/equipment_detail_controller.dart';
import 'notifications/notifications_view.dart';
import 'notifications/notifications_preferences_controller.dart';
import 'notifications/notifications_preferences_view.dart';
import 'equipment/equipment_detail_view.dart';
import 'scan/scan_controller.dart';
import 'scan/scan_view.dart';
import 'search/search_controller.dart';
import 'search/search_view.dart';
import 'sync/sync_controller.dart';
import 'sync/sync_view.dart';

/// Route nghiệp vụ (ngoài auth/shell). Thêm module mới: thêm GetPage ở đây.
List<GetPage<dynamic>> featurePages() {
  final protected = [AuthMiddleware(), RoleMiddleware(), PasswordMiddleware()];
  return [
    GetPage(
      name: Routes.notifications,
      page: () => const NotificationsView(),
      middlewares: protected,
    ),
    GetPage(
      name: Routes.notificationsPreferences,
      page: () => const NotificationsPreferencesView(),
      middlewares: protected,
      binding: BindingsBuilder(
        () => Get.lazyPut(
          () => NotificationsPreferencesController(
            repo: Get.find<NotificationsRepository>(),
          ),
        ),
      ),
    ),
    GetPage(
      name: Routes.search,
      page: () => const SearchView(),
      middlewares: protected,
      binding: BindingsBuilder(
        () => Get.lazyPut(
          () => GlobalSearchController(
            equipment: Get.find<EquipmentRepository>(),
            supplies: Get.find<SuppliesRepository>(),
            repairs: Get.find<RepairsRepository>(),
            requests: Get.find<RequestsRepository>(),
          ),
        ),
      ),
    ),
    GetPage(
      name: Routes.sync,
      page: () => const SyncView(),
      middlewares: protected,
      binding: BindingsBuilder(
        () => Get.lazyPut(
          () => SyncController(outbox: Get.find<OutboxService>()),
        ),
      ),
    ),
    GetPage(
      name: Routes.lock,
      page: () => const LockView(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.scan,
      page: () => const ScanView(),
      middlewares: protected,
      binding: BindingsBuilder(() {
        final args = Get.arguments;
        final continuous = args is Map && args['continuous'] == true;
        Get.lazyPut(
          () => ScanController(
            equipment: Get.find<EquipmentRepository>(),
            continuous: continuous,
          ),
        );
      }),
    ),
    GetPage(
      name: Routes.equipmentDetail,
      page: () => const EquipmentDetailView(),
      middlewares: protected,
      binding: BindingsBuilder(
        () => Get.lazyPut(
          () => EquipmentDetailController(
            equipment: Get.find<EquipmentRepository>(),
            id: Get.parameters['id'] ?? '',
          ),
          tag: Get.parameters['id'],
        ),
      ),
    ),
  ];
}
