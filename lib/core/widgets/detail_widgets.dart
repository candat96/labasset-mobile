import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'app_buttons.dart';
import 'app_card.dart';
import 'icon_chip.dart';

/// Số liệu nhỏ dạng chip trong header chi tiết.
class DetailStat {
  const DetailStat(this.label, this.value, {this.icon, this.color});
  final String label;
  final String value;
  final IconData? icon;
  final Color? color;
}

/// Header card màn chi tiết: chip icon 48, tên 20/700, mã + badge, dòng phụ,
/// 2–3 số liệu nhỏ dạng chip.
class DetailHeaderCard extends StatelessWidget {
  const DetailHeaderCard({
    super.key,
    required this.icon,
    required this.title,
    this.code,
    this.badges = const [],
    this.subtitle,
    this.stats = const [],
    this.onTitleTap,
    this.extra,
    this.margin = const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.md,
      AppSpacing.lg,
      AppSpacing.md,
    ),
  });

  final IconData icon;
  final String title;
  final String? code;
  final List<Widget> badges;
  final String? subtitle;
  final List<DetailStat> stats;
  final VoidCallback? onTitleTap;
  final Widget? extra;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.appText;
    return Padding(
      padding: margin,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconChip(icon: icon, size: 48, iconSize: 24, radius: 14),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: onTitleTap,
                        child: Text(
                          title,
                          style: text.title.copyWith(
                            color: onTitleTap == null ? null : scheme.primary,
                          ),
                        ),
                      ),
                      if (code != null || badges.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.xs,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (code != null)
                              Text(
                                code!,
                                style: text.label.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ...badges,
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(subtitle!, style: text.label),
            ],
            if (stats.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [for (final s in stats) _StatChip(stat: s)],
              ),
            ],
            if (extra != null) ...[
              const SizedBox(height: AppSpacing.sm),
              extra!,
            ],
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.stat});
  final DetailStat stat;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.appText;
    final color = stat.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color?.withValues(alpha: 0.1) ?? scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.tile),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (stat.icon != null) ...[
            Icon(stat.icon, size: 14, color: color ?? text.label.color),
            const SizedBox(width: 4),
          ],
          if (stat.label.isNotEmpty)
            Text(
              '${stat.label}: ',
              style: text.caption.copyWith(color: color ?? text.label.color),
            ),
          Text(
            stat.value,
            style: text.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: color ?? scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

/// TabBar kiểu pill cuộn ngang (thay underline) — dùng làm `AppBar.bottom`
/// hoặc đặt trong body.
class PillTabBar extends StatelessWidget implements PreferredSizeWidget {
  const PillTabBar({super.key, required this.tabs, this.controller});

  final List<String> tabs;
  final TabController? controller;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Container(
        height: 40,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: context.isDark ? AppColors.segmentDark : AppColors.segment,
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
        child: TabBar(
          controller: controller,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          padding: EdgeInsets.zero,
          indicatorPadding: EdgeInsets.zero,
          tabs: [for (final t in tabs) Tab(text: t, height: 34)],
        ),
      ),
    );
  }
}

/// Hàng thông tin 2 cột: nhãn 13/500 muted / giá trị 15/600, divider mờ.
class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.showDivider = true,
  });

  final String label;
  final String? value;
  final Color? valueColor;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final text = context.appText;
    if (value == null || value!.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 128, child: Text(label, style: text.label)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  value!,
                  style: text.bodyStrong.copyWith(color: valueColor),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1, color: Theme.of(context).dividerColor),
      ],
    );
  }
}

/// Thanh hành động dính đáy: nút chính gradient full-width + nút phụ outline.
class StickyActionBar extends StatelessWidget {
  const StickyActionBar({
    super.key,
    this.primary,
    this.secondary = const [],
    this.child,
  });

  /// Nút chính (thường là [GradientButton]).
  final Widget? primary;

  /// Nút phụ đặt cạnh nút chính (mỗi nút chiếm phần bằng nhau).
  final List<Widget> secondary;

  /// Nội dung tuỳ ý thay cho primary/secondary.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        boxShadow: context.isDark ? null : AppShadows.navUp,
        border: context.isDark
            ? Border(top: BorderSide(color: context.cardBorder))
            : null,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child:
              child ??
              Row(
                children: [
                  for (final s in secondary) ...[
                    Expanded(child: s),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  if (primary != null)
                    Expanded(flex: secondary.isEmpty ? 1 : 2, child: primary!),
                ],
              ),
        ),
      ),
    );
  }
}

/// Nút phụ outline cao 52 dùng trong [StickyActionBar].
class StickySecondaryButton extends StatelessWidget {
  const StickySecondaryButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.danger = false,
  });
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? context.status.danger : null;
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color ?? Theme.of(context).colorScheme.outline),
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 6)],
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
