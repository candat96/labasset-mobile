import 'dart:io';

import 'package:dio/dio.dart';
import 'package:get/get.dart';

/// Cấu hình build-time (`--dart-define`) và chế độ tenant.
class Env {
  Env._();

  static const _apiUrl = 'https://api-labasset.vattu.site';
  static const _tenantMode = String.fromEnvironment('TENANT_MODE');

  /// Emulator Android trỏ về máy host qua 10.0.2.2; iOS simulator dùng localhost.
  static String get apiUrl {
    if (_apiUrl.isNotEmpty) return _apiUrl;
    return Platform.isAndroid
        ? 'http://10.0.2.2:3969'
        : 'http://localhost:3969';
  }

  /// `multi` | `single`; null = chưa xác định.
  static final Rxn<String> tenantMode = Rxn<String>(
    _tenantMode == 'multi' || _tenantMode == 'single' ? _tenantMode : null,
  );

  static bool get isMulti => tenantMode.value != 'single';

  /// Đọc `GET /health` → `mode`; lỗi mạng → mặc định `multi`.
  static Future<String> resolveTenantMode(Dio dio) async {
    final cached = tenantMode.value;
    if (cached != null) return cached;
    var mode = 'multi';
    try {
      final res = await dio.get<Map<String, dynamic>>('/health');
      if (res.data?['mode'] == 'single') mode = 'single';
    } catch (_) {
      // giữ multi
    }
    tenantMode.value = mode;
    return mode;
  }
}
