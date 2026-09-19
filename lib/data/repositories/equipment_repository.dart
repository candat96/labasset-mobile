import 'package:dio/dio.dart';

import '../api/endpoints.dart';
import '../models/equipment.dart';

class EquipmentRepository {
  EquipmentRepository(this._dio);
  final Dio _dio;

  Future<QrEquipment> byQr(String token) async {
    final res = await _dio.get<Map<String, dynamic>>(Ep.equipmentByQr(token));
    return QrEquipment.fromJson(res.data!);
  }

  Future<EquipmentSummary> byId(String id) async {
    final res = await _dio.get<Map<String, dynamic>>(Ep.equipment(id));
    return EquipmentSummary.fromJson(res.data!);
  }

  Future<EquipmentPage> search(String q, {int limit = 5}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      Ep.equipmentList,
      queryParameters: {'q': q, 'page': 1, 'limit': limit},
    );
    return EquipmentPage.fromJson(res.data!);
  }
}
