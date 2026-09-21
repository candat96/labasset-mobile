import 'dart:convert';

import 'sse_parser.dart';

/// Ngân sách token tháng (`GET /v1/ai/status.budget`).
class AiBudget {
  const AiBudget({this.monthlyTokenBudget = 0, this.used = 0, this.remaining});

  final int monthlyTokenBudget;
  final int used;
  final int? remaining;

  bool get exhausted => remaining != null && remaining! <= 0;
}

/// Trạng thái AI (`GET /v1/ai/status`).
class AiStatus {
  const AiStatus({
    this.enabled = false,
    this.apiMissing = true,
    this.model,
    this.budget,
    this.rateLimitPerHour,
  });

  final bool enabled;

  /// API chưa có (404/503) → hiện EmptyState "chưa hỗ trợ".
  final bool apiMissing;
  final String? model;
  final AiBudget? budget;
  final int? rateLimitPerHour;
}

/// Hội thoại AI (`AiConversationDto`).
class AiConversation {
  AiConversation({
    required this.id,
    required this.title,
    this.equipmentId,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  String title;
  final String? equipmentId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory AiConversation.fromJson(Map<String, dynamic> json) => AiConversation(
    id: json['id'] as String,
    title: (json['title'] as String?) ?? '',
    equipmentId: json['equipmentId'] as String?,
    createdAt: _date(json['createdAt']),
    updatedAt: _date(json['updatedAt']),
  );

  static DateTime? _date(Object? v) =>
      v is String ? DateTime.tryParse(v)?.toLocal() : null;
}

class AiConversationPage {
  const AiConversationPage({
    required this.items,
    required this.total,
    this.page = 1,
    this.limit = 20,
  });

  final List<AiConversation> items;
  final int total;
  final int page;
  final int limit;
}

/// `GET /v1/ai/conversations/:id` → hội thoại kèm danh sách tin nhắn.
class AiConversationDetail {
  const AiConversationDetail({
    required this.conversation,
    required this.messages,
  });

  final AiConversation conversation;
  final List<AiMessage> messages;
}

enum AiRole { user, assistant, tool }

/// Một thẻ tool trong câu trả lời.
class AiToolChip {
  AiToolChip({
    required this.name,
    this.status = 'done',
    this.summary,
    this.rows = const [],
  });

  final String name;
  String status;
  String? summary;
  final List<Map<String, dynamic>> rows;
}

/// Một tin nhắn trong hội thoại (chat + lịch sử).
class AiMessage {
  AiMessage({
    required this.id,
    required this.role,
    this.text = '',
    this.tools = const [],
    this.error,
    this.errorCode,
    this.streaming = false,
    this.feedback,
    this.interrupted = false,
    this.createdAt,
  });

  String id;
  final AiRole role;
  String text;
  List<AiToolChip> tools;
  String? error;
  String? errorCode;
  bool streaming;
  bool? feedback;
  bool interrupted;
  final DateTime? createdAt;

  /// Dựng tin nhắn từ `AiMessageDto` (lịch sử).
  factory AiMessage.fromJson(Map<String, dynamic> json) {
    final role = switch (json['role']) {
      'assistant' => AiRole.assistant,
      'tool' => AiRole.tool,
      _ => AiRole.user,
    };
    final content = (json['content'] as String?) ?? '';
    final tools = <AiToolChip>[];
    if (role == AiRole.tool) {
      final rows = _rowsFromContent(content);
      final calls = (json['toolCalls'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();
      tools.add(
        AiToolChip(
          name: (calls.firstOrNull?['name'] as String?) ?? 'tool',
          status: 'done',
          summary: rows.isEmpty ? null : '${rows.length} dòng',
          rows: rows,
        ),
      );
    }
    return AiMessage(
      id: json['id'] as String,
      role: role,
      text: role == AiRole.tool ? '' : content,
      tools: tools,
      feedback: switch (json['feedback']) {
        'up' => true,
        'down' => false,
        _ => null,
      },
      interrupted: json['interrupted'] == true,
      createdAt: AiConversation._date(json['createdAt']),
    );
  }

  static List<Map<String, dynamic>> _rowsFromContent(String content) {
    try {
      final d = jsonDecode(content);
      if (d is Map && d['rows'] is List) {
        return (d['rows'] as List)
            .whereType<Map<String, dynamic>>()
            .take(50)
            .toList();
      }
    } catch (_) {
      // nội dung tool không phải JSON rows → bỏ qua
    }
    return const [];
  }
}

/// Áp dụng sự kiện SSE vào tin nhắn (reducer thuần, test được).
///
/// Protocol thật: `text {delta}` · `tool {name,status,summary?}` ·
/// `error {code,message}` · `done {messageId,tokensIn,tokensOut}`.
class AiStreamReducer {
  AiStreamReducer(this.message);

  final AiMessage message;

  void apply(SseEvent event) {
    switch (event.event) {
      case 'text':
        message.text += _delta(event.data);
      case 'tool':
        final data = _json(event.data);
        final name = (data['name'] as String?) ?? 'tool';
        final status = (data['status'] as String?) ?? 'done';
        if (status == 'start') {
          message.tools = [
            ...message.tools,
            AiToolChip(name: name, status: 'start'),
          ];
        } else {
          final idx = message.tools.lastIndexWhere(
            (t) => t.name == name && t.status == 'start',
          );
          final chip = AiToolChip(
            name: name,
            status: 'done',
            summary: data['summary'] as String?,
          );
          if (idx >= 0) {
            final next = [...message.tools];
            next[idx] = chip;
            message.tools = next;
          } else {
            message.tools = [...message.tools, chip];
          }
        }
      case 'error':
        final data = _json(event.data);
        message.error = (data['message'] as String?) ?? event.data;
        message.errorCode = data['code'] as String?;
      case 'done':
        final data = _json(event.data);
        final id = data['messageId'];
        if (id is String && id.isNotEmpty) message.id = id;
        message.streaming = false;
    }
  }

  static String _delta(String raw) {
    final d = _json(raw);
    final delta = d['delta'];
    if (delta is String) return delta;
    // Fallback: server cũ gửi chuỗi thô.
    return raw;
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

/// Tên tool (EN) → khoá i18n tiếng Việt.
const Map<String, String> aiToolNames = {
  'search_equipment': 'ai.tool.search_equipment',
  'get_equipment': 'ai.tool.get_equipment',
  'list_repairs': 'ai.tool.list_repairs',
  'list_maintenance_tasks': 'ai.tool.list_maintenance_tasks',
  'calibration_due': 'ai.tool.calibration_due',
  'stock_balances': 'ai.tool.stock_balances',
  'stock_alerts': 'ai.tool.stock_alerts',
  'stock_runway': 'ai.tool.stock_runway',
  'list_requests': 'ai.tool.list_requests',
  'run_report': 'ai.tool.run_report',
  'search_faults': 'ai.tool.search_faults',
  'search_documents': 'ai.tool.search_documents',
  'get_my_tasks': 'ai.tool.get_my_tasks',
  'repair_stats': 'ai.tool.repair_stats',
  'equipment_timeline': 'ai.tool.equipment_timeline',
};

/// Huỷ stream (giống CancelToken của dio nhưng không phụ thuộc dio trong core).
abstract class CancelTokenLike {
  bool get isCancelled;
}
