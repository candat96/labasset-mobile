import 'package:dio/dio.dart';

import '../api/endpoints.dart';

class SettingsRepository {
  SettingsRepository(this._dio);
  final Dio _dio;

  // TODO(api): GET /v1/settings/public chưa có response schema trong OpenAPI.
  Future<String?> hospitalName() async {
    final res = await _dio.get<Map<String, dynamic>>(Ep.settingsPublic);
    final d = res.data ?? {};
    final v = d['hospitalName'] ?? d['name'];
    return v is String && v.isNotEmpty ? v : null;
  }
}
