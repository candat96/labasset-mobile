import 'package:flutter/material.dart';

import 'status_badge.dart';

/// Icon trong ô bo góc nền màu nhạt + icon màu đậm tương ứng.
class IconChip extends StatelessWidget {
  const IconChip({
    super.key,
    required this.icon,
    this.size = 36,
    this.iconSize,
    this.radius = 12,
    this.tone,
    this.background,
    this.foreground,
    this.circle = false,
  });

  final IconData icon;
  final double size;
  final double? iconSize;
  final double radius;

  /// Tone trạng thái; null = primary-soft.
  final StatusTone? tone;
  final Color? background;
  final Color? foreground;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Color bg;
    Color fg;
    if (tone != null) {
      final palette = paletteForTone(context, tone!);
      bg = palette.background;
      fg = palette.color;
    } else {
      bg = scheme.primaryContainer;
      fg = scheme.onPrimaryContainer;
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background ?? bg,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(radius),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: iconSize ?? size * 0.55, color: foreground ?? fg),
    );
  }
}
