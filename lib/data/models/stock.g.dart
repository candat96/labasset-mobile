// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StockAlertSummary _$StockAlertSummaryFromJson(Map<String, dynamic> json) =>
    StockAlertSummary(
      id: json['id'] as String,
      type: json['type'] as String,
      supplyId: json['supplyId'] as String,
      warehouseId: json['warehouseId'] as String?,
      lotId: json['lotId'] as String?,
      level: json['level'] as String?,
      message: json['message'] as String? ?? '',
      createdAt: json['createdAt'] as String?,
      resolvedAt: json['resolvedAt'] as String?,
    );

Map<String, dynamic> _$StockAlertSummaryToJson(StockAlertSummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'supplyId': instance.supplyId,
      'warehouseId': instance.warehouseId,
      'lotId': instance.lotId,
      'level': instance.level,
      'message': instance.message,
      'createdAt': instance.createdAt,
      'resolvedAt': instance.resolvedAt,
    };

StockAlertPage _$StockAlertPageFromJson(Map<String, dynamic> json) =>
    StockAlertPage(
      items: (json['items'] as List<dynamic>)
          .map((e) => StockAlertSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as num,
      page: json['page'] as num? ?? 1,
      limit: json['limit'] as num? ?? 20,
    );

Map<String, dynamic> _$StockAlertPageToJson(StockAlertPage instance) =>
    <String, dynamic>{
      'items': instance.items,
      'total': instance.total,
      'page': instance.page,
      'limit': instance.limit,
    };

StockLotSummary _$StockLotSummaryFromJson(Map<String, dynamic> json) =>
    StockLotSummary(
      id: json['id'] as String,
      supplyId: json['supplyId'] as String,
      warehouseId: json['warehouseId'] as String?,
      lotNo: json['lotNo'] as String,
      qtyOnHand: json['qtyOnHand'] as String? ?? '0',
      qtyReserved: json['qtyReserved'] as String? ?? '0',
      available: json['available'] as String? ?? '0',
      unitCost: json['unitCost'] as String? ?? '0',
      status: json['status'] as String? ?? 'available',
      expiresAt: json['expiresAt'] as String?,
      effectiveExpiresAt: json['effectiveExpiresAt'] as String?,
    );

Map<String, dynamic> _$StockLotSummaryToJson(StockLotSummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'supplyId': instance.supplyId,
      'warehouseId': instance.warehouseId,
      'lotNo': instance.lotNo,
      'qtyOnHand': instance.qtyOnHand,
      'qtyReserved': instance.qtyReserved,
      'available': instance.available,
      'unitCost': instance.unitCost,
      'status': instance.status,
      'expiresAt': instance.expiresAt,
      'effectiveExpiresAt': instance.effectiveExpiresAt,
    };

StockLotPage _$StockLotPageFromJson(Map<String, dynamic> json) => StockLotPage(
  items: (json['items'] as List<dynamic>)
      .map((e) => StockLotSummary.fromJson(e as Map<String, dynamic>))
      .toList(),
  total: json['total'] as num,
  page: json['page'] as num? ?? 1,
  limit: json['limit'] as num? ?? 20,
);

Map<String, dynamic> _$StockLotPageToJson(StockLotPage instance) =>
    <String, dynamic>{
      'items': instance.items,
      'total': instance.total,
      'page': instance.page,
      'limit': instance.limit,
    };
