import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/format/format.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_list.dart';
import '../../core/widgets/segment_tabs.dart';
import '../../data/models/notification_item.dart';
import 'notification_presentation.dart';
import 'notifications_controller.dart';

class NotificationsView extends GetView<NotificationsController> {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Obx(() {
      final items = controller.items.toList(growable: false);
      return RefreshIndicator(
        onRefresh: controller.reload,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar.large(
              title: Text('notifications.title'.tr),
              actions: [
                AppIconButton(
                  icon: LucideIcons.slidersHorizontal,
                  tooltip: 'notifications.preferences.title'.tr,
                  onPressed: () => Get.toNamed(Routes.notificationsPreferences),
                ),
                const SizedBox(width: AppSpacing.sm),
                AppButton.soft(
                  tone: AppButtonTone.success,
                  label: 'notifications.markAll'.tr,
                  onPressed: controller.unreadCount.value == 0
                      ? null
                      : controller.markAllRead,
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xs,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              sliver: SliverToBoxAdapter(
                child: SegmentTabs<bool>(
                  tabs: [
                    SegmentTab(value: false, label: 'notifications.all'.tr),
                    SegmentTab(value: true, label: 'notifications.unread'.tr),
                  ],
                  selected: controller.onlyUnread.value,
                  onChanged: controller.toggleUnread,
                ),
              ),
            ),
            if (controller.loading.value && items.isEmpty)
              const SliverFillRemaining(
                child: LoadingList(rows: 6, height: 104),
              )
            else if (controller.error.value != null && items.isEmpty)
              SliverFillRemaining(
                child: ErrorState(
                  error: controller.error.value!,
                  onRetry: controller.reload,
                ),
              )
            else if (items.isEmpty)
              SliverFillRemaining(
                child: EmptyState(
                  icon: LucideIcons.bellOff,
                  title: 'notifications.empty'.tr,
                ),
              )
            else
              _NotificationSliver(items: items, controller: controller),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
          ],
        ),
      );
    }),
  );
}

class _NotificationSliver extends StatelessWidget {
  const _NotificationSliver({required this.items, required this.controller});

  final List<NotificationItem> items;
  final NotificationsController controller;

  @override
  Widget build(BuildContext context) {
    final entries = <Object>[];
    NotificationSection? previous;
    for (final item in items) {
      final section = notificationSection(item.createdAt);
      if (section != previous) {
        entries.add(section);
        previous = section;
      }
      entries.add(item);
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      sliver: SliverList.builder(
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final entry = entries[index];
          if (entry is NotificationSection) {
            return Padding(
              padding: EdgeInsets.only(
                top: index == 0 ? AppSpacing.xs : AppSpacing.xl,
                bottom: AppSpacing.sm,
              ),
              child: Text(
                notificationSectionLabel(entry),
                style: context.appText.section,
              ),
            );
          }
          final item = entry as NotificationItem;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _DismissibleNotification(
              item: item,
              onTap: () => controller.open(item),
              onDismissed: () => controller.dismissRead(item),
            ),
          );
        },
      ),
    );
  }
}

class _DismissibleNotification extends StatelessWidget {
  const _DismissibleNotification({
    required this.item,
    required this.onTap,
    required this.onDismissed,
  });

  final NotificationItem item;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  @override
  Widget build(BuildContext context) => Dismissible(
    key: ValueKey('notification-${item.id}'),
    direction: item.isRead
        ? DismissDirection.none
        : DismissDirection.endToStart,
    onDismissed: (_) => onDismissed(),
    background: const SizedBox.shrink(),
    secondaryBackground: Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: AppSpacing.xl),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Icon(
        LucideIcons.check,
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
    child: _NotificationCard(item: item, onTap: onTap),
  );
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item, required this.onTap});

  final NotificationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final unread = !item.isRead;
    return AppCard(
      onTap: onTap,
      accentColor: unread ? scheme.primary : null,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _NotificationIcon(type: item.type),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (unread) ...[
                      Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.only(top: 6),
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Expanded(
                      child: Text(
                        notificationTitle(item),
                        style: context.appText.bodyStrong.copyWith(
                          fontWeight: unread
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      formatRelative(item.createdAt),
                      style: context.appText.caption,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  notificationBody(item.body),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.appText.label,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationIcon extends StatelessWidget {
  const _NotificationIcon({required this.type});
  final String type;

  IconData get icon {
    if (type.startsWith('repair.')) return LucideIcons.wrench;
    if (type.startsWith('equipment.transfer.')) {
      return LucideIcons.arrowLeftRight;
    }
    if (type.startsWith('request.')) return LucideIcons.fileText;
    if (type.startsWith('stock.') || type.startsWith('stocktake.')) {
      return LucideIcons.package2;
    }
    if (type.startsWith('maintenance.') || type.startsWith('calibration.')) {
      return LucideIcons.calendarCheck;
    }
    return LucideIcons.bell;
  }

  @override
  Widget build(BuildContext context) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primaryContainer,
      shape: BoxShape.circle,
    ),
    child: Icon(
      icon,
      size: 20,
      color: Theme.of(context).colorScheme.onPrimaryContainer,
    ),
  );
}
