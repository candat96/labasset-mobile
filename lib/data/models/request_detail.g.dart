// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request_detail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RequestDetail _$RequestDetailFromJson(Map<String, dynamic> json) =>
    RequestDetail(
      id: json['id'] as String,
      code: json['code'] as String,
      type: json['type'] as String? ?? 'supply',
      departmentId: json['departmentId'] as String? ?? '',
      requesterId: json['requesterId'] as String? ?? '',
      equipmentId: json['equipmentId'] as String?,
      priority: json['priority'] as String? ?? 'normal',
      reason: json['reason'] as String? ?? '',
      neededBy: json['neededBy'] as String?,
      status: json['status'] as String? ?? 'submitted',
      approvalLevels: json['approvalLevels'] as num? ?? 1,
      quotaExceeded: json['quotaExceeded'] as bool? ?? false,
      partiallyIssued: json['partiallyIssued'] as bool? ?? false,
      submittedAt: json['submittedAt'] as String?,
      approvedAt: json['approvedAt'] as String?,
      rejectedReason: json['rejectedReason'] as String?,
      issueId: json['issueId'] as String?,
      repairTicketId: json['repairTicketId'] as String?,
      receivedAt: json['receivedAt'] as String?,
      createdAt: json['createdAt'] as String?,
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => RequestItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      comments:
          (json['comments'] as List<dynamic>?)
              ?.map((e) => RequestComment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      departmentName: json['departmentName'] as String?,
      requesterName: json['requesterName'] as String?,
      equipment: json['equipment'] == null
          ? null
          : EquipmentRef.fromJson(json['equipment'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$RequestDetailToJson(RequestDetail instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'type': instance.type,
      'departmentId': instance.departmentId,
      'requesterId': instance.requesterId,
      'equipmentId': instance.equipmentId,
      'priority': instance.priority,
      'reason': instance.reason,
      'neededBy': instance.neededBy,
      'status': instance.status,
      'approvalLevels': instance.approvalLevels,
      'quotaExceeded': instance.quotaExceeded,
      'partiallyIssued': instance.partiallyIssued,
      'submittedAt': instance.submittedAt,
      'approvedAt': instance.approvedAt,
      'rejectedReason': instance.rejectedReason,
      'issueId': instance.issueId,
      'repairTicketId': instance.repairTicketId,
      'receivedAt': instance.receivedAt,
      'createdAt': instance.createdAt,
      'items': instance.items,
      'comments': instance.comments,
      'departmentName': instance.departmentName,
      'requesterName': instance.requesterName,
      'equipment': instance.equipment,
    };

RequestItem _$RequestItemFromJson(Map<String, dynamic> json) => RequestItem(
  id: json['id'] as String,
  supplyId: json['supplyId'] as String? ?? '',
  qtyRequested: json['qtyRequested'] as String? ?? '0',
  qtyApproved: json['qtyApproved'] as String? ?? '0',
  qtyIssued: json['qtyIssued'] as String? ?? '0',
  shortage: json['shortage'] as String? ?? '0',
  quotaExceeded: json['quotaExceeded'] as bool? ?? false,
  note: json['note'] as String?,
  approverNote: json['approverNote'] as String?,
  supplyName: _readSupplyName(json, 'supplyName') as String?,
  supplyCode: _readSupplyCode(json, 'supplyCode') as String?,
);

Map<String, dynamic> _$RequestItemToJson(RequestItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'supplyId': instance.supplyId,
      'qtyRequested': instance.qtyRequested,
      'qtyApproved': instance.qtyApproved,
      'qtyIssued': instance.qtyIssued,
      'shortage': instance.shortage,
      'quotaExceeded': instance.quotaExceeded,
      'note': instance.note,
      'approverNote': instance.approverNote,
      'supplyName': instance.supplyName,
      'supplyCode': instance.supplyCode,
    };

RequestComment _$RequestCommentFromJson(Map<String, dynamic> json) =>
    RequestComment(
      id: json['id'] as String,
      userId: json['userId'] as String?,
      body: json['body'] as String? ?? '',
      createdAt: json['createdAt'] as String?,
      userName: _readUserName(json, 'userName') as String?,
    );

Map<String, dynamic> _$RequestCommentToJson(RequestComment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'body': instance.body,
      'createdAt': instance.createdAt,
      'userName': instance.userName,
    };
