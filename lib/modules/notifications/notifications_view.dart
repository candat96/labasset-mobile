import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/format/format.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_list.dart';
import 'notifications_controller.dart';

class NotificationsView extends GetView<NotificationsController> {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('notifications.title'.tr),
        actions: [
          IconButton(
            tooltip: 'notifications.preferences.title'.tr,
            icon: const Icon(Icons.tune),
            onPressed: () => Get.toNamed(Routes.notificationsPreferences),
          ),
          Obx(
            () => TextButton(
              onPressed: controller.unreadCount.value == 0
                  ? null
                  : controller.markAllRead,
              child: Text('notifications.markAll'.tr),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Obx(
            () => SwitchListTile(
              dense: true,
              title: Text('notifications.unread'.tr),
              value: controller.onlyUnread.value,
              onChanged: controller.toggleUnread,
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Obx(() {
              if (controller.loading.value && controller.items.isEmpty) {
                return const LoadingList();
              }
              if (controller.error.value != null && controller.items.isEmpty) {
                return ErrorState(
                  error: controller.error.value!,
                  onRetry: controller.reload,
                );
              }
              if (controller.items.isEmpty) {
                return EmptyState(
                  icon: Icons.notifications_none,
                  title: 'notifications.empty'.tr,
                );
              }
              return RefreshIndicator(
                onRefresh: controller.reload,
                child: ListView.separated(
                  itemCount: controller.items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final n = controller.items[i];
                    return ListTile(
                      tileColor: n.isRead
                          ? null
                          : theme.colorScheme.primary.withValues(alpha: 0.05),
                      leading: Icon(
                        n.isRead
                            ? Icons.notifications_none
                            : Icons.notifications_active_outlined,
                        color: n.isRead
                            ? theme.colorScheme.onSurfaceVariant
                            : theme.colorScheme.primary,
                      ),
                      title: Text(
                        n.title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: n.isRead
                              ? FontWeight.w400
                              : FontWeight.w600,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              n.body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              formatRelative(n.createdAt),
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      onTap: () => controller.open(n),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
