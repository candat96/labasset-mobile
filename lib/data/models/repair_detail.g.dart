// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repair_detail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RepairLog _$RepairLogFromJson(Map<String, dynamic> json) => RepairLog(
  id: json['id'] as String?,
  ticketId: json['ticketId'] as String?,
  at: json['at'] as String,
  byUserId: json['byUserId'] as String?,
  action: json['action'] as String,
  note: json['note'] as String?,
  durationMinutes: json['durationMinutes'] as num?,
  clientId: json['clientId'] as String?,
  pending: json['pending'] as bool? ?? false,
);

Map<String, dynamic> _$RepairLogToJson(RepairLog instance) => <String, dynamic>{
  'id': instance.id,
  'ticketId': instance.ticketId,
  'at': instance.at,
  'byUserId': instance.byUserId,
  'action': instance.action,
  'note': instance.note,
  'durationMinutes': instance.durationMinutes,
  'clientId': instance.clientId,
  'pending': instance.pending,
};

RepairAssignment _$RepairAssignmentFromJson(Map<String, dynamic> json) =>
    RepairAssignment(
      id: json['id'] as String,
      userId: json['userId'] as String?,
      role: json['role'] as String? ?? 'primary',
      response: json['response'] as String? ?? 'pending',
      responseNote: json['responseNote'] as String?,
      assignedAt: json['assignedAt'] as String?,
      respondedAt: json['respondedAt'] as String?,
    );

Map<String, dynamic> _$RepairAssignmentToJson(RepairAssignment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'role': instance.role,
      'response': instance.response,
      'responseNote': instance.responseNote,
      'assignedAt': instance.assignedAt,
      'respondedAt': instance.respondedAt,
    };

RepairPart _$RepairPartFromJson(Map<String, dynamic> json) => RepairPart(
  id: json['id'] as String,
  source: json['source'] as String? ?? 'stock',
  supplyId: json['supplyId'] as String?,
  stockLotId: json['stockLotId'] as String?,
  componentId: json['componentId'] as String?,
  name: json['name'] as String,
  quantity: json['quantity'] as String? ?? '1',
  unitCost: json['unitCost'] as String?,
  totalCost: json['totalCost'] as String?,
  note: json['note'] as String?,
);

Map<String, dynamic> _$RepairPartToJson(RepairPart instance) =>
    <String, dynamic>{
      'id': instance.id,
      'source': instance.source,
      'supplyId': instance.supplyId,
      'stockLotId': instance.stockLotId,
      'componentId': instance.componentId,
      'name': instance.name,
      'quantity': instance.quantity,
      'unitCost': instance.unitCost,
      'totalCost': instance.totalCost,
      'note': instance.note,
    };

RepairCost _$RepairCostFromJson(Map<String, dynamic> json) => RepairCost(
  id: json['id'] as String,
  category: json['category'] as String? ?? 'other',
  description: json['description'] as String? ?? '',
  amount: json['amount'] as String? ?? '0',
  invoiceNo: json['invoiceNo'] as String?,
  invoiceDate: json['invoiceDate'] as String?,
  paidAt: json['paidAt'] as String?,
);

Map<String, dynamic> _$RepairCostToJson(RepairCost instance) =>
    <String, dynamic>{
      'id': instance.id,
      'category': instance.category,
      'description': instance.description,
      'amount': instance.amount,
      'invoiceNo': instance.invoiceNo,
      'invoiceDate': instance.invoiceDate,
      'paidAt': instance.paidAt,
    };

RepairVendor _$RepairVendorFromJson(Map<String, dynamic> json) => RepairVendor(
  id: json['id'] as String,
  supplierId: json['supplierId'] as String?,
  engineerName: json['engineerName'] as String?,
  engineerPhone: json['engineerPhone'] as String?,
  contractNo: json['contractNo'] as String?,
  quotationAmount: json['quotationAmount'] as String?,
  visitAt: json['visitAt'] as String?,
  note: json['note'] as String?,
);

