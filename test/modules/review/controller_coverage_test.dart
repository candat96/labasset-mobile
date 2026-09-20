import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:labasset_mobile/core/cache/kv_cache.dart';
import 'package:labasset_mobile/core/services/attachment_service.dart';
import 'package:labasset_mobile/core/stocktake/stocktake_local_store.dart';
import 'package:labasset_mobile/core/sync/outbox_service.dart';
import 'package:labasset_mobile/data/models/request.dart';
import 'package:labasset_mobile/data/models/stock.dart';
import 'package:labasset_mobile/data/models/stock_issue.dart';
import 'package:labasset_mobile/data/models/supply.dart';
import 'package:labasset_mobile/data/models/task.dart';
import 'package:labasset_mobile/data/repositories/ai_repository.dart';
import 'package:labasset_mobile/data/repositories/auth_repository.dart';
import 'package:labasset_mobile/data/repositories/catalogs_repository.dart';
import 'package:labasset_mobile/data/repositories/departments_repository.dart';
import 'package:labasset_mobile/data/repositories/equipment_repository.dart';
import 'package:labasset_mobile/data/repositories/faults_repository.dart';
import 'package:labasset_mobile/data/repositories/repairs_repository.dart';
import 'package:labasset_mobile/data/repositories/requests_repository.dart';
import 'package:labasset_mobile/data/repositories/settings_repository.dart';
import 'package:labasset_mobile/data/repositories/stock_repository.dart';
import 'package:labasset_mobile/data/repositories/stocktakes_repository.dart';
import 'package:labasset_mobile/data/repositories/supplies_repository.dart';
import 'package:labasset_mobile/data/repositories/tasks_repository.dart';
import 'package:labasset_mobile/modules/account/account_controller.dart';
import 'package:labasset_mobile/modules/account/lock_controller.dart';
import 'package:labasset_mobile/modules/ai/ai_controller.dart';
import 'package:labasset_mobile/modules/auth/otp_controller.dart';
import 'package:labasset_mobile/modules/maintenance/maintenance_tasks_controller.dart';
import 'package:labasset_mobile/modules/repairs/repair_form_controller.dart';
import 'package:labasset_mobile/modules/reports/reports_controller.dart';
import 'package:labasset_mobile/modules/requests/request_detail_controller.dart';
import 'package:labasset_mobile/modules/requests/requests_list_controller.dart';
import 'package:labasset_mobile/modules/shell/shell_controller.dart';
import 'package:labasset_mobile/modules/stock/issue_form_controller.dart';
import 'package:labasset_mobile/modules/stock/issues_controller.dart';
import 'package:labasset_mobile/modules/stock/receipts_controller.dart';
import 'package:labasset_mobile/modules/stock/stock_lookup_controller.dart';
import 'package:labasset_mobile/modules/stock/stock_overview_controller.dart';
import 'package:labasset_mobile/modules/stock/supply_detail_controller.dart';
import 'package:labasset_mobile/modules/stock/transfer_form_controller.dart';
import 'package:labasset_mobile/modules/stocktake/offline_data_controller.dart';
import 'package:labasset_mobile/modules/stocktake/stocktakes_controller.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_helpers.dart';

class _Auth extends Mock implements AuthRepository {}

class _Attachments extends Mock implements AttachmentService {}

class _Equipment extends Mock implements EquipmentRepository {}

class _Faults extends Mock implements FaultsRepository {}

class _Repairs extends Mock implements RepairsRepository {}

class _Requests extends Mock implements RequestsRepository {}

class _Settings extends Mock implements SettingsRepository {}

class _Store extends Mock implements StocktakeLocalStore {}

class _Outbox extends Mock implements OutboxService {}

class _Stocktakes extends Mock implements StocktakesRepository {}

class _Ai extends Mock implements AiRepository {}

class _Tasks extends Mock implements TasksRepository {}

class _Stock extends Mock implements StockRepository {}

class _Supplies extends Mock implements SuppliesRepository {}

class _Catalogs extends Mock implements CatalogsRepository {}

class _Departments extends Mock implements DepartmentsRepository {}

