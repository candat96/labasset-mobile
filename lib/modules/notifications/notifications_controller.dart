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

  Future<void> markAllRead() async {
    try {
      await repo.markAllRead();
      await reload(silent: true);
    } catch (e) {
      AppSnackbar.error(e);
    }
  }

  /// Mở đối tượng liên quan: chỉ map các path mobile hỗ trợ.
  Future<void> open(NotificationItem n) async {
    await markRead(n);
    final path = n.data?['path'];
    if (path == null) return;
    final route = mapPath(path);
    if (route != null) await Get.toNamed(route);
  }

  static String? mapPath(String path) {
    final eq = RegExp(r'^/equipment/([^/]+)$').firstMatch(path);
    if (eq != null) return Routes.equipment(eq.group(1)!);
    final first = path.split('/').where((s) => s.isNotEmpty).firstOrNull;
    if (first == null) return null;
    const known = {
      'repairs': 'repairs',
      'maintenance': 'maintenance',
      'calibrations': 'maintenance',
      'stock': 'stock',
      'supplies': 'stock',
      'requests': 'requests',
      'stocktakes': 'stocktake',
    };
    final key = known[first];
    return key == null ? null : Routes.placeholderFor(key);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.onClose();
  }
}
