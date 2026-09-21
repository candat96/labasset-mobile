// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'global_search.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GlobalSearchResponse _$GlobalSearchResponseFromJson(
  Map<String, dynamic> json,
) => GlobalSearchResponse(
  equipment: (json['equipment'] as List<dynamic>)
      .map((e) => GlobalSearchHit.fromJson(e as Map<String, dynamic>))
      .toList(),
  supplies: (json['supplies'] as List<dynamic>)
      .map((e) => GlobalSearchHit.fromJson(e as Map<String, dynamic>))
      .toList(),
  repairs: (json['repairs'] as List<dynamic>)
      .map((e) => GlobalSearchHit.fromJson(e as Map<String, dynamic>))
      .toList(),
  requests: (json['requests'] as List<dynamic>)
      .map((e) => GlobalSearchHit.fromJson(e as Map<String, dynamic>))
      .toList(),
  faults: (json['faults'] as List<dynamic>)
      .map((e) => GlobalSearchHit.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$GlobalSearchResponseToJson(
  GlobalSearchResponse instance,
) => <String, dynamic>{
  'equipment': instance.equipment.map((e) => e.toJson()).toList(),
  'supplies': instance.supplies.map((e) => e.toJson()).toList(),
  'repairs': instance.repairs.map((e) => e.toJson()).toList(),
  'requests': instance.requests.map((e) => e.toJson()).toList(),
  'faults': instance.faults.map((e) => e.toJson()).toList(),
};

GlobalSearchHit _$GlobalSearchHitFromJson(Map<String, dynamic> json) =>
    GlobalSearchHit(
      id: json['id'] as String,
      code: json['code'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      link: json['link'] as String,
      room: json['room'] == null
          ? null
          : RoomRef.fromJson(json['room'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$GlobalSearchHitToJson(GlobalSearchHit instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'title': instance.title,
      'subtitle': instance.subtitle,
      'link': instance.link,
      'room': instance.room,
    };
