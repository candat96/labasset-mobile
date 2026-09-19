import 'package:json_annotation/json_annotation.dart';

import 'equipment.dart';

part 'repair.g.dart';

/// Tập con của RepairSummaryDto (`GET /v1/repairs`) đủ cho danh sách/tìm kiếm.
@JsonSerializable()
class RepairSummary {
  const RepairSummary({
    required this.id,
    required this.code,
    required this.equipmentId,
    this.description = '',
    this.severity = 'medium',
    this.status = 'new',
    this.assigneeId,
    this.createdAt,
    this.dueAt,
    this.isOverdue = false,
    this.equipment,
  });

  final String id;
  final String code;
  final String equipmentId;
  final String description;
  final String severity;
  final String status;
  final String? assigneeId;
  final String? createdAt;
  final String? dueAt;
  @JsonKey(defaultValue: false)
  final bool isOverdue;
  final EquipmentRef? equipment;

  String get equipmentLabel => equipment?.name ?? equipmentId;

  factory RepairSummary.fromJson(Map<String, dynamic> json) =>
      _$RepairSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$RepairSummaryToJson(this);
}

@JsonSerializable()
class RepairPage {
  const RepairPage({
    required this.items,
    required this.total,
    this.page = 1,
    this.limit = 20,
  });

  final List<RepairSummary> items;
  final num total;
  final num page;
  final num limit;

  factory RepairPage.fromJson(Map<String, dynamic> json) =>
      _$RepairPageFromJson(json);
  Map<String, dynamic> toJson() => _$RepairPageToJson(this);
}
