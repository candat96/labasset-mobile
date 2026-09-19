import 'package:dio/dio.dart';

import '../api/endpoints.dart';
import '../models/equipment_extras.dart';

class FaultsRepository {
  FaultsRepository(this._dio);
  final Dio _dio;

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
