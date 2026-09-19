import 'package:json_annotation/json_annotation.dart';

import 'equipment.dart';
import 'stock.dart';

part 'stock_extra.g.dart';

/// `GET /v1/supplies/:id/stock` → { balances, lots }.
@JsonSerializable()
class SupplyStock {
  const SupplyStock({this.balances = const [], this.lots = const []});

  final List<SupplyBalance> balances;
  final List<StockLotSummary> lots;

  factory SupplyStock.fromJson(Map<String, dynamic> json) {
    final rawLots = json['lots'];
    return SupplyStock(
      balances: (json['balances'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(SupplyBalance.fromJson)
          .toList(),
      lots: rawLots is List
          ? rawLots
                .whereType<Map<String, dynamic>>()
                .map(StockLotSummary.fromJson)
                .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() => _$SupplyStockToJson(this);
}

@JsonSerializable()
class SupplyBalance {
  const SupplyBalance({
    required this.warehouseId,
    this.qtyOnHand = '0',
    this.qtyReserved = '0',
    this.available = '0',
    this.warehouseName,
  });

  final String warehouseId;
  final String qtyOnHand;
  final String qtyReserved;
  final String available;
  final String? warehouseName;

  factory SupplyBalance.fromJson(Map<String, dynamic> json) =>
      _$SupplyBalanceFromJson(json);
  Map<String, dynamic> toJson() => _$SupplyBalanceToJson(this);
}

/// `GET /v1/stock/forecast`.
@JsonSerializable()
class StockForecast {
  const StockForecast({
    required this.supplyId,
    this.warehouseId,
    this.onHand = '0',
    this.avg30 = '0',
    this.avg90 = '0',
    this.dailyUsage = '0',
    this.basis = 'unknown',
    this.daysLeft = 0,
  });

  final String supplyId;
  final String? warehouseId;
  final String onHand;
  final String avg30;
  final String avg90;
  final String dailyUsage;
  final String basis;
  final num daysLeft;

  factory StockForecast.fromJson(Map<String, dynamic> json) =>
      _$StockForecastFromJson(json);
  Map<String, dynamic> toJson() => _$StockForecastToJson(this);
}

/// `GET /v1/stock/receipts` → ReceiptResponseDto.
@JsonSerializable()
class StockReceipt {
  const StockReceipt({
    required this.id,
    required this.code,
    this.type = 'purchase',
    required this.warehouseId,
    this.supplierId,
    this.fromDepartmentId,
    this.invoiceNo,
    this.invoiceDate,
    this.receivedAt,
    this.qcStatus = 'pending',
    this.qcNote,
    this.notes,
    this.items = const [],
    this.status = 'draft',
    this.totalAmount = '0',
    this.postedAt,
    this.postedBy,
  });

  final String id;
  final String code;
  final String type;
  final String warehouseId;
  final String? supplierId;
  final String? fromDepartmentId;
  final String? invoiceNo;
  final String? invoiceDate;
  final String? receivedAt;
  final String qcStatus;
  final String? qcNote;
  final String? notes;
  final List<ReceiptItem> items;
  final String status;
  final String totalAmount;
  final String? postedAt;
  final String? postedBy;

  factory StockReceipt.fromJson(Map<String, dynamic> json) =>
      _$StockReceiptFromJson(json);
  Map<String, dynamic> toJson() => _$StockReceiptToJson(this);
}

@JsonSerializable()
class ReceiptItem {
  const ReceiptItem({
    required this.supplyId,
    this.lotNo,
    this.expiresAt,
    this.quantity = '0',
    this.unitCost = '0',
  });

  final String supplyId;
  final String? lotNo;
  final String? expiresAt;
  final String quantity;
  final String unitCost;

  factory ReceiptItem.fromJson(Map<String, dynamic> json) =>
      _$ReceiptItemFromJson(json);
  Map<String, dynamic> toJson() => _$ReceiptItemToJson(this);
}

@JsonSerializable()
class StockReceiptPage {
  const StockReceiptPage({
    required this.items,
    required this.total,
    this.page = 1,
    this.limit = 20,
  });

  final List<StockReceipt> items;
  final num total;
  final num page;
  final num limit;

  factory StockReceiptPage.fromJson(Map<String, dynamic> json) =>
      _$StockReceiptPageFromJson(json);
  Map<String, dynamic> toJson() => _$StockReceiptPageToJson(this);
}

/// Máy tương thích với vật tư (`GET /v1/supplies/:id/equipment`).
@JsonSerializable()
class SupplyEquipment {
  const SupplyEquipment({
    required this.id,
    required this.code,
    required this.name,
  });

  final String id;
  final String code;
  final String name;

  EquipmentRef toRef() => EquipmentRef(id: id, code: code, name: name);

  factory SupplyEquipment.fromJson(Map<String, dynamic> json) =>
      _$SupplyEquipmentFromJson(json);
  Map<String, dynamic> toJson() => _$SupplyEquipmentToJson(this);
}
