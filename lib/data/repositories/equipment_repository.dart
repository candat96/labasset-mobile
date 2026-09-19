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

  /// Tổng số máy theo bộ lọc (limit 1 chỉ lấy `total`).
  Future<num> count({bool? calibrationOverdue}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      Ep.equipmentList,
      queryParameters: {
        'calibrationOverdue': ?calibrationOverdue,
        'page': 1,
        'limit': 1,
      },
    );
    return EquipmentPage.fromJson(res.data!).total;
  }

  /// Ghi chú vào timeline máy (`POST /:id/notes`, mọi role).
  Future<void> addNote(String id, String text) =>
      _dio.post<void>(Ep.equipmentNotes(id), data: {'text': text});
}
