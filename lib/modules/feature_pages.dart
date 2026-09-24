import 'package:get/get.dart';

import '../core/routes/app_routes.dart';
import '../core/routes/middlewares.dart';
import '../core/cache/kv_cache.dart';
import '../core/services/attachment_service.dart';
import '../core/stocktake/stocktake_local_store.dart';
import '../core/storage/session_store.dart';
import '../core/sync/outbox_service.dart';
import '../data/models/room.dart';
import '../data/repositories/calendar_repository.dart';
import '../data/repositories/calibrations_repository.dart';
import '../data/repositories/catalogs_repository.dart';
import '../data/repositories/ai_repository.dart';
import '../data/repositories/demand_repository.dart';
import '../data/repositories/departments_repository.dart';
import '../data/repositories/equipment_repository.dart';
import '../data/repositories/files_repository.dart';
import '../data/repositories/faults_repository.dart';
import '../data/repositories/notifications_repository.dart';
import '../data/repositories/repairs_repository.dart';
import '../data/repositories/requests_repository.dart';
import '../data/repositories/reports_repository.dart';
import '../data/repositories/search_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/stock_repository.dart';
import '../data/repositories/stocktakes_repository.dart';
import '../data/repositories/supplies_repository.dart';
import '../data/repositories/tasks_repository.dart';
import 'account/lock_view.dart';
import 'ai/ai_controller.dart';
import 'ai/ai_conversations_controller.dart';
import 'ai/ai_conversations_view.dart';
import 'ai/ai_view.dart';
import 'calendar/calendar_controller.dart';
import 'calendar/calendar_view.dart';
import 'demand/demand_controller.dart';
import 'demand/demand_period_controller.dart';
import 'demand/demand_period_view.dart';
import 'demand/demand_request_controller.dart';
import 'demand/demand_request_view.dart';
import 'demand/demand_view.dart';
import 'equipment/equipment_detail_controller.dart';
import 'equipment/equipment_list_controller.dart';
import 'equipment/equipment_list_view.dart';
import 'equipment/new_equipment_controller.dart';
import 'equipment/new_equipment_view.dart';
import 'notifications/notifications_view.dart';
import 'notifications/notifications_preferences_controller.dart';
import 'notifications/notifications_preferences_view.dart';
import 'equipment/equipment_detail_view.dart';
import 'maintenance/calibrations_controller.dart';
import 'maintenance/calibrations_view.dart';
import 'maintenance/maintenance_task_controller.dart';
import 'maintenance/maintenance_task_view.dart';
import 'maintenance/maintenance_tasks_controller.dart';
import 'maintenance/maintenance_tasks_view.dart';
import 'repairs/repair_detail_controller.dart';
import 'repairs/repair_detail_view.dart';
import 'repairs/repair_form_controller.dart';
import 'repairs/repair_form_view.dart';
import 'repairs/repairs_controller.dart';
import 'repairs/repairs_view.dart';
import 'repairs/tabs/vendors_tab.dart';
import 'repairs/tabs/parts_tab.dart';
import 'repairs/tabs/costs_tab.dart';
import 'reports/reports_controller.dart';
import 'reports/reports_view.dart';
import 'requests/request_detail_controller.dart';
import 'requests/request_detail_view.dart';
import 'requests/requests_list_controller.dart';
import 'requests/requests_list_view.dart';
import 'stocktake/offline_data_controller.dart';
import 'stocktake/offline_data_view.dart';
import 'stocktake/stocktake_count_controller.dart';
import 'stocktake/stocktake_count_view.dart';
import 'stocktake/stocktakes_controller.dart';
import 'stocktake/stocktakes_view.dart';
import 'stock/receipt_form_controller.dart';
import 'stock/receipt_form_view.dart';
import 'stock/receipts_controller.dart';
import 'stock/receipts_view.dart';
import 'stock/issue_detail_view.dart';
import 'stock/issue_form_controller.dart';
import 'stock/issue_form_view.dart';
import 'stock/issues_controller.dart';
import 'stock/stock_alerts_view.dart';
import 'stock/stock_overview_controller.dart';
import 'stock/stock_overview_view.dart';
import 'stock/stock_lookup_controller.dart';
import 'stock/stock_lookup_view.dart';
import 'stock/supply_detail_controller.dart';
import 'stock/supply_detail_view.dart';
import 'stock/transfer_form_controller.dart';
import 'stock/transfer_form_view.dart';
import 'equipment/tabs/accessories_tab.dart';
import 'equipment/tabs/components_tab.dart';
import 'equipment/tabs/maintenance_tab.dart';
import 'equipment/tabs/network_tab.dart';
import 'equipment/tabs/repairs_tab.dart';
import 'equipment/tabs/software_tab.dart';
import 'equipment/tabs/supplies_tab.dart';
import 'equipment/tabs/timeline_tab.dart';
import 'scan/lot_card_sheet.dart';
import 'scan/scan_controller.dart';
import 'scan/scan_view.dart';
import 'rooms/rooms_controller.dart';
import 'search/search_controller.dart';
import 'search/search_view.dart';
import 'sync/sync_controller.dart';
import 'sync/sync_view.dart';

