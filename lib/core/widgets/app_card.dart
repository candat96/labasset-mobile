import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// Bề mặt card chuẩn: nền card, bo 16, viền 1px mờ + bóng nhẹ (light) hoặc
/// viền (dark). Dùng thay `Card` khi cần bóng hai lớp hoặc thanh màu trái.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    this.accentColor,
    this.floating = false,
    this.color,
    this.radius = AppRadius.card,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  /// Thanh màu 4px bo ở cạnh trái (mức khẩn/trạng thái).
  final Color? accentColor;

  /// Bóng đậm hơn cho card nổi đè hero.
  final bool floating;
  final Color? color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderRadius = BorderRadius.circular(radius);
    Widget body = Padding(padding: padding, child: child);
    if (accentColor != null) {
      body = IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(4),
                  ),
                ),
              ),
            ),
            Expanded(child: body),
          ],
        ),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? theme.colorScheme.surface,
        borderRadius: borderRadius,
        border: Border.all(color: context.cardBorder),
        boxShadow: context.isDark
            ? null
            : floating
            ? AppShadows.floating
            : AppShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: onTap == null
            ? body
            : InkWell(onTap: onTap, borderRadius: borderRadius, child: body),
      ),
    );
  }
}
