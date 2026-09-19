// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repair.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RepairSummary _$RepairSummaryFromJson(Map<String, dynamic> json) =>
    RepairSummary(
      id: json['id'] as String,
      code: json['code'] as String,
      equipmentId: json['equipmentId'] as String,
      description: json['description'] as String? ?? '',
      severity: json['severity'] as String? ?? 'medium',
      status: json['status'] as String? ?? 'new',
      assigneeId: json['assigneeId'] as String?,
      createdAt: json['createdAt'] as String?,
      dueAt: json['dueAt'] as String?,
      isOverdue: json['isOverdue'] as bool? ?? false,
      equipment: json['equipment'] == null
          ? null
          : EquipmentRef.fromJson(json['equipment'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$RepairSummaryToJson(RepairSummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'equipmentId': instance.equipmentId,
      'description': instance.description,
      'severity': instance.severity,
      'status': instance.status,
      'assigneeId': instance.assigneeId,
      'createdAt': instance.createdAt,
      'dueAt': instance.dueAt,
      'isOverdue': instance.isOverdue,
      'equipment': instance.equipment,
    };

RepairPage _$RepairPageFromJson(Map<String, dynamic> json) => RepairPage(
  items: (json['items'] as List<dynamic>)
      .map((e) => RepairSummary.fromJson(e as Map<String, dynamic>))
      .toList(),
  total: json['total'] as num,
  page: json['page'] as num? ?? 1,
  limit: json['limit'] as num? ?? 20,
);

Map<String, dynamic> _$RepairPageToJson(RepairPage instance) =>
    <String, dynamic>{
      'items': instance.items,
      'total': instance.total,
      'page': instance.page,
      'limit': instance.limit,
    };