/// Route nghiệp vụ (ngoài auth/shell). Thêm module mới: thêm GetPage ở đây.
List<GetPage<dynamic>> featurePages() {
  final protected = [AuthMiddleware(), RoleMiddleware(), PasswordMiddleware()];
  return [
    GetPage(
      name: Routes.repairs,
      page: () => const RepairsView(),
      middlewares: protected,
      binding: BindingsBuilder(() {
        final initial = switch (Get.parameters['segment']) {
          'unassigned' => RepairsSegment.unassigned,
          'all' => RepairsSegment.all,
          _ => RepairsSegment.mine,
        };
        Get.lazyPut(
          () => RepairsController(
            repairs: Get.find<RepairsRepository>(),
            userId: Get.find<SessionStore>().user.value?.id ?? '',
            initialSegment: initial,
          ),
        );
      }),
    ),
    GetPage(
      name: Routes.stock,
      page: () => const StockOverviewView(),
      middlewares: protected,
      binding: BindingsBuilder(
        () => Get.lazyPut(
          () => StockOverviewController(
            stock: Get.find<StockRepository>(),
            requests: Get.find<RequestsRepository>(),
          ),
        ),
      ),
    ),
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
          () =>
              GlobalSearchController(repository: Get.find<SearchRepository>()),
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
      name: Routes.maintenanceTasks,
      page: () => const MaintenanceTasksView(),
      middlewares: protected,
      binding: BindingsBuilder(
        () => Get.lazyPut(
          () => MaintenanceTasksController(
            tasks: Get.find<TasksRepository>(),
            userId: Get.find<SessionStore>().user.value?.id ?? '',
          ),
        ),
      ),
    ),
    GetPage(
      name: Routes.maintenanceTaskDetail,
      page: () => const MaintenanceTaskView(),
      middlewares: protected,
      binding: BindingsBuilder(() {
        final id = Get.parameters['id'] ?? '';
        final user = Get.find<SessionStore>().user.value;
        Get.lazyPut(
          () => MaintenanceTaskController(
            tasks: Get.find<TasksRepository>(),
            outbox: Get.find<OutboxService>(),
            cache: Get.find<KvCache>(),
            attachments: Get.find<AttachmentService>(),
            id: id,
            userId: user?.id ?? '',
            roles: user?.roles ?? const [],
          ),
          tag: id,
        );
      }),
    ),
    GetPage(
      name: Routes.calibrations,
      page: () => const CalibrationsView(),
      middlewares: protected,
      binding: BindingsBuilder(
        () => Get.lazyPut(
          () => CalibrationsController(
            repo: Get.find<CalibrationsRepository>(),
            catalogs: Get.find<CatalogsRepository>(),
            attachments: Get.find<AttachmentService>(),
            userId: Get.find<SessionStore>().user.value?.id ?? '',
          ),
        ),
      ),
    ),
    GetPage(
      name: Routes.calendar,
      page: () => const CalendarView(),
      middlewares: protected,
      binding: BindingsBuilder(
        () => Get.lazyPut(
          () => CalendarController(
            calendar: Get.find<CalendarRepository>(),
            userId: Get.find<SessionStore>().user.value?.id ?? '',
          ),
        ),
      ),
    ),
    GetPage(
      name: Routes.stockLookup,
      page: () => const StockLookupView(),
      middlewares: protected,
      binding: BindingsBuilder(() {
        final args = Get.arguments;
        Get.lazyPut(
          () => StockLookupController(
            supplies: Get.find<SuppliesRepository>(),
            stock: Get.find<StockRepository>(),
            equipment: Get.find<EquipmentRepository>(),
            initialQuery:
                (args is Map ? args['q'] as String? : null) ??
                Get.parameters['lotId'] ??
                Get.parameters['q'],
          ),
        );
      }),
    ),
    GetPage(
      name: Routes.supplyDetail,
      page: () => const SupplyDetailView(),
      middlewares: protected,
      binding: BindingsBuilder(() {
        final id = Get.parameters['id'] ?? '';
        Get.lazyPut(
          () => SupplyDetailController(
            supplies: Get.find<SuppliesRepository>(),
            stock: Get.find<StockRepository>(),
            id: id,
            isAdmin: Get.find<SessionStore>().hasRole(const ['HOSPITAL_ADMIN']),
          ),
          tag: id,
        );
      }),
    ),
    GetPage(
      name: Routes.stockReceipts,
      page: () => const ReceiptsView(),
      middlewares: protected,
      binding: BindingsBuilder(
        () => Get.lazyPut(
          () => ReceiptsController(stock: Get.find<StockRepository>()),
        ),
      ),
    ),
    GetPage(
      name: Routes.stockReceiptNew,
      page: () => const ReceiptFormView(),
      middlewares: protected,
      binding: BindingsBuilder(
        () => Get.lazyPut(
          () => ReceiptFormController(
            stock: Get.find<StockRepository>(),
            supplies: Get.find<SuppliesRepository>(),
            departments: Get.find<DepartmentsRepository>(),
            catalogs: Get.find<CatalogsRepository>(),
            attachments: Get.find<AttachmentService>(),
          ),
        ),
      ),
    ),
    GetPage(
      name: Routes.stockReceiptDetail,
      page: () => ReceiptDetailView(id: Get.parameters['id'] ?? ''),
      middlewares: protected,
    ),
    GetPage(
      name: Routes.stockIssues,
      page: () => const IssuesView(),
      middlewares: protected,
      binding: BindingsBuilder(
        () => Get.lazyPut(
          () => IssuesController(stock: Get.find<StockRepository>()),
        ),
      ),
    ),
    GetPage(
      name: Routes.stockIssueNew,
      page: () => const IssueFormView(),
      middlewares: protected,
      binding: BindingsBuilder(() {
        final args = Get.arguments;
        final map = args is Map ? args : const {};
        Get.lazyPut(
          () => IssueFormController(
            stock: Get.find<StockRepository>(),
            supplies: Get.find<SuppliesRepository>(),
            departments: Get.find<DepartmentsRepository>(),
            catalogs: Get.find<CatalogsRepository>(),
            equipmentRepository: Get.find<EquipmentRepository>(),
            initialType: map['type'] as String?,
            equipmentId: map['equipmentId'] as String?,
            repairTicketId: map['repairTicketId'] as String?,
            maintenanceTaskId: map['maintenanceTaskId'] as String?,
            lotId: map['lotId'] as String? ?? Get.parameters['lotId'],
            supplyId: map['supplyId'] as String? ?? Get.parameters['supplyId'],
          ),
        );
      }),
    ),
    GetPage(
      name: Routes.stockIssueDetail,
      page: () => IssueDetailView(id: Get.parameters['id'] ?? ''),
      middlewares: protected,
    ),
    GetPage(
      name: Routes.stockTransferNew,
      page: () => const TransferFormView(),
      middlewares: protected,
      binding: BindingsBuilder(
        () => Get.lazyPut(
          () => TransferFormController(
            stock: Get.find<StockRepository>(),
            catalogs: Get.find<CatalogsRepository>(),
          ),
        ),
      ),
    ),
    GetPage(
      name: Routes.stockAlerts,
      page: () => const StockAlertsView(),
      middlewares: protected,
      binding: BindingsBuilder(() {
        final args = Get.arguments;
        Get.lazyPut(
          () => StockAlertsController(
            stock: Get.find<StockRepository>(),
            initialType:
                (args is Map ? args['type'] as String? : null) ??
                Get.parameters['type'],
          ),
        );
      }),
    ),
    GetPage(
      name: Routes.requests,
      page: () => const RequestsListView(),
      middlewares: protected,
      binding: BindingsBuilder(() {
        final initial = switch (Get.parameters['segment']) {
          'toIssue' => RequestSegment.toIssue,
          'all' => RequestSegment.all,
          _ => RequestSegment.pending,
        };
        Get.lazyPut(
          () => RequestsListController(
            requests: Get.find<RequestsRepository>(),
            isAdmin: Get.find<SessionStore>().hasRole(const ['HOSPITAL_ADMIN']),
            initialSegment: initial,
          ),
        );
      }),
    ),
    GetPage(
      name: Routes.requestDetail,
      page: () => const RequestDetailView(),
      middlewares: protected,
      binding: BindingsBuilder(() {
        final id = Get.parameters['id'] ?? '';
        Get.lazyPut(
          () => RequestDetailController(
            requests: Get.find<RequestsRepository>(),
            id: id,
          ),
          tag: id,
        );
      }),
    ),
    GetPage(
      name: Routes.demand,
      page: () => const DemandView(),
      middlewares: protected,
      binding: BindingsBuilder(() {
        final initial = switch (Get.parameters['segment']) {
          'periods' => DemandSegment.periods,
          _ => DemandSegment.mine,
        };
        Get.lazyPut(
          () => DemandController(
            demand: Get.find<DemandRepository>(),
            canSeePeriods: Get.find<SessionStore>().hasRole(
              Routes.warehouseRoles,
            ),
            isDept: Get.find<SessionStore>().hasRole(Routes.deptRoles),
            initialSegment: initial,
          ),
        );
      }),
    ),
    GetPage(
      name: Routes.demandRequestDetail,
      page: () => const DemandRequestView(),
      middlewares: protected,
      binding: BindingsBuilder(() {
        final id = Get.parameters['id'] ?? '';
        final store = Get.find<SessionStore>();
        Get.lazyPut(
          () => DemandRequestController(
            demand: Get.find<DemandRepository>(),
            id: id,
            isDeptHead: store.hasRole(const ['DEPT_HEAD']),
            isStaff: store.hasRole(const ['EQUIPMENT_STAFF']),
            isAdmin: store.hasRole(const ['HOSPITAL_ADMIN']),
          ),
          tag: id,
        );
      }),
    ),
    GetPage(
      name: Routes.demandPeriodDetail,
      page: () => const DemandPeriodView(),
      middlewares: protected,
      binding: BindingsBuilder(() {
        final id = Get.parameters['id'] ?? '';
        Get.lazyPut(
          () => DemandPeriodController(
            demand: Get.find<DemandRepository>(),
            id: id,
          ),
          tag: id,
        );
      }),
    ),
    GetPage(
      name: Routes.stocktakes,
      page: () => const StocktakesView(),
      middlewares: protected,
      binding: BindingsBuilder(
        () => Get.lazyPut(
          () => StocktakesController(
            repo: Get.find<StocktakesRepository>(),
            store: Get.find<StocktakeLocalStore>(),
            userId: Get.find<SessionStore>().user.value?.id ?? '',
            isAdmin: Get.find<SessionStore>().hasRole(const ['HOSPITAL_ADMIN']),
          ),
        ),
      ),
    ),
    GetPage(
      name: Routes.stocktakeDetail,
      page: () => const StocktakeCountView(),
      middlewares: protected,
      binding: BindingsBuilder(() {
        final id = Get.parameters['id'] ?? '';
        Get.lazyPut(
          () => StocktakeCountController(
            repo: Get.find<StocktakesRepository>(),
            store: Get.find<StocktakeLocalStore>(),
            outbox: Get.find<OutboxService>(),
            attachments: Get.find<AttachmentService>(),
            files: Get.find<FilesRepository>(),
            id: id,
          ),
          tag: id,
        );
      }),
    ),
    GetPage(
      name: Routes.offlineData,
      page: () => const OfflineDataView(),
      middlewares: protected,
      binding: BindingsBuilder(
        () => Get.lazyPut(
          () => OfflineDataController(
            store: Get.find<StocktakeLocalStore>(),
            outbox: Get.find<OutboxService>(),
          ),
        ),
      ),
    ),
    GetPage(
      name: Routes.reports,
      page: () => const ReportsView(),
      middlewares: protected,
      binding: BindingsBuilder(
        () => Get.lazyPut(
          () => ReportsController(
            reports: Get.find<ReportsRepository>(),
            equipment: Get.find<EquipmentRepository>(),
            departments: Get.find<DepartmentsRepository>(),
            cache: Get.find<KvCache>(),
          ),
        ),
      ),
    ),
    GetPage(
      name: Routes.aiConversations,
      page: () => const AiConversationsView(),
      middlewares: protected,
      binding: BindingsBuilder(
        () => Get.lazyPut(
          () => AiConversationsController(
            repo: Get.find<AiRepository>(),
            equipment: Get.find<EquipmentRepository>(),
          ),
        ),
      ),
    ),
    GetPage(
      name: Routes.aiChatDetail,
      page: () => const AiView(),
      middlewares: protected,
      binding: BindingsBuilder(
        () => Get.lazyPut(
          () => AiController(
            repo: Get.find<AiRepository>(),
            conversationId: Get.parameters['id'],
            equipment: Get.find<EquipmentRepository>(),
          ),
        ),
      ),
    ),
    GetPage(
      name: Routes.ai,
      page: () => const AiView(),
      middlewares: protected,
      binding: BindingsBuilder(
        () => Get.lazyPut(
          () => AiController(
            repo: Get.find<AiRepository>(),
            equipmentId: Get.parameters['equipmentId'],
            equipment: Get.find<EquipmentRepository>(),
          ),
        ),
      ),
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
            settings: Get.find<SettingsRepository>(),
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
        // Controller các tab phụ (cùng tag = id phiếu).
        Get.lazyPut(
          () => PartsTabController(
            repairs: Get.find<RepairsRepository>(),
            supplies: Get.find<SuppliesRepository>(),
            equipment: Get.find<EquipmentRepository>(),
            ticketId: id,
            equipmentId: '',
          ),
          tag: id,
        );
        Get.lazyPut(
          () => VendorsTabController(
            repairs: Get.find<RepairsRepository>(),
            catalogs: Get.find<CatalogsRepository>(),
            ticketId: id,
          ),
          tag: id,
        );
        Get.lazyPut(
          () => CostsTabController(
            repairs: Get.find<RepairsRepository>(),
            ticketId: id,
          ),
          tag: id,
        );
      }),
    ),
    GetPage(
      name: Routes.equipmentList,
      page: () => const EquipmentListView(),
      middlewares: protected,
      binding: BindingsBuilder(() {
        Get.lazyPut(
          () => EquipmentListController(
            equipment: Get.find<EquipmentRepository>(),
            departments: Get.find<DepartmentsRepository>(),
            catalogs: Get.find<CatalogsRepository>(),
            initialStatus: Get.parameters['status'],
            initialDepartmentId: Get.parameters['departmentId'],
            initialRoom: switch (Get.arguments) {
              {'room': final RoomRef room} => room,
              _ => null,
            },
          ),
        );
        // Mode "Theo phòng" của trang hồ sơ thiết bị.
        Get.lazyPut(
          () => RoomsController(
            catalogs: Get.find<CatalogsRepository>(),
            departments: Get.find<DepartmentsRepository>(),
            reports: Get.find<ReportsRepository>(),
            autoLoad: false,
          ),
          tag: RoomsController.tagEquipment,
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
            catalogs: Get.find<CatalogsRepository>(),
            attachments: Get.find<AttachmentService>(),
            canCreateRoom: Get.find<SessionStore>().hasRole(const [
              'HOSPITAL_ADMIN',
              'EQUIPMENT_STAFF',
            ]),
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
          () => EquipmentRepairsTabController(
            repairs: Get.find<RepairsRepository>(),
            equipmentId: id,
          ),
        );
        Get.lazyPut(
          () => EquipmentMaintenanceTabController(
            tasks: Get.find<TasksRepository>(),
            calibrations: Get.find<CalibrationsRepository>(),
            equipmentId: id,
          ),
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
