import 'package:dio/dio.dart';

import '../api/endpoints.dart';
import '../models/maintenance.dart';
import '../models/task.dart';

class TasksRepository {
  TasksRepository(this._dio);
  final Dio _dio;

  Future<TaskPage> list({
    String? assigneeId,
    String? status,
    String? type,
    String? equipmentId,
    String? from,
    String? to,
    int page = 1,
    int limit = 20,
  }) async {
    final assignee = _nonEmpty(assigneeId);
    final st = _nonEmpty(status);
    final ty = _nonEmpty(type);
    final eq = _nonEmpty(equipmentId);
    final res = await _dio.get<Map<String, dynamic>>(
      Ep.maintenanceTasks,
      queryParameters: {
        'assigneeId': ?assignee,
        'status': ?st,
        'type': ?ty,
        'equipmentId': ?eq,
        'from': ?from,
        'to': ?to,
        'page': page,
        'limit': limit,
      },
    );
    return TaskPage.fromJson(res.data!);
  }

  Future<MaintenanceTask> detail(String id) async {
    final res = await _dio.get<Map<String, dynamic>>(Ep.maintenanceTask(id));
    return MaintenanceTask.fromJson(res.data!);
  }

  /// Bắt đầu — bắt buộc token QR máy (trừ ADM bỏ qua).
  Future<void> start(String id, {String? equipmentQrToken}) => _dio.post<void>(
    Ep.maintenanceTaskStart(id),
    data: {'equipmentQrToken': ?equipmentQrToken},
  );

  /// Lưu kết quả checklist (clientVersion để phát hiện stale).
  Future<void> saveResults(
    String id, {
    required num clientVersion,
    required List<TaskResult> results,
  }) => _dio.put<void>(
    Ep.maintenanceTaskResults(id),
    data: {
      'clientVersion': clientVersion,
      'results': results.map((r) => r.toJson()).toList(),
    },
  );

  Future<void> finish(
    String id, {
    required bool overallPass,
    String? notes,
    List<UsedSupply> suppliesUsed = const [],
  }) => _dio.post<void>(
    Ep.maintenanceTaskFinish(id),
    data: {
      'overallPass': overallPass,
      'notes': ?notes,
      'suppliesUsed': suppliesUsed.map((s) => s.toJson()).toList(),
    },
  );

  Future<void> skip(String id, String reason) =>
      _dio.post<void>(Ep.maintenanceTaskSkip(id), data: {'reason': reason});

  Future<void> addSignature(
    String id, {
    required String role,
    required String signerName,
    required String fileId,
  }) => _dio.post<void>(
    Ep.maintenanceTaskSignatures(id),
    data: {'role': role, 'signerName': signerName, 'fileId': fileId},
  );

  Future<List<int>> reportPdf(String id) async {
    final res = await _dio.get<List<int>>(
      Ep.maintenanceTaskReportPdf(id),
      options: Options(responseType: ResponseType.bytes),
    );
    return res.data ?? const [];
  }

  /// Tạo bảo dưỡng đột xuất (`POST /v1/maintenance/tasks`).
  Future<TaskSummary> create({
    required String equipmentId,
    required String scheduledAt,
    String? assigneeId,
    String? templateId,
    String? notes,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      Ep.maintenanceTasks,
      data: {
        'equipmentId': equipmentId,
        'scheduledAt': scheduledAt,
        'assigneeId': ?assigneeId,
        'templateId': ?templateId,
        'notes': ?notes,
      },
    );
    return TaskSummary.fromJson(res.data!);
  }
}

String? _nonEmpty(String? v) => v == null || v.isEmpty ? null : v;
