// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'supply.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SupplySummary _$SupplySummaryFromJson(Map<String, dynamic> json) =>
    SupplySummary(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      isActive: json['isActive'] as bool? ?? true,
      unitId: json['unitId'] as String?,
      groupId: json['groupId'] as String?,
      circulationNumber: json['circulationNumber'] as String?,
      circulationValidTo: json['circulationValidTo'] as String?,
      riskClass: json['riskClass'] as String?,
      countryOfOrigin: json['countryOfOrigin'] as String?,
      insuranceCode: json['insuranceCode'] as String?,
      insuranceName: json['insuranceName'] as String?,
      insuranceRate: json['insuranceRate'] as String?,
      insurancePrice: json['insurancePrice'] as String?,
      bidPackage: json['bidPackage'] as String?,
      bidDecisionNo: json['bidDecisionNo'] as String?,
      bidPrice: json['bidPrice'] as String?,
      bidValidTo: json['bidValidTo'] as String?,
      purchaseUnitId: json['purchaseUnitId'] as String?,
      conversionFactor: json['conversionFactor'] as String?,
      minShelfLifeDays: (json['minShelfLifeDays'] as num?)?.toInt(),
    );

Map<String, dynamic> _$SupplySummaryToJson(SupplySummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'name': instance.name,
      'isActive': instance.isActive,
      'unitId': instance.unitId,
      'groupId': instance.groupId,
      'circulationNumber': instance.circulationNumber,
      'circulationValidTo': instance.circulationValidTo,
      'riskClass': instance.riskClass,
      'countryOfOrigin': instance.countryOfOrigin,
      'insuranceCode': instance.insuranceCode,
      'insuranceName': instance.insuranceName,
      'insuranceRate': instance.insuranceRate,
      'insurancePrice': instance.insurancePrice,
      'bidPackage': instance.bidPackage,
      'bidDecisionNo': instance.bidDecisionNo,
      'bidPrice': instance.bidPrice,
      'bidValidTo': instance.bidValidTo,
      'purchaseUnitId': instance.purchaseUnitId,
      'conversionFactor': instance.conversionFactor,
      'minShelfLifeDays': instance.minShelfLifeDays,
    };

SupplyPage _$SupplyPageFromJson(Map<String, dynamic> json) => SupplyPage(
  items: (json['items'] as List<dynamic>)
      .map((e) => SupplySummary.fromJson(e as Map<String, dynamic>))
      .toList(),
  total: json['total'] as num,
  page: json['page'] as num? ?? 1,
  limit: json['limit'] as num? ?? 20,
);

Map<String, dynamic> _$SupplyPageToJson(SupplyPage instance) =>
    <String, dynamic>{
      'items': instance.items,
      'total': instance.total,
      'page': instance.page,
      'limit': instance.limit,
    };

SupplySubstitute _$SupplySubstituteFromJson(Map<String, dynamic> json) =>
    SupplySubstitute(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      unitName: json['unitName'] as String?,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$SupplySubstituteToJson(SupplySubstitute instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'name': instance.name,
      'unitName': instance.unitName,
      'notes': instance.notes,
    };
