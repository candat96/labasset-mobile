import 'package:dio/dio.dart';

import '../api/endpoints.dart';
import '../models/department.dart';

class DepartmentsRepository {
  DepartmentsRepository(this._dio);
  final Dio _dio;

  Future<List<DepartmentRef>> list({
    String? q,
    bool? isActive,
    int limit = 20,
  }) async {
    final query = q == null || q.isEmpty ? null : q;
    final res = await _dio.get<dynamic>(
      Ep.departments,
      queryParameters: {
        'q': ?query,
        'isActive': ?isActive,
        'page': 1,
        'limit': limit,
      },
    );
    final data = res.data;
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(DepartmentRef.fromJson)
          .toList();
    }
    return DepartmentPage.fromJson(data as Map<String, dynamic>).items;
  }
}
