import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// Nhãn **trên** ô nhập (14/20, màu chữ chính) + dấu `*` cho trường bắt buộc.
/// Theo §Chuẩn thành phần → Ô nhập.
class FieldLabel extends StatelessWidget {
  const FieldLabel({super.key, required this.label, this.required = false});

  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Text.rich(
      TextSpan(
        children: [
          TextSpan(text: label),
          if (required)
            TextSpan(
              text: ' *',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
      style: context.appText.body.copyWith(
        fontSize: 14,
        height: 20 / 14,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    ),
  );
}

/// Decoration chuẩn cho ô nhập trong app: nền `--muted`, **không viền**, bo 12,
/// cao 44, chữ 14/20; focus vòng sáng 2px, lỗi viền 1px `--destructive`.
InputDecoration appFieldDecoration(
  BuildContext context, {
  String? hintText,
  String? errorText,
  Widget? suffix,
  String? suffixText,
  Widget? suffixIcon,
}) {
  final scheme = Theme.of(context).colorScheme;
  final radius = BorderRadius.circular(AppRadius.card);

  OutlineInputBorder line(Color color, double width) => OutlineInputBorder(
    borderRadius: radius,
    borderSide: width == 0
        ? BorderSide.none
        : BorderSide(color: color, width: width),
  );

  return InputDecoration(
    isDense: true,
    filled: true,
    fillColor: context.isDark ? AppColors.mutedDark : AppColors.muted,
    hintText: hintText,
    hintStyle: context.appText.label.copyWith(fontSize: 14),
    errorText: errorText,
    errorStyle: TextStyle(color: scheme.error, fontSize: 12, height: 16 / 12),
    suffix: suffix,
    suffixText: suffixText,
    suffixIcon: suffixIcon,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11.5),
    border: line(scheme.primary, 0),
    enabledBorder: line(scheme.primary, 0),
    focusedBorder: line(scheme.primary.withValues(alpha: 0.2), 2),
    errorBorder: line(scheme.error, 1),
    focusedErrorBorder: line(scheme.error, 1),
  );
}
