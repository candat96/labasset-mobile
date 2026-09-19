import 'package:json_annotation/json_annotation.dart';

import 'equipment.dart';

part 'request_detail.g.dart';

/// `GET /v1/requests/:id` → RequestDetailDto.
@JsonSerializable()
class RequestDetail {
  const RequestDetail({
    required this.id,
    required this.code,
    this.type = 'supply',
    this.departmentId = '',
    this.requesterId = '',
    this.equipmentId,
    this.priority = 'normal',
    this.reason = '',
    this.neededBy,
    this.status = 'submitted',
    this.approvalLevels = 1,
    this.quotaExceeded = false,
    this.partiallyIssued = false,
    this.submittedAt,
    this.approvedAt,
    this.rejectedReason,
    this.issueId,
    this.repairTicketId,
    this.receivedAt,
    this.createdAt,
    this.items = const [],
    this.comments = const [],
    this.departmentName,
    this.requesterName,
    this.equipment,
  });

  final String id;
  final String code;
  final String type;
  final String departmentId;
  final String requesterId;
  final String? equipmentId;
  final String priority;
  final String reason;
  final String? neededBy;
  final String status;
  final num approvalLevels;
  final bool quotaExceeded;
  final bool partiallyIssued;
  final String? submittedAt;
  final String? approvedAt;
  final String? rejectedReason;
  final String? issueId;
  final String? repairTicketId;
  final String? receivedAt;
  final String? createdAt;
  final List<RequestItem> items;
  final List<RequestComment> comments;
  final String? departmentName;
  final String? requesterName;
  final EquipmentRef? equipment;

  factory RequestDetail.fromJson(Map<String, dynamic> json) =>
      _$RequestDetailFromJson(json);
  Map<String, dynamic> toJson() => _$RequestDetailToJson(this);
}

@JsonSerializable()
class RequestItem {
  const RequestItem({
    required this.id,
    this.supplyId = '',
    this.qtyRequested = '0',
    this.qtyApproved = '0',
    this.qtyIssued = '0',
    this.shortage = '0',
    this.quotaExceeded = false,
    this.note,
    this.approverNote,
    this.supplyName,
    this.supplyCode,
  });

  final String id;
  final String supplyId;
  final String qtyRequested;
  final String qtyApproved;
  final String qtyIssued;
  final String shortage;
  final bool quotaExceeded;
  final String? note;
  final String? approverNote;
  final String? supplyName;
  final String? supplyCode;

  String get label =>
      supplyCode == null ? supplyId : '$supplyCode — $supplyName';

  factory RequestItem.fromJson(Map<String, dynamic> json) =>
      _$RequestItemFromJson(json);
  Map<String, dynamic> toJson() => _$RequestItemToJson(this);
}

@JsonSerializable()
class RequestComment {
  const RequestComment({
    required this.id,
    this.userId,
    this.body = '',
    this.createdAt,
    this.userName,
  });

  final String id;
  final String? userId;
  final String body;
  final String? createdAt;
  final String? userName;

  factory RequestComment.fromJson(Map<String, dynamic> json) =>
      _$RequestCommentFromJson(json);
  Map<String, dynamic> toJson() => _$RequestCommentToJson(this);
}
