// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_extra.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SupplyStock _$SupplyStockFromJson(Map<String, dynamic> json) => SupplyStock(
  balances:
      (json['balances'] as List<dynamic>?)
          ?.map((e) => SupplyBalance.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  lots:
      (json['lots'] as List<dynamic>?)
          ?.map((e) => StockLotSummary.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$SupplyStockToJson(SupplyStock instance) =>
    <String, dynamic>{'balances': instance.balances, 'lots': instance.lots};

SupplyBalance _$SupplyBalanceFromJson(Map<String, dynamic> json) =>
    SupplyBalance(
      warehouseId: json['warehouseId'] as String,
      qtyOnHand: json['qtyOnHand'] as String? ?? '0',
      qtyReserved: json['qtyReserved'] as String? ?? '0',
      available: json['available'] as String? ?? '0',
      warehouseName: json['warehouseName'] as String?,
    );

Map<String, dynamic> _$SupplyBalanceToJson(SupplyBalance instance) =>
    <String, dynamic>{
      'warehouseId': instance.warehouseId,
      'qtyOnHand': instance.qtyOnHand,
      'qtyReserved': instance.qtyReserved,
      'available': instance.available,
      'warehouseName': instance.warehouseName,
    };

StockForecast _$StockForecastFromJson(Map<String, dynamic> json) =>
    StockForecast(
      supplyId: json['supplyId'] as String,
      warehouseId: json['warehouseId'] as String?,
      onHand: json['onHand'] as String? ?? '0',
      avg30: json['avg30'] as String? ?? '0',
      avg90: json['avg90'] as String? ?? '0',
      dailyUsage: json['dailyUsage'] as String? ?? '0',
      basis: json['basis'] as String? ?? 'unknown',
      daysLeft: json['daysLeft'] as num? ?? 0,
    );

Map<String, dynamic> _$StockForecastToJson(StockForecast instance) =>
    <String, dynamic>{
      'supplyId': instance.supplyId,
      'warehouseId': instance.warehouseId,
      'onHand': instance.onHand,
      'avg30': instance.avg30,
      'avg90': instance.avg90,
      'dailyUsage': instance.dailyUsage,
      'basis': instance.basis,
      'daysLeft': instance.daysLeft,
    };

StockReceipt _$StockReceiptFromJson(Map<String, dynamic> json) => StockReceipt(
  id: json['id'] as String,
  code: json['code'] as String,
  type: json['type'] as String? ?? 'purchase',
  warehouseId: json['warehouseId'] as String,
  supplierId: json['supplierId'] as String?,
  fromDepartmentId: json['fromDepartmentId'] as String?,
  invoiceNo: json['invoiceNo'] as String?,
  invoiceDate: json['invoiceDate'] as String?,
  receivedAt: json['receivedAt'] as String?,
  qcStatus: json['qcStatus'] as String? ?? 'pending',
  qcNote: json['qcNote'] as String?,
  notes: json['notes'] as String?,
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => ReceiptItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  status: json['status'] as String? ?? 'draft',
  totalAmount: json['totalAmount'] as String? ?? '0',
  postedAt: json['postedAt'] as String?,
  postedBy: json['postedBy'] as String?,
);

Map<String, dynamic> _$StockReceiptToJson(StockReceipt instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'type': instance.type,
      'warehouseId': instance.warehouseId,
      'supplierId': instance.supplierId,
      'fromDepartmentId': instance.fromDepartmentId,
      'invoiceNo': instance.invoiceNo,
      'invoiceDate': instance.invoiceDate,
      'receivedAt': instance.receivedAt,
      'qcStatus': instance.qcStatus,
      'qcNote': instance.qcNote,
      'notes': instance.notes,
      'items': instance.items,
      'status': instance.status,
      'totalAmount': instance.totalAmount,
      'postedAt': instance.postedAt,
      'postedBy': instance.postedBy,
    };

ReceiptItem _$ReceiptItemFromJson(Map<String, dynamic> json) => ReceiptItem(
  supplyId: json['supplyId'] as String,
  lotNo: json['lotNo'] as String?,
  expiresAt: json['expiresAt'] as String?,
  quantity: json['quantity'] as String? ?? '0',
  unitCost: json['unitCost'] as String? ?? '0',
);

Map<String, dynamic> _$ReceiptItemToJson(ReceiptItem instance) =>
    <String, dynamic>{
      'supplyId': instance.supplyId,
      'lotNo': instance.lotNo,
      'expiresAt': instance.expiresAt,
      'quantity': instance.quantity,
      'unitCost': instance.unitCost,
    };

StockReceiptPage _$StockReceiptPageFromJson(Map<String, dynamic> json) =>
    StockReceiptPage(
      items: (json['items'] as List<dynamic>)
          .map((e) => StockReceipt.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as num,
      page: json['page'] as num? ?? 1,
      limit: json['limit'] as num? ?? 20,
    );

Map<String, dynamic> _$StockReceiptPageToJson(StockReceiptPage instance) =>
    <String, dynamic>{
      'items': instance.items,
      'total': instance.total,
      'page': instance.page,
      'limit': instance.limit,
    };

SupplyEquipment _$SupplyEquipmentFromJson(Map<String, dynamic> json) =>
    SupplyEquipment(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
    );

Map<String, dynamic> _$SupplyEquipmentToJson(SupplyEquipment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'name': instance.name,
    };
