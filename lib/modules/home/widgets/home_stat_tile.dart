import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/icon_chip.dart';

/// Ô chỉ số kiểu Figma trên trang chủ: biểu tượng tròn nền màu (theo [accent]
/// lấy từ token), số lớn 24/600, nhãn 14/500 bên dưới. Bấm ô mở danh sách đã lọc.
class HomeStatTile extends StatelessWidget {
  const HomeStatTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.accent,
    this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;

  /// Cặp màu nền/tiền cảnh của biểu tượng tròn (token trong `tokens.dart`).
  final AppAccent accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(AppRadius.card);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: radius,
        border: Border.all(color: context.cardBorder),
        boxShadow: context.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconChip(
                  icon: icon,
                  size: 40,
                  iconSize: 20,
                  circle: true,
                  background: accent.backgroundFor(context),
                  foreground: accent.foregroundFor(context),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  value,
                  maxLines: 1,
                  style: context.appText.kpi.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.appText.body.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
