import 'package:json_annotation/json_annotation.dart';

import 'equipment.dart';

part 'repair_detail.g.dart';

/// Một dòng nhật ký (`GET/POST /v1/repairs/:id/logs`).
@JsonSerializable()
class RepairLog {
  const RepairLog({
    this.id,
    this.ticketId,
    required this.at,
    this.byUserId,
    required this.action,
    this.note,
    this.durationMinutes,
    this.clientId,
    this.pending = false,
  });

  final String? id;
  final String? ticketId;
  final String at;
  final String? byUserId;
  final String action;
  final String? note;
  final num? durationMinutes;
  final String? clientId;

  /// Đang chờ đồng bộ (lấy từ outbox, không phải server).
  @JsonKey(defaultValue: false)
  final bool pending;

  RepairLog copyWith({bool? pending}) => RepairLog(
    id: id,
    ticketId: ticketId,
    at: at,
    byUserId: byUserId,
    action: action,
    note: note,
    durationMinutes: durationMinutes,
    clientId: clientId,
    pending: pending ?? this.pending,
  );

  factory RepairLog.fromJson(Map<String, dynamic> json) =>
      _$RepairLogFromJson(json);
  Map<String, dynamic> toJson() => _$RepairLogToJson(this);
}

@JsonSerializable()
class RepairAssignment {
  const RepairAssignment({
    required this.id,
    this.userId,
    this.role = 'primary',
    this.response = 'pending',
    this.responseNote,
    this.assignedAt,
    this.respondedAt,
  });

  final String id;
  final String? userId;
  final String role;
  final String response;
  final String? responseNote;
  final String? assignedAt;
  final String? respondedAt;

  factory RepairAssignment.fromJson(Map<String, dynamic> json) =>
      _$RepairAssignmentFromJson(json);
  Map<String, dynamic> toJson() => _$RepairAssignmentToJson(this);
}

@JsonSerializable()
class RepairPart {
  const RepairPart({
    required this.id,
    this.source = 'stock',
    this.supplyId,
    this.stockLotId,
    this.componentId,
    required this.name,
    this.quantity = '1',
    this.unitCost,
    this.totalCost,
    this.note,
  });

  final String id;
  final String source;
  final String? supplyId;
  final String? stockLotId;
  final String? componentId;
  final String name;
  final String quantity;
  final String? unitCost;
  final String? totalCost;
  final String? note;

  factory RepairPart.fromJson(Map<String, dynamic> json) =>
      _$RepairPartFromJson(json);
  Map<String, dynamic> toJson() => _$RepairPartToJson(this);
}

@JsonSerializable()
class RepairCost {
  const RepairCost({
    required this.id,
    this.category = 'other',
    this.description = '',
    this.amount = '0',
    this.invoiceNo,
    this.invoiceDate,
    this.paidAt,
  });

  final String id;
  final String category;
  final String description;
  final String amount;
  final String? invoiceNo;
  final String? invoiceDate;
  final String? paidAt;

  factory RepairCost.fromJson(Map<String, dynamic> json) =>
      _$RepairCostFromJson(json);
  Map<String, dynamic> toJson() => _$RepairCostToJson(this);
}

@JsonSerializable()
class RepairVendor {
  const RepairVendor({
    required this.id,
    this.supplierId,
    this.engineerName,
    this.engineerPhone,
    this.contractNo,
    this.quotationAmount,
    this.visitAt,
    this.note,
  });

  final String id;
  final String? supplierId;
  final String? engineerName;
  final String? engineerPhone;
  final String? contractNo;
  final String? quotationAmount;
  final String? visitAt;
  final String? note;

  factory RepairVendor.fromJson(Map<String, dynamic> json) =>
      _$RepairVendorFromJson(json);
  Map<String, dynamic> toJson() => _$RepairVendorToJson(this);
}

/// `GET /v1/repairs/:id` → RepairDetailDto (tập con đủ dùng).
@JsonSerializable()
class RepairDetail {
  const RepairDetail({
    required this.id,
    required this.code,
    required this.equipmentId,
    this.reportedBy,
    this.reportedDepartmentId,
    this.description = '',
    this.errorCode,
    this.severity = 'medium',
    this.equipmentDown = false,
    this.status = 'new',
    this.faultId,
    this.diagnosis,
    this.faultGroupId,
    this.resolutionType,
    this.assigneeId,
    this.assistantIds = const [],
    this.dueAt,
    this.acceptedAt,
    this.startedAt,
    this.completedAt,
    this.acceptedByDeptAt,
    this.closedAt,
    this.resolutionSummary,
    this.postRepairWarrantyUntil,
    this.rating,
    this.ratingNote,
    this.calibrationRequired = false,
    this.calibrationTicketId,
    this.totalCost = '0',
    this.costWarning = false,
    this.createdAt,
    this.updatedAt,
    this.isOverdue = false,
    this.equipment,
    this.assignee,
    this.logs = const [],
    this.parts = const [],
    this.costs = const [],
    this.vendors = const [],
    this.assignments = const [],
    this.faultInfo,
  });

