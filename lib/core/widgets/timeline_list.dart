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
  });

  final String title;
  final Object? at;
  final String? summary;
  final String? by;
  final IconData icon;
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
                      Icon(
                        items[i].icon,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      if (i != items.length - 1)
                        Expanded(
                          child: Container(
                            width: 2,
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            color: theme.colorScheme.outlineVariant,
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
