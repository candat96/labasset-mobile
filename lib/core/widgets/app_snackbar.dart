import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../errors/api_error.dart';

class AppSnackbar {
  AppSnackbar._();

  static void success(String message) => _show(message, _success);

  static void error(Object e) => _show(ApiError.messageFor(e), _danger);

  static void info(String message) => _show(message, _neutral);

  /// Màu lấy trong try — Get.theme ném khi chưa runApp (unit test).
  static Color? get _success {
    try {
      return Get.theme.colorScheme.primary;
    } catch (_) {
      return null;
    }
  }

  static Color? get _danger {
    try {
      return Get.theme.colorScheme.error;
    } catch (_) {
      return null;
    }
  }

  static Color? get _neutral {
    try {
      return Get.theme.colorScheme.onSurface;
    } catch (_) {
      return null;
    }
  }

  static void _show(String message, Color? color) {
    if (color == null) return; // chưa runApp / unit test
    try {
      if (Get.context == null) return;
      Get.rawSnackbar(
        message: message,
        backgroundColor: color,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
        borderRadius: 6,
        duration: const Duration(seconds: 3),
      );
    } catch (_) {
      // Chưa có overlay (unit test / chưa runApp) → bỏ qua.
    }
  }
}
