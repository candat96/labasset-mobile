import 'package:dio/dio.dart';

import '../api/endpoints.dart';
import '../models/stock_extra.dart';
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

  Future<SupplySummary> byId(String id) async {
    final res = await _dio.get<Map<String, dynamic>>(Ep.supply(id));
    return SupplySummary.fromJson(res.data!);
  }

  /// Tồn theo kho/lô: `GET /v1/supplies/:id/stock`.
  Future<SupplyStock> stock(String id) async {
    final res = await _dio.get<Map<String, dynamic>>(Ep.supplyStock(id));
    return SupplyStock.fromJson(res.data!);
  }

  /// Máy tương thích: `GET /v1/supplies/:id/equipment`.
  Future<List<SupplyEquipment>> equipment(String id) async {
    final res = await _dio.get<List<dynamic>>(Ep.supplyEquipment(id));
    return (res.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(SupplyEquipment.fromJson)
        .toList();
  }
}
