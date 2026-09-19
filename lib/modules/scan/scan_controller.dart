import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../core/cache/kv_cache.dart';
import '../../core/errors/api_error.dart';
import '../../core/routes/app_routes.dart';
import '../../data/models/stock.dart';
import '../../data/repositories/equipment_repository.dart';
import '../../data/repositories/stock_repository.dart';

/// Quét QR/barcode: tra máy → mở hồ sơ; không thấy máy → tra lô vật tư;
/// chế độ liên tục thì gom mã. Lịch sử 10 mã gần nhất lưu cache.
class ScanController extends GetxController {
  ScanController({
    required this.equipment,
    this.stock,
    this.cache,
    Future<void> Function(String route)? navigate,
    void Function(Object? result)? pop,
    this.onLot,
    this.continuous = false,
    this.onCode,
  }) : _navigate = navigate ?? ((r) async => Get.toNamed(r)),
       _pop = pop ?? ((r) => Get.back(result: r));

  final EquipmentRepository equipment;
  final StockRepository? stock;
  final KvCache? cache;
  final Future<void> Function(String route) _navigate;
  final void Function(Object? result) _pop;
  final Future<void> Function(StockLotSummary lot)? onLot;

  /// Quét liên tục: không tra/mở hồ sơ, gom mã + đếm + rung/tiếng.
  final bool continuous;
  final Future<void> Function(String code)? onCode;

  static const historyKey = 'scan.history';

  final manual = TextEditingController();
  final RxBool busy = false.obs;
  final RxnString message = RxnString();
  final RxBool torch = false.obs;
  final RxInt scanCount = 0.obs;
  final RxList<String> recentCodes = <String>[].obs;
  final RxList<String> history = <String>[].obs;

  DateTime? _lastScan;

  @override
  void onInit() {
    super.onInit();
    unawaited(_loadHistory());
  }

  /// Mã QR tem máy là `labasset://eq/<token>`; endpoint chỉ nhận token.
  static String qrToken(String raw) {
    final trimmed = raw.trim();
    final m = RegExp(r'^labasset://eq/(.+)$').firstMatch(trimmed);
    return m?.group(1) ?? trimmed;
  }

  /// Trả id máy nếu tìm thấy (null nếu không); không thấy máy thì thử lô vật tư.
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
      if (id != null) {
        await _remember(code);
        await _navigate(Routes.equipment(id));
        return id;
      }
      final lot = await lookupLot(code);
      if (lot != null) {
        await _remember(code);
        if (onLot != null) await onLot!(lot);
        return null;
      }
      message.value = 'scan.notFound'.tr;
      return null;
    } catch (e) {
      message.value = ApiError.messageFor(e);
      return null;
    } finally {
      busy.value = false;
    }
  }

  /// Tra lô vật tư theo mã quét (khớp chính xác `lotNo`, hoặc duy nhất 1 kết quả).
  Future<StockLotSummary?> lookupLot(String raw) async {
    final repo = stock;
    if (repo == null) return null;
    final code = qrToken(raw);
    if (code.isEmpty) return null;
    try {
      final page = await repo.lots(q: code, limit: 5);
      final upper = code.toUpperCase();
      for (final lot in page.items) {
        if (lot.lotNo.toUpperCase() == upper) return lot;
      }
      return page.items.length == 1 ? page.items.first : null;
    } catch (_) {
      return null; // tra lô là best-effort
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
    await _remember(code);
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
      HapticFeedback.mediumImpact().ignore();
      await lookup(value);
    }
  }

  Future<void> submitManual() =>
      continuous ? addCode(manual.text) : lookup(manual.text);

  /// Kết thúc quét liên tục: trả danh sách mã cho màn gọi.
  void finish() => _pop(recentCodes.toList());

  Future<void> _remember(String code) async {
    history.remove(code);
    history.insert(0, code);
    if (history.length > 10) history.removeLast();
    try {
      await cache?.put(historyKey, {'codes': history.toList()});
    } catch (_) {
      // best-effort
    }
  }

  Future<void> _loadHistory() async {
    try {
      final cached = await cache?.get(historyKey);
      final codes = cached?.value['codes'];
      if (codes is List) {
        history.assignAll(codes.whereType<String>());
      }
    } catch (_) {
      // cache hỏng → bỏ qua
    }
  }

  @override
  void onClose() {
    manual.dispose();
    super.onClose();
  }
}
