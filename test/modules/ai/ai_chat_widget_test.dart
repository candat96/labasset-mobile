import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:labasset_mobile/core/ai/ai_models.dart';
import 'package:labasset_mobile/data/models/equipment.dart';
import 'package:labasset_mobile/data/repositories/ai_repository.dart';
import 'package:labasset_mobile/data/repositories/equipment_repository.dart';
import 'package:labasset_mobile/modules/ai/ai_controller.dart';
import 'package:labasset_mobile/modules/ai/ai_view.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_helpers.dart';

class _MockAiRepo extends Mock implements AiRepository {}

class _MockEquipment extends Mock implements EquipmentRepository {}

void main() {
  late _MockAiRepo repo;

  setUp(() {
    repo = _MockAiRepo();
  });

  tearDown(Get.reset);

  Future<AiController> pumpChat(
    WidgetTester tester, {
    List<AiMessage> messages = const [],
    String? equipmentId,
    EquipmentSummary? equipment,
  }) async {
    when(() => repo.getConversation('c1')).thenAnswer(
      (_) async => AiConversationDetail(
        conversation: AiConversation(
          id: 'c1',
          title: 'Hội thoại máy',
          equipmentId: equipmentId,
        ),
        messages: messages,
      ),
    );
    final c = AiController(
      repo: repo,
      conversationId: 'c1',
      equipment: equipment == null ? null : _MockEquipment(),
    );
    await c.load();
    if (equipment != null) c.equipmentInfo.value = equipment;
    Get.put<AiController>(c);
    await tester.pumpWidget(wrap(const AiView()));
    await tester.pumpAndSettle();
    return c;
  }

  testWidgets('hội thoại trống → 4 gợi ý', (tester) async {
    await pumpChat(tester);
    expect(find.text('Máy nào đang hỏng?'), findsOneWidget);
    expect(find.text('Vật tư nào sắp hết hạn?'), findsOneWidget);
    expect(find.text('Lịch kiểm định tháng này?'), findsOneWidget);
    expect(find.text('Chi phí sửa chữa tháng này?'), findsOneWidget);
  });

  testWidgets('chip ngữ cảnh máy khi có equipment', (tester) async {
    await pumpChat(
      tester,
      equipmentId: 'e1',
      equipment: const EquipmentSummary(
        id: 'e1',
        code: 'TB-1',
        name: 'Máy ly tâm',
        status: 'active',
      ),
    );
    expect(find.text('TB-1 — Máy ly tâm'), findsOneWidget);
    // Có máy → 4 gợi ý theo máy.
    expect(find.text('Máy này sửa mấy lần?'), findsOneWidget);
  });

  testWidgets('markdown bảng render trong bong bóng', (tester) async {
    await pumpChat(
      tester,
      messages: [
        AiMessage(id: 'u1', role: AiRole.user, text: 'Liệt kê'),
        AiMessage(
          id: 'a1',
          role: AiRole.assistant,
          text: 'Kết quả:\n\n| Mã | Tên |\n| --- | --- |\n| SC-1 | Máy X |\n',
        ),
      ],
    );
    expect(find.text('Mã'), findsOneWidget);
    expect(find.text('SC-1'), findsOneWidget);
    expect(find.text('Máy X'), findsOneWidget);
  });

  testWidgets('chip tool hiện tên tiếng Việt', (tester) async {
    await pumpChat(
      tester,
      messages: [
        AiMessage(id: 'u1', role: AiRole.user, text: 'hỏi'),
        AiMessage(
          id: 't1',
          role: AiRole.tool,
          tools: [
            AiToolChip(name: 'list_repairs', status: 'done', summary: '3 dòng'),
          ],
        ),
      ],
    );
    expect(find.textContaining('Phiếu sửa chữa'), findsOneWidget);
    expect(find.textContaining('3 dòng'), findsOneWidget);
  });
}
