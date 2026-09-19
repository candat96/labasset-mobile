import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../errors/api_error.dart';

class AppSnackbar {
  AppSnackbar._();

  static void success(String message) =>
      _show(message, Get.theme.colorScheme.primary);

  static void error(Object e) =>
      _show(ApiError.messageFor(e), Get.theme.colorScheme.error);

  static void info(String message) =>
      _show(message, Get.theme.colorScheme.onSurface);

  static void _show(String message, Color color) {
    if (Get.context == null) return; // chưa runApp / unit test
    try {
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
