import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'status_badge.dart';

/// Thẻ số liệu cho trang chủ/thống kê: nhãn, giá trị, icon, tone màu.
class KpiTile extends StatelessWidget {
  const KpiTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.tone = StatusTone.info,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData? icon;
  final StatusTone tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = context.status;
    final color = switch (tone) {
      StatusTone.success => s.success,
      StatusTone.warning => s.warning,
      StatusTone.danger => s.danger,
      StatusTone.info => s.info,
      StatusTone.muted => s.muted,
    };
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: color),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
