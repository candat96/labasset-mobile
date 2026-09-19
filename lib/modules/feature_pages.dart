import 'package:get/get.dart';

import '../core/routes/app_routes.dart';
import '../core/routes/middlewares.dart';
import '../core/cache/kv_cache.dart';
import '../core/services/attachment_service.dart';
import '../core/storage/session_store.dart';
import '../core/sync/outbox_service.dart';
import '../data/repositories/departments_repository.dart';
import '../data/repositories/equipment_repository.dart';
import '../data/repositories/faults_repository.dart';
import '../data/repositories/notifications_repository.dart';
import '../data/repositories/repairs_repository.dart';
import '../data/repositories/requests_repository.dart';
import '../data/repositories/stock_repository.dart';
import '../data/repositories/supplies_repository.dart';
import '../data/repositories/tasks_repository.dart';
import 'account/lock_view.dart';
import 'equipment/equipment_detail_controller.dart';
import 'equipment/new_equipment_controller.dart';
import 'equipment/new_equipment_view.dart';
import 'notifications/notifications_view.dart';
import 'notifications/notifications_preferences_controller.dart';
import 'notifications/notifications_preferences_view.dart';
import 'equipment/equipment_detail_view.dart';
import 'repairs/repair_detail_controller.dart';
import 'repairs/repair_detail_view.dart';
import 'repairs/repair_form_controller.dart';
import 'repairs/repair_form_view.dart';
import 'equipment/tabs/accessories_tab.dart';
import 'equipment/tabs/components_tab.dart';
import 'equipment/tabs/network_tab.dart';
import 'equipment/tabs/software_tab.dart';
import 'equipment/tabs/supplies_tab.dart';
import 'equipment/tabs/timeline_tab.dart';
import 'scan/lot_card_sheet.dart';
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
            stock: Get.find<StockRepository>(),
            cache: Get.find<KvCache>(),
            continuous: continuous,
            onLot: LotCardSheet.show,
          ),
        );
      }),
    ),
    GetPage(
      name: Routes.repairNew,
      page: () => const RepairFormView(),
      middlewares: protected,
      binding: BindingsBuilder(
        () => Get.lazyPut(
          () => RepairFormController(
            repairs: Get.find<RepairsRepository>(),
            equipment: Get.find<EquipmentRepository>(),
            faults: Get.find<FaultsRepository>(),
            attachments: Get.find<AttachmentService>(),
            equipmentId: Get.parameters['equipmentId'],
          ),
        ),
      ),
    ),
    GetPage(
      name: Routes.repairDetail,
      page: () => const RepairDetailView(),
      middlewares: protected,
      binding: BindingsBuilder(() {
        final id = Get.parameters['id'] ?? '';
        final user = Get.find<SessionStore>().user.value;
        Get.lazyPut(
          () => RepairDetailController(
            repairs: Get.find<RepairsRepository>(),
            outbox: Get.find<OutboxService>(),
            id: id,
            userId: user?.id ?? '',
            roles: user?.roles ?? const [],
          ),
          tag: id,
        );
      }),
    ),
    GetPage(
      name: Routes.equipmentNew,
      page: () => const NewEquipmentView(),
      middlewares: protected,
      binding: BindingsBuilder(
        () => Get.lazyPut(
          () => NewEquipmentController(
            equipment: Get.find<EquipmentRepository>(),
            departments: Get.find<DepartmentsRepository>(),
            attachments: Get.find<AttachmentService>(),
          ),
        ),
      ),
    ),
    GetPage(
      name: Routes.equipmentDetail,
      page: () => const EquipmentDetailView(),
      middlewares: protected,
      binding: BindingsBuilder(() {
        final id = Get.parameters['id'] ?? '';
        Get.lazyPut(
          () => EquipmentDetailController(
            equipment: Get.find<EquipmentRepository>(),
            tasks: Get.find<TasksRepository>(),
            id: id,
            userId: Get.find<SessionStore>().user.value?.id ?? '',
          ),
          tag: id,
        );
        Get.lazyPut(
          () => NetworkTabController(
            equipment: Get.find<EquipmentRepository>(),
            id: id,
          ),
        );
        Get.lazyPut(
          () => AccessoriesTabController(
            equipment: Get.find<EquipmentRepository>(),
            id: id,
          ),
        );
        Get.lazyPut(
          () => SoftwareTabController(
            equipment: Get.find<EquipmentRepository>(),
            id: id,
          ),
        );
        Get.lazyPut(
          () => ComponentsTabController(
            equipment: Get.find<EquipmentRepository>(),
            id: id,
          ),
        );
        Get.lazyPut(
          () => SuppliesTabController(
            equipment: Get.find<EquipmentRepository>(),
            supplies: Get.find<SuppliesRepository>(),
            id: id,
          ),
        );
        Get.lazyPut(
          () => TimelineTabController(
            equipment: Get.find<EquipmentRepository>(),
            id: id,
          ),
        );
      }),
    ),
  ];
}
