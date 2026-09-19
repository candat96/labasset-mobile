import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../core/errors/api_error.dart';
import '../../core/routes/app_routes.dart';
import '../../data/repositories/equipment_repository.dart';

/// Quét QR/barcode → tra máy → mở hồ sơ (chế độ đơn) hoặc gom mã (liên tục).
class ScanController extends GetxController {
  ScanController({
    required this.equipment,
    Future<void> Function(String route)? navigate,
    void Function(Object? result)? pop,
    this.continuous = false,
    this.onCode,
  }) : _navigate = navigate ?? ((r) async => Get.toNamed(r)),
       _pop = pop ?? ((r) => Get.back(result: r));

  final EquipmentRepository equipment;
  final Future<void> Function(String route) _navigate;
  final void Function(Object? result) _pop;

  /// Quét liên tục: không tra/mở hồ sơ, gom mã + đếm + rung/tiếng.
  final bool continuous;
  final Future<void> Function(String code)? onCode;

  final manual = TextEditingController();
  final RxBool busy = false.obs;
  final RxnString message = RxnString();
  final RxBool torch = false.obs;
  final RxInt scanCount = 0.obs;
  final RxList<String> recentCodes = <String>[].obs;

  DateTime? _lastScan;

  /// Mã QR tem máy là `labasset://eq/<token>`; endpoint chỉ nhận token.
  static String qrToken(String raw) {
    final trimmed = raw.trim();
    final m = RegExp(r'^labasset://eq/(.+)$').firstMatch(trimmed);
    return m?.group(1) ?? trimmed;
  }

  /// Trả id máy nếu tìm thấy (null nếu không); dùng cho cả quét và nhập tay.
  Future<String?> lookup(String raw) async {
    final code = qrToken(raw);
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

  /// Thêm một mã vào danh sách quét liên tục (không gọi API).
  Future<void> addCode(String raw) async {
    final code = raw.trim();
    if (code.isEmpty) return;
    recentCodes.remove(code);
    recentCodes.insert(0, code);
    if (recentCodes.length > 10) recentCodes.removeLast();
    scanCount.value++;
    HapticFeedback.mediumImpact().ignore();
    SystemSound.play(SystemSoundType.click).ignore();
    await onCode?.call(code);
  }

  void removeCode(String code) => recentCodes.remove(code);

  Future<void> onDetected(String? value) async {
    if (value == null || value.isEmpty) return;
    final now = DateTime.now();
    if (_lastScan != null &&
        now.difference(_lastScan!) < const Duration(milliseconds: 1500)) {
      return;
    }
    _lastScan = now;
    if (continuous) {
      await addCode(value);
    } else {
      unawaited(HapticFeedback.mediumImpact());
      await lookup(value);
    }
  }

  Future<void> submitManual() =>
      continuous ? addCode(manual.text) : lookup(manual.text);

  /// Kết thúc quét liên tục: trả danh sách mã cho màn gọi.
  void finish() => _pop(recentCodes.toList());

  @override
  void onClose() {
    manual.dispose();
    super.onClose();
  }
}
