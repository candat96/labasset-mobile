import 'package:json_annotation/json_annotation.dart';

import 'room.dart';

part 'task.g.dart';

/// Tập con của TaskResponseDto (`GET /v1/maintenance/tasks`).
@JsonSerializable()
class TaskSummary {
  const TaskSummary({
    required this.id,
    required this.code,
    required this.equipmentId,
    this.planId,
    this.type = 'periodic',
    required this.scheduledAt,
    this.dueAt,
    this.status = 'scheduled',
    this.assigneeId,
    this.notes,
    this.room,
  });

  final String id;
  final String code;
  final String equipmentId;
  final String? planId;
  final String type;
  final String scheduledAt;
  final String? dueAt;
  final String status;
  final String? assigneeId;
  final String? notes;
  final RoomRef? room;

  factory TaskSummary.fromJson(Map<String, dynamic> json) =>
      _$TaskSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$TaskSummaryToJson(this);
}

@JsonSerializable()
class TaskPage {
  const TaskPage({
    required this.items,
    required this.total,
    this.page = 1,
    this.limit = 20,
  });

  final List<TaskSummary> items;
  final num total;
  final num page;
  final num limit;

  factory TaskPage.fromJson(Map<String, dynamic> json) =>
      _$TaskPageFromJson(json);
  Map<String, dynamic> toJson() => _$TaskPageToJson(this);
}
