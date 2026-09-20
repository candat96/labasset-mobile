import 'package:dio/dio.dart';

import '../../core/config/env.dart';
import '../api/endpoints.dart';

class SettingsRepository {
  SettingsRepository(this._dio);
  final Dio _dio;

  Map<String, dynamic>? _cache;

  /// Đọc chế độ tenant qua repository để controller không phụ thuộc Dio.
  Future<String> resolveTenantMode() => Env.resolveTenantMode(_dio);

  /// `GET /v1/settings/public` — khoá phẳng kiểu `hospital.name` (C14-C17).
  Future<Map<String, dynamic>> publicSettings({bool refresh = false}) async {
    if (!refresh && _cache != null) return _cache!;
    final res = await _dio.get<Map<String, dynamic>>(Ep.settingsPublic);
    _cache = res.data ?? const {};
    return _cache!;
  }

  Future<String?> hospitalName() async {
    try {
      final d = await publicSettings();
      final v = d['hospital.name'] ?? d['hospitalName'] ?? d['name'];
      return v is String && v.isNotEmpty ? v : null;
    } catch (_) {
      return null;
    }
  }

  /// Máy chủ đã bật push FCM chưa (kèm `FCM_ENABLED` phía API).
  Future<bool> pushEnabled() async {
    try {
      final d = await publicSettings();
      return d['pushEnabled'] == true;
    } catch (_) {
      return false;
    }
  }

  /// SLA sửa chữa theo mức khẩn (giờ): `{low, medium, high, critical}`.
  Future<Map<String, int>> repairSla() async {
    try {
      final d = await publicSettings();
      final raw = d['repairSla'];
      if (raw is! Map) return const {};
      return {
        for (final e in raw.entries)
          if (e.value is num) '${e.key}': (e.value as num).toInt(),
      };
    } catch (_) {
      return const {};
    }
  }
}
