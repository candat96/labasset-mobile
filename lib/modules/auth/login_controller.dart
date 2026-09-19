import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/config/env.dart';
import '../../core/errors/api_error.dart';
import '../../core/routes/app_routes.dart';
import '../../core/storage/session_store.dart';
import '../../data/models/login_result.dart';
import '../../data/repositories/auth_repository.dart';

class LoginController extends GetxController {
  LoginController({
    required this.auth,
    required this.store,
    Dio? dio,
    Future<void> Function(String route, Map<String, dynamic> args)? push,
    Future<void> Function(String route)? replaceAll,
  }) : _dio = dio,
       _push = push ?? ((r, a) async => Get.toNamed(r, arguments: a)),
       _replaceAll = replaceAll ?? ((r) async => Get.offAllNamed(r));

  final AuthRepository auth;
  final SessionStore store;
  final Dio? _dio;
  final Future<void> Function(String route, Map<String, dynamic> args) _push;
  final Future<void> Function(String route) _replaceAll;

  final formKey = GlobalKey<FormState>();
  final hospitalCode = TextEditingController();
  final username = TextEditingController();
  final password = TextEditingController();

  final RxnString tenantMode = RxnString();
  final RxBool submitting = false.obs;
  final RxnString error = RxnString();
  final RxnString notice = RxnString();

  bool get isMulti => tenantMode.value != 'single';

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    final reason =
        (args is Map ? args['reason'] as String? : null) ??
        store.lastLogoutReason;
    if (reason != null && reason != 'manual') {
      final key = 'auth.login.$reason';
      final t = key.tr;
      notice.value = t == key ? null : t;
    }
    _resolveMode();
  }

  Future<void> _resolveMode() async {
    if (Env.tenantMode.value != null) {
      tenantMode.value = Env.tenantMode.value;
      return;
    }
    final dio = _dio ?? (Get.isRegistered<Dio>() ? Get.find<Dio>() : null);
    if (dio == null) return;
    tenantMode.value = await Env.resolveTenantMode(dio);
  }

  @override
  void onClose() {
    hospitalCode.dispose();
    username.dispose();
    password.dispose();
    super.onClose();
  }

  String? requiredValidator(String? v) =>
      (v == null || v.trim().isEmpty) ? 'auth.login.required'.tr : null;

  /// otpToken gần nhất (phục vụ test và điều hướng).
  String? lastOtpToken;

  Future<void> submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    await submitUnchecked();
  }

  /// Gửi đăng nhập không qua validate Form (đã validate hoặc test unit).
  Future<void> submitUnchecked() async {
    error.value = null;
    submitting.value = true;
    try {
      final outcome = await auth.login(
        hospitalCode: isMulti ? hospitalCode.text.trim().toUpperCase() : null,
        username: username.text.trim(),
        password: password.text,
        deviceInfo: _deviceInfo(),
      );
      switch (outcome) {
        case OtpRequired(:final challenge):
          lastOtpToken = challenge.otpToken;
          await _push(Routes.otp, {
            'otpToken': challenge.otpToken,
            'returnTo': _returnTo(),
          });
        case LoggedIn(:final result):
          await store.saveSession(result);
          await _replaceAll(_returnTo());
      }
    } catch (e) {
      error.value = ApiError.messageFor(e);
    } finally {
      submitting.value = false;
    }
  }

  String _returnTo() {
    final args = Get.arguments;
    final r = args is Map ? args['returnTo'] as String? : null;
    return (r != null && r.startsWith('/') && r != Routes.login)
        ? r
        : Routes.shell;
  }

  static String _deviceInfo() {
    try {
      return '${Platform.operatingSystem} ${Platform.operatingSystemVersion}'
          .substring(0, 60);
    } catch (_) {
      return Platform.operatingSystem;
    }
  }
}
