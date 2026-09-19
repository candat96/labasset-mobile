import 'package:json_annotation/json_annotation.dart';

part 'notification_item.g.dart';

@JsonSerializable()
class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.createdAt,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    this.readAt,
  });

  final String id;
  final String createdAt;
  final String type;
  final String title;
  final String body;
  final Map<String, String>? data;
  final String? readAt;

  bool get isRead => readAt != null;

  factory NotificationItem.fromJson(Map<String, dynamic> json) =>
      _$NotificationItemFromJson(json);
  Map<String, dynamic> toJson() => _$NotificationItemToJson(this);
}

@JsonSerializable()
class NotificationsPage {
  const NotificationsPage({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.unreadCount,
  });

  final List<NotificationItem> items;
  final num total;
  final num page;
  final num limit;
  final num unreadCount;

  factory NotificationsPage.fromJson(Map<String, dynamic> json) =>
      _$NotificationsPageFromJson(json);
  Map<String, dynamic> toJson() => _$NotificationsPageToJson(this);
}
