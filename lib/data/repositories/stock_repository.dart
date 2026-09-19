import 'package:dio/dio.dart';

import '../api/endpoints.dart';
import '../models/stock.dart';

class StockRepository {
  StockRepository(this._dio);
  final Dio _dio;

  Future<StockAlertPage> alerts({
    bool? resolved,
    String? type,
    String? supplyId,
    int page = 1,
    int limit = 20,
  }) async {
    final t = _nonEmpty(type);
    final sid = _nonEmpty(supplyId);
    final res = await _dio.get<Map<String, dynamic>>(
      Ep.stockAlerts,
      queryParameters: {
        'resolved': ?resolved,
        'type': ?t,
        'supplyId': ?sid,
        'page': page,
        'limit': limit,
      },
    );
    return StockAlertPage.fromJson(res.data!);
  }

  Future<StockLotPage> lots({
    String? q,
    String? supplyId,
    String? warehouseId,
    String? status,
    bool? belowMin,
    int page = 1,
    int limit = 20,
  }) async {
    final query = _nonEmpty(q);
    final sid = _nonEmpty(supplyId);
    final wid = _nonEmpty(warehouseId);
    final st = _nonEmpty(status);
    final res = await _dio.get<Map<String, dynamic>>(
      Ep.stockLots,
      queryParameters: {
        'q': ?query,
        'supplyId': ?sid,
        'warehouseId': ?wid,
        'status': ?st,
        'belowMin': ?belowMin,
        'page': page,
        'limit': limit,
      },
    );
    return StockLotPage.fromJson(res.data!);
  }

  /// Mở nắp lô (hoá chất): POST /v1/stock/lots/:id/open.
  Future<void> openLot(String id) => _dio.post<void>(Ep.stockLotOpen(id));
}

String? _nonEmpty(String? v) => v == null || v.isEmpty ? null : v;
