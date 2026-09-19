import 'package:json_annotation/json_annotation.dart';

import 'equipment.dart';

part 'maintenance.g.dart';

/// `GET /v1/maintenance/tasks/:id` → TaskDetailDto.
@JsonSerializable()
class MaintenanceTask {
  const MaintenanceTask({
    required this.id,
    required this.code,
    this.planId,
    required this.equipmentId,
    this.type = 'periodic',
    required this.scheduledAt,
    this.dueAt,
    this.assigneeId,
    this.status = 'scheduled',
    this.startedAt,
    this.finishedAt,
    this.templateId,
    this.templateItems = const [],
    this.results = const [],
    this.suppliesUsed = const [],
    this.clientVersion = 0,
    this.overallPass,
    this.notes,
    this.techSignatureFileId,
    this.deptSignatureFileId,
    this.equipment,
  });

  final String id;
  final String code;
  final String? planId;
  final String equipmentId;
  final String type;
  final String scheduledAt;
  final String? dueAt;
  final String? assigneeId;
  final String status;
  final String? startedAt;
  final String? finishedAt;
  final String? templateId;
  final List<ChecklistItem> templateItems;
  final List<TaskResult> results;
  final List<UsedSupply> suppliesUsed;
  final num clientVersion;
  final bool? overallPass;
  final String? notes;
  final String? techSignatureFileId;
  final String? deptSignatureFileId;
  final EquipmentRef? equipment;

  String get equipmentLabel => equipment == null
      ? equipmentId
      : '${equipment!.code} — ${equipment!.name}';

  factory MaintenanceTask.fromJson(Map<String, dynamic> json) =>
      _$MaintenanceTaskFromJson(json);
  Map<String, dynamic> toJson() => _$MaintenanceTaskToJson(this);
}

@JsonSerializable()
class ChecklistItem {
  const ChecklistItem({
    required this.key,
    required this.label,
    this.type = 'check',
    this.unit,
    this.min,
    this.max,
    this.optional = false,
  });

  final String key;
  final String label;
  final String type;
  final String? unit;
  final num? min;
  final num? max;
  final bool optional;

  factory ChecklistItem.fromJson(Map<String, dynamic> json) =>
      _$ChecklistItemFromJson(json);
  Map<String, dynamic> toJson() => _$ChecklistItemToJson(this);
}

@JsonSerializable()
class TaskResult {
  const TaskResult({
    required this.key,
    this.value,
    this.pass,
    this.note,
    this.photoFileId,
  });

  final String key;
  final String? value;
  final bool? pass;
  final String? note;
  final String? photoFileId;

  TaskResult copyWith({
    String? value,
    bool? pass,
    String? note,
    String? photoFileId,
  }) => TaskResult(
    key: key,
    value: value ?? this.value,
    pass: pass ?? this.pass,
    note: note ?? this.note,
    photoFileId: photoFileId ?? this.photoFileId,
  );

  factory TaskResult.fromJson(Map<String, dynamic> json) =>
      _$TaskResultFromJson(json);
  Map<String, dynamic> toJson() => _$TaskResultToJson(this);
}

@JsonSerializable()
class UsedSupply {
  const UsedSupply({
    required this.supplyId,
    required this.quantity,
    this.lotNo,
  });

  final String supplyId;
  final num quantity;
  final String? lotNo;

  factory UsedSupply.fromJson(Map<String, dynamic> json) =>
      _$UsedSupplyFromJson(json);
  Map<String, dynamic> toJson() => _$UsedSupplyToJson(this);
}

@JsonSerializable()
class TaskPageResponse {
  const TaskPageResponse({
    required this.items,
    required this.total,
    this.page = 1,
    this.limit = 20,
  });

  final List<MaintenanceTask> items;
  final num total;
  final num page;
  final num limit;

  factory TaskPageResponse.fromJson(Map<String, dynamic> json) =>
      _$TaskPageResponseFromJson(json);
  Map<String, dynamic> toJson() => _$TaskPageResponseToJson(this);
}

/// `GET /v1/calibrations` → CalibrationResponseDto.
@JsonSerializable()
class Calibration {
  const Calibration({
    required this.id,
    required this.code,
    required this.equipmentId,
    this.type = 'calibration',
    this.performedAt,
    this.scheduledAt,
    this.nextDueAt,
    this.agencyId,
    this.performedByUserId,
    this.performerName,
    this.certificateNo,
    this.certificateFileId,
    this.result,
    this.findings,
    this.cost,
    this.cycleMonths,
    this.repairTicketId,
    this.status = 'scheduled',
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String code;
  final String equipmentId;
  final String type;
  final String? performedAt;
  final String? scheduledAt;
  final String? nextDueAt;
  final String? agencyId;
  final String? performedByUserId;
  final String? performerName;
  final String? certificateNo;
  final String? certificateFileId;
  final String? result;
  final String? findings;
  final String? cost;
  final num? cycleMonths;
  final String? repairTicketId;
  final String status;
  final String? createdAt;
  final String? updatedAt;

  factory Calibration.fromJson(Map<String, dynamic> json) =>
      _$CalibrationFromJson(json);
  Map<String, dynamic> toJson() => _$CalibrationToJson(this);
}

@JsonSerializable()
class CalibrationPage {
  const CalibrationPage({
    required this.items,
    required this.total,
    this.page = 1,
    this.limit = 20,
  });

  final List<Calibration> items;
  final num total;
  final num page;
  final num limit;

  factory CalibrationPage.fromJson(Map<String, dynamic> json) =>
      _$CalibrationPageFromJson(json);
  Map<String, dynamic> toJson() => _$CalibrationPageToJson(this);
}
