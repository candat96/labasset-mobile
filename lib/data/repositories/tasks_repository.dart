import 'package:dio/dio.dart';

import '../api/endpoints.dart';
import '../models/task.dart';

class TasksRepository {
  TasksRepository(this._dio);
  final Dio _dio;

  Future<TaskPage> list({
    String? assigneeId,
    String? status,
    String? equipmentId,
    String? from,
    String? to,
    int page = 1,
    int limit = 20,
  }) async {
    final assignee = _nonEmpty(assigneeId);
    final st = _nonEmpty(status);
    final eq = _nonEmpty(equipmentId);
    final res = await _dio.get<Map<String, dynamic>>(
      Ep.maintenanceTasks,
      queryParameters: {
        'assigneeId': ?assignee,
        'status': ?st,
        'equipmentId': ?eq,
        'from': ?from,
        'to': ?to,
        'page': page,
        'limit': limit,
      },
    );
    return TaskPage.fromJson(res.data!);
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
