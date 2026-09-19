import 'package:json_annotation/json_annotation.dart';

part 'department.g.dart';

@JsonSerializable()
class DepartmentRef {
  const DepartmentRef({
    required this.id,
    required this.code,
    required this.name,
  });

  final String id;
  final String code;
  final String name;

  factory DepartmentRef.fromJson(Map<String, dynamic> json) =>
      _$DepartmentRefFromJson(json);
  Map<String, dynamic> toJson() => _$DepartmentRefToJson(this);
}

@JsonSerializable()
class DepartmentPage {
  const DepartmentPage({
    required this.items,
    this.total = 0,
    this.page = 1,
    this.limit = 20,
  });

  final List<DepartmentRef> items;
  final num total;
  final num page;
  final num limit;

  factory DepartmentPage.fromJson(Map<String, dynamic> json) =>
      _$DepartmentPageFromJson(json);
  Map<String, dynamic> toJson() => _$DepartmentPageToJson(this);
}
