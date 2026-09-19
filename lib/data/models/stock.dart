import 'package:json_annotation/json_annotation.dart';

part 'stock.g.dart';

/// `GET /v1/stock/alerts` → StockAlertResponseDto (tập con đủ dùng).
@JsonSerializable()
class StockAlertSummary {
  const StockAlertSummary({
    required this.id,
    required this.type,
    required this.supplyId,
    this.warehouseId,
    this.lotId,
    this.level,
    this.message = '',
    this.createdAt,
    this.resolvedAt,
  });

  final String id;
  final String type;
  final String supplyId;
  final String? warehouseId;
  final String? lotId;
  final String? level;
  final String message;
  final String? createdAt;
  final String? resolvedAt;

  bool get isResolved => resolvedAt != null;

  factory StockAlertSummary.fromJson(Map<String, dynamic> json) =>
      _$StockAlertSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$StockAlertSummaryToJson(this);
}

@JsonSerializable()
class StockAlertPage {
  const StockAlertPage({
    required this.items,
    required this.total,
    this.page = 1,
    this.limit = 20,
  });

  final List<StockAlertSummary> items;
  final num total;
  final num page;
  final num limit;

  factory StockAlertPage.fromJson(Map<String, dynamic> json) =>
      _$StockAlertPageFromJson(json);
  Map<String, dynamic> toJson() => _$StockAlertPageToJson(this);
}

/// `GET /v1/stock/lots` → StockLotResponseDto.
@JsonSerializable()
class StockLotSummary {
  const StockLotSummary({
    required this.id,
    required this.supplyId,
    this.warehouseId,
    required this.lotNo,
    this.qtyOnHand = '0',
    this.qtyReserved = '0',
    this.available = '0',
    this.unitCost = '0',
    this.status = 'available',
    this.expiresAt,
    this.effectiveExpiresAt,
  });

  final String id;
  final String supplyId;
  final String? warehouseId;
  final String lotNo;
  final String qtyOnHand;
  final String qtyReserved;
  final String available;
  final String unitCost;
  final String status;
  final String? expiresAt;
  final String? effectiveExpiresAt;

  factory StockLotSummary.fromJson(Map<String, dynamic> json) =>
      _$StockLotSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$StockLotSummaryToJson(this);
}

@JsonSerializable()
class StockLotPage {
  const StockLotPage({
    required this.items,
    required this.total,
    this.page = 1,
    this.limit = 20,
  });

  final List<StockLotSummary> items;
  final num total;
  final num page;
  final num limit;

  factory StockLotPage.fromJson(Map<String, dynamic> json) =>
      _$StockLotPageFromJson(json);
  Map<String, dynamic> toJson() => _$StockLotPageToJson(this);
}
