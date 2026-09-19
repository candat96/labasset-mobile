import 'package:json_annotation/json_annotation.dart';

part 'equipment.g.dart';

/// `GET /v1/equipment/by-qr/{token}` → QrEquipmentDto.
@JsonSerializable()
class QrEquipment {
  const QrEquipment({
    required this.id,
    required this.code,
    required this.name,
    this.departmentId,
    required this.status,
  });

  final String id;
  final String code;
  final String name;
  final String? departmentId;
  final String status;

  factory QrEquipment.fromJson(Map<String, dynamic> json) =>
      _$QrEquipmentFromJson(json);
  Map<String, dynamic> toJson() => _$QrEquipmentToJson(this);
}

@JsonSerializable()
class EquipmentRef {
  const EquipmentRef({
    required this.id,
    required this.code,
    required this.name,
  });
  final String id;
  final String code;
  final String name;
  factory EquipmentRef.fromJson(Map<String, dynamic> json) =>
      _$EquipmentRefFromJson(json);
  Map<String, dynamic> toJson() => _$EquipmentRefToJson(this);
}

@JsonSerializable()
class EquipmentUserRef {
  const EquipmentUserRef({
    required this.id,
    required this.username,
    required this.fullName,
  });
  final String id;
  final String username;
  final String fullName;
  factory EquipmentUserRef.fromJson(Map<String, dynamic> json) =>
      _$EquipmentUserRefFromJson(json);
  Map<String, dynamic> toJson() => _$EquipmentUserRefToJson(this);
}

/// Tập con của EquipmentDetailDto / EquipmentListItemDto đủ cho thẻ tóm tắt.
/// Các field lạ trong JSON được bỏ qua.
@JsonSerializable()
class EquipmentSummary {
  const EquipmentSummary({
    required this.id,
    required this.code,
    required this.name,
    this.model,
    this.serial,
    this.location,
    required this.status,
    this.departmentId,
    this.departmentName,
    this.groupName,
    this.manufacturerName,
    this.department,
    this.group,
    this.manufacturer,
    this.staffInCharge,
    this.warrantyUntil,
    this.nextMaintenanceAt,
    this.nextCalibrationAt,
    this.calibrationOverdue = false,
    this.imageUrl,
  });

  final String id;
  final String code;
  final String name;
  final String? model;
  final String? serial;
  final String? location;
  final String status;
  final String? departmentId;
  final String? departmentName;
  final String? groupName;
  final String? manufacturerName;
  final EquipmentRef? department;
  final EquipmentRef? group;
  final EquipmentRef? manufacturer;
  final EquipmentUserRef? staffInCharge;
  final String? warrantyUntil;
  final String? nextMaintenanceAt;
  final String? nextCalibrationAt;
  @JsonKey(defaultValue: false)
  final bool calibrationOverdue;
  final String? imageUrl;

  String? get departmentLabel => department?.name ?? departmentName;
  String? get groupLabel => group?.name ?? groupName;
  String? get manufacturerLabel => manufacturer?.name ?? manufacturerName;

  factory EquipmentSummary.fromJson(Map<String, dynamic> json) =>
      _$EquipmentSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$EquipmentSummaryToJson(this);
}

@JsonSerializable()
class EquipmentPage {
  const EquipmentPage({required this.items, required this.total});
  final List<EquipmentSummary> items;
  final num total;
  factory EquipmentPage.fromJson(Map<String, dynamic> json) =>
      _$EquipmentPageFromJson(json);
  Map<String, dynamic> toJson() => _$EquipmentPageToJson(this);
}
