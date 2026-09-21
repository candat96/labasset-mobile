import 'package:dio/dio.dart';

import '../api/endpoints.dart';
import '../models/report.dart';

class ReportsRepository {
  ReportsRepository(this._dio);
  final Dio _dio;

  Future<DashboardResponse> dashboard() async {
    final res = await _dio.get<Map<String, dynamic>>(Ep.dashboard);
    return DashboardResponse.fromJson(res.data!);
  }

  Future<List<ReportMeta>> list() async {
    final res = await _dio.get<List<dynamic>>(Ep.reports);
    return (res.data ?? const [])
        .whereType<Map>()
        .map((e) => ReportMeta.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<ReportExport> export(
    String key, {
    required String format,
    String? departmentId,
    String? from,
    String? to,
  }) async {
    final res = await _dio.get<List<int>>(
      Ep.report(key),
      queryParameters: {
        'format': format,
        'departmentId': ?departmentId,
        'from': ?from,
        'to': ?to,
      },
      options: Options(responseType: ResponseType.bytes),
    );
    final disposition = res.headers.value('content-disposition') ?? '';
    final match = RegExp(r'filename="?([^";]+)').firstMatch(disposition);
    return ReportExport(
      bytes: res.data ?? const [],
      fileName: match?.group(1) ?? '$key.$format',
    );
  }
}
