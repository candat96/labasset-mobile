import 'package:json_annotation/json_annotation.dart';

part 'notification_preference.g.dart';

/// Một dòng `GET/PUT /v1/notifications/preferences`.
@JsonSerializable()
class NotificationPreference {
  NotificationPreference({
    required this.type,
    required this.push,
    required this.inapp,
  });

  final String type;
  bool push;
  bool inapp;

  factory NotificationPreference.fromJson(Map<String, dynamic> json) =>
      _$NotificationPreferenceFromJson(json);
  Map<String, dynamic> toJson() => _$NotificationPreferenceToJson(this);
}
