import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../core/routes/app_routes.dart';
import '../../core/storage/session_store.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../data/models/notification_item.dart';
import '../../data/repositories/notifications_repository.dart';

/// Thông báo trong app: polling 60 s khi foreground (FCM chỉ kích hoạt làm mới sớm).
class NotificationsController extends GetxController
    with WidgetsBindingObserver {
  NotificationsController({
    required this.repo,
    required this.store,
    this.pollInterval = const Duration(seconds: 60),
  });

  final NotificationsRepository repo;
  final SessionStore store;
  final Duration pollInterval;

  final RxList<NotificationItem> items = <NotificationItem>[].obs;
  final RxInt unreadCount = 0.obs;
  final RxBool loading = false.obs;
  final Rxn<Object> error = Rxn<Object>();
  final RxBool onlyUnread = false.obs;

  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    ever(store.user, (u) => u == null ? stop() : start());
    if (store.isLoggedIn) start();
  }

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(pollInterval, (_) => reload(silent: true));
    unawaited(reload(silent: true));
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    items.clear();
    unreadCount.value = 0;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!store.isLoggedIn) return;
    if (state == AppLifecycleState.resumed) {
      start();
    } else if (state == AppLifecycleState.paused) {
      _timer?.cancel();
    }
  }

  Future<void> reload({bool silent = false}) async {
    if (!store.isLoggedIn) return;
    if (!silent) loading.value = true;
    try {
      final page = await repo.list(
        unread: onlyUnread.value ? true : null,
        limit: 50,
      );
      items.assignAll(page.items);
      unreadCount.value = page.unreadCount.toInt();
      error.value = null;
    } catch (e) {
      if (!silent) error.value = e;
    } finally {
      loading.value = false;
    }
  }

  Future<void> toggleUnread(bool v) async {
    onlyUnread.value = v;
    await reload();
  }

  Future<void> markRead(NotificationItem n) async {
    if (n.isRead) return;
    try {
      await repo.markRead(n.id);
      await reload(silent: true);
    } catch (e) {
      AppSnackbar.error(e);
    }
  }

  /// Vuốt trái: bỏ dòng ngay để Dismissible hoàn tất animation, sau đó đồng bộ
  /// trạng thái đọc. Ở tab Tất cả dòng sẽ trở lại dạng đã đọc sau lần tải mới.
  Future<void> dismissRead(NotificationItem n) async {
    if (n.isRead) return;
    items.removeWhere((item) => item.id == n.id);
    try {
      await repo.markRead(n.id);
      await reload(silent: true);
    } catch (e) {
      AppSnackbar.error(e);
      await reload(silent: true);
    }
  }

  Future<void> markAllRead() async {
    try {
      await repo.markAllRead();
      await reload(silent: true);
    } catch (e) {
      AppSnackbar.error(e);
    }
  }

  /// Mở đối tượng liên quan: map `data` (00 §2.10) rồi tới `path`.
  Future<void> open(NotificationItem n) async {
    await markRead(n);
    final route =
        mapData(n.data, type: n.type) ?? mapPath(n.data?['path'] ?? '');
    if (route != null) await Get.toNamed(route);
  }

  /// Map `data` thông báo → route mobile. [type] để phân biệt `demand.*`
  /// (dùng chung khoá `requestId` với phiếu yêu cầu C2).
  static String? mapData(Map<String, dynamic>? data, {String? type}) {
    if (data == null) return null;
    if (type != null && type.startsWith('demand.')) return _mapDemand(data);
    final equipmentId = data['equipmentId'];
    if (equipmentId is String && equipmentId.isNotEmpty) {
      return Routes.equipment(equipmentId);
    }
    String? value(String key) {
      final raw = data[key];
      return raw is String && raw.isNotEmpty ? raw : null;
    }

    final repairId = value('repairTicketId');
    if (repairId != null) return Routes.repair(repairId);
    final taskId = value('taskId');
    if (taskId != null) return Routes.maintenanceTask(taskId);
    final requestId = value('requestId');
    if (requestId != null) return Routes.request(requestId);
    final issueId = value('issueId');
    if (issueId != null) return Routes.stockIssue(issueId);
    final receiptId = value('receiptId');
    if (receiptId != null) return Routes.stockReceipt(receiptId);
    final sessionId = value('sessionId');
    if (sessionId != null) return Routes.stocktake(sessionId);
    final alertId = value('alertId');
    if (alertId != null) return '${Routes.stockAlerts}?alertId=$alertId';
    final supplyId = value('supplyId');
    if (supplyId != null) return Routes.supply(supplyId);
    final lotId = value('lotId');
    if (lotId != null) return '${Routes.stockLookup}?lotId=$lotId';
    return null;
  }

  /// `demand.request_*` → phiếu dự trù; `demand.period_*`/`deadline_soon` → kỳ.
  static String? _mapDemand(Map<String, dynamic> data) {
    String? str(String key) {
      final raw = data[key];
      return raw is String && raw.isNotEmpty ? raw : null;
    }

    final requestId = str('requestId');
    if (requestId != null) return Routes.demandRequest(requestId);
    final periodId = str('periodId');
    if (periodId != null) return Routes.demandPeriod(periodId);
    return Routes.demand;
  }

  static String? mapPath(String path) {
    if (path.isEmpty) return null;
    final detailRoutes = <RegExp, String Function(String)>{
      RegExp(r'^/equipment/([^/]+)$'): Routes.equipment,
      RegExp(r'^/repairs/([^/]+)$'): Routes.repair,
      RegExp(r'^/maintenance/tasks/([^/]+)$'): Routes.maintenanceTask,
      RegExp(r'^/requests/([^/]+)$'): Routes.request,
      RegExp(r'^/stock/issues/([^/]+)$'): Routes.stockIssue,
      RegExp(r'^/stock/receipts/([^/]+)$'): Routes.stockReceipt,
      RegExp(r'^/stocktakes/([^/]+)$'): Routes.stocktake,
      RegExp(r'^/supplies/([^/]+)$'): Routes.supply,
    };
    for (final entry in detailRoutes.entries) {
      final match = entry.key.firstMatch(path);
      if (match != null) return entry.value(match.group(1)!);
    }
    final first = path.split('/').where((s) => s.isNotEmpty).firstOrNull;
    if (first == null) return null;
    const known = {
      'repairs': Routes.repairs,
      'maintenance': Routes.maintenanceTasks,
      'calibrations': Routes.calibrations,
      'stock': Routes.stock,
      'supplies': Routes.stockLookup,
      'requests': Routes.requests,
      'stocktakes': Routes.stocktakes,
    };
    return known[first];
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.onClose();
  }
}
