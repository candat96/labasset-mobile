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

/// `GET /v1/notifications/types` → NotificationTypeDto (B6-B13).
@JsonSerializable()
class NotificationType {
  const NotificationType({required this.type, this.label = ''});

  final String type;
  final String label;

  factory NotificationType.fromJson(Map<String, dynamic> json) =>
      _$NotificationTypeFromJson(json);
  Map<String, dynamic> toJson() => _$NotificationTypeToJson(this);
}
