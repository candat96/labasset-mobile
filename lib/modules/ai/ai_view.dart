import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/ai/ai_models.dart';
import '../../core/format/format.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/attachment_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/app_sheet.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../data/models/equipment.dart';
import 'ai_controller.dart';

/// Màn chat Trợ lý AI `/ai/:id` (và `/ai` → tạo mới rồi chuyển sang chat).
class AiView extends GetView<AiController> {
  const AiView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(
          () => InkWell(
            onTap: () => _rename(context, controller),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    controller.conversation.value?.title ?? 'ai.title'.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(LucideIcons.pencil, size: 15),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'ai.history'.tr,
            icon: const Icon(LucideIcons.history),
            onPressed: () => Get.toNamed(Routes.aiConversations),
          ),
          IconButton(
            tooltip: 'ai.digest'.tr,
            icon: const Icon(LucideIcons.fileText),
            onPressed: () => _digest(context, controller),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.error.value != null &&
            controller.conversation.value == null) {
          return ErrorState(
            error: controller.error.value!,
            onRetry: controller.load,
          );
        }
        return Column(
          children: [
            if (controller.banner.value != null)
              _Banner(text: controller.banner.value!),
            if (controller.equipmentInfo.value != null)
              _EquipmentContext(
                equipment: controller.equipmentInfo.value!,
                onTap: () => Get.toNamed(
                  Routes.equipment(controller.equipmentInfo.value!.id),
                ),
              ),
            Expanded(
              child: controller.messages.isEmpty
                  ? _Suggestions(
                      keys: controller.suggestions,
                      onPick: controller.send,
                    )
                  : _MessageList(controller: controller),
            ),
            _Composer(controller: controller),
          ],
        );
      }),
    );
  }

  Future<void> _rename(BuildContext context, AiController c) async {
    final title = await AppDialog.prompt(
      context,
      title: 'ai.rename'.tr,
      initial: c.conversation.value?.title,
      label: 'ai.title'.tr,
    );
    if (title != null && title.isNotEmpty) c.rename(title);
  }

  Future<void> _digest(BuildContext context, AiController c) async {
    final text = await c.weeklyDigest();
    if (!context.mounted) return;
    await AppSheet.show<void>(
      context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ai.digest'.tr, style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            MarkdownBody(data: text),
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    color: context.status.warningBackground,
    padding: const EdgeInsets.all(AppSpacing.md),
    child: Row(
      children: [
        Icon(
          LucideIcons.triangleAlert,
          size: 18,
          color: context.status.warning,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: context.appText.label.copyWith(
              color: context.status.warningForeground,
            ),
          ),
        ),
      ],
    ),
  );
}

class _EquipmentContext extends StatelessWidget {
  const _EquipmentContext({required this.equipment, required this.onTap});

  final EquipmentSummary equipment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.sm,
      AppSpacing.lg,
      0,
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.chip),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.monitorCog,
              size: 16,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                '${equipment.code} — ${equipment.name}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.appText.label.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Suggestions extends StatelessWidget {
  const _Suggestions({required this.keys, required this.onPick});

  final List<String> keys;
  final void Function(String text) onPick;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(AppSpacing.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.lg),
        EmptyState(
          icon: LucideIcons.sparkles,
          title: 'ai.empty'.tr,
          description: 'ai.hint'.tr,
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final k in keys)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: OutlinedButton(
              onPressed: () => onPick(k.tr),
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
              ),
              child: Text(k.tr, textAlign: TextAlign.left),
            ),
          ),
      ],
    ),
  );
}

class _MessageList extends StatefulWidget {
  const _MessageList({required this.controller});

  final AiController controller;

  @override
  State<_MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<_MessageList> {
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final atBottom =
        _scroll.position.pixels >= _scroll.position.maxScrollExtent - 40;
    widget.controller.setAtBottom(atBottom);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final messages = widget.controller.messages;
      if (widget.controller.atBottom.value) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scroll.hasClients) {
            _scroll.jumpTo(_scroll.position.maxScrollExtent);
          }
        });
      }
      return Stack(
        children: [
          ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: messages.length,
            itemBuilder: (_, i) => _MessageRow(
              message: messages[i],
              onFeedback: (helpful) =>
                  widget.controller.feedback(messages[i], helpful),
              onRetry: () => widget.controller.retry(messages[i]),
            ),
          ),
          if (!widget.controller.atBottom.value)
            Positioned(
              right: AppSpacing.lg,
              bottom: AppSpacing.md,
              child: FloatingActionButton.small(
                heroTag: 'ai-scroll-down',
                onPressed: () {
                  if (_scroll.hasClients) {
                    _scroll.animateTo(
                      _scroll.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                    );
                  }
                },
                child: const Icon(LucideIcons.arrowDown),
              ),
            ),
        ],
      );
    });
  }
}

class _MessageRow extends StatelessWidget {
  const _MessageRow({
    required this.message,
    required this.onFeedback,
    required this.onRetry,
  });

  final AiMessage message;
  final ValueChanged<bool> onFeedback;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (message.role == AiRole.tool) {
      return _ToolChips(tools: message.tools);
    }
    return _Bubble(message: message, onFeedback: onFeedback, onRetry: onRetry);
  }
}

class _ToolChips extends StatelessWidget {
  const _ToolChips({required this.tools});

