import 'package:dio/dio.dart';

import '../api/endpoints.dart';
import '../models/calendar.dart';

class CalendarRepository {
  CalendarRepository(this._dio);
  final Dio _dio;

  Future<CalendarPage> list({
    required String from,
    required String to,
    List<String> types = const [],
    String? assigneeId,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      Ep.calendar,
      queryParameters: {
        'from': from,
        'to': to,
        if (types.isNotEmpty) 'types': types.join(','),
        if (assigneeId != null && assigneeId.isNotEmpty)
          'assigneeId': assigneeId,
      },
    );
    return CalendarPage.fromJson(res.data!);
  }
}
