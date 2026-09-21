import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'app_card.dart';

/// Card có tiêu đề section (13/700 viết hoa) + hàng nút hành động.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    this.title,
    this.trailing,
    this.actions = const [],
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    required this.child,
  });

  final String? title;
  final Widget? trailing;
  final List<Widget> actions;
  final EdgeInsetsGeometry padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null || trailing != null || actions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Row(
                children: [
                  if (title != null) Expanded(child: SectionTitle(title!)),
                  ...[trailing].whereType<Widget>(),
                  ...actions,
                ],
              ),
            ),
          child,
        ],
      ),
    );
  }
}

/// Tiêu đề khối dùng ngoài card (trên nền màn): viết hoa, 13/700, muted.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final title = Text(
      text.toUpperCase(),
      style: context.appText.section,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    if (trailing == null) return title;
    return Row(
      children: [
        Expanded(child: title),
        trailing!,
      ],
    );
  }
}
