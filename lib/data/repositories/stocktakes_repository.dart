import 'package:dio/dio.dart';

import '../api/endpoints.dart';
import '../models/stocktake.dart';

/// Kết quả tải package: 304 giữ nguyên, 200 có dữ liệu mới.
class PackageResult {
  const PackageResult({
    required this.notModified,
    this.etag,
    this.items = const [],
  });

  final bool notModified;
  final String? etag;
  final List<StocktakePackageItem> items;
}

class StocktakesRepository {
  StocktakesRepository(this._dio);
  final Dio _dio;

  Future<StocktakePage> list({String? status, String? type}) async {
    final res = await _dio.get<dynamic>(
      Ep.stocktakes,
      queryParameters: {'status': ?status, 'type': ?type, 'limit': 50},
    );
    final data = res.data;
    if (data is List) {
      return StocktakePage(
        items: data
            .whereType<Map<String, dynamic>>()
            .map(StocktakeSession.fromJson)
            .toList(),
        total: data.length,
      );
    }
    return StocktakePage.fromJson(data as Map<String, dynamic>);
  }

  Future<StocktakeSession> detail(String id) async {
    final res = await _dio.get<Map<String, dynamic>>(Ep.stocktake(id));
    return StocktakeSession.fromJson(res.data!);
  }

  /// `GET /:id/package` với `If-None-Match`.
  Future<PackageResult> package(String id, {String? etag}) async {
    final res = await _dio.get<dynamic>(
      Ep.stocktakePackage(id),
      options: Options(
        validateStatus: (s) => s == 200 || s == 304,
        headers: {if (etag != null && etag.isNotEmpty) 'If-None-Match': etag},
      ),
    );
    if (res.statusCode == 304) return const PackageResult(notModified: true);
    final data = res.data;
    final rawItems = data is Map ? data['items'] : data;
    final items = (rawItems as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(StocktakePackageItem.fromJson)
        .toList();
    return PackageResult(
      notModified: false,
      etag: res.headers.value('etag'),
      items: items,
    );
  }

  Future<StocktakeProgress> progress(String id) async {
    final res = await _dio.get<Map<String, dynamic>>(Ep.stocktakeProgress(id));
    return StocktakeProgress.fromJson(res.data!);
  }

  /// Gửi batch counts (idempotent theo `clientId`).
  Future<StocktakeCountResult> postCounts(
    String id,
    List<Map<String, dynamic>> counts,
  ) async {
    final res = await _dio.post<Map<String, dynamic>>(
      Ep.stocktakeCounts(id),
      data: {'counts': counts},
    );
    return StocktakeCountResult.fromJson(res.data ?? const {});
  }
}
