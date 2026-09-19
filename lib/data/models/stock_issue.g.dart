// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_issue.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StockIssue _$StockIssueFromJson(Map<String, dynamic> json) => StockIssue(
  id: json['id'] as String,
  code: json['code'] as String,
  type: json['type'] as String? ?? 'to_department',
  warehouseId: json['warehouseId'] as String,
  toDepartmentId: json['toDepartmentId'] as String?,
  equipmentId: json['equipmentId'] as String?,
  repairTicketId: json['repairTicketId'] as String?,
  maintenanceTaskId: json['maintenanceTaskId'] as String?,
  requestId: json['requestId'] as String?,
  receiverUserId: json['receiverUserId'] as String?,
  receiverSignatureFileId: json['receiverSignatureFileId'] as String?,
  receiverName: json['receiverName'] as String?,
  reason: json['reason'] as String?,
  notes: json['notes'] as String?,
  issuedAt: json['issuedAt'] as String?,
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => IssueItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  status: json['status'] as String? ?? 'draft',
  fefoWarning: json['fefoWarning'] as bool? ?? false,
  postedAt: json['postedAt'] as String?,
);

Map<String, dynamic> _$StockIssueToJson(StockIssue instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'type': instance.type,
      'warehouseId': instance.warehouseId,
      'toDepartmentId': instance.toDepartmentId,
      'equipmentId': instance.equipmentId,
      'repairTicketId': instance.repairTicketId,
      'maintenanceTaskId': instance.maintenanceTaskId,
      'requestId': instance.requestId,
      'receiverUserId': instance.receiverUserId,
      'receiverSignatureFileId': instance.receiverSignatureFileId,
      'receiverName': instance.receiverName,
      'reason': instance.reason,
      'notes': instance.notes,
      'issuedAt': instance.issuedAt,
      'items': instance.items,
      'status': instance.status,
      'fefoWarning': instance.fefoWarning,
      'postedAt': instance.postedAt,
    };

IssueItem _$IssueItemFromJson(Map<String, dynamic> json) => IssueItem(
  supplyId: json['supplyId'] as String,
  lotId: json['lotId'] as String?,
  quantity: json['quantity'] as String? ?? '1',
);

Map<String, dynamic> _$IssueItemToJson(IssueItem instance) => <String, dynamic>{
  'supplyId': instance.supplyId,
  'lotId': instance.lotId,
  'quantity': instance.quantity,
};

StockIssuePage _$StockIssuePageFromJson(Map<String, dynamic> json) =>
    StockIssuePage(
      items: (json['items'] as List<dynamic>)
          .map((e) => StockIssue.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as num,
      page: json['page'] as num? ?? 1,
      limit: json['limit'] as num? ?? 20,
    );

Map<String, dynamic> _$StockIssuePageToJson(StockIssuePage instance) =>
    <String, dynamic>{
      'items': instance.items,
      'total': instance.total,
      'page': instance.page,
      'limit': instance.limit,
    };

LotSuggestion _$LotSuggestionFromJson(Map<String, dynamic> json) =>
    LotSuggestion(
      lotId: json['lotId'] as String,
      lotNo: json['lotNo'] as String? ?? '',
      quantity: json['quantity'] as String? ?? '0',
      available: json['available'] as String? ?? '0',
      unitCost: json['unitCost'] as String? ?? '0',
      effectiveExpiresAt: json['effectiveExpiresAt'] as String?,
    );

Map<String, dynamic> _$LotSuggestionToJson(LotSuggestion instance) =>
    <String, dynamic>{
      'lotId': instance.lotId,
      'lotNo': instance.lotNo,
      'quantity': instance.quantity,
      'available': instance.available,
      'unitCost': instance.unitCost,
      'effectiveExpiresAt': instance.effectiveExpiresAt,
    };
