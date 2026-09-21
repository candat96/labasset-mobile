import 'package:json_annotation/json_annotation.dart';

part 'demand.g.dart';

/// `GET /v1/demand/periods[...]` → DemandPeriodResponseDto/DemandPeriodDetailDto.
/// Số lượng/tiền là chuỗi numeric(18,4) (`"1.2000"`).
@JsonSerializable(explicitToJson: true)
class DemandPeriod {
  const DemandPeriod({
    required this.id,
    required this.code,
    required this.name,
    required this.kind,
    required this.year,
    this.quarter,
    this.buckets = 12,
    this.submitDeadline,
    this.status = 'draft',
    this.notes,
    this.cancelReason,
    this.approvedBy,
    this.approvedAt,
    this.consolidatedAt,
    this.closedAt,
    this.createdAt,
    this.updatedAt,
    this.progress,
  });

  final String id;
  final String code;
  final String name;
  final String kind; // annual | quarterly | adhoc
  final num year;
  final num? quarter;
  final num buckets; // 12 | 4 | 1
  final String? submitDeadline;
  final String
  status; // draft|collecting|consolidating|approved|closed|cancelled
  final String? notes;
  final String? cancelReason;
  final String? approvedBy;
  final String? approvedAt;
  final String? consolidatedAt;
  final String? closedAt;
  final String? createdAt;
  final String? updatedAt;
  final DemandProgress? progress;

  factory DemandPeriod.fromJson(Map<String, dynamic> json) =>
      _$DemandPeriodFromJson(json);
  Map<String, dynamic> toJson() => _$DemandPeriodToJson(this);
}

@JsonSerializable()
class DemandProgress {
  const DemandProgress({
    required this.total,
    required this.submitted,
    required this.deptApproved,
    required this.accepted,
  });

  final num total;
  final num submitted;
  final num deptApproved;
  final num accepted;

  factory DemandProgress.fromJson(Map<String, dynamic> json) =>
      _$DemandProgressFromJson(json);
  Map<String, dynamic> toJson() => _$DemandProgressToJson(this);
}

@JsonSerializable(explicitToJson: true)
class DemandPeriodPage {
  const DemandPeriodPage({
    required this.items,
    this.total = 0,
    this.page = 1,
    this.limit = 20,
  });

  final List<DemandPeriod> items;
  final num total;
  final num page;
  final num limit;

  factory DemandPeriodPage.fromJson(Map<String, dynamic> json) =>
      _$DemandPeriodPageFromJson(json);
  Map<String, dynamic> toJson() => _$DemandPeriodPageToJson(this);
}

/// `GET /v1/demand/periods/:id/requests` → DemandDepartmentSummaryDto.
@JsonSerializable()
class DemandRequestSummary {
  const DemandRequestSummary({
    required this.requestId,
    this.departmentId,
    this.departmentCode,
    this.departmentName,
    this.status = 'draft',
    this.lineCount = 0,
    this.totalEstimated = '0',
  });

  final String requestId;
  final String? departmentId;
  final String? departmentCode;
  final String? departmentName;
  final String status;
  final num lineCount;
  final String totalEstimated;

  factory DemandRequestSummary.fromJson(Map<String, dynamic> json) =>
      _$DemandRequestSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$DemandRequestSummaryToJson(this);
}

@JsonSerializable(explicitToJson: true)
class DemandRequestSummaryPage {
  const DemandRequestSummaryPage({
    required this.items,
    this.progress,
    this.total = 0,
    this.page = 1,
    this.limit = 20,
  });

  final List<DemandRequestSummary> items;
  final DemandProgress? progress;
  final num total;
  final num page;
  final num limit;

  factory DemandRequestSummaryPage.fromJson(Map<String, dynamic> json) =>
      _$DemandRequestSummaryPageFromJson(json);
  Map<String, dynamic> toJson() => _$DemandRequestSummaryPageToJson(this);
}

/// Tham chiếu kỳ gắn trong phiếu (`period {id, code, name, status}`).
@JsonSerializable()
class DemandPeriodRef {
  const DemandPeriodRef({
    required this.id,
    required this.code,
    required this.name,
    this.status = '',
  });

  final String id;
  final String code;
  final String name;
  final String status;

  factory DemandPeriodRef.fromJson(Map<String, dynamic> json) =>
      _$DemandPeriodRefFromJson(json);
  Map<String, dynamic> toJson() => _$DemandPeriodRefToJson(this);
}

@JsonSerializable()
class DemandDepartmentRef {
  const DemandDepartmentRef({
    required this.id,
    required this.code,
    required this.name,
  });

