import 'package:dio/dio.dart';

import '../api/endpoints.dart';
import '../models/equipment_extras.dart';
import '../models/repair_detail.dart';

class FaultsRepository {
  FaultsRepository(this._dio);
  final Dio _dio;

  /// `GET /v1/faults/suggest` — gợi ý lỗi theo máy/mã lỗi/mô tả.
  Future<List<FaultSuggestionMatch>> suggest({
    required String equipmentId,
    String? errorCode,
    String? q,
  }) async {
    final res = await _dio.get<List<dynamic>>(
      Ep.faultsSuggest,
      queryParameters: {
        'equipmentId': equipmentId,
        if (errorCode != null && errorCode.isNotEmpty) 'errorCode': errorCode,
        if (q != null && q.isNotEmpty) 'q': q,
      },
    );
    return (res.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(FaultSuggestionMatch.fromJson)
        .toList();
  }

  Future<FaultPage> list({
    String? model,
    String? q,
    String status = 'published',
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      Ep.faults,
      queryParameters: {
        if (model != null && model.isNotEmpty) 'model': model,
        if (q != null && q.isNotEmpty) 'q': q,
        if (status.isNotEmpty) 'status': status,
        'page': page,
        'limit': limit,
      },
    );
    return FaultPage.fromJson(res.data!);
  }
}
