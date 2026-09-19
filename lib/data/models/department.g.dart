// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'department.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DepartmentRef _$DepartmentRefFromJson(Map<String, dynamic> json) =>
    DepartmentRef(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
    );

Map<String, dynamic> _$DepartmentRefToJson(DepartmentRef instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'name': instance.name,
    };

DepartmentPage _$DepartmentPageFromJson(Map<String, dynamic> json) =>
    DepartmentPage(
      items: (json['items'] as List<dynamic>)
          .map((e) => DepartmentRef.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as num? ?? 0,
      page: json['page'] as num? ?? 1,
      limit: json['limit'] as num? ?? 20,
    );

Map<String, dynamic> _$DepartmentPageToJson(DepartmentPage instance) =>
    <String, dynamic>{
      'items': instance.items,
      'total': instance.total,
      'page': instance.page,
      'limit': instance.limit,
    };
