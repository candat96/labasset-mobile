import 'package:json_annotation/json_annotation.dart';

import 'equipment.dart';

part 'request.g.dart';

/// Tập con của RequestResponseDto (`GET /v1/requests`) đủ cho danh sách/tìm kiếm.
@JsonSerializable()
class RequestSummary {
  const RequestSummary({
    required this.id,
    required this.code,
    this.type = 'supply',
    this.status = 'submitted',
    this.priority = 'normal',
    this.reason = '',
    this.neededBy,
    this.equipmentId,
    this.equipment,
    this.itemCount = 0,
    this.departmentName,
    this.requesterName,
    this.createdAt,
  });

  final String id;
  final String code;
  final String type;
  final String status;
  final String priority;
  final String reason;
  final String? neededBy;
  final String? equipmentId;
  final EquipmentRef? equipment;
  final num itemCount;
  final String? departmentName;
  final String? requesterName;
  final String? createdAt;

  factory RequestSummary.fromJson(Map<String, dynamic> json) =>
      _$RequestSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$RequestSummaryToJson(this);
}

@JsonSerializable()
class RequestPage {
  const RequestPage({
    required this.items,
    required this.total,
    this.page = 1,
    this.limit = 20,
  });

  final List<RequestSummary> items;
  final num total;
  final num page;
  final num limit;

  factory RequestPage.fromJson(Map<String, dynamic> json) =>
      _$RequestPageFromJson(json);
  Map<String, dynamic> toJson() => _$RequestPageToJson(this);
}