  final String id;
  final String code;
  final String equipmentId;
  final String? reportedBy;
  final String? reportedDepartmentId;
  final String description;
  final String? errorCode;
  final String severity;
  final bool equipmentDown;
  final String status;
  final String? faultId;
  final String? diagnosis;
  final String? faultGroupId;
  final String? resolutionType;
  final String? assigneeId;
  final List<String> assistantIds;
  final String? dueAt;
  final String? acceptedAt;
  final String? startedAt;
  final String? completedAt;
  final String? acceptedByDeptAt;
  final String? closedAt;
  final String? resolutionSummary;
  final String? postRepairWarrantyUntil;
  final num? rating;
  final String? ratingNote;
  @JsonKey(defaultValue: false)
  final bool calibrationRequired;
  final String? calibrationTicketId;
  final String totalCost;
  @JsonKey(defaultValue: false)
  final bool costWarning;
  final String? createdAt;
  final String? updatedAt;
  @JsonKey(defaultValue: false)
  final bool isOverdue;
  final EquipmentRef? equipment;
  final RepairAssigneeRef? assignee;
  final List<RepairLog> logs;
  final List<RepairPart> parts;
  final List<RepairCost> costs;
  final List<RepairVendor> vendors;
  final List<RepairAssignment> assignments;
  final Map<String, dynamic>? faultInfo;

  String get equipmentLabel => equipment == null
      ? equipmentId
      : '${equipment!.code} — ${equipment!.name}';

  /// Assignment đang chờ phản hồi của một user.
  RepairAssignment? pendingAssignmentFor(String? userId) {
    if (userId == null) return null;
    for (final a in assignments) {
      if (a.userId == userId && a.response == 'pending') return a;
    }
    return null;
  }

  factory RepairDetail.fromJson(Map<String, dynamic> json) =>
      _$RepairDetailFromJson(json);
  Map<String, dynamic> toJson() => _$RepairDetailToJson(this);
}

@JsonSerializable()
class RepairAssigneeRef {
  const RepairAssigneeRef({required this.id, this.fullName = ''});

  final String id;
  final String fullName;

  factory RepairAssigneeRef.fromJson(Map<String, dynamic> json) =>
      _$RepairAssigneeRefFromJson(json);
  Map<String, dynamic> toJson() => _$RepairAssigneeRefToJson(this);
}

/// `GET /v1/repairs/assign/suggest` → { id, fullName, openTickets }.
@JsonSerializable()
class AssignSuggestItem {
  const AssignSuggestItem({
    required this.id,
    this.fullName = '',
    this.openTickets = 0,
  });

  final String id;
  final String fullName;
  final num openTickets;

  factory AssignSuggestItem.fromJson(Map<String, dynamic> json) =>
      _$AssignSuggestItemFromJson(json);
  Map<String, dynamic> toJson() => _$AssignSuggestItemToJson(this);
}

/// `GET /v1/faults/suggest` → FaultSuggestionMatchDto.
@JsonSerializable()
class FaultSuggestionMatch {
  const FaultSuggestionMatch({
    required this.fault,
    this.score = 0,
    this.matchedBy = 'all',
    this.onEquipment = 0,
    this.sameModel = 0,
  });

  final SuggestedFault fault;
  final num score;
  final String matchedBy;
  final num onEquipment;
  final num sameModel;

  factory FaultSuggestionMatch.fromJson(Map<String, dynamic> json) {
    final occurrences =
        json['occurrences'] as Map<String, dynamic>? ?? const {};
    return FaultSuggestionMatch(
      fault: SuggestedFault.fromJson(
        json['fault'] as Map<String, dynamic>? ?? const {},
      ),
      score: (json['score'] as num?) ?? 0,
      matchedBy: (json['matchedBy'] as String?) ?? 'all',
      onEquipment: (occurrences['onEquipment'] as num?) ?? 0,
      sameModel: (occurrences['sameModel'] as num?) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'fault': fault.toJson(),
    'score': score,
    'matchedBy': matchedBy,
    'occurrences': {'onEquipment': onEquipment, 'sameModel': sameModel},
  };
}

@JsonSerializable()
class SuggestedFault {
  const SuggestedFault({
    required this.id,
    this.title = '',
    this.errorCode = '',
    this.severity = 'medium',
    this.model = '',
  });

  final String id;
  final String title;
  final String errorCode;
  final String severity;
  final String model;

  factory SuggestedFault.fromJson(Map<String, dynamic> json) =>
      _$SuggestedFaultFromJson(json);
  Map<String, dynamic> toJson() => _$SuggestedFaultToJson(this);
}

/// `GET /v1/repairs/stats` → totals.
@JsonSerializable()
class RepairStats {
  const RepairStats({
    this.tickets = 0,
    this.completed = 0,
    this.cost = '0',
    this.mttrHours = 0,
    this.downtimeHours = 0,
  });

  final num tickets;
  final num completed;
  final String cost;
  final num mttrHours;
  final num downtimeHours;

  factory RepairStats.fromJson(Map<String, dynamic> json) {
    final totals = json['totals'] as Map<String, dynamic>? ?? json;
    return RepairStats(
      tickets: (totals['tickets'] as num?) ?? 0,
      completed: (totals['completed'] as num?) ?? 0,
      cost: (totals['cost'] as String?) ?? '0',
      mttrHours: (totals['mttrHours'] as num?) ?? 0,
      downtimeHours: (totals['downtimeHours'] as num?) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => _$RepairStatsToJson(this);
}

/// `GET /v1/repairs/workload`.
@JsonSerializable()
class WorkloadItem {
  const WorkloadItem({
    required this.id,
    this.fullName = '',
    this.open = 0,
    this.overdue = 0,
    this.awaitingResponse = 0,
  });

  final String id;
  final String fullName;
  final num open;
  final num overdue;
  final num awaitingResponse;

  factory WorkloadItem.fromJson(Map<String, dynamic> json) =>
      _$WorkloadItemFromJson(json);
  Map<String, dynamic> toJson() => _$WorkloadItemToJson(this);
}
