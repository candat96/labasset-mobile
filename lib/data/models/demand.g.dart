// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'demand.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DemandPeriod _$DemandPeriodFromJson(Map<String, dynamic> json) => DemandPeriod(
  id: json['id'] as String,
  code: json['code'] as String,
  name: json['name'] as String,
  kind: json['kind'] as String,
  year: json['year'] as num,
  quarter: json['quarter'] as num?,
  buckets: json['buckets'] as num? ?? 12,
  submitDeadline: json['submitDeadline'] as String?,
  status: json['status'] as String? ?? 'draft',
  notes: json['notes'] as String?,
  cancelReason: json['cancelReason'] as String?,
  approvedBy: json['approvedBy'] as String?,
  approvedAt: json['approvedAt'] as String?,
  consolidatedAt: json['consolidatedAt'] as String?,
  closedAt: json['closedAt'] as String?,
  createdAt: json['createdAt'] as String?,
  updatedAt: json['updatedAt'] as String?,
  progress: json['progress'] == null
      ? null
      : DemandProgress.fromJson(json['progress'] as Map<String, dynamic>),
);

Map<String, dynamic> _$DemandPeriodToJson(DemandPeriod instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'name': instance.name,
      'kind': instance.kind,
      'year': instance.year,
      'quarter': instance.quarter,
      'buckets': instance.buckets,
      'submitDeadline': instance.submitDeadline,
      'status': instance.status,
      'notes': instance.notes,
      'cancelReason': instance.cancelReason,
      'approvedBy': instance.approvedBy,
      'approvedAt': instance.approvedAt,
      'consolidatedAt': instance.consolidatedAt,
      'closedAt': instance.closedAt,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      'progress': instance.progress?.toJson(),
    };

DemandProgress _$DemandProgressFromJson(Map<String, dynamic> json) =>
    DemandProgress(
      total: json['total'] as num,
      submitted: json['submitted'] as num,
      deptApproved: json['deptApproved'] as num,
      accepted: json['accepted'] as num,
    );

Map<String, dynamic> _$DemandProgressToJson(DemandProgress instance) =>
    <String, dynamic>{
      'total': instance.total,
      'submitted': instance.submitted,
      'deptApproved': instance.deptApproved,
      'accepted': instance.accepted,
    };

