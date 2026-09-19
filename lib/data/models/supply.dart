import 'package:json_annotation/json_annotation.dart';

part 'supply.g.dart';

/// Tập con của SupplyResponseDto (`GET /v1/supplies`) đủ cho chọn tham chiếu.
@JsonSerializable()
class SupplySummary {
  const SupplySummary({
    required this.id,
    required this.code,
    required this.name,
    this.isActive = true,
    this.unitId,
    this.groupId,
  });

  final String id;
  final String code;
  final String name;
  @JsonKey(defaultValue: true)
  final bool isActive;
  final String? unitId;
  final String? groupId;

  factory SupplySummary.fromJson(Map<String, dynamic> json) =>
      _$SupplySummaryFromJson(json);
  Map<String, dynamic> toJson() => _$SupplySummaryToJson(this);
}

@JsonSerializable()
class SupplyPage {
  const SupplyPage({
    required this.items,
    required this.total,
    this.page = 1,
    this.limit = 20,
  });

  final List<SupplySummary> items;
  final num total;
  final num page;
  final num limit;

  factory SupplyPage.fromJson(Map<String, dynamic> json) =>
      _$SupplyPageFromJson(json);
  Map<String, dynamic> toJson() => _$SupplyPageToJson(this);
}
