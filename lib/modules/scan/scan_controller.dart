import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/errors/api_error.dart';
import '../../core/routes/app_routes.dart';
import '../../data/repositories/equipment_repository.dart';

/// Quét QR/barcode → tra máy → mở hồ sơ. Chống quét lặp 1,5 s.
class ScanController extends GetxController {
  ScanController({
    required this.equipment,
    Future<void> Function(String route)? navigate,
  }) : _navigate = navigate ?? ((r) async => Get.toNamed(r));

  final EquipmentRepository equipment;
  final Future<void> Function(String route) _navigate;

  final manual = TextEditingController();
  final RxBool busy = false.obs;
  final RxnString message = RxnString();
  final RxBool torch = false.obs;

  DateTime? _lastScan;

  /// Trả id máy nếu tìm thấy (null nếu không); dùng cho cả quét và nhập tay.
  Future<String?> lookup(String raw) async {
    final code = raw.trim();
    if (code.isEmpty || busy.value) return null;
    busy.value = true;
    message.value = null;
    try {
      String? id;
      try {
        id = (await equipment.byQr(code)).id;
      } catch (e) {
        final err = ApiError.from(e);
        if (err.status != 404 && err.status != 400) rethrow;
        // Không phải token QR → thử coi là mã máy (barcode).
        final page = await equipment.search(code, limit: 5);
        final upper = code.toUpperCase();
        for (final it in page.items) {
          if (it.code.toUpperCase() == upper) {
            id = it.id;
            break;
          }
        }
      }
      if (id == null) {
        message.value = 'scan.notFound'.tr;
        return null;
      }
      await _navigate(Routes.equipment(id));
      return id;
    } catch (e) {
      message.value = ApiError.messageFor(e);
      return null;
    } finally {
      busy.value = false;
    }
  }

  Future<void> onDetected(String? value) async {
    if (value == null || value.isEmpty) return;
    final now = DateTime.now();
    if (_lastScan != null &&
        now.difference(_lastScan!) < const Duration(milliseconds: 1500)) {
      return;
    }
    _lastScan = now;
    unawaited(HapticFeedback.mediumImpact());
    await lookup(value);
  }

  Future<void> submitManual() => lookup(manual.text);

  @override
  void onClose() {
    manual.dispose();
    super.onClose();
  }
}
