import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:labasset_mobile/core/ai/ai_models.dart';
import 'package:labasset_mobile/core/ai/sse_parser.dart';
import 'package:labasset_mobile/core/i18n/app_translations.dart';
import 'package:labasset_mobile/data/repositories/ai_repository.dart';
import 'package:labasset_mobile/modules/ai/ai_controller.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('vi', 'VN');
  });

  tearDown(Get.reset);

  group('SseParser', () {
    test('tách event/data theo khối \\n\\n, giữ phần dư', () {
      final p = SseParser();
      final first = p.add('event: text\ndata: Xin chào');
      expect(first, isEmpty);
      final second = p.add('\n\nevent: text\ndata: thế giới\n\n');
      expect(second, hasLength(2));
      expect(second[0].event, 'text');
      expect(second[0].data, 'Xin chào');
      expect(second[1].data, 'thế giới');
    });

    test('data nhiều dòng nối bằng \\n và bỏ qua khối rỗng', () {
      final p = SseParser();
      final events = p.add('event: tool\ndata: {"a":1}\ndata: ok\n\n\n\n');
      expect(events, hasLength(1));
      expect(events.single.data, '{"a":1}\nok');
    });

    test('CRLF được chuẩn hoá', () {
      final p = SseParser();
      final events = p.add('event: done\r\ndata: {}\r\n\r\n');
      expect(events.single.event, 'done');
    });
  });

  group('AiStreamReducer', () {
    test('nối text, thêm tool, nguồn, lỗi, done', () {
      final m = AiMessage(id: 'a1', role: AiRole.assistant, streaming: true);
      final r = AiStreamReducer(m);
      r.apply(const SseEvent(event: 'text', data: 'Xin '));
      r.apply(const SseEvent(event: 'text', data: 'chào'));
      r.apply(
        const SseEvent(
          event: 'tool',
          data: '{"name":"fault_lookup","rows":[{"a":1}]}',
        ),
      );
      r.apply(const SseEvent(event: 'sources', data: '["fault:E12"]'));
      r.apply(const SseEvent(event: 'done', data: '{}'));
      expect(m.text, 'Xin chào');
      expect(m.tools.single.name, 'fault_lookup');
      expect(m.tools.single.rows.single['a'], 1);
      expect(m.sources, ['fault:E12']);
      expect(m.streaming, isFalse);
    });

    test('tool rows giới hạn 50', () {
      final m = AiMessage(id: 'a1', role: AiRole.assistant);
      final rows = List.generate(60, (i) => {'i': i});
      AiStreamReducer(m).apply(
        SseEvent(event: 'tool', data: jsonEncode({'name': 'x', 'rows': rows})),
      );
      expect(m.tools.single.rows, hasLength(50));
    });
  });

  group('AiController (mock stream)', () {
    test('gửi tin nhắn: text chảy dần + tool + done', () async {
      final repo = AiRepository(
        Dio(),
        mock: MockAiService(chunkDelay: Duration.zero),
      );
      // Dio thật sẽ 404 → fallback mock; dùng Dio trần.
      final c = AiController(repo: repo);
      await c.send('Máy lỗi E12 xử lý sao?');
      expect(c.messages, hasLength(2));
      final reply = c.messages.last;
      expect(reply.role, AiRole.assistant);
      expect(reply.text, isNotEmpty);
      expect(reply.streaming, isFalse);
      expect(reply.tools, isNotEmpty);
      expect(reply.sources, contains('fault:E12'));
    });

    test('stop dừng stream', () async {
      final repo = AiRepository(
        Dio(),
        mock: MockAiService(chunkDelay: const Duration(milliseconds: 50)),
      );
      final c = AiController(repo: repo);
      final future = c.send('câu hỏi dài');
      await Future<void>.delayed(const Duration(milliseconds: 60));
      c.stop();
      await future;
      expect(c.sending.value, isFalse);
    });

    test('feedback ghi nhận', () async {
      final repo = AiRepository(
        Dio(),
        mock: MockAiService(chunkDelay: Duration.zero),
      );
      final c = AiController(repo: repo);
      await c.send('hỏi');
      final reply = c.messages.last;
      c.feedback(reply, true);
      expect(reply.feedback, isTrue);
    });
  });
}
