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
    );

Map<String, dynamic> _$SupplySummaryToJson(SupplySummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'name': instance.name,
      'isActive': instance.isActive,
      'unitId': instance.unitId,
      'groupId': instance.groupId,
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
