import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/ai/ai_models.dart';
import '../../core/format/format.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/app_sheet.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/section_card.dart';
import 'ai_controller.dart';

/// Trợ lý AI `/ai`: danh sách hội thoại + chat.
class AiView extends GetView<AiController> {
  const AiView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final input = TextEditingController();
    return Scaffold(
      appBar: AppBar(
        title: Text('ai.title'.tr),
        actions: [
          IconButton(
            tooltip: 'ai.new'.tr,
            icon: const Icon(Icons.add_comment_outlined),
            onPressed: () => controller.newConversation(),
          ),
          IconButton(
            tooltip: 'ai.digest'.tr,
            icon: const Icon(Icons.summarize_outlined),
            onPressed: () => _digest(context, controller),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final status = controller.status.value;
        return Column(
          children: [
            if (status?.apiMissing ?? true)
              Container(
                width: double.infinity,
                color: context.status.warning.withValues(alpha: 0.15),
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Text(
                  'ai.mockNote'.tr,
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
            if (controller.conversations.isNotEmpty)
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  children: [
                    for (final c in controller.conversations)
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.xs),
                        child: Obx(
                          () => ChoiceChip(
                            label: Text(
                              c.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            selected: controller.current.value?.id == c.id,
                            onSelected: (_) => controller.open(c),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            Expanded(
              child: controller.messages.isEmpty
                  ? EmptyState(
                      icon: Icons.smart_toy_outlined,
                      title: 'ai.empty'.tr,
                      description: 'ai.hint'.tr,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: controller.messages.length,
                      itemBuilder: (_, i) => _Bubble(
                        message: controller.messages[i],
                        onFeedback: (helpful) => controller.feedback(
                          controller.messages[i],
                          helpful,
                        ),
                      ),
                    ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: input,
                        decoration: InputDecoration(
                          hintText: 'ai.inputHint'.tr,
                        ),
                        onSubmitted: (v) {
                          controller.send(v);
                          input.clear();
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Obx(
                      () => controller.sending.value
                          ? IconButton.filled(
                              tooltip: 'ai.stop'.tr,
                              onPressed: controller.stop,
                              icon: const Icon(Icons.stop),
                            )
                          : IconButton.filled(
                              tooltip: 'ai.send'.tr,
                              onPressed: () {
                                controller.send(input.text);
                                input.clear();
                              },
                              icon: const Icon(Icons.send),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
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
            Text(text),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.onFeedback});

  final AiMessage message;
  final ValueChanged<bool> onFeedback;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.role == AiRole.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? theme.colorScheme.primary.withValues(alpha: 0.12)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.text.isNotEmpty)
              SelectableText(message.text + (message.streaming ? ' ▌' : '')),
            for (final tool in message.tools) ...[
              const SizedBox(height: AppSpacing.sm),
              SectionCard(
                title: tool.name,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: [
                      for (final k
                          in (tool.rows.firstOrNull?.keys ?? const <String>[]))
                        DataColumn(label: Text(k)),
                    ],
                    rows: [
                      for (final r in tool.rows)
                        DataRow(
                          cells: [
                            for (final v in r.values) DataCell(Text('$v')),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
            if (message.sources.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                children: [
                  for (final s in message.sources)
                    Chip(
                      visualDensity: VisualDensity.compact,
                      avatar: const Icon(Icons.source_outlined, size: 14),
                      label: Text(s),
                    ),
                ],
              ),
            ],
            if (message.error != null)
              Text(
                message.error!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            if (!isUser && !message.streaming && message.text.isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'ai.feedback.helpful'.tr,
                    icon: Icon(
                      message.feedback == true
                          ? Icons.thumb_up
                          : Icons.thumb_up_outlined,
                      size: 18,
                    ),
                    onPressed: () => onFeedback(true),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'ai.feedback.notHelpful'.tr,
                    icon: Icon(
                      message.feedback == false
                          ? Icons.thumb_down
                          : Icons.thumb_down_outlined,
                      size: 18,
                    ),
                    onPressed: () => onFeedback(false),
                  ),
                  Text(
                    formatRelative(DateTime.now()),
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
