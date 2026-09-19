// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CalendarItem _$CalendarItemFromJson(Map<String, dynamic> json) => CalendarItem(
  id: json['id'] as String,
  type: json['type'] as String,
  title: json['title'] as String,
  equipment: json['equipment'] == null
      ? null
      : EquipmentRef.fromJson(json['equipment'] as Map<String, dynamic>),
  start: json['start'] as String,
  end: json['end'] as String,
  status: json['status'] as String? ?? '',
  assigneeId: json['assigneeId'] as String?,
  assigneeName: json['assigneeName'] as String?,
  movable: json['movable'] as bool? ?? false,
);

Map<String, dynamic> _$CalendarItemToJson(CalendarItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'title': instance.title,
      'equipment': instance.equipment,
      'start': instance.start,
      'end': instance.end,
      'status': instance.status,
      'assigneeId': instance.assigneeId,
      'assigneeName': instance.assigneeName,
      'movable': instance.movable,
    };

CalendarPage _$CalendarPageFromJson(Map<String, dynamic> json) => CalendarPage(
  items: (json['items'] as List<dynamic>)
      .map((e) => CalendarItem.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$CalendarPageToJson(CalendarPage instance) =>
    <String, dynamic>{'items': instance.items};
