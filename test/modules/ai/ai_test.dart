import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:labasset_mobile/core/ai/ai_models.dart';
import 'package:labasset_mobile/core/ai/sse_parser.dart';
import 'package:labasset_mobile/core/i18n/app_translations.dart';
import 'package:labasset_mobile/data/repositories/ai_repository.dart';
import 'package:labasset_mobile/modules/ai/ai_controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockAiRepo extends Mock implements AiRepository {}

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

  group('AiStreamReducer (protocol thật)', () {
    test('text {delta} + tool start/done + done', () {
      final m = AiMessage(id: 'a1', role: AiRole.assistant, streaming: true);
      final r = AiStreamReducer(m);
      r.apply(SseEvent(event: 'text', data: jsonEncode({'delta': 'Xin '})));
      r.apply(SseEvent(event: 'text', data: jsonEncode({'delta': 'chào'})));
      r.apply(
        SseEvent(
          event: 'tool',
          data: jsonEncode({'name': 'list_repairs', 'status': 'start'}),
        ),
      );
      r.apply(
        SseEvent(
          event: 'tool',
          data: jsonEncode({
            'name': 'list_repairs',
            'status': 'done',
            'summary': '3 dòng',
          }),
        ),
      );
      r.apply(SseEvent(event: 'done', data: jsonEncode({'messageId': 'm9'})));
      expect(m.text, 'Xin chào');
      expect(m.tools.single.name, 'list_repairs');
      expect(m.tools.single.summary, '3 dòng');
      expect(m.tools.single.status, 'done');
      expect(m.id, 'm9');
      expect(m.streaming, isFalse);
    });

    test('error {code,message}', () {
      final m = AiMessage(id: 'a1', role: AiRole.assistant, streaming: true);
      AiStreamReducer(m).apply(
        SseEvent(
          event: 'error',
          data: jsonEncode({
            'code': 'AI_RATE_LIMITED',
            'message': 'Trợ lý đang bận',
          }),
        ),
      );
      expect(m.error, 'Trợ lý đang bận');
      expect(m.errorCode, 'AI_RATE_LIMITED');
    });

    test('lịch sử: tin nhắn tool → chip với rows', () {
      final m = AiMessage.fromJson({
        'id': 't1',
        'role': 'tool',
        'content': jsonEncode({
          'rows': [
            {'code': 'SC-1'},
          ],
        }),
        'toolCalls': [
          {'name': 'list_repairs'},
        ],
      });
      expect(m.role, AiRole.tool);
      expect(m.tools.single.name, 'list_repairs');
      expect(m.tools.single.rows.single['code'], 'SC-1');
    });
  });

  group('AiController', () {
    late _MockAiRepo repo;

    setUp(() {
      repo = _MockAiRepo();
      when(() => repo.getConversation('c1')).thenAnswer(
        (_) async => AiConversationDetail(
          conversation: AiConversation(id: 'c1', title: 'Hội thoại'),
          messages: const [],
        ),
      );
    });

    void stubSend(Stream<SseEvent> Function() stream) {
      when(
        () => repo.sendMessage(
          any(),
          any(),
          attachmentFileIds: any(named: 'attachmentFileIds'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) => stream());
    }

    test('stream text + tool + done', () async {
      stubSend(
        () => Stream.fromIterable([
          SseEvent(event: 'text', data: jsonEncode({'delta': 'Xin '})),
          SseEvent(event: 'text', data: jsonEncode({'delta': 'chào'})),
          SseEvent(
            event: 'tool',
            data: jsonEncode({'name': 'list_repairs', 'status': 'start'}),
          ),
          SseEvent(
            event: 'tool',
            data: jsonEncode({
              'name': 'list_repairs',
              'status': 'done',
              'summary': '3 dòng',
            }),
          ),
          SseEvent(event: 'done', data: jsonEncode({'messageId': 'm9'})),
        ]),
      );
      final c = AiController(repo: repo, conversationId: 'c1');
      await c.load();
      await c.send('Máy lỗi E12?');
      expect(c.messages, hasLength(2));
      final reply = c.messages.last;
      expect(reply.text, 'Xin chào');
      expect(reply.tools.single.name, 'list_repairs');
      expect(reply.streaming, isFalse);
      expect(c.sending.value, isFalse);
    });

    test('lỗi AI_RATE_LIMITED → error + banner; retry gửi lại', () async {
      var calls = 0;
      stubSend(() {
        calls += 1;
        if (calls == 1) {
          return Stream.fromIterable([
            SseEvent(
              event: 'error',
              data: jsonEncode({
                'code': 'AI_RATE_LIMITED',
                'message': 'Trợ lý đang bận',
              }),
            ),
          ]);
        }
        return Stream.fromIterable([
          SseEvent(event: 'text', data: jsonEncode({'delta': 'Ok'})),
          SseEvent(event: 'done', data: jsonEncode({'messageId': 'm2'})),
        ]);
      });
      final c = AiController(repo: repo, conversationId: 'c1');
      await c.load();
      await c.send('hỏi');
      final failed = c.messages.last;
      expect(failed.error, 'Trợ lý đang bận');
      expect(c.banner.value, 'Trợ lý đang bận');
      await c.retry(failed);
      expect(c.messages.last.text, 'Ok');
      expect(c.messages.last.error, isNull);
    });

    test('stop dừng stream', () async {
      final gate = Completer<void>();
      stubSend(() async* {
        yield SseEvent(event: 'text', data: jsonEncode({'delta': 'A'}));
        await gate.future;
        yield SseEvent(event: 'text', data: jsonEncode({'delta': 'B'}));
      });
      final c = AiController(repo: repo, conversationId: 'c1');
      await c.load();
      final future = c.send('câu hỏi dài');
      await Future<void>.delayed(Duration.zero);
      c.stop();
      gate.complete();
      await future;
      expect(c.sending.value, isFalse);
      expect(c.messages.last.streaming, isFalse);
      expect(c.messages.last.interrupted, isTrue);
    });

    test('feedback ghi nhận (local)', () async {
      stubSend(
        () => Stream.fromIterable([
          SseEvent(event: 'text', data: jsonEncode({'delta': 'A'})),
          SseEvent(event: 'done', data: jsonEncode({'messageId': 'm1'})),
        ]),
      );
      final c = AiController(repo: repo, conversationId: 'c1');
      await c.load();
      await c.send('hỏi');
      final reply = c.messages.last;
      when(
        () => repo.feedback(any(), helpful: any(named: 'helpful')),
      ).thenAnswer((_) async {});
      await c.feedback(reply, true);
      expect(reply.feedback, isTrue);
      verify(() => repo.feedback('m1', helpful: true)).called(1);
    });
  });
}
