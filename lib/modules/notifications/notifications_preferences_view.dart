import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_list.dart';
import '../../data/models/notification_preference.dart';
import 'notifications_preferences_controller.dart';

class NotificationsPreferencesView
    extends GetView<NotificationsPreferencesController> {
  const NotificationsPreferencesView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('notifications.preferences.title'.tr),
        actions: [
          Obx(
            () => TextButton(
              onPressed:
                  controller.saving.value ||
                      controller.loading.value ||
                      controller.items.isEmpty
                  ? null
                  : controller.save,
              child: controller.saving.value
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('common.save'.tr),
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.loading.value) return const LoadingList();
        if (controller.error.value != null) {
          return ErrorState(
            error: controller.error.value!,
            onRetry: controller.load,
          );
        }
        if (controller.items.isEmpty) {
          return EmptyState(
            icon: Icons.notifications_off_outlined,
            title: 'notifications.preferences.empty'.tr,
          );
        }
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            for (final NotificationPreference p in controller.items)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.type, style: theme.textTheme.titleSmall),
                      const SizedBox(height: AppSpacing.xs),
                      SwitchListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text('notifications.preferences.push'.tr),
                        value: p.push,
                        onChanged: (v) {
                          p.push = v;
                          controller.items.refresh();
                        },
                      ),
                      SwitchListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text('notifications.preferences.inapp'.tr),
                        value: p.inapp,
                        onChanged: (v) {
                          p.inapp = v;
                          controller.items.refresh();
                        },
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
}
