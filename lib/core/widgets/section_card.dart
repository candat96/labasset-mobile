import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Card có tiêu đề + hàng nút hành động, dùng thống nhất ở các màn chi tiết.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    this.title,
    this.actions = const [],
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    required this.child,
  });

  final String? title;
  final List<Widget> actions;
  final EdgeInsetsGeometry padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null || actions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    if (title != null)
                      Expanded(
                        child: Text(title!, style: theme.textTheme.titleSmall),
                      ),
                    ...actions,
                  ],
                ),
              ),
            child,
          ],
        ),
      ),
    );
  }
}
