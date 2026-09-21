// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'equipment_detail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EquipmentEnvironment _$EquipmentEnvironmentFromJson(
  Map<String, dynamic> json,
) => EquipmentEnvironment(
  temp: json['temp'] as String?,
  humidity: json['humidity'] as String?,
  ups: json['ups'] as String?,
  water: json['water'] as String?,
  gas: json['gas'] as String?,
);

Map<String, dynamic> _$EquipmentEnvironmentToJson(
  EquipmentEnvironment instance,
) => <String, dynamic>{
  'temp': instance.temp,
  'humidity': instance.humidity,
  'ups': instance.ups,
  'water': instance.water,
  'gas': instance.gas,
};

EquipmentSpecs _$EquipmentSpecsFromJson(Map<String, dynamic> json) =>
    EquipmentSpecs(
      voltage: json['voltage'] as String?,
      power: json['power'] as String?,
      dimensions: json['dimensions'] as String?,
      weight: json['weight'] as String?,
      env: json['env'] == null
          ? null
          : EquipmentEnvironment.fromJson(json['env'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$EquipmentSpecsToJson(EquipmentSpecs instance) =>
    <String, dynamic>{
      'voltage': instance.voltage,
      'power': instance.power,
      'dimensions': instance.dimensions,
      'weight': instance.weight,
      'env': instance.env,
    };

EquipmentCounts _$EquipmentCountsFromJson(Map<String, dynamic> json) =>
    EquipmentCounts(
      accessories: json['accessories'] as num? ?? 0,
      components: json['components'] as num? ?? 0,
      componentsDue: json['componentsDue'] as num? ?? 0,
      openRepairs: json['openRepairs'] as num? ?? 0,
    );

Map<String, dynamic> _$EquipmentCountsToJson(EquipmentCounts instance) =>
    <String, dynamic>{
      'accessories': instance.accessories,
      'components': instance.components,
      'componentsDue': instance.componentsDue,
      'openRepairs': instance.openRepairs,
    };

EquipmentDetail _$EquipmentDetailFromJson(
  Map<String, dynamic> json,
) => EquipmentDetail(
  id: json['id'] as String,
  code: json['code'] as String,
  name: json['name'] as String,
  assetCode: json['assetCode'] as String?,
  model: json['model'] as String?,
  serial: json['serial'] as String?,
  countryOfOrigin: json['countryOfOrigin'] as String?,
  purchaseContractNo: json['purchaseContractNo'] as String?,
  decisionNo: json['decisionNo'] as String?,
  location: json['location'] as String?,
  manufactureYear: json['manufactureYear'] as num?,
  receivedAt: json['receivedAt'] as String?,
  commissionedAt: json['commissionedAt'] as String?,
  warrantyUntil: json['warrantyUntil'] as String?,
  originalValue: json['originalValue'] as String?,
  status: json['status'] as String,
  statusNote: json['statusNote'] as String?,
  testTypes:
      (json['testTypes'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  throughputPerHour: json['throughputPerHour'] as num?,
  specs: json['specs'] == null
      ? null
      : EquipmentSpecs.fromJson(json['specs'] as Map<String, dynamic>),
  notes: json['notes'] as String?,
  qrToken: json['qrToken'] as String?,
  currentRunHours: json['currentRunHours'] as String?,
  currentTestCount: json['currentTestCount'] as num?,
  nextMaintenanceAt: json['nextMaintenanceAt'] as String?,
  lastMaintenanceAt: json['lastMaintenanceAt'] as String?,
  nextCalibrationAt: json['nextCalibrationAt'] as String?,
  lastCalibrationAt: json['lastCalibrationAt'] as String?,
  calibrationOverdue: json['calibrationOverdue'] as bool? ?? false,
  createdAt: json['createdAt'] as String?,
  updatedAt: json['updatedAt'] as String?,
  department: json['department'] == null
      ? null
      : EquipmentRef.fromJson(json['department'] as Map<String, dynamic>),
  group: json['group'] == null
      ? null
      : EquipmentRef.fromJson(json['group'] as Map<String, dynamic>),
  manufacturer: json['manufacturer'] == null
      ? null
      : EquipmentRef.fromJson(json['manufacturer'] as Map<String, dynamic>),
  supplier: json['supplier'] == null
      ? null
      : EquipmentRef.fromJson(json['supplier'] as Map<String, dynamic>),
  fundingSource: json['fundingSource'] == null
      ? null
      : EquipmentRef.fromJson(json['fundingSource'] as Map<String, dynamic>),
  staffInCharge: json['staffInCharge'] == null
      ? null
      : EquipmentUserRef.fromJson(
          json['staffInCharge'] as Map<String, dynamic>,
        ),
  deptContact: json['deptContact'] == null
      ? null
      : EquipmentUserRef.fromJson(json['deptContact'] as Map<String, dynamic>),
  counts: json['counts'] == null
      ? null
      : EquipmentCounts.fromJson(json['counts'] as Map<String, dynamic>),
  photoFileId: json['photoFileId'] as String?,
  roomId: json['roomId'] as String?,
  room: json['room'] == null
      ? null
      : RoomRef.fromJson(json['room'] as Map<String, dynamic>),
);

Map<String, dynamic> _$EquipmentDetailToJson(EquipmentDetail instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'name': instance.name,
      'assetCode': instance.assetCode,
      'model': instance.model,
      'serial': instance.serial,
      'countryOfOrigin': instance.countryOfOrigin,
      'purchaseContractNo': instance.purchaseContractNo,
      'decisionNo': instance.decisionNo,
      'location': instance.location,
      'manufactureYear': instance.manufactureYear,
      'receivedAt': instance.receivedAt,
      'commissionedAt': instance.commissionedAt,
      'warrantyUntil': instance.warrantyUntil,
      'originalValue': instance.originalValue,
      'status': instance.status,
      'statusNote': instance.statusNote,
      'testTypes': instance.testTypes,
      'throughputPerHour': instance.throughputPerHour,
      'specs': instance.specs,
      'notes': instance.notes,
      'qrToken': instance.qrToken,
      'currentRunHours': instance.currentRunHours,
      'currentTestCount': instance.currentTestCount,
      'nextMaintenanceAt': instance.nextMaintenanceAt,
      'lastMaintenanceAt': instance.lastMaintenanceAt,
      'nextCalibrationAt': instance.nextCalibrationAt,
      'lastCalibrationAt': instance.lastCalibrationAt,
      'calibrationOverdue': instance.calibrationOverdue,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      'department': instance.department,
      'group': instance.group,
      'manufacturer': instance.manufacturer,
      'supplier': instance.supplier,
      'fundingSource': instance.fundingSource,
      'staffInCharge': instance.staffInCharge,
      'deptContact': instance.deptContact,
      'counts': instance.counts,
      'photoFileId': instance.photoFileId,
      'roomId': instance.roomId,
      'room': instance.room,
    };

EquipmentNetwork _$EquipmentNetworkFromJson(Map<String, dynamic> json) =>
    EquipmentNetwork(
      ip: json['ip'] as String?,
      mac: json['mac'] as String?,
      port: json['port'] as num?,
      protocol: json['protocol'] as String?,
      lisConnected: json['lisConnected'] as bool? ?? false,
      lisNote: json['lisNote'] as String?,
      hostPcName: json['hostPcName'] as String?,
      hostPcSpec: json['hostPcSpec'] as String?,
      diagramFileId: json['diagramFileId'] as String?,
    );

Map<String, dynamic> _$EquipmentNetworkToJson(EquipmentNetwork instance) =>
    <String, dynamic>{
      'ip': instance.ip,
      'mac': instance.mac,
      'port': instance.port,
      'protocol': instance.protocol,
      'lisConnected': instance.lisConnected,
      'lisNote': instance.lisNote,
      'hostPcName': instance.hostPcName,
      'hostPcSpec': instance.hostPcSpec,
      'diagramFileId': instance.diagramFileId,
    };
