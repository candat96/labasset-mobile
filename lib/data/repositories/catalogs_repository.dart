import 'package:dio/dio.dart';

import '../api/endpoints.dart';
import '../models/department.dart';

/// Danh mục dùng chung (`/v1/catalogs/<slug>`) — trả `code — name`.
class CatalogsRepository {
  CatalogsRepository(this._dio);
  final Dio _dio;

  Future<List<DepartmentRef>> list(
    String slug, {
    String? q,
    int limit = 20,
  }) async {
    final path = Ep.catalog(slug);
    if (path == null) return const [];
    final res = await _dio.get<dynamic>(
      path,
      queryParameters: {
        if (q != null && q.isNotEmpty) 'q': q,
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
