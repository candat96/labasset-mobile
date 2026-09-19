// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_preference.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationPreference _$NotificationPreferenceFromJson(
  Map<String, dynamic> json,
) => NotificationPreference(
  type: json['type'] as String,
  push: json['push'] as bool,
  inapp: json['inapp'] as bool,
);

Map<String, dynamic> _$NotificationPreferenceToJson(
  NotificationPreference instance,
) => <String, dynamic>{
  'type': instance.type,
  'push': instance.push,
  'inapp': instance.inapp,
};
