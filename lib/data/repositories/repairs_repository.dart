import 'package:dio/dio.dart';

import '../api/endpoints.dart';
import '../models/repair.dart';

class RepairsRepository {
  RepairsRepository(this._dio);
  final Dio _dio;

  Future<RepairPage> list({
    String? q,
    String? status,
    String? assigneeId,
    String? equipmentId,
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      Ep.repairs,
      queryParameters: {
        if (q != null && q.isNotEmpty) 'q': q,
        if (status != null && status.isNotEmpty) 'status': status,
        if (assigneeId != null && assigneeId.isNotEmpty)
          'assigneeId': assigneeId,
        if (equipmentId != null && equipmentId.isNotEmpty)
          'equipmentId': equipmentId,
        'page': page,
        'limit': limit,
      },
    );
    return RepairPage.fromJson(res.data!);
  }
}
