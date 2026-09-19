import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/routes/app_routes.dart';
import '../../core/sync/outbox_service.dart';
import '../../core/theme/tokens.dart';
import 'account_controller.dart';

class AccountView extends GetView<AccountController> {
  const AccountView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = controller.store;
    return Scaffold(
      appBar: AppBar(title: Text('account.title'.tr)),
      body: Obx(() {
        final u = store.user.value;
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            if (u != null)
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    child: Text(
                      u.fullName.isNotEmpty ? u.fullName.characters.first : '?',
                    ),
                  ),
                  title: Text(u.fullName),
                  subtitle: Text(
                    u.roles.map((r) => 'auth.roles.$r'.tr).join(', '),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Get.toNamed(Routes.profile),
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.key_outlined),
                    title: Text('account.changePassword'.tr),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Get.toNamed(Routes.changePassword),
                  ),
                  ListTile(
                    leading: const Icon(Icons.devices_outlined),
                    title: Text('account.sessions'.tr),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Get.toNamed(Routes.sessions),
                  ),
                  ListTile(
                    leading: const Icon(Icons.cloud_sync_outlined),
                    title: Text('account.sync'.tr),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Obx(() {
                          final outbox = Get.find<OutboxService>();
                          final n = outbox.pending.value;
                          if (n == 0) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(
                              right: AppSpacing.xs,
                            ),
                            child: Chip(
                              visualDensity: VisualDensity.compact,
                              label: Text('$n'),
                            ),
                          );
                        }),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: () => Get.toNamed(Routes.sync),
                  ),
                  ListTile(
                    leading: const Icon(Icons.notifications_outlined),
                    title: Text('account.notifications'.tr),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Get.toNamed(Routes.notificationsPreferences),
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.fingerprint),
                    title: Text('account.biometric'.tr),
                    subtitle: controller.biometricSupported.value
                        ? null
                        : Text('account.biometricUnavailable'.tr),
                    value: store.biometricEnabled.value,
                    onChanged: controller.biometricSupported.value
                        ? controller.setBiometric
                        : null,
                  ),
                  ListTile(
                    leading: const Icon(Icons.brightness_6_outlined),
                    title: Text('account.theme'.tr),
                    trailing: DropdownButton<ThemeMode>(
                      value: store.themeMode.value,
                      underline: const SizedBox.shrink(),
                      onChanged: (m) =>
                          m == null ? null : controller.setTheme(m),
                      items: [
                        for (final m in ThemeMode.values)
                          DropdownMenuItem(
                            value: m,
                            child: Text('account.theme.${m.name}'.tr),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
              onPressed: controller.logout,
              icon: const Icon(Icons.logout),
              label: Text('auth.logout'.tr),
            ),
            const SizedBox(height: AppSpacing.xxl * 2),
          ],
        );
      }),
    );
  }
}
