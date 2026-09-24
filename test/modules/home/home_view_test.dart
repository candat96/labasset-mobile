import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:labasset_mobile/core/storage/session_store.dart';
import 'package:labasset_mobile/data/models/demand.dart';
import 'package:labasset_mobile/data/models/my_tasks.dart';
import 'package:labasset_mobile/data/repositories/me_repository.dart';
import 'package:labasset_mobile/data/repositories/notifications_repository.dart';
import 'package:labasset_mobile/data/repositories/settings_repository.dart';
import 'package:labasset_mobile/modules/home/home_controller.dart';
import 'package:labasset_mobile/modules/home/home_view.dart';
import 'package:labasset_mobile/modules/notifications/notifications_controller.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_helpers.dart';

class _Me extends Mock implements MeRepository {}

class _Settings extends Mock implements SettingsRepository {}

class _Notifications extends Mock implements NotificationsRepository {}

const _emptyTasks = MyTasksResponse(
  repairs: RepairTasks(assigned: 0, pendingResponse: 0, overdue: 0),
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
  demand: DemandTasks(toSubmit: 0, toApprove: 0, toAccept: 0),
);

void main() {
  setUp(() {
    Get.testMode = true;
  });
  tearDown(Get.reset);

  Future<void> pumpHome(WidgetTester tester, List<String> roles) async {
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = fakeStore()..user.value = fakeUser(roles: roles);
    Get.put<SessionStore>(store);
    final me = _Me();
    when(me.tasks).thenAnswer((_) async => _emptyTasks);
    final settings = _Settings();
    when(settings.hospitalName).thenAnswer((_) async => null);
    Get.put(HomeController(me: me, settings: settings));
    Get.put(NotificationsController(repo: _Notifications(), store: store));

    await tester.pumpWidget(wrap(const HomeView()));
    await tester.pumpAndSettle();
  }

  testWidgets('DEPT_HEAD: lối tắt khoa, ẩn nghiệp vụ kho', (tester) async {
    await pumpHome(tester, const ['DEPT_HEAD']);

    expect(find.text('Dự trù'), findsOneWidget);
    expect(find.text('Phiếu yêu cầu'), findsOneWidget);
    expect(find.text('Thiết bị'), findsOneWidget);
    expect(find.text('Xuất kho'), findsNothing);
    expect(find.text('Nhập kho'), findsNothing);
    expect(find.text('Kiểm kê'), findsNothing);
    expect(find.text('Báo cáo nhanh'), findsNothing);
    expect(find.text('Tiếp nhận máy mới'), findsNothing);
  });

  testWidgets('ADM: giữ lối tắt kho, không có Phiếu yêu cầu', (tester) async {
    await pumpHome(tester, const ['HOSPITAL_ADMIN']);

    expect(find.text('Nhập kho'), findsOneWidget);
    expect(find.text('Xuất kho'), findsOneWidget);
    expect(find.text('Dự trù'), findsOneWidget);
    expect(find.text('Phiếu yêu cầu'), findsNothing);
  });
}
