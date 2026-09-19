import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../core/storage/session_store.dart';
import '../../data/repositories/device_repository.dart';
import 'notifications_controller.dart';

/// FCM khung: chỉ hoạt động khi đã thêm google-services.json / GoogleService-Info.plist.
/// Thiếu cấu hình → `available=false`, app dùng polling.
class PushService extends GetxService {
  PushService({required this.devices, required this.store});

  final DeviceRepository devices;
  final SessionStore store;

  final RxBool available = false.obs;
  StreamSubscription<RemoteMessage>? _onMessage;
  StreamSubscription<RemoteMessage>? _onOpened;
  StreamSubscription<String>? _onToken;

  Future<PushService> init() async {
    try {
      await Firebase.initializeApp();
      available.value = true;
    } catch (e) {
      debugPrint('[push] Firebase chưa cấu hình, dùng polling: $e');
      return this;
    }
    ever(store.user, (u) => u == null ? _unregister() : _register());
    if (store.isLoggedIn) await _register();
    return this;
  }

  Future<void> _register() async {
    if (!available.value) return;
    try {
      final fm = FirebaseMessaging.instance;
      final perm = await fm.requestPermission();
      if (perm.authorizationStatus == AuthorizationStatus.denied) return;
      final token = await fm.getToken();
      if (token != null) await _sendToken(token);
      _onToken ??= fm.onTokenRefresh.listen(_sendToken);
      _onMessage ??= FirebaseMessaging.onMessage.listen((m) {
        if (Get.isRegistered<NotificationsController>()) {
          unawaited(Get.find<NotificationsController>().reload(silent: true));
        }
        final title = m.notification?.title;
        if (title != null) Get.snackbar(title, m.notification?.body ?? '');
      });
      _onOpened ??= FirebaseMessaging.onMessageOpenedApp.listen((m) {
        final path = m.data['path'] as String?;
        final route = path == null
            ? null
            : NotificationsController.mapPath(path);
        if (route != null) Get.toNamed(route);
      });
    } catch (e) {
      debugPrint('[push] đăng ký thất bại: $e');
    }
  }

  Future<void> _sendToken(String token) async {
    try {
      await devices.register(token, Platform.isIOS ? 'ios' : 'android');
      await store.setPushToken(token);
    } catch (e) {
      debugPrint('[push] gửi token thất bại: $e');
    }
  }

  /// Gọi TRƯỚC khi xoá phiên (cần token xác thực).
  Future<void> unregisterBeforeLogout() async {
    final t = store.pushToken;
    if (t == null) return;
    try {
      await devices.unregister(t);
    } catch (_) {
      // best-effort
    }
    await store.setPushToken(null);
  }

  Future<void> _unregister() async {
    await _onMessage?.cancel();
    await _onOpened?.cancel();
    _onMessage = null;
    _onOpened = null;
  }
}
