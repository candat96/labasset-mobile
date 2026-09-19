import 'dart:async';

import 'sse_parser.dart';

/// Trạng thái AI (`GET /v1/ai/status` — API D2 chưa có → mock).
class AiStatus {
  const AiStatus({this.enabled = false, this.apiMissing = true, this.model});

  final bool enabled;
  final bool apiMissing;
  final String? model;
}

class AiConversation {
  AiConversation({required this.id, required this.title, this.equipmentId});

  final String id;
  String title;
  final String? equipmentId;
}

enum AiRole { user, assistant }

/// Một thẻ tool trong câu trả lời (rows ≤ 50).
class AiToolCard {
  AiToolCard({required this.name, this.rows = const [], this.link});

  final String name;
  final List<Map<String, dynamic>> rows;
  final String? link;
}

class AiMessage {
  AiMessage({
    required this.id,
    required this.role,
    this.text = '',
    this.tools = const [],
    this.sources = const [],
    this.error,
    this.streaming = false,
    this.feedback,
  });

  final String id;
  final AiRole role;
  String text;
  List<AiToolCard> tools;
  List<String> sources;
  String? error;
  bool streaming;
  bool? feedback;
}

/// Service mock SSE khi API D2 chưa có: phát text + tool + done theo nhịp.
class MockAiService {
  MockAiService({this.chunkDelay = const Duration(milliseconds: 40)});

  final Duration chunkDelay;

  /// Trả stream sự kiện SSE giả lập theo câu hỏi.
  Stream<SseEvent> stream(String question, {CancelTokenLike? cancel}) async* {
    final answer =
        'Dựa trên hồ sơ máy và lịch sử sửa chữa, bạn nên kiểm tra cảm biến áp suất trước. '
        'Câu hỏi: "$question".';
    final chunks = answer.split(' ');
    for (final c in chunks) {
      if (cancel?.isCancelled ?? false) return;
      await Future<void>.delayed(chunkDelay);
      yield SseEvent(event: 'text', data: '$c ');
    }
    yield SseEvent(
      event: 'tool',
      data:
          '{"name":"fault_lookup","rows":[{"errorCode":"E12","title":"Lỗi cảm biến áp suất","severity":"high"}]}',
    );
    yield SseEvent(event: 'sources', data: '["fault:E12","repair:SC-001"]');
    yield SseEvent(event: 'done', data: '{"messageId":"m-1"}');
  }
}

/// Huỷ stream (giống CancelToken của dio nhưng không phụ thuộc dio trong core).
abstract class CancelTokenLike {
  bool get isCancelled;
}
