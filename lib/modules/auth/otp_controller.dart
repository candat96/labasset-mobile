import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/errors/api_error.dart';
import '../../core/routes/app_routes.dart';
import '../../core/storage/session_store.dart';
import '../../data/repositories/auth_repository.dart';

class OtpController extends GetxController {
  OtpController({required this.auth, required this.store});

  final AuthRepository auth;
  final SessionStore store;

  final formKey = GlobalKey<FormState>();
  final code = TextEditingController();
  final RxBool submitting = false.obs;
  final RxnString error = RxnString();

  String? get otpToken {
    final a = Get.arguments;
    return a is Map ? a['otpToken'] as String? : null;
  }

  String get returnTo {
    final a = Get.arguments;
    final r = a is Map ? a['returnTo'] as String? : null;
    return r ?? Routes.shell;
  }

  String? validator(String? v) =>
      RegExp(r'^\d{6}$').hasMatch(v ?? '') ? null : 'auth.otp.invalid'.tr;

  Future<void> submit() async {
    final token = otpToken;
    if (token == null || !(formKey.currentState?.validate() ?? false)) return;
    submitting.value = true;
    error.value = null;
    try {
      final r = await auth.verifyOtp(token, code.text.trim());
      await store.saveSession(r);
      await Get.offAllNamed(returnTo);
    } catch (e) {
      error.value = ApiError.messageFor(e);
    } finally {
      submitting.value = false;
    }
  }

  @override
  void onClose() {
    code.dispose();
    super.onClose();
  }
}
