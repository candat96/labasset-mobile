import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:labasset_mobile/core/cache/kv_cache.dart';
import 'package:labasset_mobile/core/services/attachment_service.dart';
import 'package:labasset_mobile/core/stocktake/stocktake_local_store.dart';
import 'package:labasset_mobile/core/sync/outbox_service.dart';
import 'package:labasset_mobile/core/widgets/empty_state.dart';
import 'package:labasset_mobile/core/widgets/error_state.dart';
import 'package:labasset_mobile/data/models/my_tasks.dart';
import 'package:labasset_mobile/data/models/report.dart';
import 'package:labasset_mobile/data/repositories/ai_repository.dart';
import 'package:labasset_mobile/data/repositories/catalogs_repository.dart';
import 'package:labasset_mobile/data/repositories/departments_repository.dart';
import 'package:labasset_mobile/data/repositories/equipment_repository.dart';
import 'package:labasset_mobile/data/repositories/files_repository.dart';
import 'package:labasset_mobile/data/repositories/me_repository.dart';
import 'package:labasset_mobile/data/repositories/notifications_repository.dart';
import 'package:labasset_mobile/data/repositories/repairs_repository.dart';
import 'package:labasset_mobile/data/repositories/requests_repository.dart';
import 'package:labasset_mobile/data/repositories/reports_repository.dart';
import 'package:labasset_mobile/data/repositories/settings_repository.dart';
import 'package:labasset_mobile/data/repositories/stock_repository.dart';
import 'package:labasset_mobile/data/repositories/stocktakes_repository.dart';
import 'package:labasset_mobile/data/repositories/supplies_repository.dart';
import 'package:labasset_mobile/data/repositories/tasks_repository.dart';
import 'package:labasset_mobile/modules/ai/ai_controller.dart';
import 'package:labasset_mobile/modules/ai/ai_view.dart';
import 'package:labasset_mobile/modules/home/home_controller.dart';
import 'package:labasset_mobile/modules/home/home_view.dart';
import 'package:labasset_mobile/modules/maintenance/maintenance_task_controller.dart';
import 'package:labasset_mobile/modules/maintenance/maintenance_task_view.dart';
import 'package:labasset_mobile/modules/notifications/notifications_controller.dart';
import 'package:labasset_mobile/modules/repairs/repair_detail_controller.dart';
import 'package:labasset_mobile/modules/repairs/repair_detail_view.dart';
import 'package:labasset_mobile/modules/repairs/repairs_controller.dart';
import 'package:labasset_mobile/modules/repairs/repairs_view.dart';
import 'package:labasset_mobile/modules/reports/reports_controller.dart';
import 'package:labasset_mobile/modules/reports/reports_view.dart';
import 'package:labasset_mobile/modules/requests/requests_list_controller.dart';
import 'package:labasset_mobile/modules/requests/requests_list_view.dart';
import 'package:labasset_mobile/modules/stock/issue_form_controller.dart';
import 'package:labasset_mobile/modules/stock/issue_form_view.dart';
import 'package:labasset_mobile/modules/stock/stock_overview_controller.dart';
import 'package:labasset_mobile/modules/stock/stock_overview_view.dart';
import 'package:labasset_mobile/modules/stocktake/stocktake_count_controller.dart';
import 'package:labasset_mobile/modules/stocktake/stocktake_count_view.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_helpers.dart';

class _RepairsRepo extends Mock implements RepairsRepository {}

class _TasksRepo extends Mock implements TasksRepository {}

class _RequestsRepo extends Mock implements RequestsRepository {}

class _EquipmentRepo extends Mock implements EquipmentRepository {}

class _StockRepo extends Mock implements StockRepository {}

class _SettingsRepo extends Mock implements SettingsRepository {}

class _StocktakesRepo extends Mock implements StocktakesRepository {}

class _NotificationsRepo extends Mock implements NotificationsRepository {}

class _CatalogsRepo extends Mock implements CatalogsRepository {}

