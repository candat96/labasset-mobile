import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/ai/ai_models.dart';
import '../../core/ai/sse_parser.dart';
import '../api/endpoints.dart';

/// Repository AI (D2) — API thật (`/v1/ai/*`), không còn mock.
class AiRepository {
  AiRepository(this._dio);

  final Dio _dio;

  /// `GET /v1/ai/status`. 404/503/501 → `apiMissing` (EmptyState chưa hỗ trợ).
  Future<AiStatus> status() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(Ep.aiStatus);
      final d = res.data ?? const <String, dynamic>{};
      final budget = d['budget'];
      final rate = d['rateLimit'];
      return AiStatus(
        enabled: d['enabled'] == true,
        apiMissing: false,
        model: d['model'] as String?,
        budget: budget is Map<String, dynamic>
            ? AiBudget(
                monthlyTokenBudget:
                    (budget['monthlyTokenBudget'] as num?)?.toInt() ?? 0,
                used: (budget['used'] as num?)?.toInt() ?? 0,
                remaining: (budget['remaining'] as num?)?.toInt(),
              )
            : null,
        rateLimitPerHour: rate is Map<String, dynamic>
            ? (rate['perHour'] as num?)?.toInt()
            : null,
      );
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 404 || code == 503 || code == 501) {
        return const AiStatus(enabled: false, apiMissing: true);
      }
      rethrow;
    }
  }

  Future<AiConversationPage> listConversations({
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      Ep.aiConversations,
      queryParameters: {'page': page, 'limit': limit},
    );
    final d = res.data ?? const <String, dynamic>{};
    final items = (d['items'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(AiConversation.fromJson)
        .toList();
    return AiConversationPage(
      items: items,
      total: (d['total'] as num?)?.toInt() ?? items.length,
      page: page,
      limit: limit,
    );
  }

  Future<AiConversation> createConversation({
    String? title,
    String? equipmentId,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      Ep.aiConversations,
      data: {
        if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
        'equipmentId': ?equipmentId,
      },
    );
    return AiConversation.fromJson(res.data!);
  }

  Future<AiConversationDetail> getConversation(String id) async {
    final res = await _dio.get<Map<String, dynamic>>(Ep.aiConversation(id));
    final d = res.data ?? const <String, dynamic>{};
    return AiConversationDetail(
      conversation: AiConversation.fromJson(d),
      messages: (d['messages'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(AiMessage.fromJson)
          .toList(),
    );
  }

  Future<void> deleteConversation(String id) =>
      _dio.delete<void>(Ep.aiConversation(id));

  Future<void> feedback(String messageId, {required bool helpful}) =>
      _dio.post<void>(
        Ep.aiMessageFeedback(messageId),
        data: {'feedback': helpful ? 'up' : 'down'},
      );

  /// `POST /v1/ai/conversations/:id/messages` → stream SSE.
  Stream<SseEvent> sendMessage(
    String conversationId,
    String content, {
    List<String> attachmentFileIds = const [],
    CancelToken? cancelToken,
  }) async* {
    final res = await _dio.post<ResponseBody>(
      Ep.aiMessages(conversationId),
      data: {
        'content': content,
        if (attachmentFileIds.isNotEmpty)
          'attachmentFileIds': attachmentFileIds,
      },
      options: Options(
        responseType: ResponseType.stream,
        headers: {'Accept': 'text/event-stream'},
      ),
      cancelToken: cancelToken,
    );
    final parser = SseParser();
    await for (final chunk in res.data!.stream) {
      final raw = utf8.decode(chunk, allowMalformed: true);
      for (final e in parser.add(raw)) {
        yield e;
      }
    }
  }

  /// `GET /v1/ai/digest/weekly` → tóm tắt tuần.
  Future<String> weeklyDigest({String? weekStart}) async {
    final res = await _dio.get<dynamic>(
      Ep.aiDigestWeekly,
      queryParameters: {'weekStart': ?weekStart},
    );
    final d = res.data;
    if (d is Map) {
      return (d['summary'] as String?) ??
          (d['text'] as String?) ??
          d.toString();
    }
    return d?.toString() ?? '';
  }
}
