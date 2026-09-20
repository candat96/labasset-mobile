import 'dart:async';

import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../core/ai/ai_models.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../data/repositories/ai_repository.dart';

/// Trợ lý AI: danh sách hội thoại (local) + chat stream (mock khi API thiếu).
class AiController extends GetxController {
  AiController({required this.repo, this.equipmentId});

  final AiRepository repo;
  final String? equipmentId;

  final Rxn<AiStatus> status = Rxn<AiStatus>();
  final RxList<AiConversation> conversations = <AiConversation>[].obs;
  final Rxn<AiConversation> current = Rxn<AiConversation>();
  final RxList<AiMessage> messages = <AiMessage>[].obs;
  final RxBool sending = false.obs;
  final RxBool loading = true.obs;
  final RxString error = ''.obs;

  CancelToken? _cancel;

  @override
  void onInit() {
    super.onInit();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    status.value = await repo.status();
    loading.value = false;
  }

  AiConversation newConversation({String? title}) {
    final c = AiConversation(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      title:
          title ?? (equipmentId == null ? 'ai.new'.tr : 'ai.askEquipment'.tr),
      equipmentId: equipmentId,
    );
    conversations.insert(0, c);
    current.value = c;
    messages.clear();
    return c;
  }

  void open(AiConversation c) {
    current.value = c;
    messages.clear();
  }

  void delete(AiConversation c) {
    conversations.remove(c);
    if (current.value?.id == c.id) {
      current.value = null;
      messages.clear();
    }
  }

  /// Gửi tin nhắn, nối dần text/tool theo SSE (mock nếu API chưa có).
  Future<void> send(
    String text, {
    List<String> attachmentFileIds = const [],
  }) async {
    if (text.trim().isEmpty) return;
    final c = current.value ?? newConversation();
    messages.add(
      AiMessage(
        id: 'u-${DateTime.now().microsecondsSinceEpoch}',
        role: AiRole.user,
        text: text.trim(),
      ),
    );
    final reply = AiMessage(
      id: 'a-${DateTime.now().microsecondsSinceEpoch}',
      role: AiRole.assistant,
      streaming: true,
    );
    messages.add(reply);
    sending.value = true;
    error.value = '';
    _cancel = CancelToken();
    final reducer = AiStreamReducer(reply);
    try {
      await for (final event in repo.sendMessage(
        c.id,
        text.trim(),
        attachmentFileIds: attachmentFileIds,
        cancelToken: _cancel,
      )) {
        reducer.apply(event);
        messages.refresh();
        if (event.event == 'done' || event.event == 'error') break;
      }
    } catch (e) {
      if (!CancelToken.isCancel(e as DioException)) {
        reply.error = e.toString();
      }
    } finally {
      reply.streaming = false;
      sending.value = false;
      messages.refresh();
    }
  }

  void stop() {
    _cancel?.cancel('user');
    sending.value = false;
  }

  void feedback(AiMessage m, bool helpful) {
    m.feedback = helpful;
    messages.refresh();
    AppSnackbar.success('ai.feedback.saved'.tr);
  }

  /// Tóm tắt tuần (mock khi API chưa có).
  Future<String> weeklyDigest() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return 'Tuần này: 3 phiếu sửa hoàn thành, 1 phiếu quá hạn, 2 máy đến hạn bảo dưỡng. '
        'Nổi bật: máy ly tâm Eppendorf lỗi E12 đã xử lý xong.';
  }
}
