import 'package:json_annotation/json_annotation.dart';

part 'equipment_extras.g.dart';

/// `GET /v1/equipment/:id/supplies` → SupplyResponseDto (mapping máy–vật tư).
@JsonSerializable()
class EquipmentSupplyLink {
  const EquipmentSupplyLink({
    required this.supplyId,
    this.normQtyPerTest,
    this.normQtyPerDay,
    this.isPrimary = false,
    this.notes,
  });

  final String supplyId;
  final String? normQtyPerTest;
  final String? normQtyPerDay;
  final bool isPrimary;
  final String? notes;

  factory EquipmentSupplyLink.fromJson(Map<String, dynamic> json) =>
      _$EquipmentSupplyLinkFromJson(json);
  Map<String, dynamic> toJson() => _$EquipmentSupplyLinkToJson(this);
}

/// `GET /:id/supplies/runway` → RunwayResponseDto.
@JsonSerializable()
class EquipmentRunway {
  const EquipmentRunway({
    required this.equipmentId,
    this.scope = 'department',
    this.items = const [],
  });

  final String equipmentId;
  final String scope;
  final List<RunwayItem> items;

  factory EquipmentRunway.fromJson(Map<String, dynamic> json) =>
      _$EquipmentRunwayFromJson(json);
  Map<String, dynamic> toJson() => _$EquipmentRunwayToJson(this);
}

@JsonSerializable()
class RunwayItem {
  const RunwayItem({
    required this.supplyId,
    this.isPrimary = false,
    this.onHand = '0',
    this.dailyUsage = '0',
    this.daysLeft = 0,
    this.basis = 'unknown',
  });

  final String supplyId;
  final bool isPrimary;
  final String onHand;
  final String dailyUsage;
  final num daysLeft;
  final String basis;

  factory RunwayItem.fromJson(Map<String, dynamic> json) =>
      _$RunwayItemFromJson(json);
  Map<String, dynamic> toJson() => _$RunwayItemToJson(this);
}

/// `GET /v1/equipment/:id/events` → EventResponseDto.
@JsonSerializable()
class EquipmentEvent {
  const EquipmentEvent({
    required this.id,
    required this.type,
    required this.title,
    this.summary,
    this.refType,
    this.refId,
    this.byUserId,
    required this.at,
  });

  final String id;
  final String type;
  final String title;
  final String? summary;
  final String? refType;
  final String? refId;
  final String? byUserId;
  final String at;

  factory EquipmentEvent.fromJson(Map<String, dynamic> json) =>
      _$EquipmentEventFromJson(json);
  Map<String, dynamic> toJson() => _$EquipmentEventToJson(this);
}

@JsonSerializable()
class EquipmentEventPage {
  const EquipmentEventPage({
    required this.items,
    required this.total,
    this.page = 1,
    this.limit = 20,
  });

  final List<EquipmentEvent> items;
  final num total;
  final num page;
  final num limit;

  factory EquipmentEventPage.fromJson(Map<String, dynamic> json) =>
      _$EquipmentEventPageFromJson(json);
  Map<String, dynamic> toJson() => _$EquipmentEventPageToJson(this);
}

/// `GET /v1/equipment/:id/transfers` → TransferResponseDto.
@JsonSerializable()
class EquipmentTransfer {
  const EquipmentTransfer({
    required this.id,
    required this.equipmentId,
    this.fromDepartmentId,
    this.toDepartmentId,
    this.fromLocation,
    this.toLocation,
    this.reason,
    this.status = 'pending',
    this.requestedBy,
    this.approvedBy,
    this.minutesFileId,
    this.createdAt,
    this.toDepartmentName,
  });

  final String id;
  final String equipmentId;
  final String? fromDepartmentId;
  final String? toDepartmentId;
  final String? fromLocation;
  final String? toLocation;
  final String? reason;
  final String status;
  final String? requestedBy;
  final String? approvedBy;
  final String? minutesFileId;
  final String? createdAt;
  final String? toDepartmentName;

  factory EquipmentTransfer.fromJson(Map<String, dynamic> json) =>
      _$EquipmentTransferFromJson(json);
  Map<String, dynamic> toJson() => _$EquipmentTransferToJson(this);
}

@JsonSerializable()
class EquipmentTransferPage {
  const EquipmentTransferPage({
    required this.items,
    required this.total,
    this.page = 1,
    this.limit = 20,
  });

  final List<EquipmentTransfer> items;
  final num total;
  final num page;
  final num limit;

  factory EquipmentTransferPage.fromJson(Map<String, dynamic> json) =>
      _$EquipmentTransferPageFromJson(json);
  Map<String, dynamic> toJson() => _$EquipmentTransferPageToJson(this);
}

/// `GET /v1/faults` → FaultListItemDto (thư viện lỗi theo model).
@JsonSerializable()
class FaultItem {
  const FaultItem({
    required this.id,
    required this.title,
    this.scope = 'all',
    this.model = '',
    this.errorCode = '',
    this.severity = 'medium',
    this.status = 'published',
    this.version = 1,
    this.helpfulCount = 0,
    this.viewCount = 0,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String scope;
  final String model;
  final String errorCode;
  final String severity;
  final String status;
  final num version;
  final num helpfulCount;
  final num viewCount;
  final String? updatedAt;

  factory FaultItem.fromJson(Map<String, dynamic> json) =>
      _$FaultItemFromJson(json);
  Map<String, dynamic> toJson() => _$FaultItemToJson(this);
}

@JsonSerializable()
class FaultPage {
  const FaultPage({
    required this.items,
    required this.total,
    this.page = 1,
    this.limit = 20,
  });

  final List<FaultItem> items;
  final num total;
  final num page;
  final num limit;

  factory FaultPage.fromJson(Map<String, dynamic> json) =>
      _$FaultPageFromJson(json);
  Map<String, dynamic> toJson() => _$FaultPageToJson(this);
}