  final String id;
  final String code;
  final String name;

  factory DemandDepartmentRef.fromJson(Map<String, dynamic> json) =>
      _$DemandDepartmentRefFromJson(json);
  Map<String, dynamic> toJson() => _$DemandDepartmentRefToJson(this);
}

@JsonSerializable()
class DemandCreatorRef {
  const DemandCreatorRef({required this.id, this.fullName = ''});

  final String id;
  final String fullName;

  factory DemandCreatorRef.fromJson(Map<String, dynamic> json) =>
      _$DemandCreatorRefFromJson(json);
  Map<String, dynamic> toJson() => _$DemandCreatorRefToJson(this);
}

/// `GET /v1/demand/requests/:id` → DemandRequestDetailDto.
@JsonSerializable(explicitToJson: true)
class DemandRequest {
  const DemandRequest({
    required this.id,
    required this.periodId,
    this.departmentId,
    this.status = 'draft',
    this.createdBy,
    this.submittedAt,
    this.deptApprovedBy,
    this.deptApprovedAt,
    this.returnReason,
    this.notes,
    this.totalEstimated = '0',
    this.createdAt,
    this.updatedAt,
    this.period,
    this.department,
    this.creator,
    this.lines = const [],
  });

  final String id;
  final String periodId;
  final String? departmentId;
  final String status;
  final String? createdBy;
  final String? submittedAt;
  final String? deptApprovedBy;
  final String? deptApprovedAt;
  final String? returnReason;
  final String? notes;
  final String totalEstimated;
  final String? createdAt;
  final String? updatedAt;
  final DemandPeriodRef? period;
  final DemandDepartmentRef? department;
  final DemandCreatorRef? creator;
  final List<DemandLine> lines;

  factory DemandRequest.fromJson(Map<String, dynamic> json) =>
      _$DemandRequestFromJson(json);
  Map<String, dynamic> toJson() => _$DemandRequestToJson(this);
}

/// `GET /v1/demand/my` → DemandRequestPageDto (items là phiếu chi tiết).
@JsonSerializable(explicitToJson: true)
class DemandRequestPage {
  const DemandRequestPage({
    required this.items,
    this.total = 0,
    this.page = 1,
    this.limit = 20,
  });

  final List<DemandRequest> items;
  final num total;
  final num page;
  final num limit;

  factory DemandRequestPage.fromJson(Map<String, dynamic> json) =>
      _$DemandRequestPageFromJson(json);
  Map<String, dynamic> toJson() => _$DemandRequestPageToJson(this);
}

