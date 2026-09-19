import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/ai/ai_models.dart';
import '../../core/ai/sse_parser.dart';
import '../api/endpoints_ai.dart';

/// Repository AI (D2). API chưa có → `status` trả apiMissing, chat dùng mock.
class AiRepository {
  AiRepository(this._dio, {MockAiService? mock})
    : mock = mock ?? MockAiService();

  final Dio _dio;
  final MockAiService mock;

  Future<AiStatus> status() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(EpAi.status);
      return AiStatus(
        enabled: (res.data?['enabled'] as bool?) ?? false,
        apiMissing: false,
        model: res.data?['model'] as String?,
      );
    } catch (e) {
      final err = e is DioException ? e.response?.statusCode : null;
      if (err == 404 || err == 501) {
        return const AiStatus(enabled: false, apiMissing: true);
      }
      return const AiStatus(enabled: false, apiMissing: true);
    }
  }

  /// Stream trả lời: dùng SSE thật khi API có, fallback mock khi thiếu.
  Stream<SseEvent> sendMessage(
    String conversationId,
    String text, {
    List<String> attachmentFileIds = const [],
    CancelToken? cancelToken,
  }) async* {
    try {
      final res = await _dio.post<ResponseBody>(
        EpAi.messages(conversationId),
        data: {
          'text': text,
          if (attachmentFileIds.isNotEmpty)
            'attachmentFileIds': attachmentFileIds,
        },
        options: Options(responseType: ResponseType.stream),
        cancelToken: cancelToken,
      );
      final parser = SseParser();
      await for (final chunk in res.data!.stream) {
        final raw = utf8.decode(chunk, allowMalformed: true);
        for (final e in parser.add(raw)) {
          yield e;
        }
      }
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) rethrow;
      final status = e.response?.statusCode;
      // API chưa có (404) hoặc không kết nối được → chế độ mô phỏng.
      if (status == 404 || status == 501 || e.response == null) {
        yield* _mockStream(text, cancelToken);
        return;
      }
      rethrow;
    }
  }

  Stream<SseEvent> _mockStream(String text, CancelToken? cancel) async* {
    final like = _DioCancel(cancel);
    yield* mock.stream(text, cancel: like);
  }
}

class _DioCancel implements CancelTokenLike {
  _DioCancel(this._token);
  final CancelToken? _token;

  @override
  bool get isCancelled => _token?.isCancelled ?? false;
}

/// Áp dụng sự kiện SSE vào tin nhắn (reducer thuần, test được).
class AiStreamReducer {
  AiStreamReducer(this.message);

  final AiMessage message;

  void apply(SseEvent event) {
    switch (event.event) {
      case 'text':
        message.text += event.data;
      case 'tool':
        final data = _json(event.data);
        final rows = (data['rows'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList();
        message.tools = [
          ...message.tools,
          AiToolCard(
            name: (data['name'] as String?) ?? 'tool',
            rows: rows.take(50).toList(),
            link: data['link'] as String?,
          ),
        ];
      case 'sources':
        final list = jsonDecode(event.data);
        if (list is List) {
          message.sources = list.whereType<String>().toList();
        }
      case 'error':
        message.error = _json(event.data)['message'] as String? ?? event.data;
      case 'done':
        message.streaming = false;
    }
  }

  static Map<String, dynamic> _json(String raw) {
    try {
      final d = jsonDecode(raw);
      return d is Map<String, dynamic> ? d : const {};
    } catch (_) {
      return const {};
    }
  }
}
