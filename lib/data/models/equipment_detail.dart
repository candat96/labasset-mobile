import 'package:json_annotation/json_annotation.dart';

import 'equipment.dart';

part 'equipment_detail.g.dart';

@JsonSerializable()
class EquipmentEnvironment {
  const EquipmentEnvironment({
    this.temp,
    this.humidity,
    this.ups,
    this.water,
    this.gas,
  });

  final String? temp;
  final String? humidity;
  final String? ups;
  final String? water;
  final String? gas;

  factory EquipmentEnvironment.fromJson(Map<String, dynamic> json) =>
      _$EquipmentEnvironmentFromJson(json);
  Map<String, dynamic> toJson() => _$EquipmentEnvironmentToJson(this);
}

@JsonSerializable()
class EquipmentSpecs {
  const EquipmentSpecs({
    this.voltage,
    this.power,
    this.dimensions,
    this.weight,
    this.env,
  });

  final String? voltage;
  final String? power;
  final String? dimensions;
  final String? weight;
  final EquipmentEnvironment? env;

  factory EquipmentSpecs.fromJson(Map<String, dynamic> json) =>
      _$EquipmentSpecsFromJson(json);
  Map<String, dynamic> toJson() => _$EquipmentSpecsToJson(this);
}

@JsonSerializable()
class EquipmentCounts {
  const EquipmentCounts({
    this.accessories = 0,
    this.components = 0,
    this.componentsDue = 0,
    this.openRepairs = 0,
  });

  final num accessories;
  final num components;
  final num componentsDue;
  final num openRepairs;

  factory EquipmentCounts.fromJson(Map<String, dynamic> json) =>
      _$EquipmentCountsFromJson(json);
  Map<String, dynamic> toJson() => _$EquipmentCountsToJson(this);
}

/// `GET /v1/equipment/:id` → EquipmentDetailDto.
@JsonSerializable()
class EquipmentDetail {
  const EquipmentDetail({
    required this.id,
    required this.code,
    required this.name,
    this.assetCode,
    this.model,
    this.serial,
    this.countryOfOrigin,
    this.purchaseContractNo,
    this.decisionNo,
    this.location,
    this.manufactureYear,
    this.receivedAt,
    this.commissionedAt,
    this.warrantyUntil,
    this.originalValue,
    required this.status,
    this.statusNote,
    this.testTypes = const [],
    this.throughputPerHour,
    this.specs,
    this.notes,
    this.qrToken,
    this.currentRunHours,
    this.currentTestCount,
    this.nextMaintenanceAt,
    this.lastMaintenanceAt,
    this.nextCalibrationAt,
    this.lastCalibrationAt,
    this.calibrationOverdue = false,
    this.createdAt,
    this.updatedAt,
    this.department,
    this.group,
    this.manufacturer,
    this.supplier,
    this.fundingSource,
    this.staffInCharge,
    this.deptContact,
    this.counts,
    this.photoFileId,
  });

  final String id;
  final String code;
  final String name;
  final String? assetCode;
  final String? model;
  final String? serial;
  final String? countryOfOrigin;
  final String? purchaseContractNo;
  final String? decisionNo;
  final String? location;
  final num? manufactureYear;
  final String? receivedAt;
  final String? commissionedAt;
  final String? warrantyUntil;
  final String? originalValue;
  final String status;
  final String? statusNote;
  final List<String> testTypes;
  final num? throughputPerHour;
  final EquipmentSpecs? specs;
  final String? notes;
  final String? qrToken;
  final String? currentRunHours;
  final num? currentTestCount;
  final String? nextMaintenanceAt;
  final String? lastMaintenanceAt;
  final String? nextCalibrationAt;
  final String? lastCalibrationAt;
  @JsonKey(defaultValue: false)
  final bool calibrationOverdue;
  final String? createdAt;
  final String? updatedAt;
  final EquipmentRef? department;
  final EquipmentRef? group;
  final EquipmentRef? manufacturer;
  final EquipmentRef? supplier;
  final EquipmentRef? fundingSource;
  final EquipmentUserRef? staffInCharge;
  final EquipmentUserRef? deptContact;
  final EquipmentCounts? counts;
  final String? photoFileId;

  factory EquipmentDetail.fromJson(Map<String, dynamic> json) =>
      _$EquipmentDetailFromJson(json);
  Map<String, dynamic> toJson() => _$EquipmentDetailToJson(this);
}

/// `GET/PUT /v1/equipment/:id/network` → NetworkDto.
@JsonSerializable()
class EquipmentNetwork {
  const EquipmentNetwork({
    this.ip,
    this.mac,
    this.port,
    this.protocol,
    this.lisConnected = false,
    this.lisNote,
    this.hostPcName,
    this.hostPcSpec,
    this.diagramFileId,
  });

  final String? ip;
  final String? mac;
  final num? port;
  final String? protocol;
  @JsonKey(defaultValue: false)
  final bool lisConnected;
  final String? lisNote;
  final String? hostPcName;
  final String? hostPcSpec;
  final String? diagramFileId;

  EquipmentNetwork copyWith({
    String? ip,
    String? mac,
    num? port,
    String? protocol,
    bool? lisConnected,
    String? lisNote,
    String? hostPcName,
    String? hostPcSpec,
    String? diagramFileId,
  }) => EquipmentNetwork(
    ip: ip ?? this.ip,
    mac: mac ?? this.mac,
    port: port ?? this.port,
    protocol: protocol ?? this.protocol,
    lisConnected: lisConnected ?? this.lisConnected,
    lisNote: lisNote ?? this.lisNote,
    hostPcName: hostPcName ?? this.hostPcName,
    hostPcSpec: hostPcSpec ?? this.hostPcSpec,
    diagramFileId: diagramFileId ?? this.diagramFileId,
  );

  factory EquipmentNetwork.fromJson(Map<String, dynamic> json) =>
      _$EquipmentNetworkFromJson(json);
  Map<String, dynamic> toJson() => _$EquipmentNetworkToJson(this);
}
