import 'package:dio/dio.dart';

import '../api/endpoints.dart';
import '../models/request.dart';

class RequestsRepository {
  RequestsRepository(this._dio);
  final Dio _dio;

  Future<RequestPage> list({
    String? q,
    String? status,
    bool pendingForMe = false,
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      Ep.requests,
      queryParameters: {
        if (q != null && q.isNotEmpty) 'q': q,
        if (status != null && status.isNotEmpty) 'status': status,
        if (pendingForMe) 'pendingFor': 'me',
        'page': page,
        'limit': limit,
      },
    );
    return RequestPage.fromJson(res.data!);
  }
}