class _Cache extends Mock implements KvCache {}

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  test('OtpController kiểm tra OTP đúng 6 chữ số', () {
    final c = OtpController(auth: _Auth(), store: fakeStore());
    expect(c.validator('123456'), isNull);
    expect(c.validator('12345'), isNotNull);
  });

  test('ShellController đổi tab chính', () {
    final c = ShellController()..select(2);
    expect(c.index.value, 2);
  });

  test('LockController không khoá khách chưa đăng nhập', () {
    final c = LockController(store: fakeStore());
    c.lockIfNeeded();
    expect(c.failures, 0);
  });

  test('AccountController đổi theme và cỡ chữ qua SessionStore', () async {
    final store = fakeStore();
    final c = AccountController(store: store, auth: _Auth());
    await c.setTheme(ThemeMode.dark);
    await c.setTextScale(true);
    expect(store.themeMode.value, ThemeMode.dark);
    expect(store.textScale.value, 1.15);
  });

  test('RepairFormController chặn submit khi chưa chọn máy', () async {
    final c = RepairFormController(
      repairs: _Repairs(),
      equipment: _Equipment(),
      faults: _Faults(),
      attachments: _Attachments(),
      settings: _Settings(),
    );
    expect(await c.submit(), isFalse);
    expect(c.error.value, isNotEmpty);
  });

  test('RequestDetailController load lỗi ghi error', () async {
    final repo = _Requests();
    when(() => repo.detail('r1')).thenThrow(Exception('load'));
    final c = RequestDetailController(requests: repo, id: 'r1');
    await c.load();
    expect(c.error.value, isNotNull);
  });

  test('RequestsListController load thành công cập nhật tổng', () async {
    final repo = _Requests();
    when(
      () => repo.list(pendingForMe: true, limit: 30),
    ).thenAnswer((_) async => const RequestPage(items: [], total: 4));
    final c = RequestsListController(requests: repo);
    await c.load();
    expect(c.total.value, 4);
    expect(c.error.value, isNull);
  });

  test('OfflineDataController load danh sách local rỗng', () async {
    final store = _Store();
    when(store.downloadedSessions).thenAnswer((_) async => const []);
    final c = OfflineDataController(store: store, outbox: _Outbox());
    await c.load();
    expect(c.sessions, isEmpty);
    expect(c.error.value, isNull);
  });

  test('StocktakesController load lỗi ghi error', () async {
    final repo = _Stocktakes();
    when(() => repo.list(status: 'open,counting')).thenThrow(Exception('load'));
    final c = StocktakesController(repo: repo, store: _Store());
    await c.load();
    expect(c.error.value, isNotNull);
  });

  test('AiController tạo và xoá hội thoại local', () {
    final c = AiController(repo: _Ai());
    final conversation = c.newConversation(title: 'Test');
    expect(c.current.value, conversation);
    c.delete(conversation);
    expect(c.current.value, isNull);
  });

  test('MaintenanceTasksController load và chuyển TaskSummary', () async {
    final repo = _Tasks();
    when(
      () => repo.list(assigneeId: 'me', status: null, type: null, limit: 30),
    ).thenAnswer(
      (_) async => const TaskPage(
        items: [
          TaskSummary(
            id: 't1',
            code: 'BD-1',
            equipmentId: 'e1',
            scheduledAt: '2026-09-20',
            status: 'scheduled',
          ),
        ],
        total: 1,
      ),
    );
    final c = MaintenanceTasksController(tasks: repo, userId: 'u1');
    await c.load();
    expect(c.items.single.code, 'BD-1');
  });

  test('ReceiptsController load lỗi ghi error', () async {
    final repo = _Stock();
    when(
      () => repo.receipts(status: null, limit: 30),
    ).thenThrow(Exception('load'));
    final c = ReceiptsController(stock: repo);
    await c.load();
    expect(c.error.value, isNotNull);
  });

  test('StockOverviewController vẫn có dữ liệu khi một nguồn lỗi', () async {
    final stock = _Stock();
    final requests = _Requests();
    when(
      () => stock.alerts(resolved: false, type: any(named: 'type'), limit: 1),
    ).thenAnswer((_) async => const StockAlertPage(items: [], total: 2));
    when(
      () => requests.list(status: 'approved,partially_approved', limit: 1),
    ).thenThrow(Exception('requests'));
    final c = StockOverviewController(stock: stock, requests: requests);
    await c.load();
    expect(c.totalOf('low_stock'), 2);
    expect(c.error.value, isNull);
  });

  test('StockLookupController tìm cả vật tư và lô', () async {
    final supplies = _Supplies();
    final stock = _Stock();
    when(
      () => supplies.list(q: 'VT', limit: 20),
    ).thenAnswer((_) async => const SupplyPage(items: [], total: 0));
    when(
      () => stock.lots(q: 'VT', limit: 20),
    ).thenAnswer((_) async => const StockLotPage(items: [], total: 0));
    when(
      () => stock.lots(barcode: 'VT', limit: 20),
    ).thenAnswer((_) async => const StockLotPage(items: [], total: 0));
    final c = StockLookupController(
      supplies: supplies,
      stock: stock,
      equipment: _Equipment(),
    );
    await c.search('VT');
    expect(c.searched.value, isTrue);
    expect(c.error.value, isNull);
  });

  test('IssuesController load thành công cập nhật tổng', () async {
    final repo = _Stock();
    when(
      () => repo.issues(status: null, limit: 30),
    ).thenAnswer((_) async => const StockIssuePage(items: [], total: 3));
    final c = IssuesController(stock: repo);
    await c.load();
    expect(c.total.value, 3);
  });

  test('IssueFormController chặn lưu khi thiếu kho và dòng', () async {
    final c = IssueFormController(
      stock: _Stock(),
      supplies: _Supplies(),
      departments: _Departments(),
      catalogs: _Catalogs(),
    );
    expect(await c.save(), isFalse);
    expect(c.error.value, isNotEmpty);
  });

  test('TransferFormController chặn gửi khi thiếu hai kho', () async {
    final c = TransferFormController(stock: _Stock(), catalogs: _Catalogs());
    expect(await c.submit(), isFalse);
    expect(c.error.value, isNotEmpty);
  });

  test('SupplyDetailController load lỗi ghi error', () async {
    final supplies = _Supplies();
    when(() => supplies.byId('s1')).thenThrow(Exception('load'));
    final c = SupplyDetailController(
      supplies: supplies,
      stock: _Stock(),
      id: 's1',
    );
    await c.load();
    expect(c.error.value, isNotNull);
  });

  test('ReportsController báo lỗi khi mọi nguồn đều thất bại', () async {
    final equipment = _Equipment();
    final repairs = _Repairs();
    final stock = _Stock();
    when(
      () => equipment.count(status: any(named: 'status')),
    ).thenThrow(Exception('equipment'));
    when(
      () => repairs.stats(
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    ).thenThrow(Exception('stats'));
    when(repairs.workload).thenThrow(Exception('workload'));
    when(
      () => stock.alerts(resolved: false, limit: 1),
    ).thenThrow(Exception('alerts'));
    final c = ReportsController(
      equipment: equipment,
      repairs: repairs,
      stock: stock,
      departments: _Departments(),
      cache: _Cache(),
    );
    await c.load();
    expect(c.error.value, isNotNull);
  });
}
