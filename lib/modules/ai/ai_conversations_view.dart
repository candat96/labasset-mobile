import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/ai/ai_models.dart';
import '../../core/format/format.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/confirm_sheet.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/icon_chip.dart';
import '../../core/widgets/large_title_scaffold.dart';
import '../../core/widgets/list_item_card.dart';
import '../../core/widgets/loading_list.dart';
import 'ai_conversations_controller.dart';

/// Danh sách hội thoại Trợ lý AI `/ai/conversations`.
class AiConversationsView extends GetView<AiConversationsController> {
  const AiConversationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return LargeTitleScaffold(
      title: 'ai.title'.tr,
      floatingActionButton: GradientFab(
        label: 'ai.new'.tr,
        icon: LucideIcons.plus,
        onPressed: () async {
          await controller.create();
          await controller.load();
        },
      ),
      body: Obx(() {
        if (controller.loading.value && controller.items.isEmpty) {
          return const LoadingList();
        }
        if (controller.error.value != null && controller.items.isEmpty) {
          return ErrorState(
            error: controller.error.value!,
            onRetry: controller.load,
          );
        }
        if (controller.items.isEmpty) {
          return EmptyState(
            icon: LucideIcons.sparkles,
            title: 'ai.conversations.empty'.tr,
            action: AppButton.primary(
              label: 'ai.new'.tr,
              icon: LucideIcons.plus,
              onPressed: () async {
                await controller.create();
                await controller.load();
              },
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: controller.load,
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n.metrics.extentAfter < 400) {
                unawaited(controller.loadMore());
              }
              return false;
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.xxl * 3,
              ),
              itemCount: controller.items.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (_, i) {
                final c = controller.items[i];
                return Dismissible(
                  key: ValueKey(c.id),
                  direction: DismissDirection.endToStart,
                  background: _deleteBackground(context),
                  confirmDismiss: (_) => ConfirmSheet.show(
                    context,
                    title: 'ai.conversations.delete'.tr,
                    description: c.title,
                    confirmLabel: 'common.delete'.tr,
                    destructive: true,
                  ),
                  onDismissed: (_) => controller.delete(c),
                  child: _ConversationCard(
                    conversation: c,
                    equipmentLabel: c.equipmentId == null
                        ? null
                        : controller.equipmentLabels[c.equipmentId],
                    onTap: () async {
                      await Get.toNamed(Routes.aiChat(c.id));
                      await controller.load();
                    },
                  ),
                );
              },
            ),
          ),
        );
      }),
    );
  }
}

Widget _deleteBackground(BuildContext context) => Container(
  alignment: Alignment.centerRight,
  padding: const EdgeInsets.only(right: AppSpacing.lg),
  decoration: BoxDecoration(
    color: context.status.dangerBackground,
    borderRadius: BorderRadius.circular(AppRadius.card),
  ),
  child: Icon(LucideIcons.trash2, color: context.status.danger),
);

class _ConversationCard extends StatelessWidget {
  const _ConversationCard({
    required this.conversation,
    required this.equipmentLabel,
    required this.onTap,
  });

  final AiConversation conversation;
  final String? equipmentLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final time = conversation.updatedAt ?? conversation.createdAt;
    return ListItemCard(
      leading: const IconChip(icon: LucideIcons.sparkles),
      title: conversation.title.isEmpty
          ? 'ai.conversations.untitled'.tr
          : conversation.title,
      metas: [
        if (time != null) ListMeta(LucideIcons.clock3, formatRelative(time)),
        if (equipmentLabel != null)
          ListMeta(LucideIcons.monitorCog, equipmentLabel!),
      ],
      onTap: onTap,
    );
  }
}
