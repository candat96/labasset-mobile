import 'package:json_annotation/json_annotation.dart';

part 'report.g.dart';

@JsonSerializable(explicitToJson: true)
class DashboardResponse {
  const DashboardResponse({required this.generatedAt, required this.cards});
  final String generatedAt;
  final List<DashboardCard> cards;
  factory DashboardResponse.fromJson(Map<String, dynamic> json) =>
      _$DashboardResponseFromJson(json);
  Map<String, dynamic> toJson() => _$DashboardResponseToJson(this);
}

@JsonSerializable()
class DashboardCard {
  const DashboardCard({
    required this.key,
    required this.title,
    required this.value,
    required this.link,
    this.unit,
    this.trend,
  });
  final String key;
  final String title;
  final Object value;
  final String? unit;
  final num? trend;
  final String link;
  factory DashboardCard.fromJson(Map<String, dynamic> json) =>
      _$DashboardCardFromJson(json);
  Map<String, dynamic> toJson() => _$DashboardCardToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ReportMeta {
  const ReportMeta({
    required this.key,
    required this.title,
    required this.group,
    required this.params,
    required this.columns,
  });
  final String key;
  final String title;
  final String group;
  final Map<String, dynamic> params;
  final List<ReportColumn> columns;
  factory ReportMeta.fromJson(Map<String, dynamic> json) =>
      _$ReportMetaFromJson(json);
  Map<String, dynamic> toJson() => _$ReportMetaToJson(this);
}

@JsonSerializable()
class ReportColumn {
  const ReportColumn({
    required this.key,
    required this.title,
    required this.type,
    this.width,
  });
  final String key;
  final String title;
  final String type;
  final num? width;
  factory ReportColumn.fromJson(Map<String, dynamic> json) =>
      _$ReportColumnFromJson(json);
  Map<String, dynamic> toJson() => _$ReportColumnToJson(this);
}

class ReportExport {
  const ReportExport({required this.bytes, required this.fileName});
  final List<int> bytes;
  final String fileName;
}
