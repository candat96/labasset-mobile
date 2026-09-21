import 'package:json_annotation/json_annotation.dart';

part 'stock_issue.g.dart';

/// `GET /v1/stock/issues` → IssueResponseDto.
@JsonSerializable()
class StockIssue {
  const StockIssue({
    required this.id,
    required this.code,
    this.type = 'to_department',
    required this.warehouseId,
    this.toDepartmentId,
    this.equipmentId,
    this.repairTicketId,
    this.maintenanceTaskId,
    this.requestId,
    this.receiverUserId,
    this.receiverSignatureFileId,
    this.receiverName,
    this.reason,
    this.notes,
    this.issuedAt,
    this.items = const [],
    this.status = 'draft',
    this.fefoWarning = false,
    this.postedAt,
  });

  final String id;
  final String code;
  final String type;
  final String warehouseId;
  final String? toDepartmentId;
  final String? equipmentId;
  final String? repairTicketId;
  final String? maintenanceTaskId;
  final String? requestId;
  final String? receiverUserId;
  final String? receiverSignatureFileId;
  final String? receiverName;
  final String? reason;
  final String? notes;
  final String? issuedAt;
  final List<IssueItem> items;
  final String status;
  final bool fefoWarning;
  final String? postedAt;

  factory StockIssue.fromJson(Map<String, dynamic> json) =>
      _$StockIssueFromJson(json);
  Map<String, dynamic> toJson() => _$StockIssueToJson(this);
}

@JsonSerializable()
class IssueItem {
  const IssueItem({required this.supplyId, this.lotId, this.quantity = '1'});

  final String supplyId;
  final String? lotId;
  final String quantity;

  factory IssueItem.fromJson(Map<String, dynamic> json) =>
      _$IssueItemFromJson(json);
  Map<String, dynamic> toJson() => _$IssueItemToJson(this);
}

@JsonSerializable()
class StockIssuePage {
  const StockIssuePage({
    required this.items,
    required this.total,
    this.page = 1,
    this.limit = 20,
  });

  final List<StockIssue> items;
  final num total;
  final num page;
  final num limit;

  factory StockIssuePage.fromJson(Map<String, dynamic> json) =>
      _$StockIssuePageFromJson(json);
  Map<String, dynamic> toJson() => _$StockIssuePageToJson(this);
}

/// `GET /v1/stock/issues/suggest-lots` — gợi ý FEFO.
@JsonSerializable()
class LotSuggestion {
  const LotSuggestion({
    required this.lotId,
    this.lotNo = '',
    this.quantity = '0',
    this.available = '0',
    this.unitCost = '0',
    this.effectiveExpiresAt,
  });

  final String lotId;
  final String lotNo;
  final String quantity;
  final String available;
  final String unitCost;
  final String? effectiveExpiresAt;

  factory LotSuggestion.fromJson(Map<String, dynamic> json) =>
      _$LotSuggestionFromJson(json);
  Map<String, dynamic> toJson() => _$LotSuggestionToJson(this);
}

/// Dòng xuất kho đang soạn (kèm tên hiển thị + cảnh báo FEFO).
class IssueLine {
  IssueLine({
    required this.supplyId,
    required this.label,
    this.lotId,
    this.lotNo,
    this.quantity = '1',
    this.available,
    this.fefoWarning = false,
  });

  final String supplyId;
  String label;
  String? lotId;
  String? lotNo;
  String quantity;
  String? available;
  bool fefoWarning;

  IssueItem toItem() =>
      IssueItem(supplyId: supplyId, lotId: lotId, quantity: quantity);
}
