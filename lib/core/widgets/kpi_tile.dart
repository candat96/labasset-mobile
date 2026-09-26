import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'icon_chip.dart';
import 'status_badge.dart';

/// Thẻ cảnh báo nhỏ 140×96 cuộn ngang: chip icon + số 24/800 cùng hàng,
/// nhãn 12 tối đa hai dòng (không cắt "…"). Số 0 → neutral.
class KpiTile extends StatelessWidget {
  const KpiTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.tone = StatusTone.info,
    this.onTap,
    this.width = 140,
    this.accent,
    this.height = 96,
  });

  final String label;
  final String value;
  final IconData? icon;
  final StatusTone tone;
  final VoidCallback? onTap;
  final double width;

  /// Màu riêng cho chip icon (luôn hiển thị, kể cả khi 0) — trang chủ.
  final AppAccent? accent;
  final double height;

  @override
  Widget build(BuildContext context) {
    final zero = value.trim() == '0';
    final effectiveTone = zero ? StatusTone.muted : tone;
    final palette = paletteForTone(context, effectiveTone);
    final scheme = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(AppRadius.card);
    final chipBg =
        accent?.backgroundFor(context) ??
        (zero ? null : palette.color.withValues(alpha: 0.14));
    final chipFg = accent?.foregroundFor(context);
    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: zero ? scheme.surface : palette.background,
          borderRadius: borderRadius,
          border: Border.all(
            color: zero
                ? context.cardBorder
                : palette.color.withValues(alpha: 0.14),
          ),
          boxShadow: context.cardShadow,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: borderRadius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            borderRadius: borderRadius,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (icon != null)
                        IconChip(
                          icon: icon!,
                          size: 32,
                          iconSize: 18,
                          radius: AppRadius.card,
                          tone: effectiveTone,
                          background: chipBg,
                          foreground: chipFg,
                        ),
                      const Spacer(),
                      // Thu nhỏ khi giá trị dài (tiền rút gọn) — không tràn.
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            value,
                            style: context.appText.kpi.copyWith(
                              fontSize: 24,
                              color: zero
                                  ? scheme.onSurface
                                  : palette.foreground,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    label,
                    maxLines: 2,
                    style: context.appText.caption.copyWith(
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                      color: zero
                          ? scheme.onSurfaceVariant
                          : palette.foreground,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
