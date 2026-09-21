import 'package:dio/dio.dart';

import '../api/endpoints.dart';
import '../models/department.dart';
import '../models/room.dart';

/// Danh mục dùng chung (`/v1/catalogs/<slug>`) — trả `code — name`.
class CatalogsRepository {
  CatalogsRepository(this._dio);
  final Dio _dio;

  /// Danh sách phòng (`rooms`). `includeShared` = lấy cả phòng dùng chung
  /// (`departmentId = null`); `all=true` → API trả mảng đầy đủ.
  Future<List<RoomRef>> rooms({
    String? departmentId,
    String? q,
    bool includeShared = true,
  }) async {
    final res = await _dio.get<dynamic>(
      Ep.catalogRooms,
      queryParameters: {
        'departmentId': ?departmentId,
        if (q != null && q.isNotEmpty) 'q': q,
        'includeShared': includeShared,
        'all': true,
      },
    );
    final data = res.data;
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(RoomRef.fromJson)
          .toList();
    }
    final items = (data as Map<String, dynamic>)['items'] as List<dynamic>?;
    return (items ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(RoomRef.fromJson)
        .toList();
  }

  /// Tạo phòng nhanh (`POST /v1/catalogs/rooms`).
  Future<RoomRef> createRoom({
    String? code,
    required String name,
    String? departmentId,
    String? building,
    String? floor,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      Ep.catalogRooms,
      data: {
        if (code != null && code.trim().isNotEmpty) 'code': code.trim(),
        'name': name,
        'departmentId': ?departmentId,
        if (building != null && building.trim().isNotEmpty)
          'building': building.trim(),
        if (floor != null && floor.trim().isNotEmpty) 'floor': floor.trim(),
      },
    );
    return RoomRef.fromJson(res.data!);
  }

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
