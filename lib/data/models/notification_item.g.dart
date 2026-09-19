// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationItem _$NotificationItemFromJson(Map<String, dynamic> json) =>
    NotificationItem(
      id: json['id'] as String,
      createdAt: json['createdAt'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      data: (json['data'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
      readAt: json['readAt'] as String?,
    );

Map<String, dynamic> _$NotificationItemToJson(NotificationItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'createdAt': instance.createdAt,
      'type': instance.type,
      'title': instance.title,
      'body': instance.body,
      'data': instance.data,
      'readAt': instance.readAt,
    };

NotificationsPage _$NotificationsPageFromJson(Map<String, dynamic> json) =>
    NotificationsPage(
      items: (json['items'] as List<dynamic>)
          .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as num,
      page: json['page'] as num,
      limit: json['limit'] as num,
      unreadCount: json['unreadCount'] as num,
    );

Map<String, dynamic> _$NotificationsPageToJson(NotificationsPage instance) =>
    <String, dynamic>{
      'items': instance.items,
      'total': instance.total,
      'page': instance.page,
      'limit': instance.limit,
      'unreadCount': instance.unreadCount,
    };
