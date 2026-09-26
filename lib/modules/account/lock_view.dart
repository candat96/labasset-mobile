import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:get/get.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/app_buttons.dart';
import 'lock_controller.dart';

class LockView extends StatelessWidget {
  const LockView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<LockController>();
    WidgetsBinding.instance.addPostFrameCallback((_) => c.unlock());
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.lock,
                    size: 56,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'lock.title'.tr,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text('lock.desc'.tr, textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton.primary(
                    label: 'lock.unlock'.tr,
                    icon: LucideIcons.fingerprint,
                    onPressed: c.unlock,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton.soft(
                    label: 'lock.useLogin'.tr,
                    onPressed: c.signOut,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
