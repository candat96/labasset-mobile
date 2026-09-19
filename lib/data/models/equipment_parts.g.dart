// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'equipment_parts.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EquipmentAccessory _$EquipmentAccessoryFromJson(Map<String, dynamic> json) =>
    EquipmentAccessory(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String?,
      type: json['type'] as String? ?? 'other',
      quantity: json['quantity'] as num? ?? 1,
      condition: json['condition'] as String? ?? 'good',
      replacedAt: json['replacedAt'] as String?,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$EquipmentAccessoryToJson(EquipmentAccessory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'code': instance.code,
      'type': instance.type,
      'quantity': instance.quantity,
      'condition': instance.condition,
      'replacedAt': instance.replacedAt,
      'notes': instance.notes,
    };

EquipmentSoftware _$EquipmentSoftwareFromJson(Map<String, dynamic> json) =>
    EquipmentSoftware(
      id: json['id'] as String,
      name: json['name'] as String,
      version: json['version'] as String?,
      updatedOn: json['updatedOn'] as String?,
      licenseExpiresAt: json['licenseExpiresAt'] as String?,
      notes: json['notes'] as String?,
      hasLicenseKey: json['hasLicenseKey'] as bool? ?? false,
      licenseKeyMasked: json['licenseKeyMasked'] as String?,
    );

Map<String, dynamic> _$EquipmentSoftwareToJson(EquipmentSoftware instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'version': instance.version,
      'updatedOn': instance.updatedOn,
      'licenseExpiresAt': instance.licenseExpiresAt,
      'notes': instance.notes,
      'hasLicenseKey': instance.hasLicenseKey,
      'licenseKeyMasked': instance.licenseKeyMasked,
    };

SoftwareHistoryItem _$SoftwareHistoryItemFromJson(Map<String, dynamic> json) =>
    SoftwareHistoryItem(
      id: json['id'] as String,
      fromVersion: json['fromVersion'] as String?,
      toVersion: json['toVersion'] as String,
      changedAt: json['changedAt'] as String,
      changedBy: json['changedBy'] as String?,
      note: json['note'] as String?,
    );

Map<String, dynamic> _$SoftwareHistoryItemToJson(
  SoftwareHistoryItem instance,
) => <String, dynamic>{
  'id': instance.id,
  'fromVersion': instance.fromVersion,
  'toVersion': instance.toVersion,
  'changedAt': instance.changedAt,
  'changedBy': instance.changedBy,
  'note': instance.note,
};

EquipmentComponent _$EquipmentComponentFromJson(Map<String, dynamic> json) =>
    EquipmentComponent(
      id: json['id'] as String,
      name: json['name'] as String,
      componentTypeId: json['componentTypeId'] as String?,
      partNo: json['partNo'] as String?,
      serial: json['serial'] as String?,
      installedAt: json['installedAt'] as String?,
      lifespanHours: json['lifespanHours'] as num?,
      lifespanTests: json['lifespanTests'] as num?,
      lifespanMonths: json['lifespanMonths'] as num?,
      usageHoursAtInstall: json['usageHoursAtInstall'] as String? ?? '0',
      usageTestsAtInstall: json['usageTestsAtInstall'] as num? ?? 0,
      status: json['status'] as String? ?? 'ok',
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$EquipmentComponentToJson(EquipmentComponent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'componentTypeId': instance.componentTypeId,
      'partNo': instance.partNo,
      'serial': instance.serial,
      'installedAt': instance.installedAt,
      'lifespanHours': instance.lifespanHours,
      'lifespanTests': instance.lifespanTests,
      'lifespanMonths': instance.lifespanMonths,
      'usageHoursAtInstall': instance.usageHoursAtInstall,
      'usageTestsAtInstall': instance.usageTestsAtInstall,
      'status': instance.status,
      'notes': instance.notes,
    };
