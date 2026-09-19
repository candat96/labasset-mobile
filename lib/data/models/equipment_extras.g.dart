// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'equipment_extras.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EquipmentSupplyLink _$EquipmentSupplyLinkFromJson(Map<String, dynamic> json) =>
    EquipmentSupplyLink(
      supplyId: json['supplyId'] as String,
      normQtyPerTest: json['normQtyPerTest'] as String?,
      normQtyPerDay: json['normQtyPerDay'] as String?,
      isPrimary: json['isPrimary'] as bool? ?? false,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$EquipmentSupplyLinkToJson(
  EquipmentSupplyLink instance,
) => <String, dynamic>{
  'supplyId': instance.supplyId,
  'normQtyPerTest': instance.normQtyPerTest,
  'normQtyPerDay': instance.normQtyPerDay,
  'isPrimary': instance.isPrimary,
  'notes': instance.notes,
};

EquipmentRunway _$EquipmentRunwayFromJson(Map<String, dynamic> json) =>
    EquipmentRunway(
      equipmentId: json['equipmentId'] as String,
      scope: json['scope'] as String? ?? 'department',
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => RunwayItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$EquipmentRunwayToJson(EquipmentRunway instance) =>
    <String, dynamic>{
      'equipmentId': instance.equipmentId,
      'scope': instance.scope,
      'items': instance.items,
    };

RunwayItem _$RunwayItemFromJson(Map<String, dynamic> json) => RunwayItem(
  supplyId: json['supplyId'] as String,
  isPrimary: json['isPrimary'] as bool? ?? false,
  onHand: json['onHand'] as String? ?? '0',
  dailyUsage: json['dailyUsage'] as String? ?? '0',
  daysLeft: json['daysLeft'] as num? ?? 0,
  basis: json['basis'] as String? ?? 'unknown',
);

Map<String, dynamic> _$RunwayItemToJson(RunwayItem instance) =>
    <String, dynamic>{
      'supplyId': instance.supplyId,
      'isPrimary': instance.isPrimary,
      'onHand': instance.onHand,
      'dailyUsage': instance.dailyUsage,
      'daysLeft': instance.daysLeft,
      'basis': instance.basis,
    };

EquipmentEvent _$EquipmentEventFromJson(Map<String, dynamic> json) =>
    EquipmentEvent(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      summary: json['summary'] as String?,
      refType: json['refType'] as String?,
      refId: json['refId'] as String?,
      byUserId: json['byUserId'] as String?,
      at: json['at'] as String,
    );

Map<String, dynamic> _$EquipmentEventToJson(EquipmentEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'title': instance.title,
      'summary': instance.summary,
      'refType': instance.refType,
      'refId': instance.refId,
      'byUserId': instance.byUserId,
      'at': instance.at,
    };

EquipmentEventPage _$EquipmentEventPageFromJson(Map<String, dynamic> json) =>
    EquipmentEventPage(
      items: (json['items'] as List<dynamic>)
          .map((e) => EquipmentEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as num,
      page: json['page'] as num? ?? 1,
      limit: json['limit'] as num? ?? 20,
    );

Map<String, dynamic> _$EquipmentEventPageToJson(EquipmentEventPage instance) =>
    <String, dynamic>{
      'items': instance.items,
      'total': instance.total,
      'page': instance.page,
      'limit': instance.limit,
    };

EquipmentTransfer _$EquipmentTransferFromJson(Map<String, dynamic> json) =>
    EquipmentTransfer(
      id: json['id'] as String,
      equipmentId: json['equipmentId'] as String,
      fromDepartmentId: json['fromDepartmentId'] as String?,
      toDepartmentId: json['toDepartmentId'] as String?,
      fromLocation: json['fromLocation'] as String?,
      toLocation: json['toLocation'] as String?,
      reason: json['reason'] as String?,
      status: json['status'] as String? ?? 'pending',
      requestedBy: json['requestedBy'] as String?,
      approvedBy: json['approvedBy'] as String?,
      minutesFileId: json['minutesFileId'] as String?,
      createdAt: json['createdAt'] as String?,
      toDepartmentName: json['toDepartmentName'] as String?,
    );

Map<String, dynamic> _$EquipmentTransferToJson(EquipmentTransfer instance) =>
    <String, dynamic>{
      'id': instance.id,
      'equipmentId': instance.equipmentId,
      'fromDepartmentId': instance.fromDepartmentId,
      'toDepartmentId': instance.toDepartmentId,
      'fromLocation': instance.fromLocation,
      'toLocation': instance.toLocation,
      'reason': instance.reason,
      'status': instance.status,
      'requestedBy': instance.requestedBy,
      'approvedBy': instance.approvedBy,
      'minutesFileId': instance.minutesFileId,
      'createdAt': instance.createdAt,
      'toDepartmentName': instance.toDepartmentName,
    };

EquipmentTransferPage _$EquipmentTransferPageFromJson(
  Map<String, dynamic> json,
) => EquipmentTransferPage(
  items: (json['items'] as List<dynamic>)
      .map((e) => EquipmentTransfer.fromJson(e as Map<String, dynamic>))
      .toList(),
  total: json['total'] as num,
  page: json['page'] as num? ?? 1,
  limit: json['limit'] as num? ?? 20,
);

Map<String, dynamic> _$EquipmentTransferPageToJson(
  EquipmentTransferPage instance,
) => <String, dynamic>{
  'items': instance.items,
  'total': instance.total,
  'page': instance.page,
  'limit': instance.limit,
};

FaultItem _$FaultItemFromJson(Map<String, dynamic> json) => FaultItem(
  id: json['id'] as String,
  title: json['title'] as String,
  scope: json['scope'] as String? ?? 'all',
  model: json['model'] as String? ?? '',
  errorCode: json['errorCode'] as String? ?? '',
  severity: json['severity'] as String? ?? 'medium',
  status: json['status'] as String? ?? 'published',
  version: json['version'] as num? ?? 1,
  helpfulCount: json['helpfulCount'] as num? ?? 0,
  viewCount: json['viewCount'] as num? ?? 0,
  updatedAt: json['updatedAt'] as String?,
);

Map<String, dynamic> _$FaultItemToJson(FaultItem instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'scope': instance.scope,
  'model': instance.model,
  'errorCode': instance.errorCode,
  'severity': instance.severity,
  'status': instance.status,
  'version': instance.version,
  'helpfulCount': instance.helpfulCount,
  'viewCount': instance.viewCount,
  'updatedAt': instance.updatedAt,
};

FaultPage _$FaultPageFromJson(Map<String, dynamic> json) => FaultPage(
  items: (json['items'] as List<dynamic>)
      .map((e) => FaultItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  total: json['total'] as num,
  page: json['page'] as num? ?? 1,
  limit: json['limit'] as num? ?? 20,
);

Map<String, dynamic> _$FaultPageToJson(FaultPage instance) => <String, dynamic>{
  'items': instance.items,
  'total': instance.total,
  'page': instance.page,
  'limit': instance.limit,
};