  final List<AiToolChip> tools;

  @override
  Widget build(BuildContext context) {
    if (tools.isEmpty) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final t in tools)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      t.status == 'start'
                          ? LucideIcons.loader
                          : LucideIcons.wrench,
                      size: 13,
                      color: context.appText.label.color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '🔧 ${aiToolLabel(t.name)}${t.summary == null ? '' : ' · ${t.summary}'}',
                      style: context.appText.caption,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    required this.onFeedback,
    required this.onRetry,
  });

  final AiMessage message;
  final ValueChanged<bool> onFeedback;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.role == AiRole.user;
    final scheme = theme.colorScheme;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.85,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? scheme.primaryContainer
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser && message.tools.isNotEmpty)
              _ToolChips(tools: message.tools),
            if (isUser)
              SelectableText(
                message.text,
                style: context.appText.body.copyWith(
                  color: scheme.onPrimaryContainer,
                ),
              )
            else if (message.text.isNotEmpty)
              MarkdownBody(
                data: message.text,
                selectable: true,
                styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                  p: context.appText.body,
                  listBullet: context.appText.body,
                  strong: context.appText.body.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  code: context.appText.caption.copyWith(
                    backgroundColor: scheme.surface,
                  ),
                ),
              ),
            if (message.streaming)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: _BlinkingCursor(),
              ),
            if (message.error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: context.status.dangerBackground,
                  borderRadius: BorderRadius.circular(AppRadius.tile),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.error!,
                      style: context.appText.label.copyWith(
                        color: context.status.dangerForeground,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    TextButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(LucideIcons.refreshCw, size: 16),
                      label: Text('common.retry'.tr),
                    ),
                  ],
                ),
              ),
            ],
            if (message.interrupted)
              Text('ai.stopped'.tr, style: context.appText.caption),
            if (!isUser &&
                !message.streaming &&
                message.error == null &&
                message.text.isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'ai.feedback.helpful'.tr,
                    icon: Icon(
                      LucideIcons.thumbsUp,
                      size: 18,
                      color: message.feedback == true
                          ? scheme.primary
                          : context.appText.label.color,
                    ),
                    onPressed: () => onFeedback(true),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'ai.feedback.notHelpful'.tr,
                    icon: Icon(
                      LucideIcons.thumbsDown,
                      size: 18,
                      color: message.feedback == false
                          ? context.status.danger
                          : context.appText.label.color,
                    ),
                    onPressed: () => onFeedback(false),
                  ),
                  if (message.createdAt != null)
                    Text(
                      formatRelative(message.createdAt),
                      style: context.appText.caption,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _BlinkingCursor extends StatefulWidget {
  const _BlinkingCursor();

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _c,
    child: Container(width: 10, height: 16, color: context.appText.label.color),
  );
}

class _Composer extends StatefulWidget {
  const _Composer({required this.controller});

  final AiController controller;

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  final TextEditingController _input = TextEditingController();
  final List<String> _fileIds = [];
  bool _uploading = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _attach() async {
    if (_fileIds.length >= 4 || _uploading) return;
    final service = Get.find<AttachmentService>();
    final picked = await service.pickImageBytes();
    if (picked == null) return;
    setState(() => _uploading = true);
    try {
      final id = await service.uploadFileBytes(
        name: picked.name,
        mime: picked.mime,
        bytes: picked.bytes,
      );
      if (!mounted) return;
      setState(() => _fileIds.add(id));
    } catch (e) {
      AppSnackbar.error(e);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    final ids = List<String>.from(_fileIds);
    _input.clear();
    setState(() => _fileIds.clear());
    await widget.controller.send(text, attachmentFileIds: ids);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(top: BorderSide(color: context.cardBorder)),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_fileIds.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.paperclip,
                      size: 14,
                      color: context.appText.label.color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'ai.attachments'.trParams({'n': '${_fileIds.length}'}),
                      style: context.appText.caption,
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => setState(_fileIds.clear),
                      child: Text('common.clear'.tr),
                    ),
                  ],
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'ai.attach'.tr,
                  onPressed: _fileIds.length >= 4 ? null : _attach,
                  icon: _uploading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(LucideIcons.paperclip),
                ),
                Expanded(
                  child: TextField(
                    controller: _input,
                    minLines: 1,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.newline,
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                      hintText: 'ai.inputHint'.tr,
                      filled: true,
                      fillColor: context.isDark
                          ? AppColors.mutedDark
                          : AppColors.muted,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      border: _inputBorder,
                      enabledBorder: _inputBorder,
                      focusedBorder: _inputBorder,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Obx(
                  () => widget.controller.sending.value
                      ? IconButton.filled(
                          tooltip: 'ai.stop'.tr,
                          onPressed: widget.controller.stop,
                          icon: const Icon(LucideIcons.square, size: 18),
                        )
                      : IconButton.filled(
                          tooltip: 'ai.send'.tr,
                          onPressed: _send,
                          icon: const Icon(LucideIcons.send, size: 18),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

const _inputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(AppRadius.chip)),
  borderSide: BorderSide.none,
);

/// Nhãn tiếng Việt cho tên tool (mặc định giữ nguyên tên).
String aiToolLabel(String name) {
  final key = aiToolNames[name];
  if (key == null) return name;
  final label = key.tr;
  return label == key ? name : label;
}
