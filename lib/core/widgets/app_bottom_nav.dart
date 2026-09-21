import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// Một mục của [AppBottomNav].
class AppNavItem {
  const AppNavItem({required this.icon, required this.label, this.badge});
  final IconData icon;
  final String label;

  /// Widget đếm (badge) đặt góc phải trên icon.
  final Widget? badge;
}

/// Bottom nav 5 mục nền card bóng hắt lên: mục active icon + nhãn primary +
/// pill 20×4; mục giữa = nút Quét tròn 56 gradient nổi lên 12px.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    required this.centerIcon,
    required this.centerLabel,
    required this.onCenterTap,
  });

  /// Bốn mục thường (2 trái, 2 phải).
  final List<AppNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final IconData centerIcon;
  final String centerLabel;
  final VoidCallback onCenterTap;

  @override
  Widget build(BuildContext context) {
    assert(items.length == 4, 'AppBottomNav cần đúng 4 mục + nút giữa');
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
        child: SizedBox(
          height: 64,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < 2; i++)
                Expanded(
                  child: _NavButton(
                    item: items[i],
                    selected: selectedIndex == i,
                    onTap: () => onSelected(i),
                  ),
                ),
              Expanded(
                child: _CenterButton(
                  icon: centerIcon,
                  label: centerLabel,
                  onTap: onCenterTap,
                ),
              ),
              for (var i = 2; i < 4; i++)
                Expanded(
                  child: _NavButton(
                    item: items[i],
                    selected: selectedIndex == i,
                    onTap: () => onSelected(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });
  final AppNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.primary : scheme.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: InkResponse(
        onTap: onTap,
        radius: 36,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 6),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(item.icon, size: 24, color: color),
                if (item.badge != null)
                  Positioned(right: -10, top: -7, child: item.badge!),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                height: 1.2,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: selected ? 20 : 0,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterButton extends StatelessWidget {
  const _CenterButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Positioned(
              top: -12,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: context.brandGradient,
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.brand,
                ),
                child: Icon(icon, size: 26, color: AppColors.onPrimary),
              ),
            ),
            Positioned(
              top: 48,
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
