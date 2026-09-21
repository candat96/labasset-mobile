// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'maintenance.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MaintenanceTask _$MaintenanceTaskFromJson(Map<String, dynamic> json) =>
    MaintenanceTask(
      id: json['id'] as String,
      code: json['code'] as String,
      planId: json['planId'] as String?,
      equipmentId: json['equipmentId'] as String,
      type: json['type'] as String? ?? 'periodic',
      scheduledAt: json['scheduledAt'] as String,
      dueAt: json['dueAt'] as String?,
      assigneeId: json['assigneeId'] as String?,
      status: json['status'] as String? ?? 'scheduled',
      startedAt: json['startedAt'] as String?,
      finishedAt: json['finishedAt'] as String?,
      templateId: json['templateId'] as String?,
      templateItems:
          (json['templateItems'] as List<dynamic>?)
              ?.map((e) => ChecklistItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      results:
          (json['results'] as List<dynamic>?)
              ?.map((e) => TaskResult.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      suppliesUsed:
          (json['suppliesUsed'] as List<dynamic>?)
              ?.map((e) => UsedSupply.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      clientVersion: json['clientVersion'] as num? ?? 0,
      overallPass: json['overallPass'] as bool?,
      notes: json['notes'] as String?,
      techSignatureFileId: json['techSignatureFileId'] as String?,
      deptSignatureFileId: json['deptSignatureFileId'] as String?,
      equipment: json['equipment'] == null
          ? null
          : EquipmentRef.fromJson(json['equipment'] as Map<String, dynamic>),
      room: json['room'] == null
          ? null
          : RoomRef.fromJson(json['room'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MaintenanceTaskToJson(MaintenanceTask instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'planId': instance.planId,
      'equipmentId': instance.equipmentId,
      'type': instance.type,
      'scheduledAt': instance.scheduledAt,
      'dueAt': instance.dueAt,
      'assigneeId': instance.assigneeId,
      'status': instance.status,
      'startedAt': instance.startedAt,
      'finishedAt': instance.finishedAt,
      'templateId': instance.templateId,
      'templateItems': instance.templateItems,
      'results': instance.results,
      'suppliesUsed': instance.suppliesUsed,
      'clientVersion': instance.clientVersion,
      'overallPass': instance.overallPass,
      'notes': instance.notes,
      'techSignatureFileId': instance.techSignatureFileId,
      'deptSignatureFileId': instance.deptSignatureFileId,
      'equipment': instance.equipment,
      'room': instance.room,
    };

ChecklistItem _$ChecklistItemFromJson(Map<String, dynamic> json) =>
    ChecklistItem(
      key: json['key'] as String,
      label: json['label'] as String,
      type: json['type'] as String? ?? 'check',
      unit: json['unit'] as String?,
      min: json['min'] as num?,
      max: json['max'] as num?,
      optional: json['optional'] as bool? ?? false,
    );

Map<String, dynamic> _$ChecklistItemToJson(ChecklistItem instance) =>
    <String, dynamic>{
      'key': instance.key,
      'label': instance.label,
      'type': instance.type,
      'unit': instance.unit,
      'min': instance.min,
      'max': instance.max,
      'optional': instance.optional,
    };

TaskResult _$TaskResultFromJson(Map<String, dynamic> json) => TaskResult(
  key: json['key'] as String,
  value: json['value'] as String?,
  pass: json['pass'] as bool?,
  note: json['note'] as String?,
  photoFileId: json['photoFileId'] as String?,
);

Map<String, dynamic> _$TaskResultToJson(TaskResult instance) =>
    <String, dynamic>{
      'key': instance.key,
      'value': instance.value,
      'pass': instance.pass,
      'note': instance.note,
      'photoFileId': instance.photoFileId,
    };

UsedSupply _$UsedSupplyFromJson(Map<String, dynamic> json) => UsedSupply(
  supplyId: json['supplyId'] as String,
  quantity: json['quantity'] as num,
  lotNo: json['lotNo'] as String?,
);

Map<String, dynamic> _$UsedSupplyToJson(UsedSupply instance) =>
    <String, dynamic>{
      'supplyId': instance.supplyId,
      'quantity': instance.quantity,
      'lotNo': instance.lotNo,
    };

TaskPageResponse _$TaskPageResponseFromJson(Map<String, dynamic> json) =>
    TaskPageResponse(
      items: (json['items'] as List<dynamic>)
          .map((e) => MaintenanceTask.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as num,
      page: json['page'] as num? ?? 1,
      limit: json['limit'] as num? ?? 20,
    );

Map<String, dynamic> _$TaskPageResponseToJson(TaskPageResponse instance) =>
    <String, dynamic>{
      'items': instance.items,
      'total': instance.total,
      'page': instance.page,
      'limit': instance.limit,
    };

Calibration _$CalibrationFromJson(Map<String, dynamic> json) => Calibration(
  id: json['id'] as String,
  code: json['code'] as String,
  equipmentId: json['equipmentId'] as String,
  type: json['type'] as String? ?? 'calibration',
  performedAt: json['performedAt'] as String?,
  scheduledAt: json['scheduledAt'] as String?,
  nextDueAt: json['nextDueAt'] as String?,
  agencyId: json['agencyId'] as String?,
  performedByUserId: json['performedByUserId'] as String?,
  performerName: json['performerName'] as String?,
  certificateNo: json['certificateNo'] as String?,
  certificateFileId: json['certificateFileId'] as String?,
  result: json['result'] as String?,
  findings: json['findings'] as String?,
  cost: json['cost'] as String?,
  cycleMonths: json['cycleMonths'] as num?,
  repairTicketId: json['repairTicketId'] as String?,
  status: json['status'] as String? ?? 'scheduled',
  createdAt: json['createdAt'] as String?,
  updatedAt: json['updatedAt'] as String?,
  room: json['room'] == null
      ? null
      : RoomRef.fromJson(json['room'] as Map<String, dynamic>),
);

Map<String, dynamic> _$CalibrationToJson(Calibration instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'equipmentId': instance.equipmentId,
      'type': instance.type,
      'performedAt': instance.performedAt,
      'scheduledAt': instance.scheduledAt,
      'nextDueAt': instance.nextDueAt,
      'agencyId': instance.agencyId,
      'performedByUserId': instance.performedByUserId,
      'performerName': instance.performerName,
      'certificateNo': instance.certificateNo,
      'certificateFileId': instance.certificateFileId,
      'result': instance.result,
      'findings': instance.findings,
      'cost': instance.cost,
      'cycleMonths': instance.cycleMonths,
      'repairTicketId': instance.repairTicketId,
      'status': instance.status,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      'room': instance.room,
    };

CalibrationPage _$CalibrationPageFromJson(Map<String, dynamic> json) =>
    CalibrationPage(
      items: (json['items'] as List<dynamic>)
          .map((e) => Calibration.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as num,
      page: json['page'] as num? ?? 1,
      limit: json['limit'] as num? ?? 20,
    );

Map<String, dynamic> _$CalibrationPageToJson(CalibrationPage instance) =>
    <String, dynamic>{
      'items': instance.items,
      'total': instance.total,
      'page': instance.page,
      'limit': instance.limit,
    };
