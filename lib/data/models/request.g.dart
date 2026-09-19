// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RequestSummary _$RequestSummaryFromJson(Map<String, dynamic> json) =>
    RequestSummary(
      id: json['id'] as String,
      code: json['code'] as String,
      type: json['type'] as String? ?? 'supply',
      status: json['status'] as String? ?? 'submitted',
      priority: json['priority'] as String? ?? 'normal',
      reason: json['reason'] as String? ?? '',
      neededBy: json['neededBy'] as String?,
      equipmentId: json['equipmentId'] as String?,
      equipment: json['equipment'] == null
          ? null
          : EquipmentRef.fromJson(json['equipment'] as Map<String, dynamic>),
      itemCount: json['itemCount'] as num? ?? 0,
      departmentName: json['departmentName'] as String?,
      requesterName: json['requesterName'] as String?,
      createdAt: json['createdAt'] as String?,
    );

Map<String, dynamic> _$RequestSummaryToJson(RequestSummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'type': instance.type,
      'status': instance.status,
      'priority': instance.priority,
      'reason': instance.reason,
      'neededBy': instance.neededBy,
      'equipmentId': instance.equipmentId,
      'equipment': instance.equipment,
      'itemCount': instance.itemCount,
      'departmentName': instance.departmentName,
      'requesterName': instance.requesterName,
      'createdAt': instance.createdAt,
    };

RequestPage _$RequestPageFromJson(Map<String, dynamic> json) => RequestPage(
  items: (json['items'] as List<dynamic>)
      .map((e) => RequestSummary.fromJson(e as Map<String, dynamic>))
      .toList(),
  total: json['total'] as num,
  page: json['page'] as num? ?? 1,
  limit: json['limit'] as num? ?? 20,
);

Map<String, dynamic> _$RequestPageToJson(RequestPage instance) =>
    <String, dynamic>{
      'items': instance.items,
      'total': instance.total,
      'page': instance.page,
      'limit': instance.limit,
    };
