import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'icon_chip.dart';

/// Lối tắt đặt trực tiếp trên nền: chip icon 48 bo 14 + nhãn 12/600 hai dòng.
class ShortcutTile extends StatelessWidget {
  const ShortcutTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.accent,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Cặp màu chip icon (mặc định primary-soft).
  final AppAccent? accent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final a = accent;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.card),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
          horizontal: AppSpacing.xs,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            IconChip(
              icon: icon,
              size: 48,
              iconSize: 22,
              radius: 14,
              background: a?.backgroundFor(context),
              foreground: a?.foregroundFor(context),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: context.appText.caption.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.25,
                color: colors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
