import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/tokens.dart';

/// Bottom sheet xác nhận; trả true khi đồng ý.
class ConfirmSheet {
  ConfirmSheet._();

  static Future<bool> show({
    required String title,
    String? description,
    String? confirmLabel,
    bool destructive = false,
  }) async {
    final result = await Get.bottomSheet<bool>(
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: Get.textTheme.titleMedium),
              if (description != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(description, style: Get.textTheme.bodySmall),
              ],
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                style: destructive
                    ? FilledButton.styleFrom(
                        backgroundColor: Get.theme.colorScheme.error,
                      )
                    : null,
                onPressed: () => Get.back(result: true),
                child: Text(confirmLabel ?? 'common.confirm'.tr),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                onPressed: () => Get.back(result: false),
                child: Text('common.cancel'.tr),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Get.theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg * 2),
        ),
      ),
    );
    return result ?? false;
  }
}
