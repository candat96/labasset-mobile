import 'package:json_annotation/json_annotation.dart';

part 'supply.g.dart';

/// Tập con của SupplyResponseDto (`GET /v1/supplies`, `/v1/supplies/:id`) đủ cho
/// chọn tham chiếu và hồ sơ vật tư chi tiết (các trường mới đều nullable).
@JsonSerializable()
class SupplySummary {
  const SupplySummary({
    required this.id,
    required this.code,
    required this.name,
    this.isActive = true,
    this.unitId,
    this.groupId,
    this.circulationNumber,
    this.circulationValidTo,
    this.riskClass,
    this.countryOfOrigin,
    this.insuranceCode,
    this.insuranceName,
    this.insuranceRate,
    this.insurancePrice,
    this.bidPackage,
    this.bidDecisionNo,
    this.bidPrice,
    this.bidValidTo,
    this.purchaseUnitId,
    this.conversionFactor,
    this.minShelfLifeDays,
  });

  final String id;
  final String code;
  final String name;
  @JsonKey(defaultValue: true)
  final bool isActive;
  final String? unitId;
  final String? groupId;

  // Hồ sơ vật tư tiêu hao chi tiết — pháp lý lưu hành, BHYT, thầu, quy đổi
  // đơn vị mua ↔ dùng, hạn dùng tối thiểu khi nhập. Nullable vì dữ liệu cũ
  // chưa khai.
  final String? circulationNumber;
  final String? circulationValidTo;
  final String? riskClass;
  final String? countryOfOrigin;
  final String? insuranceCode;
  final String? insuranceName;
  final String? insuranceRate;
  final String? insurancePrice;
  final String? bidPackage;
  final String? bidDecisionNo;
  final String? bidPrice;
  final String? bidValidTo;
  final String? purchaseUnitId;
  final String? conversionFactor;
  final int? minShelfLifeDays;

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

/// Vật tư thay thế (`GET /v1/supplies/:id/substitutes`), đọc hai chiều.
@JsonSerializable()
class SupplySubstitute {
  const SupplySubstitute({
    required this.id,
    required this.code,
    required this.name,
    this.unitName,
    this.notes,
  });

  final String id;
  final String code;
  final String name;
  final String? unitName;
  final String? notes;

  factory SupplySubstitute.fromJson(Map<String, dynamic> json) =>
      _$SupplySubstituteFromJson(json);
  Map<String, dynamic> toJson() => _$SupplySubstituteToJson(this);
}
