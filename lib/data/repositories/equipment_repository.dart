import 'package:dio/dio.dart';

import '../api/endpoints.dart';
import '../models/equipment.dart';
import '../models/equipment_detail.dart';
import '../models/equipment_extras.dart';
import '../models/equipment_parts.dart';

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

  Future<EquipmentDetail> detail(String id) async {
    final res = await _dio.get<Map<String, dynamic>>(Ep.equipment(id));
    return EquipmentDetail.fromJson(res.data!);
  }

  Future<EquipmentPage> search(String q, {int limit = 5}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      Ep.equipmentList,
      queryParameters: {'q': q, 'page': 1, 'limit': limit},
    );
    return EquipmentPage.fromJson(res.data!);
  }

  /// Tổng số máy theo bộ lọc (limit 1 chỉ lấy `total`).
  Future<num> count({bool? calibrationOverdue, String? status}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      Ep.equipmentList,
      queryParameters: {
        'calibrationOverdue': ?calibrationOverdue,
        'status': ?status,
        'page': 1,
        'limit': 1,
      },
    );
    return EquipmentPage.fromJson(res.data!).total;
  }

  /// Danh sách gọn theo khoa (báo cáo thực địa) — limit tối đa 200.
  Future<EquipmentPage> listByDepartment(
    String departmentId, {
    int limit = 200,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      Ep.equipmentList,
      queryParameters: {
        'departmentId': departmentId,
        'page': 1,
        'limit': limit,
      },
    );
    return EquipmentPage.fromJson(res.data!);
  }

  Future<EquipmentDetail> create(Map<String, dynamic> data) async {
    final res = await _dio.post<Map<String, dynamic>>(
      Ep.equipmentList,
      data: data,
    );
    return EquipmentDetail.fromJson(res.data!);
  }

  /// `PATCH /:id` — không gửi `status`/`departmentId` (đổi qua hành động riêng).
  Future<void> patch(String id, Map<String, dynamic> data) =>
      _dio.patch<void>(Ep.equipment(id), data: data);

  /// Ghi chú vào timeline máy (`POST /:id/notes`, mọi role).
  Future<void> addNote(String id, String text) =>
      _dio.post<void>(Ep.equipmentNotes(id), data: {'text': text});

  Future<void> changeStatus(String id, String status, String reason) =>
      _dio.post<void>(
        Ep.equipmentStatus(id),
        data: {'status': status, 'reason': reason},
      );

  Future<void> addCounters(
    String id, {
    String? runHours,
    num? testCount,
    String? note,
    String? recordedAt,
  }) => _dio.post<void>(
    Ep.equipmentCounters(id),
    data: {
      'source': 'manual',
      'runHours': ?runHours,
      'testCount': ?testCount,
      'recordedAt': ?recordedAt,
      'note': ?note,
    },
  );

  // ── Kết nối ────────────────────────────────────────────────
  Future<EquipmentNetwork> network(String id) async {
    final res = await _dio.get<Map<String, dynamic>>(Ep.equipmentNetwork(id));
    return EquipmentNetwork.fromJson(res.data!);
  }

  Future<void> putNetwork(String id, EquipmentNetwork n) =>
      _dio.put<void>(Ep.equipmentNetwork(id), data: n.toJson());

  // ── Phụ kiện ───────────────────────────────────────────────
  Future<List<EquipmentAccessory>> accessories(String id) async {
    final res = await _dio.get<List<dynamic>>(Ep.equipmentAccessories(id));
    return _list(res, EquipmentAccessory.fromJson);
  }

  Future<void> createAccessory(String id, Map<String, dynamic> data) =>
      _dio.post<void>(Ep.equipmentAccessories(id), data: data);

  Future<void> updateAccessory(
    String id,
    String aid,
    Map<String, dynamic> data,
  ) => _dio.patch<void>(Ep.equipmentAccessory(id, aid), data: data);

  Future<void> deleteAccessory(String id, String aid) =>
      _dio.delete<void>(Ep.equipmentAccessory(id, aid));

  // ── Phần mềm ───────────────────────────────────────────────
  Future<List<EquipmentSoftware>> software(String id) async {
    final res = await _dio.get<List<dynamic>>(Ep.equipmentSoftware(id));
    return _list(res, EquipmentSoftware.fromJson);
  }

  Future<void> createSoftware(String id, Map<String, dynamic> data) =>
      _dio.post<void>(Ep.equipmentSoftware(id), data: data);

  Future<void> updateSoftware(
    String id,
    String sid,
    Map<String, dynamic> data,
  ) => _dio.patch<void>(Ep.equipmentSoftwareItem(id, sid), data: data);

  Future<void> deleteSoftware(String id, String sid) =>
      _dio.delete<void>(Ep.equipmentSoftwareItem(id, sid));

  /// `GET …/license-key` → trả key thật (hiện 10 giây ở UI).
  Future<String> licenseKey(String id, String sid) async {
    final res = await _dio.get<Map<String, dynamic>>(
      Ep.equipmentSoftwareLicenseKey(id, sid),
    );
    return (res.data?['licenseKey'] as String?) ?? '';
  }

  Future<void> upgradeSoftware(
    String id,
    String sid, {
    required String toVersion,
    String? note,
  }) => _dio.post<void>(
    Ep.equipmentSoftwareUpgrade(id, sid),
    data: {'toVersion': toVersion, 'note': ?note},
  );

  Future<List<SoftwareHistoryItem>> softwareHistory(
    String id,
    String sid,
  ) async {
    final res = await _dio.get<List<dynamic>>(
      Ep.equipmentSoftwareHistory(id, sid),
    );
    return _list(res, SoftwareHistoryItem.fromJson);
  }

  // ── Linh kiện ──────────────────────────────────────────────
  Future<List<EquipmentComponent>> components(String id) async {
    final res = await _dio.get<List<dynamic>>(Ep.equipmentComponents(id));
    return _list(res, EquipmentComponent.fromJson);
  }

  Future<void> createComponent(String id, Map<String, dynamic> data) =>
      _dio.post<void>(Ep.equipmentComponents(id), data: data);

  Future<void> replaceComponent(
    String id,
    String cid, {
    required String reason,
    String? newSerial,
    String? cost,
  }) => _dio.post<void>(
    Ep.equipmentComponentReplace(id, cid),
    data: {'reason': reason, 'newSerial': ?newSerial, 'cost': ?cost},
  );

  // ── Vật tư theo máy ────────────────────────────────────────
  Future<List<EquipmentSupplyLink>> supplies(String id) async {
    final res = await _dio.get<List<dynamic>>(Ep.equipmentSupplies(id));
    return _list(res, EquipmentSupplyLink.fromJson);
  }

  Future<void> putSupplies(String id, List<EquipmentSupplyLink> links) =>
      _dio.put<void>(
        Ep.equipmentSupplies(id),
        data: links.map((l) => l.toJson()).toList(),
      );

  Future<EquipmentRunway> runway(String id) async {
    final res = await _dio.get<Map<String, dynamic>>(Ep.equipmentRunway(id));
    return EquipmentRunway.fromJson(res.data!);
  }

  // ── Timeline ───────────────────────────────────────────────
  Future<EquipmentEventPage> events(
    String id, {
    int page = 1,
    int limit = 20,
    String? type,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      Ep.equipmentEvents(id),
      queryParameters: {'page': page, 'limit': limit, 'type': ?type},
    );
    return EquipmentEventPage.fromJson(res.data!);
  }

  // ── Điều chuyển ────────────────────────────────────────────
  Future<EquipmentTransferPage> transfers(
    String id, {
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      Ep.equipmentTransfers(id),
      queryParameters: {'page': page, 'limit': limit},
    );
    return EquipmentTransferPage.fromJson(res.data!);
  }

  Future<void> createTransfer(
    String id, {
    required String toDepartmentId,
    String? toLocation,
    required String reason,
  }) => _dio.post<void>(
    Ep.equipmentTransfers(id),
    data: {
      'toDepartmentId': toDepartmentId,
      'toLocation': ?toLocation,
      'reason': reason,
    },
  );

  Future<void> approveTransfer(String id, String tid) =>
      _dio.post<void>(Ep.equipmentTransferApprove(id, tid));

  Future<void> rejectTransfer(String id, String tid, String reason) =>
      _dio.post<void>(
        Ep.equipmentTransferReject(id, tid),
        data: {'reason': reason},
      );

  Future<void> cancelTransfer(String id, String tid) =>
      _dio.post<void>(Ep.equipmentTransferCancel(id, tid));

  static List<T> _list<T>(
    Response<List<dynamic>> res,
    T Function(Map<String, dynamic>) fromJson,
  ) =>
      (res.data ?? []).whereType<Map<String, dynamic>>().map(fromJson).toList();
}
