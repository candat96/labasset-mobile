// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TaskSummary _$TaskSummaryFromJson(Map<String, dynamic> json) => TaskSummary(
  id: json['id'] as String,
  code: json['code'] as String,
  equipmentId: json['equipmentId'] as String,
  planId: json['planId'] as String?,
  type: json['type'] as String? ?? 'periodic',
  scheduledAt: json['scheduledAt'] as String,
  dueAt: json['dueAt'] as String?,
  status: json['status'] as String? ?? 'scheduled',
  assigneeId: json['assigneeId'] as String?,
  notes: json['notes'] as String?,
  room: json['room'] == null
      ? null
      : RoomRef.fromJson(json['room'] as Map<String, dynamic>),
);

Map<String, dynamic> _$TaskSummaryToJson(TaskSummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'equipmentId': instance.equipmentId,
      'planId': instance.planId,
      'type': instance.type,
      'scheduledAt': instance.scheduledAt,
      'dueAt': instance.dueAt,
      'status': instance.status,
      'assigneeId': instance.assigneeId,
      'notes': instance.notes,
      'room': instance.room,
    };

TaskPage _$TaskPageFromJson(Map<String, dynamic> json) => TaskPage(
  items: (json['items'] as List<dynamic>)
      .map((e) => TaskSummary.fromJson(e as Map<String, dynamic>))
      .toList(),
  total: json['total'] as num,
  page: json['page'] as num? ?? 1,
  limit: json['limit'] as num? ?? 20,
);

Map<String, dynamic> _$TaskPageToJson(TaskPage instance) => <String, dynamic>{
  'items': instance.items,
  'total': instance.total,
  'page': instance.page,
  'limit': instance.limit,
};