/// Dòng dự trù → DemandLineResponseDto.
@JsonSerializable(explicitToJson: true)
class DemandLine {
  const DemandLine({
    required this.id,
    required this.requestId,
    this.itemType = 'supply',
    this.supplyId,
    this.equipmentId,
    this.itemName = '',
    this.spec,
    this.unit,
    this.qtyByBucket = const [],
    this.qtyRequested = '0',
    this.unitPriceEst = '0',
    this.amountEst = '0',
    this.reason,
    this.priority = 'normal',
    this.suggestedQty,
    this.suggestion,
    this.qtyApproved,
    this.approverNote,
    this.supplyCode,
    this.sortOrder = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String requestId;
  final String itemType; // supply | component | equipment | service
  final String? supplyId;
  final String? equipmentId;
  final String itemName;
  final String? spec;
  final String? unit;
  final List<String> qtyByBucket;
  final String qtyRequested;
  final String unitPriceEst;
  final String amountEst;
  final String? reason;
  final String priority; // normal | high | urgent
  final String? suggestedQty;
  final DemandSuggestion? suggestion;
  final String? qtyApproved;
  final String? approverNote;
  final String? supplyCode;
  final num sortOrder;
  final String? createdAt;
  final String? updatedAt;

  factory DemandLine.fromJson(Map<String, dynamic> json) =>
      _$DemandLineFromJson(json);
  Map<String, dynamic> toJson() => _$DemandLineToJson(this);
}

/// Snapshot gợi ý số lượng server tính (`suggestion` jsonb).
@JsonSerializable()
class DemandSuggestion {
  const DemandSuggestion({
    this.consumption12m = '0',
    this.avgMonthly = '0',
    this.onHand = '0',
    this.runwayDays,
    this.minStock = '0',
    this.maxStock = '0',
    this.lastUnitPrice = '0',
    this.basis = '',
  });

  final String consumption12m;
  final String avgMonthly;
  final String onHand;
  final num? runwayDays;
  final String minStock;
  final String maxStock;
  final String lastUnitPrice;
  final String basis; // consumption | min_stock

  factory DemandSuggestion.fromJson(Map<String, dynamic> json) =>
      _$DemandSuggestionFromJson(json);
  Map<String, dynamic> toJson() => _$DemandSuggestionToJson(this);
}

/// Dòng gộp toàn viện → DemandConsolidationRowDto.
@JsonSerializable(explicitToJson: true)
class DemandConsolidation {
  const DemandConsolidation({
    required this.id,
    required this.periodId,
    this.key = '',
    this.itemType = 'supply',
    this.supplyId,
    this.supplyCode,
    this.itemName = '',
    this.spec,
    this.unit,
    this.qtyRequested = '0',
    this.qtyApproved = '0',
    this.onHand,
    this.unitPricePlan = '0',
    this.amountPlan = '0',
    this.breakdown = const [],
    this.decision = 'buy',
    this.suggestedDecision,
    this.note,
    this.sortOrder = 0,
  });

  final String id;
  final String periodId;
  final String key;
  final String itemType;
  final String? supplyId;
  final String? supplyCode;
  final String itemName;
  final String? spec;
  final String? unit;
  final String qtyRequested;
  final String qtyApproved;
  final String? onHand;
  final String unitPricePlan;
  final String amountPlan;
  final List<DemandBreakdownEntry> breakdown;
  final String decision; // buy | from_stock | reject
  final String? suggestedDecision;
  final String? note;
  final num sortOrder;

  factory DemandConsolidation.fromJson(Map<String, dynamic> json) =>
      _$DemandConsolidationFromJson(json);
  Map<String, dynamic> toJson() => _$DemandConsolidationToJson(this);
}

@JsonSerializable()
class DemandBreakdownEntry {
  const DemandBreakdownEntry({
    this.departmentId,
    required this.requestId,
    required this.lineId,
    this.qtyRequested = '0',
    this.qtyApproved = '0',
  });

  final String? departmentId;
  final String requestId;
  final String lineId;
  final String qtyRequested;
  final String qtyApproved;

  factory DemandBreakdownEntry.fromJson(Map<String, dynamic> json) =>
      _$DemandBreakdownEntryFromJson(json);
  Map<String, dynamic> toJson() => _$DemandBreakdownEntryToJson(this);
}

@JsonSerializable(explicitToJson: true)
class DemandConsolidationList {
  const DemandConsolidationList({required this.items});

  final List<DemandConsolidation> items;

  factory DemandConsolidationList.fromJson(Map<String, dynamic> json) =>
      _$DemandConsolidationListFromJson(json);
  Map<String, dynamic> toJson() => _$DemandConsolidationListToJson(this);
}

/// `GET /v1/demand/periods/:id/summary` → KPI toàn kỳ.
@JsonSerializable(explicitToJson: true)
class DemandSummary {
  const DemandSummary({
    this.departmentsTotal = 0,
    this.departmentsSubmitted = 0,
    this.totalRequested = '0',
    this.totalApproved = '0',
    this.byItemType = const [],
  });

  final num departmentsTotal;
  final num departmentsSubmitted;
  final String totalRequested;
  final String totalApproved;
  final List<DemandSummaryByItemType> byItemType;

  factory DemandSummary.fromJson(Map<String, dynamic> json) =>
      _$DemandSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$DemandSummaryToJson(this);
}

@JsonSerializable()
class DemandSummaryByItemType {
  const DemandSummaryByItemType({
    this.itemType = 'supply',
    this.qtyRequested = '0',
    this.qtyApproved = '0',
    this.amountPlan = '0',
  });

  final String itemType;
  final String qtyRequested;
  final String qtyApproved;
  final String amountPlan;

  factory DemandSummaryByItemType.fromJson(Map<String, dynamic> json) =>
      _$DemandSummaryByItemTypeFromJson(json);
  Map<String, dynamic> toJson() => _$DemandSummaryByItemTypeToJson(this);
}

/// `/v1/me/tasks` → `demand: { toSubmit, toApprove, toAccept }`.
@JsonSerializable()
class DemandTasks {
  const DemandTasks({this.toSubmit = 0, this.toApprove = 0, this.toAccept = 0});

  final num toSubmit;
  final num toApprove;
  final num toAccept;

  bool get hasAny => toSubmit > 0 || toApprove > 0 || toAccept > 0;

  factory DemandTasks.fromJson(Map<String, dynamic> json) =>
      _$DemandTasksFromJson(json);
  Map<String, dynamic> toJson() => _$DemandTasksToJson(this);
}
