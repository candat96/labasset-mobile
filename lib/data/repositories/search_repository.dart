import 'package:dio/dio.dart';

import '../api/endpoints.dart';
import '../models/global_search.dart';

class SearchRepository {
  SearchRepository(this._dio);
  final Dio _dio;

  Future<GlobalSearchResponse> search(String q, {int limit = 5}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      Ep.search,
      queryParameters: {'q': q, 'limit': limit},
    );
    return GlobalSearchResponse.fromJson(res.data!);
  }
}
