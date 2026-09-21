// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'my_tasks.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MyTasksResponse _$MyTasksResponseFromJson(Map<String, dynamic> json) =>
    MyTasksResponse(
      repairs: RepairTasks.fromJson(json['repairs'] as Map<String, dynamic>),
      maintenance: MaintenanceTasks.fromJson(
        json['maintenance'] as Map<String, dynamic>,
      ),
      requests: RequestTasks.fromJson(json['requests'] as Map<String, dynamic>),
      stocktakes: StocktakeTasks.fromJson(
        json['stocktakes'] as Map<String, dynamic>,
      ),
      alerts: TaskAlerts.fromJson(json['alerts'] as Map<String, dynamic>),
      demand: json['demand'] == null
          ? const DemandTasks()
          : DemandTasks.fromJson(json['demand'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MyTasksResponseToJson(MyTasksResponse instance) =>
    <String, dynamic>{
      'repairs': instance.repairs.toJson(),
      'maintenance': instance.maintenance.toJson(),
      'requests': instance.requests.toJson(),
      'stocktakes': instance.stocktakes.toJson(),
      'alerts': instance.alerts.toJson(),
      'demand': instance.demand.toJson(),
    };

RepairTasks _$RepairTasksFromJson(Map<String, dynamic> json) => RepairTasks(
  assigned: json['assigned'] as num,
  pendingResponse: json['pendingResponse'] as num,
  overdue: json['overdue'] as num,
);

Map<String, dynamic> _$RepairTasksToJson(RepairTasks instance) =>
    <String, dynamic>{
      'assigned': instance.assigned,
      'pendingResponse': instance.pendingResponse,
      'overdue': instance.overdue,
    };

MaintenanceTasks _$MaintenanceTasksFromJson(Map<String, dynamic> json) =>
    MaintenanceTasks(
      due7d: json['due7d'] as num,
      overdue: json['overdue'] as num,
    );

Map<String, dynamic> _$MaintenanceTasksToJson(MaintenanceTasks instance) =>
    <String, dynamic>{'due7d': instance.due7d, 'overdue': instance.overdue};

RequestTasks _$RequestTasksFromJson(Map<String, dynamic> json) => RequestTasks(
  pendingApproval: json['pendingApproval'] as num,
  pendingIssue: json['pendingIssue'] as num,
  pendingReceive: json['pendingReceive'] as num,
);

Map<String, dynamic> _$RequestTasksToJson(RequestTasks instance) =>
    <String, dynamic>{
      'pendingApproval': instance.pendingApproval,
      'pendingIssue': instance.pendingIssue,
      'pendingReceive': instance.pendingReceive,
    };

StocktakeTasks _$StocktakeTasksFromJson(Map<String, dynamic> json) =>
    StocktakeTasks(counting: json['counting'] as num);

Map<String, dynamic> _$StocktakeTasksToJson(StocktakeTasks instance) =>
    <String, dynamic>{'counting': instance.counting};

TaskAlerts _$TaskAlertsFromJson(Map<String, dynamic> json) => TaskAlerts(
  repairsNew: json['repairsNew'] as num,
  stock: StockAlertCounts.fromJson(json['stock'] as Map<String, dynamic>),
  calibrationOverdue: json['calibrationOverdue'] as num,
);

Map<String, dynamic> _$TaskAlertsToJson(TaskAlerts instance) =>
    <String, dynamic>{
      'repairsNew': instance.repairsNew,
      'stock': instance.stock.toJson(),
      'calibrationOverdue': instance.calibrationOverdue,
    };

StockAlertCounts _$StockAlertCountsFromJson(Map<String, dynamic> json) =>
    StockAlertCounts(
      lowStock: json['low_stock'] as num,
      expiring: json['expiring'] as num,
      expired: json['expired'] as num,
      openVialExpiring: json['open_vial_expiring'] as num,
      stale: json['stale'] as num,
    );

Map<String, dynamic> _$StockAlertCountsToJson(StockAlertCounts instance) =>
    <String, dynamic>{
      'low_stock': instance.lowStock,
      'expiring': instance.expiring,
      'expired': instance.expired,
      'open_vial_expiring': instance.openVialExpiring,
      'stale': instance.stale,
    };
