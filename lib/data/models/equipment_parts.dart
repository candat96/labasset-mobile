import 'package:json_annotation/json_annotation.dart';

part 'equipment_parts.g.dart';

/// `GET /v1/equipment/:id/accessories` → AccessoryResponseDto.
@JsonSerializable()
class EquipmentAccessory {
  const EquipmentAccessory({
    required this.id,
    required this.name,
    this.code,
    this.type = 'other',
    this.quantity = 1,
    this.condition = 'good',
    this.replacedAt,
    this.notes,
  });

  final String id;
  final String name;
  final String? code;
  final String type;
  final num quantity;
  final String condition;
  final String? replacedAt;
  final String? notes;

  factory EquipmentAccessory.fromJson(Map<String, dynamic> json) =>
      _$EquipmentAccessoryFromJson(json);
  Map<String, dynamic> toJson() => _$EquipmentAccessoryToJson(this);
}

/// `GET /v1/equipment/:id/software` → SoftwareResponseDto.
@JsonSerializable()
class EquipmentSoftware {
  const EquipmentSoftware({
    required this.id,
    required this.name,
    this.version,
    this.updatedOn,
    this.licenseExpiresAt,
    this.notes,
    this.hasLicenseKey = false,
    this.licenseKeyMasked,
  });

  final String id;
  final String name;
  final String? version;
  final String? updatedOn;
  final String? licenseExpiresAt;
  final String? notes;
  @JsonKey(defaultValue: false)
  final bool hasLicenseKey;
  final String? licenseKeyMasked;

  factory EquipmentSoftware.fromJson(Map<String, dynamic> json) =>
      _$EquipmentSoftwareFromJson(json);
  Map<String, dynamic> toJson() => _$EquipmentSoftwareToJson(this);
}

/// `GET /:id/software/:sid/history`.
@JsonSerializable()
class SoftwareHistoryItem {
  const SoftwareHistoryItem({
    required this.id,
    this.fromVersion,
    required this.toVersion,
    required this.changedAt,
    this.changedBy,
    this.note,
  });

  final String id;
  final String? fromVersion;
  final String toVersion;
  final String changedAt;
  final String? changedBy;
  final String? note;

  factory SoftwareHistoryItem.fromJson(Map<String, dynamic> json) =>
      _$SoftwareHistoryItemFromJson(json);
  Map<String, dynamic> toJson() => _$SoftwareHistoryItemToJson(this);
}

/// `GET /v1/equipment/:id/components` → ComponentResponseDto.
@JsonSerializable()
class EquipmentComponent {
  const EquipmentComponent({
    required this.id,
    required this.name,
    this.componentTypeId,
    this.partNo,
    this.serial,
    this.installedAt,
    this.lifespanHours,
    this.lifespanTests,
    this.lifespanMonths,
    this.usageHoursAtInstall = '0',
    this.usageTestsAtInstall = 0,
    this.status = 'ok',
    this.notes,
  });

  final String id;
  final String name;
  final String? componentTypeId;
  final String? partNo;
  final String? serial;
  final String? installedAt;
  final num? lifespanHours;
  final num? lifespanTests;
  final num? lifespanMonths;
  final String usageHoursAtInstall;
  final num usageTestsAtInstall;
  final String status;
  final String? notes;

  /// Đã dùng % theo giờ chạy hiện tại (0..∞) — client tự tính, API không trả.
  double? usedPct({String? currentRunHours, num? currentTestCount}) {
    final candidates = <double>[];
    final hours = _num(currentRunHours);
    if (hours != null && lifespanHours != null && lifespanHours! > 0) {
      final used = hours - _num(usageHoursAtInstall)!;
      candidates.add(used / lifespanHours!);
    }
    if (currentTestCount != null &&
        lifespanTests != null &&
        lifespanTests! > 0) {
      final used = currentTestCount - usageTestsAtInstall;
      candidates.add(used / lifespanTests!);
    }
    final months = _monthsSince(installedAt);
    if (months != null && lifespanMonths != null && lifespanMonths! > 0) {
      candidates.add(months / lifespanMonths!);
    }
    if (candidates.isEmpty) return null;
    return candidates.reduce((a, b) => a > b ? a : b).clamp(0, 10);
  }

  static double? _num(String? raw) => raw == null ? null : double.tryParse(raw);

  static double? _monthsSince(String? iso) {
    final d = iso == null ? null : DateTime.tryParse(iso);
    if (d == null) return null;
    final now = DateTime.now();
    return (now.difference(d).inDays / 30.0);
  }

  factory EquipmentComponent.fromJson(Map<String, dynamic> json) =>
      _$EquipmentComponentFromJson(json);
  Map<String, dynamic> toJson() => _$EquipmentComponentToJson(this);
}
