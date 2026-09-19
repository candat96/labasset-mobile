import 'package:dio/dio.dart';

import '../api/endpoints.dart';
import '../models/notification_item.dart';

class NotificationsRepository {
  NotificationsRepository(this._dio);
  final Dio _dio;

  Future<NotificationsPage> list({
    bool? unread,
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      Ep.notifications,
      queryParameters: {
        if (unread == true) 'unread': true,
        'page': page,
        'limit': limit,
      },
    );
    return NotificationsPage.fromJson(res.data!);
  }

  Future<void> markRead(String id) => _dio.post<void>(Ep.notificationRead(id));

  Future<void> markAllRead() => _dio.post<void>(Ep.notificationsReadAll);
}
