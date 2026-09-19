/// Một sự kiện SSE đã tách (`event:` + `data:`).
class SseEvent {
  const SseEvent({this.event = 'message', this.data = ''});

  final String event;
  final String data;
}

/// Parser SSE tối giản theo khối `\n\n` (dùng cho `ResponseType.stream` của dio).
///
/// Nhận từng chunk thô, trả về các sự kiện hoàn chỉnh và giữ phần dư.
class SseParser {
  String _buffer = '';

  List<SseEvent> add(String chunk) {
    _buffer += chunk.replaceAll('\r\n', '\n');
    final events = <SseEvent>[];
    while (true) {
      final idx = _buffer.indexOf('\n\n');
      if (idx < 0) break;
      final block = _buffer.substring(0, idx);
      _buffer = _buffer.substring(idx + 2);
      final parsed = _parseBlock(block);
      if (parsed != null) events.add(parsed);
    }
    return events;
  }

  SseEvent? _parseBlock(String block) {
    var event = 'message';
    final data = StringBuffer();
    for (final line in block.split('\n')) {
      if (line.startsWith('event:')) {
        event = line.substring(6).trim();
      } else if (line.startsWith('data:')) {
        if (data.isNotEmpty) data.write('\n');
        data.write(line.substring(5).trimLeft());
      }
    }
    if (data.isEmpty && event == 'message') return null;
    return SseEvent(event: event, data: data.toString());
  }
}
