// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DashboardResponse _$DashboardResponseFromJson(Map<String, dynamic> json) =>
    DashboardResponse(
      generatedAt: json['generatedAt'] as String,
      cards: (json['cards'] as List<dynamic>)
          .map((e) => DashboardCard.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$DashboardResponseToJson(DashboardResponse instance) =>
    <String, dynamic>{
      'generatedAt': instance.generatedAt,
      'cards': instance.cards.map((e) => e.toJson()).toList(),
    };

DashboardCard _$DashboardCardFromJson(Map<String, dynamic> json) =>
    DashboardCard(
      key: json['key'] as String,
      title: json['title'] as String,
      value: json['value'] as Object,
      link: json['link'] as String,
      unit: json['unit'] as String?,
      trend: json['trend'] as num?,
    );

Map<String, dynamic> _$DashboardCardToJson(DashboardCard instance) =>
    <String, dynamic>{
      'key': instance.key,
      'title': instance.title,
      'value': instance.value,
      'unit': instance.unit,
      'trend': instance.trend,
      'link': instance.link,
    };

ReportMeta _$ReportMetaFromJson(Map<String, dynamic> json) => ReportMeta(
  key: json['key'] as String,
  title: json['title'] as String,
  group: json['group'] as String,
  params: json['params'] as Map<String, dynamic>,
  columns: (json['columns'] as List<dynamic>)
      .map((e) => ReportColumn.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ReportMetaToJson(ReportMeta instance) =>
    <String, dynamic>{
      'key': instance.key,
      'title': instance.title,
      'group': instance.group,
      'params': instance.params,
      'columns': instance.columns.map((e) => e.toJson()).toList(),
    };

ReportColumn _$ReportColumnFromJson(Map<String, dynamic> json) => ReportColumn(
  key: json['key'] as String,
  title: json['title'] as String,
  type: json['type'] as String,
  width: json['width'] as num?,
);

Map<String, dynamic> _$ReportColumnToJson(ReportColumn instance) =>
    <String, dynamic>{
      'key': instance.key,
      'title': instance.title,
      'type': instance.type,
      'width': instance.width,
    };
