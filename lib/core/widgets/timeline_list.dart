import 'package:flutter/material.dart';

import '../format/format.dart';
import '../theme/tokens.dart';

/// Một mốc trong [TimelineList].
class TimelineEntry {
  const TimelineEntry({
    required this.title,
    this.at,
    this.summary,
    this.by,
    this.icon = Icons.circle_outlined,
    this.color,
  });

  final String title;
  final Object? at;
  final String? summary;
  final String? by;
  final IconData icon;

  /// Màu dot theo trạng thái; null = primary.
  final Color? color;
}

/// Dòng thời gian sự kiện (máy, phiếu…): chấm + đường nối, thời gian tương đối.
class TimelineList extends StatelessWidget {
  const TimelineList({
    super.key,
    required this.items,
    this.showRelative = true,
  });

  final List<TimelineEntry> items;
  final bool showRelative;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < items.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 28,
                  child: Column(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: (items[i].color ?? theme.colorScheme.primary)
                              .withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          items[i].icon,
                          size: 13,
                          color: items[i].color ?? theme.colorScheme.primary,
                        ),
                      ),
                      if (i != items.length - 1)
                        Expanded(
                          child: Container(
                            width: 2,
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            color: theme.brightness == Brightness.dark
                                ? AppColors.dividerDark
                                : AppColors.timelineLine,
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: AppSpacing.sm,
                      bottom: AppSpacing.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          items[i].title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (items[i].summary != null &&
                            items[i].summary!.isNotEmpty)
                          Text(
                            items[i].summary!,
                            style: theme.textTheme.bodySmall,
                          ),
                        if (items[i].at != null)
                          Text(
                            [
                              formatDateTime(items[i].at),
                              if (showRelative) formatRelative(items[i].at),
                            ].join(' · '),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        if (items[i].by != null)
                          Text(
                            items[i].by!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