class _DepartmentsRepo extends Mock implements DepartmentsRepository {}

class _SuppliesRepo extends Mock implements SuppliesRepository {}

class _AiRepo extends Mock implements AiRepository {}

class _Outbox extends Mock implements OutboxService {}

class _Cache extends Mock implements KvCache {}

class _LocalStore extends Mock implements StocktakeLocalStore {}

class _Attachments extends Mock implements AttachmentService {}

class _Files extends Mock implements FilesRepository {}

class _MeRepo extends Mock implements MeRepository {}

class _ReportsRepo extends Mock implements ReportsRepository {}

class _Home extends HomeController {
  _Home() : super(me: _MeRepo(), settings: _SettingsRepo());
  @override
  // Test fake: intentionally skip network bootstrap.
  // ignore: must_call_super
  void onInit() {}
}

class _Repairs extends RepairsController {
  _Repairs() : super(repairs: _RepairsRepo());
  @override
  // ignore: must_call_super
  void onInit() {}
}

class _RepairDetail extends RepairDetailController {
  _RepairDetail() : super(repairs: _RepairsRepo(), outbox: _Outbox(), id: 'r1');
  @override
  // ignore: must_call_super
  void onInit() {}
}

class _MaintenanceTask extends MaintenanceTaskController {
  _MaintenanceTask()
    : super(tasks: _TasksRepo(), outbox: _Outbox(), cache: _Cache(), id: 't1');
  @override
  // ignore: must_call_super
  void onInit() {}
}

class _StockOverview extends StockOverviewController {
  _StockOverview() : super(stock: _StockRepo(), requests: _RequestsRepo());
  @override
  // ignore: must_call_super
  void onInit() {}
}

class _RequestsList extends RequestsListController {
  _RequestsList() : super(requests: _RequestsRepo());
  @override
  // ignore: must_call_super
  void onInit() {}
}

class _StocktakeCount extends StocktakeCountController {
  _StocktakeCount()
    : super(
        repo: _StocktakesRepo(),
        store: _LocalStore(),
        outbox: _Outbox(),
        attachments: _Attachments(),
        files: _Files(),
        id: 's1',
      );
  @override
  // ignore: must_call_super
  void onInit() {}
}

class _Reports extends ReportsController {
  _Reports()
    : super(
        reports: _ReportsRepo(),
        equipment: _EquipmentRepo(),
        departments: _DepartmentsRepo(),
      );
  @override
  // ignore: must_call_super
  void onInit() {}
}

