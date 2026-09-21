import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

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
  });

  final IconData icon;
  final String title;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool? switchValue;
  final ValueChanged<bool>? onSwitchChanged;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        SizedBox(
          height: 52,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.tile),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: Text(title, style: context.appText.body)),
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
                  const SizedBox(width: AppSpacing.xs),
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
            padding: const EdgeInsets.only(left: 56),
            child: Divider(height: 1, color: theme.dividerColor),
          ),
      ],
    );
  }
}
