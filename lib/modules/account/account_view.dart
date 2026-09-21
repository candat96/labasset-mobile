import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/routes/app_routes.dart';
import '../../core/sync/outbox_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_list_tile.dart';
import '../../core/widgets/large_title_scaffold.dart';
import '../../core/widgets/section_card.dart';
import '../../data/models/user_view.dart';
import 'account_controller.dart';
import 'my_stats_controller.dart';

class AccountView extends GetView<AccountController> {
  const AccountView({super.key});

  @override
  Widget build(BuildContext context) {
    final store = controller.store;
    return LargeTitleScaffold(
      title: 'account.title'.tr,
      body: Obx(() {
        final user = store.user.value;
        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.xxl * 2,
          ),
          children: [
            if (user != null) _AccountCard(user: user),
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
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              padding: EdgeInsets.zero,
              onTap: controller.logout,
              child: SizedBox(
                height: 52,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.logOut,
                        size: 20,
                        color: context.status.danger,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'auth.logout'.tr,
                        style: context.appText.bodyStrong.copyWith(
                          color: context.status.danger,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

/// Khối tài khoản: avatar 64 chữ cái nền gradient, tên 20/700, chip vai trò,
/// hàng 3 số (việc xong / chờ / quá hạn) 20/800.
class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.user});

  final UserView user;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final stats = Get.find<MyStatsController>();
    final initial = user.fullName.isNotEmpty
        ? user.fullName.trim().split(' ').last.characters.first.toUpperCase()
        : '?';
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.tile),
            onTap: () => Get.toNamed(Routes.profile),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: context.brandGradient,
                    shape: BoxShape.circle,
                    boxShadow: context.isDark ? null : AppShadows.brand,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: context.appText.display.copyWith(
                      fontSize: 26,
                      color: AppColors.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.appText.title,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          for (final role in user.roles)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.primaryContainer,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.chip,
                                ),
                              ),
                              child: Text(
                                'auth.roles.$role'.tr,
                                style: context.appText.caption.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: scheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                        ],
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
          const SizedBox(height: AppSpacing.lg),
          Divider(height: 1, color: Theme.of(context).dividerColor),
          const SizedBox(height: AppSpacing.md),
          Obx(
            () => Row(
              children: [
                _Stat(
                  label: 'account.stats.completed'.tr,
                  value: '${stats.completed.value}',
                ),
                _Stat(
                  label: 'account.stats.maintenance'.tr,
                  value: '${stats.maintenanceDone.value}',
                ),
                _Stat(
                  label: 'account.stats.overdue'.tr,
                  value: '${stats.overdue.value}',
                  danger: stats.overdue.value > 0,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.danger = false});

  final String label;
  final String value;
  final bool danger;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          style: context.appText.kpi.copyWith(
            fontSize: 20,
            color: danger ? context.status.danger : null,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.appText.caption,
        ),
      ],
    ),
  );
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
