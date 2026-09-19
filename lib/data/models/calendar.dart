import 'package:json_annotation/json_annotation.dart';

import 'equipment.dart';

part 'calendar.g.dart';

/// `GET /v1/calendar` → CalendarItemDto.
@JsonSerializable()
class CalendarItem {
  const CalendarItem({
    required this.id,
    required this.type,
    required this.title,
    this.equipment,
    required this.start,
    required this.end,
    this.status = '',
    this.assigneeId,
    this.assigneeName,
    this.movable = false,
  });

  final String id;
  final String type;
  final String title;
  final EquipmentRef? equipment;
  final String start;
  final String end;
  final String status;
  final String? assigneeId;
  final String? assigneeName;
  final bool movable;

  factory CalendarItem.fromJson(Map<String, dynamic> json) =>
      _$CalendarItemFromJson(json);
  Map<String, dynamic> toJson() => _$CalendarItemToJson(this);
}

@JsonSerializable()
class CalendarPage {
  const CalendarPage({required this.items});

  final List<CalendarItem> items;

  factory CalendarPage.fromJson(Map<String, dynamic> json) =>
      _$CalendarPageFromJson(json);
  Map<String, dynamic> toJson() => _$CalendarPageToJson(this);
}
