import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/routes/app_routes.dart';
import '../../core/storage/session_store.dart';

/// Khoá màn hình bằng sinh trắc khi app quay lại sau > [threshold] nền.
class LockController extends GetxService with WidgetsBindingObserver {
  LockController({
    required this.store,
    LocalAuthentication? localAuth,
    this.threshold = const Duration(seconds: 30),
  }) : _localAuth = localAuth ?? LocalAuthentication();

  final SessionStore store;
  final LocalAuthentication _localAuth;
  final Duration threshold;

  DateTime? _pausedAt;
  bool _locked = false;
  int failures = 0;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final p = _pausedAt;
      _pausedAt = null;
      if (p != null && DateTime.now().difference(p) >= threshold) {
        lockIfNeeded();
      }
    }
  }

  void lockIfNeeded() {
    if (_locked || !store.isLoggedIn || !store.biometricEnabled.value) return;
    _locked = true;
    failures = 0;
    Get.toNamed(Routes.lock);
  }

  Future<bool> unlock() async {
    try {
      final ok = await _localAuth.authenticate(
        localizedReason: 'lock.reason'.tr,
      );
      if (ok) {
        _locked = false;
        Get.back();
        return true;
      }
    } catch (_) {
      // rơi xuống đếm thất bại
    }
    failures++;
    if (failures >= 3) await signOut();
    return false;
  }

  Future<void> signOut() async {
    _locked = false;
    await store.clear(reason: 'locked');
    await Get.offAllNamed(Routes.login, arguments: {'reason': 'locked'});
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }
}
