// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RoomRef _$RoomRefFromJson(Map<String, dynamic> json) => RoomRef(
  id: json['id'] as String?,
  code: json['code'] as String? ?? '',
  name: json['name'] as String,
  building: json['building'] as String?,
  floor: json['floor'] as String?,
  roomType: json['roomType'] as String?,
  departmentId: json['departmentId'] as String?,
  departmentCode: json['departmentCode'] as String?,
);

Map<String, dynamic> _$RoomRefToJson(RoomRef instance) => <String, dynamic>{
  'id': instance.id,
  'code': instance.code,
  'name': instance.name,
  'building': instance.building,
  'floor': instance.floor,
  'roomType': instance.roomType,
  'departmentId': instance.departmentId,
  'departmentCode': instance.departmentCode,
};