Map<String, dynamic> _$RepairVendorToJson(RepairVendor instance) =>
    <String, dynamic>{
      'id': instance.id,
      'supplierId': instance.supplierId,
      'engineerName': instance.engineerName,
      'engineerPhone': instance.engineerPhone,
      'contractNo': instance.contractNo,
      'quotationAmount': instance.quotationAmount,
      'visitAt': instance.visitAt,
      'note': instance.note,
    };

RepairDetail _$RepairDetailFromJson(Map<String, dynamic> json) => RepairDetail(
  id: json['id'] as String,
  code: json['code'] as String,
  equipmentId: json['equipmentId'] as String,
  reportedBy: json['reportedBy'] as String?,
  reportedDepartmentId: json['reportedDepartmentId'] as String?,
  description: json['description'] as String? ?? '',
  errorCode: json['errorCode'] as String?,
  severity: json['severity'] as String? ?? 'medium',
  equipmentDown: json['equipmentDown'] as bool? ?? false,
  status: json['status'] as String? ?? 'new',
  faultId: json['faultId'] as String?,
  diagnosis: json['diagnosis'] as String?,
  faultGroupId: json['faultGroupId'] as String?,
  resolutionType: json['resolutionType'] as String?,
  assigneeId: json['assigneeId'] as String?,
  assistantIds:
      (json['assistantIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  dueAt: json['dueAt'] as String?,
  acceptedAt: json['acceptedAt'] as String?,
  startedAt: json['startedAt'] as String?,
  completedAt: json['completedAt'] as String?,
  acceptedByDeptAt: json['acceptedByDeptAt'] as String?,
  closedAt: json['closedAt'] as String?,
  resolutionSummary: json['resolutionSummary'] as String?,
  postRepairWarrantyUntil: json['postRepairWarrantyUntil'] as String?,
  rating: json['rating'] as num?,
  ratingNote: json['ratingNote'] as String?,
  calibrationRequired: json['calibrationRequired'] as bool? ?? false,
  calibrationTicketId: json['calibrationTicketId'] as String?,
  totalCost: json['totalCost'] as String? ?? '0',
  costWarning: json['costWarning'] as bool? ?? false,
  createdAt: json['createdAt'] as String?,
  updatedAt: json['updatedAt'] as String?,
  isOverdue: json['isOverdue'] as bool? ?? false,
  equipment: json['equipment'] == null
      ? null
      : EquipmentRef.fromJson(json['equipment'] as Map<String, dynamic>),
  assignee: json['assignee'] == null
      ? null
      : RepairAssigneeRef.fromJson(json['assignee'] as Map<String, dynamic>),
  logs:
      (json['logs'] as List<dynamic>?)
          ?.map((e) => RepairLog.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  parts:
      (json['parts'] as List<dynamic>?)
          ?.map((e) => RepairPart.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  costs:
      (json['costs'] as List<dynamic>?)
          ?.map((e) => RepairCost.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  vendors:
      (json['vendors'] as List<dynamic>?)
          ?.map((e) => RepairVendor.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  assignments:
      (json['assignments'] as List<dynamic>?)
          ?.map((e) => RepairAssignment.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  faultInfo: json['faultInfo'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$RepairDetailToJson(RepairDetail instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'equipmentId': instance.equipmentId,
      'reportedBy': instance.reportedBy,
      'reportedDepartmentId': instance.reportedDepartmentId,
      'description': instance.description,
      'errorCode': instance.errorCode,
      'severity': instance.severity,
      'equipmentDown': instance.equipmentDown,
      'status': instance.status,
      'faultId': instance.faultId,
      'diagnosis': instance.diagnosis,
      'faultGroupId': instance.faultGroupId,
      'resolutionType': instance.resolutionType,
      'assigneeId': instance.assigneeId,
      'assistantIds': instance.assistantIds,
      'dueAt': instance.dueAt,
      'acceptedAt': instance.acceptedAt,
      'startedAt': instance.startedAt,
      'completedAt': instance.completedAt,
      'acceptedByDeptAt': instance.acceptedByDeptAt,
      'closedAt': instance.closedAt,
      'resolutionSummary': instance.resolutionSummary,
      'postRepairWarrantyUntil': instance.postRepairWarrantyUntil,
      'rating': instance.rating,
      'ratingNote': instance.ratingNote,
      'calibrationRequired': instance.calibrationRequired,
      'calibrationTicketId': instance.calibrationTicketId,
      'totalCost': instance.totalCost,
      'costWarning': instance.costWarning,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      'isOverdue': instance.isOverdue,
      'equipment': instance.equipment,
      'assignee': instance.assignee,
      'logs': instance.logs,
      'parts': instance.parts,
      'costs': instance.costs,
      'vendors': instance.vendors,
      'assignments': instance.assignments,
      'faultInfo': instance.faultInfo,
    };

RepairAssigneeRef _$RepairAssigneeRefFromJson(Map<String, dynamic> json) =>
    RepairAssigneeRef(
      id: json['id'] as String,
      fullName: json['fullName'] as String? ?? '',
    );

Map<String, dynamic> _$RepairAssigneeRefToJson(RepairAssigneeRef instance) =>
    <String, dynamic>{'id': instance.id, 'fullName': instance.fullName};

AssignSuggestItem _$AssignSuggestItemFromJson(Map<String, dynamic> json) =>
    AssignSuggestItem(
      id: json['id'] as String,
      fullName: json['fullName'] as String? ?? '',
      openTickets: json['openTickets'] as num? ?? 0,
    );

Map<String, dynamic> _$AssignSuggestItemToJson(AssignSuggestItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fullName': instance.fullName,
      'openTickets': instance.openTickets,
    };

FaultSuggestionMatch _$FaultSuggestionMatchFromJson(
  Map<String, dynamic> json,
) => FaultSuggestionMatch(
  fault: SuggestedFault.fromJson(json['fault'] as Map<String, dynamic>),
  score: json['score'] as num? ?? 0,
  matchedBy: json['matchedBy'] as String? ?? 'all',
  onEquipment: json['onEquipment'] as num? ?? 0,
  sameModel: json['sameModel'] as num? ?? 0,
);

Map<String, dynamic> _$FaultSuggestionMatchToJson(
  FaultSuggestionMatch instance,
) => <String, dynamic>{
  'fault': instance.fault,
  'score': instance.score,
  'matchedBy': instance.matchedBy,
  'onEquipment': instance.onEquipment,
  'sameModel': instance.sameModel,
};

SuggestedFault _$SuggestedFaultFromJson(Map<String, dynamic> json) =>
    SuggestedFault(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      errorCode: json['errorCode'] as String? ?? '',
      severity: json['severity'] as String? ?? 'medium',
      model: json['model'] as String? ?? '',
    );

Map<String, dynamic> _$SuggestedFaultToJson(SuggestedFault instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'errorCode': instance.errorCode,
      'severity': instance.severity,
      'model': instance.model,
    };

RepairStats _$RepairStatsFromJson(Map<String, dynamic> json) => RepairStats(
  tickets: json['tickets'] as num? ?? 0,
  completed: json['completed'] as num? ?? 0,
  cost: json['cost'] as String? ?? '0',
  mttrHours: json['mttrHours'] as num? ?? 0,
  downtimeHours: json['downtimeHours'] as num? ?? 0,
);

Map<String, dynamic> _$RepairStatsToJson(RepairStats instance) =>
    <String, dynamic>{
      'tickets': instance.tickets,
      'completed': instance.completed,
      'cost': instance.cost,
      'mttrHours': instance.mttrHours,
      'downtimeHours': instance.downtimeHours,
    };

WorkloadItem _$WorkloadItemFromJson(Map<String, dynamic> json) => WorkloadItem(
  id: json['id'] as String,
  fullName: json['fullName'] as String? ?? '',
  open: json['open'] as num? ?? 0,
  overdue: json['overdue'] as num? ?? 0,
  awaitingResponse: json['awaitingResponse'] as num? ?? 0,
);

Map<String, dynamic> _$WorkloadItemToJson(WorkloadItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fullName': instance.fullName,
      'open': instance.open,
      'overdue': instance.overdue,
      'awaitingResponse': instance.awaitingResponse,
    };
