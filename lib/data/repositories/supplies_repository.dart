import 'package:dio/dio.dart';

import '../api/endpoints.dart';
import '../models/supply.dart';

class SuppliesRepository {
  SuppliesRepository(this._dio);
  final Dio _dio;

  Future<SupplyPage> list({
    String? q,
    bool? isActive,
    int page = 1,
    int limit = 20,
  }) async {
    final query = q == null || q.isEmpty ? null : q;
    final res = await _dio.get<Map<String, dynamic>>(
      Ep.supplies,
      queryParameters: {
        'q': ?query,
        'isActive': ?isActive,
        'page': page,
        'limit': limit,
      },
    );
    return SupplyPage.fromJson(res.data!);
  }
}
