import 'package:dio/dio.dart';

import '../api/endpoints.dart';
import '../models/kpi.dart';

/// Hiệu suất kỹ thuật (KPI) — `/v1/performance/*`.
class KpiRepository {
  KpiRepository(this._dio);
  final Dio _dio;

  /// `/v1/performance/me` — điểm của chính mình + 6 kỳ gần nhất.
  Future<KpiPerson> me({required String type, String? start}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      Ep.performanceMe,
      queryParameters: {'type': type, 'start': ?start},
    );
    return KpiPerson.fromJson(res.data!);
  }

  /// `/v1/performance/users/:id` — chi tiết một người + danh sách đầu việc.
  Future<KpiPerson> user(
    String id, {
    required String type,
    String? start,
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      Ep.performanceUser(id),
      queryParameters: {
        'type': type,
        'start': ?start,
        'page': page,
        'limit': limit,
      },
    );
    return KpiPerson.fromJson(res.data!);
  }

  /// `/v1/performance` — bảng xếp hạng toàn viện (chỉ ADM/STAFF).
  Future<KpiBoard> board({required String type, String? start}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      Ep.performance,
      queryParameters: {'type': type, 'start': ?start},
    );
    return KpiBoard.fromJson(res.data!);
  }

  /// `/v1/performance/periods` — 12 kỳ gần nhất kèm cờ đã chốt.
  Future<KpiPeriods> periods({required String type}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      Ep.performancePeriods,
      queryParameters: {'type': type},
    );
    return KpiPeriods.fromJson(res.data!);
  }
}
