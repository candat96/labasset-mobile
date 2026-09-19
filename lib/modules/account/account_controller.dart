import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/routes/app_routes.dart';
import '../../core/storage/session_store.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/confirm_sheet.dart';
import '../../data/repositories/auth_repository.dart';

class AccountController extends GetxController {
  AccountController({
    required this.store,
    required this.auth,
    LocalAuthentication? localAuth,
  }) : _localAuth = localAuth ?? LocalAuthentication();

  final SessionStore store;
  final AuthRepository auth;
  final LocalAuthentication _localAuth;

  final RxBool biometricSupported = false.obs;

  @override
  void onInit() {
    super.onInit();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    try {
      biometricSupported.value =
          await _localAuth.isDeviceSupported() &&
          await _localAuth.canCheckBiometrics;
    } catch (_) {
      biometricSupported.value = false;
    }
  }

  Future<void> setBiometric(bool v) async {
    if (v) {
      try {
        final ok = await _localAuth.authenticate(
          localizedReason: 'lock.reason'.tr,
        );
        if (!ok) return;
      } catch (_) {
        AppSnackbar.info('account.biometricUnavailable'.tr);
        return;
      }
    }
    await store.setBiometric(v);
  }

  Future<void> setTheme(ThemeMode m) => store.setThemeMode(m);

  Future<void> setTextScale(bool large) =>
      store.setTextScale(large ? 1.15 : 1.0);

  Future<void> logout() async {
    final ok = await ConfirmSheet.show(
      title: 'auth.logoutConfirm'.tr,
      confirmLabel: 'auth.logout'.tr,
      destructive: true,
    );
    if (!ok) return;
    try {
      await auth.logout(all: false, refreshToken: store.refreshToken);
    } catch (_) {
      // best-effort
    }
    await store.clear(reason: 'manual');
    await Get.offAllNamed(Routes.login);
  }
}
