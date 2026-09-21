import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'app_card.dart';

/// Một dòng meta nhỏ (icon 14 + chữ 13) dưới tiêu đề card danh sách.
class ListMeta {
  const ListMeta(this.icon, this.text, {this.color});
  final IconData icon;
  final String text;
  final Color? color;
}

/// Card mục danh sách: mã + badge phải, tiêu đề 16/700, 2–3 meta có icon,
/// thanh màu trái 4px theo [accentColor], chevron mờ; padding 14, bo 16.
class ListItemCard extends StatelessWidget {
  const ListItemCard({
    super.key,
    required this.title,
    this.code,
    this.badge,
    this.metas = const [],
    this.accentColor,
    this.leading,
    this.footer,
    this.onTap,
    this.showChevron = true,
  });

  final String title;
  final String? code;
  final Widget? badge;
  final List<ListMeta> metas;
  final Color? accentColor;
  final Widget? leading;

  /// Nội dung thêm dưới meta (thanh tiến độ, nút…).
  final Widget? footer;
  final VoidCallback? onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final text = context.appText;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (code != null || badge != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    code ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: text.label.color,
                    ),
                  ),
                ),
                ?badge,
              ],
            ),
          ),
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: text.bodyStrong.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (metas.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              for (final m in metas)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(m.icon, size: 14, color: m.color ?? text.label.color),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        m.text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.label.copyWith(color: m.color),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
        if (footer != null) ...[const SizedBox(height: AppSpacing.md), footer!],
      ],
    );
    return AppCard(
      onTap: onTap,
      accentColor: accentColor,
      padding: EdgeInsets.fromLTRB(
        accentColor == null ? 14 : 10,
        14,
        showChevron && onTap != null ? 8 : 14,
        14,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(child: content),
          if (showChevron && onTap != null)
            Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: text.caption.color?.withValues(alpha: 0.7),
            ),
        ],
      ),
    );
  }
}
