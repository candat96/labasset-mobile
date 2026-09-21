import 'package:json_annotation/json_annotation.dart';

import 'demand.dart';

part 'my_tasks.g.dart';

@JsonSerializable(explicitToJson: true)
class MyTasksResponse {
  const MyTasksResponse({
    required this.repairs,
    required this.maintenance,
    required this.requests,
    required this.stocktakes,
    required this.alerts,
    this.demand = const DemandTasks(),
  });

  final RepairTasks repairs;
  final MaintenanceTasks maintenance;
  final RequestTasks requests;
  final StocktakeTasks stocktakes;
  final TaskAlerts alerts;
  final DemandTasks demand;

  factory MyTasksResponse.fromJson(Map<String, dynamic> json) =>
      _$MyTasksResponseFromJson(json);
  Map<String, dynamic> toJson() => _$MyTasksResponseToJson(this);
}

@JsonSerializable()
class RepairTasks {
  const RepairTasks({
    required this.assigned,
    required this.pendingResponse,
    required this.overdue,
  });
  final num assigned;
  final num pendingResponse;
  final num overdue;
  factory RepairTasks.fromJson(Map<String, dynamic> json) =>
      _$RepairTasksFromJson(json);
  Map<String, dynamic> toJson() => _$RepairTasksToJson(this);
}

@JsonSerializable()
class MaintenanceTasks {
  const MaintenanceTasks({required this.due7d, required this.overdue});
  final num due7d;
  final num overdue;
  factory MaintenanceTasks.fromJson(Map<String, dynamic> json) =>
      _$MaintenanceTasksFromJson(json);
  Map<String, dynamic> toJson() => _$MaintenanceTasksToJson(this);
}

@JsonSerializable()
class RequestTasks {
  const RequestTasks({
    required this.pendingApproval,
    required this.pendingIssue,
    required this.pendingReceive,
  });
  final num pendingApproval;
  final num pendingIssue;
  final num pendingReceive;
  factory RequestTasks.fromJson(Map<String, dynamic> json) =>
      _$RequestTasksFromJson(json);
  Map<String, dynamic> toJson() => _$RequestTasksToJson(this);
}

@JsonSerializable()
class StocktakeTasks {
  const StocktakeTasks({required this.counting});
  final num counting;
  factory StocktakeTasks.fromJson(Map<String, dynamic> json) =>
      _$StocktakeTasksFromJson(json);
  Map<String, dynamic> toJson() => _$StocktakeTasksToJson(this);
}

@JsonSerializable(explicitToJson: true)
class TaskAlerts {
  const TaskAlerts({
    required this.repairsNew,
    required this.stock,
    required this.calibrationOverdue,
  });
  final num repairsNew;
  final StockAlertCounts stock;
  final num calibrationOverdue;
  factory TaskAlerts.fromJson(Map<String, dynamic> json) =>
      _$TaskAlertsFromJson(json);
  Map<String, dynamic> toJson() => _$TaskAlertsToJson(this);
}

@JsonSerializable()
class StockAlertCounts {
  const StockAlertCounts({
    required this.lowStock,
    required this.expiring,
    required this.expired,
    required this.openVialExpiring,
    required this.stale,
  });
  @JsonKey(name: 'low_stock')
  final num lowStock;
  final num expiring;
  final num expired;
  @JsonKey(name: 'open_vial_expiring')
  final num openVialExpiring;
  final num stale;

  int get total =>
      lowStock.toInt() +
      expiring.toInt() +
      expired.toInt() +
      openVialExpiring.toInt() +
      stale.toInt();

  factory StockAlertCounts.fromJson(Map<String, dynamic> json) =>
      _$StockAlertCountsFromJson(json);
  Map<String, dynamic> toJson() => _$StockAlertCountsToJson(this);
}
