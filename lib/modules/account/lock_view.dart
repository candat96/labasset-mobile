import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/tokens.dart';
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
                    Icons.lock_outline,
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
                  FilledButton.icon(
                    onPressed: c.unlock,
                    icon: const Icon(Icons.fingerprint),
                    label: Text('lock.unlock'.tr),
                  ),
                  TextButton(
                    onPressed: c.signOut,
                    child: Text('lock.useLogin'.tr),
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
