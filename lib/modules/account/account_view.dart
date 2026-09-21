import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/routes/app_routes.dart';
import '../../core/sync/outbox_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/app_list_tile.dart';
import '../../core/widgets/section_card.dart';
import 'account_controller.dart';
import 'my_stats_controller.dart';

class AccountView extends GetView<AccountController> {
  const AccountView({super.key});

  @override
  Widget build(BuildContext context) {
    final store = controller.store;
    return Scaffold(
      appBar: AppBar(title: Text('account.title'.tr)),
      body: Obx(() {
        final user = store.user.value;
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            if (user != null)
              Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  onTap: () => Get.toNamed(Routes.profile),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primaryContainer,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                          child: Text(
                            user.fullName.isNotEmpty
                                ? user.fullName.characters.first
                                : '?',
                            style: context.appText.bodyStrong,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.fullName,
                                style: context.appText.bodyStrong,
                              ),
                              Text(
                                user.roles
                                    .map((role) => 'auth.roles.$role'.tr)
                                    .join(' · '),
                                style: context.appText.caption,
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          LucideIcons.chevronRight,
                          size: 18,
                          color: context.appText.caption.color,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            const _MyStatsCard(),
            const SizedBox(height: AppSpacing.md),
            SectionCard(
              title: 'account.security'.tr,
              child: Column(
                children: [
                  AppListTile(
                    icon: LucideIcons.keyRound,
                    title: 'account.changePassword'.tr,
                    onTap: () => Get.toNamed(Routes.changePassword),
                    showDivider: true,
                  ),
                  AppListTile(
                    icon: LucideIcons.monitorSmartphone,
                    title: 'account.sessions'.tr,
                    onTap: () => Get.toNamed(Routes.sessions),
                    showDivider: true,
                  ),
                  AppListTile(
                    icon: LucideIcons.fingerprint,
                    title: 'account.biometric'.tr,
                    switchValue: store.biometricEnabled.value,
                    onSwitchChanged: controller.biometricSupported.value
                        ? controller.setBiometric
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SectionCard(
              title: 'account.data'.tr,
              child: Column(
                children: [
                  AppListTile(
                    icon: LucideIcons.cloudSync,
                    title: 'account.sync'.tr,
                    trailing: Obx(() {
                      final pending = Get.find<OutboxService>().pending.value;
                      return pending == 0
                          ? const SizedBox.shrink()
                          : Text('$pending', style: context.appText.label);
                    }),
                    onTap: () => Get.toNamed(Routes.sync),
                    showDivider: true,
                  ),
                  AppListTile(
                    icon: LucideIcons.hardDrive,
                    title: 'offline.title'.tr,
                    onTap: () => Get.toNamed(Routes.offlineData),
                    showDivider: true,
                  ),
                  AppListTile(
                    icon: LucideIcons.chartPie,
                    title: 'reports.title'.tr,
                    onTap: () => Get.toNamed(Routes.reports),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SectionCard(
              title: 'account.options'.tr,
              child: Column(
                children: [
                  AppListTile(
                    icon: LucideIcons.bell,
                    title: 'account.notifications'.tr,
                    onTap: () => Get.toNamed(Routes.notificationsPreferences),
                    showDivider: true,
                  ),
                  AppListTile(
                    icon: LucideIcons.type,
                    title: 'account.textScale'.tr,
                    switchValue: store.textScale.value > 1.05,
                    onSwitchChanged: controller.setTextScale,
                    showDivider: true,
                  ),
                  AppListTile(
                    icon: LucideIcons.sunMoon,
                    title: 'account.theme'.tr,
                    value: 'account.theme.${store.themeMode.value.name}'.tr,
                    onTap: () => _pickTheme(controller),
                    showDivider: true,
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                      onPressed: controller.logout,
                      icon: const Icon(LucideIcons.logOut, size: 20),
                      label: Text('auth.logout'.tr),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl * 2),
          ],
        );
      }),
    );
  }
}

Future<void> _pickTheme(AccountController controller) async {
  await Get.bottomSheet<void>(
    SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: RadioGroup<ThemeMode>(
          groupValue: controller.store.themeMode.value,
          onChanged: (value) async {
            if (value == null) return;
            await controller.setTheme(value);
            Get.back();
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final mode in ThemeMode.values)
                RadioListTile<ThemeMode>(
                  value: mode,
                  title: Text('account.theme.${mode.name}'.tr),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _MyStatsCard extends StatelessWidget {
  const _MyStatsCard();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MyStatsController>();
    return SectionCard(
      title: 'account.myStats'.tr,
      child: Obx(
        () => Row(
          children: [
            _stat(
              context,
              'account.stats.completed'.tr,
              '${controller.completed.value}',
            ),
            _stat(
              context,
              'account.stats.overdue'.tr,
              '${controller.overdue.value}',
            ),
            _stat(
              context,
              'account.stats.maintenance'.tr,
              '${controller.maintenanceDone.value}',
            ),
            _stat(
              context,
              'account.stats.rating'.tr,
              controller.avgRating.value?.toStringAsFixed(1) ?? '—',
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(BuildContext context, String label, String value) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          style: context.appText.kpi.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: context.appText.caption,
        ),
      ],
    ),
  );
}
