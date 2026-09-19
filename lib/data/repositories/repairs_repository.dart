import 'package:dio/dio.dart';

import '../api/endpoints.dart';
import '../models/repair.dart';
import '../models/repair_detail.dart';

class RepairsRepository {
  RepairsRepository(this._dio);
  final Dio _dio;

  Future<RepairPage> list({
    String? q,
    String? status,
    String? assigneeId,
    String? equipmentId,
    String? severity,
    String? departmentId,
    bool? overdue,
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      Ep.repairs,
      queryParameters: {
        if (q != null && q.isNotEmpty) 'q': q,
        if (status != null && status.isNotEmpty) 'status': status,
        if (assigneeId != null && assigneeId.isNotEmpty)
          'assigneeId': assigneeId,
        if (equipmentId != null && equipmentId.isNotEmpty)
          'equipmentId': equipmentId,
        if (severity != null && severity.isNotEmpty) 'severity': severity,
        if (departmentId != null && departmentId.isNotEmpty)
          'departmentId': departmentId,
        'overdue': ?overdue,
        'page': page,
        'limit': limit,
      },
    );
    return RepairPage.fromJson(res.data!);
  }

  Future<RepairDetail> detail(String id) async {
    final res = await _dio.get<Map<String, dynamic>>(Ep.repair(id));
    return RepairDetail.fromJson(res.data!);
  }

  Future<RepairDetail> create({
    required String equipmentId,
    required String description,
    String? errorCode,
    String? severity,
    bool? equipmentDown,
    String? faultId,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      Ep.repairs,
      data: {
        'equipmentId': equipmentId,
        'description': description,
        'errorCode': ?errorCode,
        'severity': ?severity,
        'equipmentDown': ?equipmentDown,
      },
    );
    final detail = RepairDetail.fromJson(res.data!);
    if (faultId != null && faultId.isNotEmpty) {
      await _dio.patch<void>(
        Ep.repairDiagnosis(detail.id),
        data: {'diagnosis': description, 'faultId': faultId},
      );
    }
    return detail;
  }

  Future<void> accept(String id) => _dio.post<void>(Ep.repairAccept(id));

  Future<void> respondAssignment(
    String id, {
    required String response,
    String? note,
  }) => _dio.post<void>(
    Ep.repairAssignmentsRespond(id),
    data: {'response': response, 'note': ?note},
  );

  Future<void> assign(
    String id, {
    required String primaryUserId,
    List<String> assistantIds = const [],
    String? dueAt,
  }) => _dio.post<void>(
    Ep.repairAssign(id),
    data: {
      'primaryUserId': primaryUserId,
      'assistantIds': assistantIds,
      'dueAt': ?dueAt,
    },
  );

  Future<void> diagnose(
    String id, {
    required String diagnosis,
    String? faultId,
    String? faultGroupId,
    String? resolutionType,
  }) => _dio.patch<void>(
    Ep.repairDiagnosis(id),
    data: {
      'diagnosis': diagnosis,
      'faultId': ?faultId,
      'faultGroupId': ?faultGroupId,
      'resolutionType': ?resolutionType,
    },
  );

  Future<void> changeStatus(String id, String status, String note) => _dio
      .post<void>(Ep.repairStatus(id), data: {'status': status, 'note': note});

  Future<void> complete(
    String id, {
    required String resolutionSummary,
    String? postRepairWarrantyUntil,
    bool? calibrationRequired,
    Map<String, dynamic>? proposeFault,
  }) => _dio.post<void>(
    Ep.repairComplete(id),
    data: {
      'resolutionSummary': resolutionSummary,
      'postRepairWarrantyUntil': ?postRepairWarrantyUntil,
      'calibrationRequired': ?calibrationRequired,
      'proposeFault': ?proposeFault,
    },
  );

  Future<void> acceptance(
    String id, {
    required bool accepted,
    num? rating,
    String? note,
  }) => _dio.post<void>(
    Ep.repairAcceptance(id),
    data: {'accepted': accepted, 'rating': ?rating, 'note': ?note},
  );

  Future<void> close(String id) => _dio.post<void>(Ep.repairClose(id));

  Future<void> cancel(String id, String reason) =>
      _dio.post<void>(Ep.repairCancel(id), data: {'reason': reason});

  // ── Nhật ký ────────────────────────────────────────────────
  Future<List<RepairLog>> logs(String id) async {
    final res = await _dio.get<List<dynamic>>(Ep.repairLogs(id));
    return (res.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(RepairLog.fromJson)
        .toList();
  }

  /// Gửi 1 phần tử batch (clientId idempotent).
  Future<void> addLog(
    String id, {
    required String clientId,
    required String at,
    required String action,
    String? note,
    num? durationMinutes,
  }) => _dio.post<void>(
    Ep.repairLogs(id),
    data: [
      {
        'clientId': clientId,
        'at': at,
        'action': action,
        'note': ?note,
        'durationMinutes': ?durationMinutes,
      },
    ],
  );

  // ── Linh kiện / chi phí / thuê ngoài ───────────────────────
  Future<List<RepairPart>> parts(String id) async {
    final res = await _dio.get<List<dynamic>>(Ep.repairParts(id));
    return (res.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(RepairPart.fromJson)
        .toList();
  }

  Future<void> addPart(String id, Map<String, dynamic> data) =>
      _dio.post<void>(Ep.repairParts(id), data: data);

  Future<List<RepairCost>> costs(String id) async {
    final res = await _dio.get<List<dynamic>>(Ep.repairCosts(id));
    return (res.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(RepairCost.fromJson)
        .toList();
  }

  Future<void> addCost(String id, Map<String, dynamic> data) =>
      _dio.post<void>(Ep.repairCosts(id), data: data);

  Future<List<RepairVendor>> vendors(String id) async {
    final res = await _dio.get<List<dynamic>>(Ep.repairVendors(id));
    return (res.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(RepairVendor.fromJson)
        .toList();
  }

  Future<void> addVendor(String id, Map<String, dynamic> data) =>
      _dio.post<void>(Ep.repairVendors(id), data: data);

  Future<void> addSignature(
    String id, {
    required String role,
    required String signerName,
    required String fileId,
  }) => _dio.post<void>(
    Ep.repairSignatures(id),
    data: {'role': role, 'signerName': signerName, 'fileId': fileId},
  );

  Future<List<AssignSuggestItem>> assignSuggest(String equipmentId) async {
    final res = await _dio.get<List<dynamic>>(
      Ep.repairAssignSuggest,
      queryParameters: {'equipmentId': equipmentId},
    );
    return (res.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(AssignSuggestItem.fromJson)
        .toList();
  }

  /// Tải biên bản PDF về bộ nhớ app (dùng Dio có Bearer).
  Future<List<int>> reportPdf(String id) async {
    final res = await _dio.get<List<int>>(
      Ep.repairReportPdf(id),
      options: Options(responseType: ResponseType.bytes),
    );
    return res.data ?? const [];
  }
}
