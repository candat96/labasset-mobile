// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'equipment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QrEquipment _$QrEquipmentFromJson(Map<String, dynamic> json) => QrEquipment(
  id: json['id'] as String,
  code: json['code'] as String,
  name: json['name'] as String,
  departmentId: json['departmentId'] as String?,
  status: json['status'] as String,
  roomId: json['roomId'] as String?,
  room: json['room'] == null
      ? null
      : RoomRef.fromJson(json['room'] as Map<String, dynamic>),
  location: json['location'] as String?,
);

Map<String, dynamic> _$QrEquipmentToJson(QrEquipment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'name': instance.name,
      'departmentId': instance.departmentId,
      'status': instance.status,
      'roomId': instance.roomId,
      'room': instance.room,
      'location': instance.location,
    };

EquipmentRef _$EquipmentRefFromJson(Map<String, dynamic> json) => EquipmentRef(
  id: json['id'] as String,
  code: json['code'] as String,
  name: json['name'] as String,
);

Map<String, dynamic> _$EquipmentRefToJson(EquipmentRef instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'name': instance.name,
    };

EquipmentUserRef _$EquipmentUserRefFromJson(Map<String, dynamic> json) =>
    EquipmentUserRef(
      id: json['id'] as String,
      username: json['username'] as String,
      fullName: json['fullName'] as String,
    );

Map<String, dynamic> _$EquipmentUserRefToJson(EquipmentUserRef instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'fullName': instance.fullName,
    };

EquipmentSummary _$EquipmentSummaryFromJson(Map<String, dynamic> json) =>
    EquipmentSummary(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      model: json['model'] as String?,
      serial: json['serial'] as String?,
      location: json['location'] as String?,
      status: json['status'] as String,
      departmentId: json['departmentId'] as String?,
      departmentName: json['departmentName'] as String?,
      groupName: json['groupName'] as String?,
      manufacturerName: json['manufacturerName'] as String?,
      department: json['department'] == null
          ? null
          : EquipmentRef.fromJson(json['department'] as Map<String, dynamic>),
      group: json['group'] == null
          ? null
          : EquipmentRef.fromJson(json['group'] as Map<String, dynamic>),
      manufacturer: json['manufacturer'] == null
          ? null
          : EquipmentRef.fromJson(json['manufacturer'] as Map<String, dynamic>),
      staffInCharge: json['staffInCharge'] == null
          ? null
          : EquipmentUserRef.fromJson(
              json['staffInCharge'] as Map<String, dynamic>,
            ),
      warrantyUntil: json['warrantyUntil'] as String?,
      nextMaintenanceAt: json['nextMaintenanceAt'] as String?,
      nextCalibrationAt: json['nextCalibrationAt'] as String?,
      calibrationOverdue: json['calibrationOverdue'] as bool? ?? false,
      imageUrl: json['imageUrl'] as String?,
      roomId: json['roomId'] as String?,
      room: json['room'] == null
          ? null
          : RoomRef.fromJson(json['room'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$EquipmentSummaryToJson(EquipmentSummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'name': instance.name,
      'model': instance.model,
      'serial': instance.serial,
      'location': instance.location,
      'status': instance.status,
      'departmentId': instance.departmentId,
      'departmentName': instance.departmentName,
      'groupName': instance.groupName,
      'manufacturerName': instance.manufacturerName,
      'department': instance.department,
      'group': instance.group,
      'manufacturer': instance.manufacturer,
      'staffInCharge': instance.staffInCharge,
      'warrantyUntil': instance.warrantyUntil,
      'nextMaintenanceAt': instance.nextMaintenanceAt,
      'nextCalibrationAt': instance.nextCalibrationAt,
      'calibrationOverdue': instance.calibrationOverdue,
      'imageUrl': instance.imageUrl,
      'roomId': instance.roomId,
      'room': instance.room,
    };

EquipmentPage _$EquipmentPageFromJson(Map<String, dynamic> json) =>
    EquipmentPage(
      items: (json['items'] as List<dynamic>)
          .map((e) => EquipmentSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as num,
    );

Map<String, dynamic> _$EquipmentPageToJson(EquipmentPage instance) =>
    <String, dynamic>{'items': instance.items, 'total': instance.total};
