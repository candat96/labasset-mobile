import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:labasset_mobile/core/ai/ai_models.dart';
import 'package:labasset_mobile/core/i18n/app_translations.dart';
import 'package:labasset_mobile/data/repositories/ai_repository.dart';
import 'package:labasset_mobile/modules/ai/ai_conversations_controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockAiRepo extends Mock implements AiRepository {}

AiConversation _conv(String id, {String? equipmentId}) => AiConversation(
  id: id,
  title: 'Hội thoại $id',
  equipmentId: equipmentId,
  updatedAt: DateTime(2026, 9, 21, 10),
);

void main() {
  late _MockAiRepo repo;
  final navigated = <String>[];

  setUp(() {
    Get.testMode = true;
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('vi', 'VN');
    repo = _MockAiRepo();
    navigated.clear();
  });

  tearDown(Get.reset);

  AiConversationsController make() => AiConversationsController(
    repo: repo,
    navigate: (r) async => navigated.add(r),
  );

  test('load nạp trang đầu + tổng số', () async {
    when(() => repo.listConversations(page: 1, limit: 20)).thenAnswer(
      (_) async =>
          AiConversationPage(items: [_conv('c1'), _conv('c2')], total: 2),
    );
    final c = make()..onInit();
    await Future<void>.delayed(Duration.zero);
    expect(c.items, hasLength(2));
    expect(c.total.value, 2);
    expect(c.loading.value, isFalse);
  });

  test('loadMore nạp thêm khi còn dữ liệu', () async {
    when(() => repo.listConversations(page: 1, limit: 20)).thenAnswer(
      (_) async => AiConversationPage(
        items: [for (var i = 0; i < 20; i++) _conv('c$i')],
        total: 25,
      ),
    );
    when(() => repo.listConversations(page: 2, limit: 20)).thenAnswer(
      (_) async => AiConversationPage(
        items: [for (var i = 20; i < 25; i++) _conv('c$i')],
        total: 25,
      ),
    );
    final c = make()..onInit();
    await Future<void>.delayed(Duration.zero);
    await c.loadMore();
    expect(c.items, hasLength(25));
    expect(c.hasMore, isFalse);
  });

  test('create tạo hội thoại rồi mở chat', () async {
    when(
      () => repo.createConversation(equipmentId: any(named: 'equipmentId')),
    ).thenAnswer((_) async => _conv('new1'));
    final c = make();
    await c.create();
    expect(c.items.first.id, 'new1');
    expect(navigated.single, '/ai/new1');
  });

  test('delete xoá khỏi danh sách; lỗi thì hoàn tác', () async {
    when(() => repo.listConversations(page: 1, limit: 20)).thenAnswer(
      (_) async => AiConversationPage(items: [_conv('c1')], total: 1),
    );
    when(() => repo.deleteConversation('c1')).thenAnswer((_) async {});
    final c = make()..onInit();
    await Future<void>.delayed(Duration.zero);
    await c.delete(c.items.first);
    expect(c.items, isEmpty);
    expect(c.total.value, 0);
    verify(() => repo.deleteConversation('c1')).called(1);
  });

  test('delete lỗi → khôi phục hội thoại + ghi error', () async {
    when(() => repo.listConversations(page: 1, limit: 20)).thenAnswer(
      (_) async => AiConversationPage(items: [_conv('c1')], total: 1),
    );
    when(() => repo.deleteConversation('c1')).thenThrow(Exception('boom'));
    final c = make()..onInit();
    await Future<void>.delayed(Duration.zero);
    await c.delete(c.items.first);
    expect(c.items, hasLength(1));
    expect(c.error.value, isNotNull);
  });
}