class _Ai extends AiController {
  _Ai() : super(repo: _AiRepo());
  @override
  // ignore: must_call_super
  void onInit() {}
}

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  testWidgets('home_view render trạng thái rỗng', (tester) async {
    final home = Get.put<HomeController>(_Home());
    home.loading.value = false;
    Get.put(
      NotificationsController(repo: _NotificationsRepo(), store: fakeStore()),
    );
    await tester.pumpWidget(wrap(const HomeView()));
    expect(find.text('Hôm nay chưa có việc nào'), findsOneWidget);
  });

  testWidgets('home_view render số nhóm việc từ D18', (tester) async {
    final home = Get.put<HomeController>(_Home());
    home.loading.value = false;
    home.data.value = const MyTasksResponse(
      repairs: RepairTasks(assigned: 2, pendingResponse: 0, overdue: 0),
      maintenance: MaintenanceTasks(due7d: 0, overdue: 0),
      requests: RequestTasks(
        pendingApproval: 0,
        pendingIssue: 0,
        pendingReceive: 0,
      ),
      stocktakes: StocktakeTasks(counting: 0),
      alerts: TaskAlerts(
        repairsNew: 0,
        stock: StockAlertCounts(
          lowStock: 0,
          expiring: 0,
          expired: 0,
          openVialExpiring: 0,
          stale: 0,
        ),
        calibrationOverdue: 0,
      ),
    );
    Get.put(
      NotificationsController(repo: _NotificationsRepo(), store: fakeStore()),
    );
    await tester.pumpWidget(wrap(const HomeView()));
    expect(find.text('Sửa chữa được giao'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('repairs_list_view render empty', (tester) async {
    final c = Get.put<RepairsController>(_Repairs());
    c.loading.value = false;
    await tester.pumpWidget(wrap(const RepairsView()));
    expect(find.byType(EmptyState), findsOneWidget);
  });

  testWidgets('repair_detail_view render error', (tester) async {
    final c = Get.put<RepairDetailController>(_RepairDetail());
    c.loading.value = false;
    c.error.value = Exception('load');
    await tester.pumpWidget(wrap(const RepairDetailView()));
    expect(find.byType(ErrorState), findsOneWidget);
  });

  testWidgets('maintenance_task_view render error', (tester) async {
    final c = Get.put<MaintenanceTaskController>(_MaintenanceTask());
    c.loading.value = false;
    c.error.value = Exception('load');
    await tester.pumpWidget(wrap(const MaintenanceTaskView()));
    expect(find.byType(ErrorState), findsOneWidget);
  });

  testWidgets('stock_overview_view render dữ liệu', (tester) async {
    final c = Get.put<StockOverviewController>(_StockOverview());
    c.loading.value = false;
    c.alertTotals['low_stock'] = 2;
    await tester.pumpWidget(wrap(const StockOverviewView()));
    expect(find.text('Cảnh báo tồn kho'), findsOneWidget);
  });

  testWidgets('issue_form_view render nút lưu bị khoá khi thiếu dữ liệu', (
    tester,
  ) async {
    final c = Get.put<IssueFormController>(
      IssueFormController(
        stock: _StockRepo(),
        supplies: _SuppliesRepo(),
        departments: _DepartmentsRepo(),
        catalogs: _CatalogsRepo(),
      ),
    );
    await tester.pumpWidget(wrap(const IssueFormView()));
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNotNull);
    expect(c.canSave, isFalse);
  });

  testWidgets('requests_list_view render empty', (tester) async {
    final c = Get.put<RequestsListController>(_RequestsList());
    c.loading.value = false;
    await tester.pumpWidget(wrap(const RequestsListView()));
    expect(find.byType(EmptyState), findsOneWidget);
  });

  testWidgets('stocktake_count_view render error', (tester) async {
    final c = Get.put<StocktakeCountController>(_StocktakeCount());
    c.loading.value = false;
    c.error.value = Exception('load');
    await tester.pumpWidget(wrap(const StocktakeCountView()));
    expect(find.byType(ErrorState), findsOneWidget);
  });

  testWidgets('reports_view render error', (tester) async {
    final c = Get.put<ReportsController>(_Reports());
    c.loading.value = false;
    c.error.value = Exception('load');
    await tester.pumpWidget(wrap(const ReportsView()));
    expect(find.byType(ErrorState), findsOneWidget);
  });

  testWidgets('reports_view render dashboard và danh sách D1', (tester) async {
    final c = Get.put<ReportsController>(_Reports());
    c.loading.value = false;
    c.cards.add(
      const DashboardCard(
        key: 'equipment.total',
        title: 'Tổng thiết bị',
        value: 12,
        link: '/equipment',
      ),
    );
    c.reportList.add(reportForWidget);
    await tester.pumpWidget(wrap(const ReportsView()));
    expect(find.text('Tổng thiết bị'), findsOneWidget);
    expect(find.text('Hiện trạng thiết bị'), findsOneWidget);
  });

  testWidgets('ai_view render empty sau khi tải', (tester) async {
    final c = Get.put<AiController>(_Ai());
    c.loading.value = false;
    await tester.pumpWidget(wrap(const AiView()));
    expect(find.byType(EmptyState), findsOneWidget);
  });
}

const reportForWidget = ReportMeta(
  key: 'equipment.byStatus',
  title: 'Hiện trạng thiết bị',
  group: 'equipment',
  params: {'type': 'object'},
  columns: [],
);
