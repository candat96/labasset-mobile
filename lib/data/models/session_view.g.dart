// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_view.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SessionView _$SessionViewFromJson(Map<String, dynamic> json) => SessionView(
  id: json['id'] as String,
  deviceInfo: json['deviceInfo'] as String?,
  ip: json['ip'] as String?,
  createdAt: json['createdAt'] as String,
  lastUsedAt: json['lastUsedAt'] as String?,
  expiresAt: json['expiresAt'] as String,
);

Map<String, dynamic> _$SessionViewToJson(SessionView instance) =>
    <String, dynamic>{
      'id': instance.id,
      'deviceInfo': instance.deviceInfo,
      'ip': instance.ip,
      'createdAt': instance.createdAt,
      'lastUsedAt': instance.lastUsedAt,
      'expiresAt': instance.expiresAt,
    };
