import 'dart:async';

import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../core/ai/ai_models.dart';
import '../../core/errors/api_error.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../data/models/equipment.dart';
import '../../data/repositories/ai_repository.dart';
import '../../data/repositories/equipment_repository.dart';

/// Màn chat Trợ lý AI `/ai/:id` (và `/ai` = tạo mới rồi chuyển sang chat).
class AiController extends GetxController {
  AiController({
    required this.repo,
    this.conversationId,
    this.equipmentId,
    this.equipment,
    Future<void> Function(String route)? replace,
  }) : _replace = replace ?? ((r) async => Get.offNamed(r));

  final AiRepository repo;
  final EquipmentRepository? equipment;

  /// Id hội thoại; null = mở từ `/ai` → tạo mới.
  final String? conversationId;

  /// Ngữ cảnh máy khi tạo hội thoại mới từ hồ sơ máy.
  final String? equipmentId;

  final Future<void> Function(String route) _replace;

  final Rxn<AiConversation> conversation = Rxn<AiConversation>();
  final RxList<AiMessage> messages = <AiMessage>[].obs;
  final RxBool loading = true.obs;
  final RxBool sending = false.obs;
  final Rxn<Object> error = Rxn<Object>();
  final RxnString banner = RxnString();
  final Rxn<EquipmentSummary> equipmentInfo = Rxn<EquipmentSummary>();

  /// Người dùng đang ở đáy (auto-scroll); false khi tự cuộn lên.
  final RxBool atBottom = true.obs;

  CancelToken? _cancel;
  bool _creating = false;

  bool get isNew => conversationId == null;

  @override
  void onInit() {
    super.onInit();
    if (isNew) {
      _createNew();
    } else {
      load();
    }
  }

  Future<void> _createNew() async {
    if (_creating) return;
    _creating = true;
    try {
      final c = await repo.createConversation(equipmentId: equipmentId);
      conversation.value = c;
      loading.value = false;
      await _replace(Routes.aiChat(c.id));
    } catch (e) {
      error.value = e;
      loading.value = false;
    } finally {
      _creating = false;
    }
  }

  Future<void> load() async {
    final id = conversationId;
    if (id == null) return;
    loading.value = true;
    error.value = null;
    try {
      final detail = await repo.getConversation(id);
      conversation.value = detail.conversation;
      messages.assignAll(detail.messages);
      unawaited(_loadEquipment(detail.conversation.equipmentId));
    } catch (e) {
      error.value = e;
    } finally {
      loading.value = false;
    }
  }

  Future<void> _loadEquipment(String? id) async {
    if (id == null || id.isEmpty || equipment == null) return;
    try {
      equipmentInfo.value = await equipment!.byId(id);
    } catch (_) {
      // best-effort — chip ngữ cảnh máy
    }
  }

  /// 4 gợi ý câu hỏi theo ngữ cảnh máy / toàn viện.
  List<String> get suggestions =>
      equipmentInfo.value != null ||
          (conversation.value?.equipmentId ?? equipmentId) != null
      ? const [
          'ai.suggest.eq1',
          'ai.suggest.eq2',
          'ai.suggest.eq3',
          'ai.suggest.eq4',
        ]
      : const [
          'ai.suggest.all1',
          'ai.suggest.all2',
          'ai.suggest.all3',
          'ai.suggest.all4',
        ];

  Future<void> send(
    String text, {
    List<String> attachmentFileIds = const [],
  }) async {
    final c = conversation.value;
    if (c == null || text.trim().isEmpty || sending.value) return;
    banner.value = null;
    messages.add(
      AiMessage(
        id: 'u-${DateTime.now().microsecondsSinceEpoch}',
        role: AiRole.user,
        text: text.trim(),
        createdAt: DateTime.now(),
      ),
    );
    final reply = AiMessage(
      id: 'a-${DateTime.now().microsecondsSinceEpoch}',
      role: AiRole.assistant,
      streaming: true,
      createdAt: DateTime.now(),
    );
    messages.add(reply);
    await _run(c.id, text.trim(), reply, attachmentFileIds);
  }

  /// Gửi lại nội dung của câu hỏi trước câu trả lời lỗi.
  Future<void> retry(AiMessage failed) async {
    if (sending.value) return;
    final idx = messages.indexOf(failed);
    String? text;
    for (var i = idx - 1; i >= 0; i--) {
      if (messages[i].role == AiRole.user) {
        text = messages[i].text;
        break;
      }
    }
    final c = conversation.value;
    if (text == null || c == null) return;
    messages.remove(failed);
    final reply = AiMessage(
      id: 'a-${DateTime.now().microsecondsSinceEpoch}',
      role: AiRole.assistant,
      streaming: true,
      createdAt: DateTime.now(),
    );
    messages.add(reply);
    await _run(c.id, text, reply, const []);
  }

  Future<void> _run(
    String conversationId,
    String text,
    AiMessage reply,
    List<String> attachmentFileIds,
  ) async {
    banner.value = null;
    sending.value = true;
    _cancel = CancelToken();
    final reducer = AiStreamReducer(reply);
    try {
      await for (final event in repo.sendMessage(
        conversationId,
        text,
        attachmentFileIds: attachmentFileIds,
        cancelToken: _cancel,
      )) {
        reducer.apply(event);
        if (event.event == 'error') _maybeBanner(reply.errorCode, reply.error);
        messages.refresh();
        if (event.event == 'done' || event.event == 'error') break;
      }
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        reply.interrupted = true;
      } else {
        reply.error = ApiError.messageFor(e);
      }
    } catch (e) {
      reply.error = ApiError.messageFor(e);
    } finally {
      reply.streaming = false;
      sending.value = false;
      messages.refresh();
    }
  }

  void _maybeBanner(String? code, String? message) {
    if (code == 'AI_BUDGET_EXCEEDED' || code == 'AI_RATE_LIMITED') {
      banner.value = message ?? 'errors.$code'.tr;
    }
  }

  void stop() {
    _cancel?.cancel('user');
    sending.value = false;
    for (final m in messages) {
      if (m.streaming) {
        m.streaming = false;
        m.interrupted = true;
      }
    }
    messages.refresh();
  }

  /// Sửa tiêu đề hội thoại (API chưa có PATCH → chỉ đổi local).
  void rename(String title) {
    final c = conversation.value;
    if (c == null) return;
    c.title = title.trim();
    conversation.refresh();
  }

  Future<void> feedback(AiMessage message, bool helpful) async {
    message.feedback = helpful;
    messages.refresh();
    if (message.id.startsWith('a-')) return; // chưa có id thật từ server
    try {
      await repo.feedback(message.id, helpful: helpful);
      AppSnackbar.success('ai.feedback.saved'.tr);
    } catch (_) {
      // giữ phản hồi local
    }
  }

  Future<String> weeklyDigest() async {
    try {
      return await repo.weeklyDigest();
    } catch (e) {
      return ApiError.messageFor(e);
    }
  }

  void setAtBottom(bool value) => atBottom.value = value;
}
