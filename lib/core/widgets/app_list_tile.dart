import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'icon_chip.dart';

/// Dòng danh sách: chip icon trái, tiêu đề 15/600, giá trị/badge/switch phải.
/// [accent] = chip 36 nền primary-soft (trang chủ); mặc định chip 32 nền muted.
class AppListTile extends StatelessWidget {
  const AppListTile({
    super.key,
    required this.icon,
    required this.title,
    this.value,
    this.trailing,
    this.onTap,
    this.switchValue,
    this.onSwitchChanged,
    this.showDivider = false,
    this.accent = false,
    this.height,
  });

  final IconData icon;
  final String title;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool? switchValue;
  final ValueChanged<bool>? onSwitchChanged;
  final bool showDivider;
  final bool accent;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chipSize = accent ? 36.0 : 32.0;
    return Column(
      children: [
        SizedBox(
          height: height ?? (accent ? 56 : 52),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.tile),
            child: Row(
              children: [
                IconChip(
                  icon: icon,
                  size: chipSize,
                  iconSize: accent ? 20 : 18,
                  radius: accent ? 12 : 10,
                  background: accent
                      ? null
                      : theme.colorScheme.surfaceContainerHighest,
                  foreground: accent
                      ? null
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.appText.bodyStrong,
                  ),
                ),
                if (value != null)
                  Text(value!, style: context.appText.label)
                else if (trailing != null)
                  trailing!
                else if (switchValue != null)
                  Switch.adaptive(
                    value: switchValue!,
                    onChanged: onSwitchChanged,
                  ),
                if (onTap != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    LucideIcons.chevronRight,
                    size: 18,
                    color: context.appText.caption.color,
                  ),
                ],
              ],
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: EdgeInsets.only(left: chipSize + AppSpacing.md),
            child: Divider(height: 1, color: theme.dividerColor),
          ),
      ],
    );
  }
}
