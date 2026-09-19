import 'package:get/get.dart';

import '../core/routes/app_routes.dart';
import '../core/routes/middlewares.dart';
import '../data/repositories/equipment_repository.dart';
import 'account/lock_view.dart';
import 'equipment/equipment_detail_controller.dart';
import 'notifications/notifications_view.dart';
import 'equipment/equipment_detail_view.dart';
import 'scan/scan_controller.dart';
import 'scan/scan_view.dart';

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
      name: Routes.lock,
      page: () => const LockView(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.scan,
      page: () => const ScanView(),
      middlewares: protected,
      binding: BindingsBuilder(
        () => Get.lazyPut(
          () => ScanController(equipment: Get.find<EquipmentRepository>()),
        ),
      ),
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
