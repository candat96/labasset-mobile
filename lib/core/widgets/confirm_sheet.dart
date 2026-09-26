import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'app_buttons.dart';
import 'app_sheet.dart';

/// Bottom sheet xác nhận; trả true khi đồng ý. Mở bằng context của widget gọi.
class ConfirmSheet {
  ConfirmSheet._();

  static Future<bool> show(
    BuildContext context, {
    required String title,
    String? description,
    String? confirmLabel,
    bool destructive = false,
  }) async {
    final result = await AppSheet.show<bool>(
      context,
      builder: (ctx) => ConfirmSheetBody(
        title: title,
        description: description,
        confirmLabel: confirmLabel,
        destructive: destructive,
      ),
    );
    return result ?? false;
  }
}

/// Nội dung sheet xác nhận (tách để test và dùng lại).
class ConfirmSheetBody extends StatelessWidget {
  const ConfirmSheetBody({
    super.key,
    required this.title,
    this.description,
    this.confirmLabel,
    this.destructive = false,
  });

  final String title;
  final String? description;
  final String? confirmLabel;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final text = context.appText;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          if (description != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(description!, style: text.label),
          ],
          const SizedBox(height: AppSpacing.lg),
          destructive
              ? AppButton.danger(
                  label: confirmLabel ?? 'common.confirm'.tr,
                  onPressed: () => AppSheet.close(context, true),
                )
              : AppButton.primary(
                  label: confirmLabel ?? 'common.confirm'.tr,
                  onPressed: () => AppSheet.close(context, true),
                ),
          const SizedBox(height: AppSpacing.sm),
          AppButton.soft(
            label: 'common.cancel'.tr,
            tone: AppButtonTone.neutral,
            onPressed: () => AppSheet.close(context, false),
          ),
        ],
      ),
    );
  }
}