DemandPeriodPage _$DemandPeriodPageFromJson(Map<String, dynamic> json) =>
    DemandPeriodPage(
      items: (json['items'] as List<dynamic>)
          .map((e) => DemandPeriod.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as num? ?? 0,
      page: json['page'] as num? ?? 1,
      limit: json['limit'] as num? ?? 20,
    );

Map<String, dynamic> _$DemandPeriodPageToJson(DemandPeriodPage instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'total': instance.total,
      'page': instance.page,
      'limit': instance.limit,
    };

DemandRequestSummary _$DemandRequestSummaryFromJson(
  Map<String, dynamic> json,
) => DemandRequestSummary(
  requestId: json['requestId'] as String,
  departmentId: json['departmentId'] as String?,
  departmentCode: json['departmentCode'] as String?,
  departmentName: json['departmentName'] as String?,
  status: json['status'] as String? ?? 'draft',
  lineCount: json['lineCount'] as num? ?? 0,
  totalEstimated: json['totalEstimated'] as String? ?? '0',
);

Map<String, dynamic> _$DemandRequestSummaryToJson(
  DemandRequestSummary instance,
) => <String, dynamic>{
  'requestId': instance.requestId,
  'departmentId': instance.departmentId,
  'departmentCode': instance.departmentCode,
  'departmentName': instance.departmentName,
  'status': instance.status,
  'lineCount': instance.lineCount,
  'totalEstimated': instance.totalEstimated,
};

DemandRequestSummaryPage _$DemandRequestSummaryPageFromJson(
  Map<String, dynamic> json,
) => DemandRequestSummaryPage(
  items: (json['items'] as List<dynamic>)
      .map((e) => DemandRequestSummary.fromJson(e as Map<String, dynamic>))
      .toList(),
  progress: json['progress'] == null
      ? null
      : DemandProgress.fromJson(json['progress'] as Map<String, dynamic>),
  total: json['total'] as num? ?? 0,
  page: json['page'] as num? ?? 1,
  limit: json['limit'] as num? ?? 20,
);

Map<String, dynamic> _$DemandRequestSummaryPageToJson(
  DemandRequestSummaryPage instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'progress': instance.progress?.toJson(),
  'total': instance.total,
  'page': instance.page,
  'limit': instance.limit,
};

DemandPeriodRef _$DemandPeriodRefFromJson(Map<String, dynamic> json) =>
    DemandPeriodRef(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      status: json['status'] as String? ?? '',
    );

Map<String, dynamic> _$DemandPeriodRefToJson(DemandPeriodRef instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'name': instance.name,
      'status': instance.status,
    };

DemandDepartmentRef _$DemandDepartmentRefFromJson(Map<String, dynamic> json) =>
    DemandDepartmentRef(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
    );

Map<String, dynamic> _$DemandDepartmentRefToJson(
  DemandDepartmentRef instance,
) => <String, dynamic>{
  'id': instance.id,
  'code': instance.code,
  'name': instance.name,
};

DemandCreatorRef _$DemandCreatorRefFromJson(Map<String, dynamic> json) =>
    DemandCreatorRef(
      id: json['id'] as String,
      fullName: json['fullName'] as String? ?? '',
    );

Map<String, dynamic> _$DemandCreatorRefToJson(DemandCreatorRef instance) =>
    <String, dynamic>{'id': instance.id, 'fullName': instance.fullName};

DemandRequest _$DemandRequestFromJson(Map<String, dynamic> json) =>
    DemandRequest(
      id: json['id'] as String,
      periodId: json['periodId'] as String,
      departmentId: json['departmentId'] as String?,
      status: json['status'] as String? ?? 'draft',
      createdBy: json['createdBy'] as String?,
      submittedAt: json['submittedAt'] as String?,
      deptApprovedBy: json['deptApprovedBy'] as String?,
      deptApprovedAt: json['deptApprovedAt'] as String?,
      returnReason: json['returnReason'] as String?,
      notes: json['notes'] as String?,
      totalEstimated: json['totalEstimated'] as String? ?? '0',
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      period: json['period'] == null
          ? null
          : DemandPeriodRef.fromJson(json['period'] as Map<String, dynamic>),
      department: json['department'] == null
          ? null
          : DemandDepartmentRef.fromJson(
              json['department'] as Map<String, dynamic>,
            ),
      creator: json['creator'] == null
          ? null
          : DemandCreatorRef.fromJson(json['creator'] as Map<String, dynamic>),
      lines:
          (json['lines'] as List<dynamic>?)
              ?.map((e) => DemandLine.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$DemandRequestToJson(DemandRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'periodId': instance.periodId,
      'departmentId': instance.departmentId,
      'status': instance.status,
      'createdBy': instance.createdBy,
      'submittedAt': instance.submittedAt,
      'deptApprovedBy': instance.deptApprovedBy,
      'deptApprovedAt': instance.deptApprovedAt,
      'returnReason': instance.returnReason,
      'notes': instance.notes,
      'totalEstimated': instance.totalEstimated,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      'period': instance.period?.toJson(),
      'department': instance.department?.toJson(),
      'creator': instance.creator?.toJson(),
      'lines': instance.lines.map((e) => e.toJson()).toList(),
    };

DemandRequestPage _$DemandRequestPageFromJson(Map<String, dynamic> json) =>
    DemandRequestPage(
      items: (json['items'] as List<dynamic>)
          .map((e) => DemandRequest.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as num? ?? 0,
      page: json['page'] as num? ?? 1,
      limit: json['limit'] as num? ?? 20,
    );

Map<String, dynamic> _$DemandRequestPageToJson(DemandRequestPage instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'total': instance.total,
      'page': instance.page,
      'limit': instance.limit,
    };

DemandLine _$DemandLineFromJson(Map<String, dynamic> json) => DemandLine(
  id: json['id'] as String,
  requestId: json['requestId'] as String,
  itemType: json['itemType'] as String? ?? 'supply',
  supplyId: json['supplyId'] as String?,
  equipmentId: json['equipmentId'] as String?,
  itemName: json['itemName'] as String? ?? '',
  spec: json['spec'] as String?,
  unit: json['unit'] as String?,
  qtyByBucket:
      (json['qtyByBucket'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  qtyRequested: json['qtyRequested'] as String? ?? '0',
  unitPriceEst: json['unitPriceEst'] as String? ?? '0',
  amountEst: json['amountEst'] as String? ?? '0',
  reason: json['reason'] as String?,
  priority: json['priority'] as String? ?? 'normal',
  suggestedQty: json['suggestedQty'] as String?,
  suggestion: json['suggestion'] == null
      ? null
      : DemandSuggestion.fromJson(json['suggestion'] as Map<String, dynamic>),
  qtyApproved: json['qtyApproved'] as String?,
  approverNote: json['approverNote'] as String?,
  supplyCode: json['supplyCode'] as String?,
  sortOrder: json['sortOrder'] as num? ?? 0,
  createdAt: json['createdAt'] as String?,
  updatedAt: json['updatedAt'] as String?,
);

Map<String, dynamic> _$DemandLineToJson(DemandLine instance) =>
    <String, dynamic>{
      'id': instance.id,
      'requestId': instance.requestId,
      'itemType': instance.itemType,
      'supplyId': instance.supplyId,
      'equipmentId': instance.equipmentId,
      'itemName': instance.itemName,
      'spec': instance.spec,
      'unit': instance.unit,
      'qtyByBucket': instance.qtyByBucket,
      'qtyRequested': instance.qtyRequested,
      'unitPriceEst': instance.unitPriceEst,
      'amountEst': instance.amountEst,
      'reason': instance.reason,
      'priority': instance.priority,
      'suggestedQty': instance.suggestedQty,
      'suggestion': instance.suggestion?.toJson(),
      'qtyApproved': instance.qtyApproved,
      'approverNote': instance.approverNote,
      'supplyCode': instance.supplyCode,
      'sortOrder': instance.sortOrder,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };

DemandSuggestion _$DemandSuggestionFromJson(Map<String, dynamic> json) =>
    DemandSuggestion(
      consumption12m: json['consumption12m'] as String? ?? '0',
      avgMonthly: json['avgMonthly'] as String? ?? '0',
      onHand: json['onHand'] as String? ?? '0',
      runwayDays: json['runwayDays'] as num?,
      minStock: json['minStock'] as String? ?? '0',
      maxStock: json['maxStock'] as String? ?? '0',
      lastUnitPrice: json['lastUnitPrice'] as String? ?? '0',
      basis: json['basis'] as String? ?? '',
    );

Map<String, dynamic> _$DemandSuggestionToJson(DemandSuggestion instance) =>
    <String, dynamic>{
      'consumption12m': instance.consumption12m,
      'avgMonthly': instance.avgMonthly,
      'onHand': instance.onHand,
      'runwayDays': instance.runwayDays,
      'minStock': instance.minStock,
      'maxStock': instance.maxStock,
      'lastUnitPrice': instance.lastUnitPrice,
      'basis': instance.basis,
    };

DemandConsolidation _$DemandConsolidationFromJson(Map<String, dynamic> json) =>
    DemandConsolidation(
      id: json['id'] as String,
      periodId: json['periodId'] as String,
      key: json['key'] as String? ?? '',
      itemType: json['itemType'] as String? ?? 'supply',
      supplyId: json['supplyId'] as String?,
      supplyCode: json['supplyCode'] as String?,
      itemName: json['itemName'] as String? ?? '',
      spec: json['spec'] as String?,
      unit: json['unit'] as String?,
      qtyRequested: json['qtyRequested'] as String? ?? '0',
      qtyApproved: json['qtyApproved'] as String? ?? '0',
      onHand: json['onHand'] as String?,
      unitPricePlan: json['unitPricePlan'] as String? ?? '0',
      amountPlan: json['amountPlan'] as String? ?? '0',
      breakdown:
          (json['breakdown'] as List<dynamic>?)
              ?.map(
                (e) => DemandBreakdownEntry.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      decision: json['decision'] as String? ?? 'buy',
      suggestedDecision: json['suggestedDecision'] as String?,
      note: json['note'] as String?,
      sortOrder: json['sortOrder'] as num? ?? 0,
    );

Map<String, dynamic> _$DemandConsolidationToJson(
  DemandConsolidation instance,
) => <String, dynamic>{
  'id': instance.id,
  'periodId': instance.periodId,
  'key': instance.key,
  'itemType': instance.itemType,
  'supplyId': instance.supplyId,
  'supplyCode': instance.supplyCode,
  'itemName': instance.itemName,
  'spec': instance.spec,
  'unit': instance.unit,
  'qtyRequested': instance.qtyRequested,
  'qtyApproved': instance.qtyApproved,
  'onHand': instance.onHand,
  'unitPricePlan': instance.unitPricePlan,
  'amountPlan': instance.amountPlan,
  'breakdown': instance.breakdown.map((e) => e.toJson()).toList(),
  'decision': instance.decision,
  'suggestedDecision': instance.suggestedDecision,
  'note': instance.note,
  'sortOrder': instance.sortOrder,
};

DemandBreakdownEntry _$DemandBreakdownEntryFromJson(
  Map<String, dynamic> json,
) => DemandBreakdownEntry(
  departmentId: json['departmentId'] as String?,
  requestId: json['requestId'] as String,
  lineId: json['lineId'] as String,
  qtyRequested: json['qtyRequested'] as String? ?? '0',
  qtyApproved: json['qtyApproved'] as String? ?? '0',
);

Map<String, dynamic> _$DemandBreakdownEntryToJson(
  DemandBreakdownEntry instance,
) => <String, dynamic>{
  'departmentId': instance.departmentId,
  'requestId': instance.requestId,
  'lineId': instance.lineId,
  'qtyRequested': instance.qtyRequested,
  'qtyApproved': instance.qtyApproved,
};

DemandConsolidationList _$DemandConsolidationListFromJson(
  Map<String, dynamic> json,
) => DemandConsolidationList(
  items: (json['items'] as List<dynamic>)
      .map((e) => DemandConsolidation.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$DemandConsolidationListToJson(
  DemandConsolidationList instance,
) => <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};

DemandSummary _$DemandSummaryFromJson(Map<String, dynamic> json) =>
    DemandSummary(
      departmentsTotal: json['departmentsTotal'] as num? ?? 0,
      departmentsSubmitted: json['departmentsSubmitted'] as num? ?? 0,
      totalRequested: json['totalRequested'] as String? ?? '0',
      totalApproved: json['totalApproved'] as String? ?? '0',
      byItemType:
          (json['byItemType'] as List<dynamic>?)
              ?.map(
                (e) =>
                    DemandSummaryByItemType.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );

Map<String, dynamic> _$DemandSummaryToJson(DemandSummary instance) =>
    <String, dynamic>{
      'departmentsTotal': instance.departmentsTotal,
      'departmentsSubmitted': instance.departmentsSubmitted,
      'totalRequested': instance.totalRequested,
      'totalApproved': instance.totalApproved,
      'byItemType': instance.byItemType.map((e) => e.toJson()).toList(),
    };

DemandSummaryByItemType _$DemandSummaryByItemTypeFromJson(
  Map<String, dynamic> json,
) => DemandSummaryByItemType(
  itemType: json['itemType'] as String? ?? 'supply',
  qtyRequested: json['qtyRequested'] as String? ?? '0',
  qtyApproved: json['qtyApproved'] as String? ?? '0',
  amountPlan: json['amountPlan'] as String? ?? '0',
);

Map<String, dynamic> _$DemandSummaryByItemTypeToJson(
  DemandSummaryByItemType instance,
) => <String, dynamic>{
  'itemType': instance.itemType,
  'qtyRequested': instance.qtyRequested,
  'qtyApproved': instance.qtyApproved,
  'amountPlan': instance.amountPlan,
};

DemandTasks _$DemandTasksFromJson(Map<String, dynamic> json) => DemandTasks(
  toSubmit: json['toSubmit'] as num? ?? 0,
  toApprove: json['toApprove'] as num? ?? 0,
  toAccept: json['toAccept'] as num? ?? 0,
);

Map<String, dynamic> _$DemandTasksToJson(DemandTasks instance) =>
    <String, dynamic>{
      'toSubmit': instance.toSubmit,
      'toApprove': instance.toApprove,
      'toAccept': instance.toAccept,
    };
