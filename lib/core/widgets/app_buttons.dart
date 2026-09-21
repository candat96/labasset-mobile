import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.loading = false,
  });
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) => _PressScale(
    enabled: onPressed != null && !loading,
    child: FilledButton(
      onPressed: loading ? null : onPressed,
      child: _ButtonContent(label: label, icon: icon, loading: loading),
    ),
  );
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.loading = false,
  });
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) => _PressScale(
    enabled: onPressed != null && !loading,
    child: OutlinedButton(
      onPressed: loading ? null : onPressed,
      child: _ButtonContent(label: label, icon: icon, loading: loading),
    ),
  );
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.label,
    required this.icon,
    required this.loading,
  });
  final String label;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) => loading
      ? const SizedBox.square(
          dimension: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
      : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20),
              const SizedBox(width: 8),
            ],
            Text(label),
          ],
        );
}

class _PressScale extends StatefulWidget {
  const _PressScale({required this.enabled, required this.child});
  final bool enabled;
  final Widget child;
  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  var _pressed = false;

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: widget.enabled
        ? (_) => setState(() => _pressed = true)
        : null,
    onPointerUp: widget.enabled
        ? (_) => setState(() => _pressed = false)
        : null,
    onPointerCancel: widget.enabled
        ? (_) => setState(() => _pressed = false)
        : null,
    child: AnimatedScale(
      scale: _pressed ? 0.98 : 1,
      duration: const Duration(milliseconds: 150),
      child: widget.child,
    ),
  );
}

/// Nút chính gradient thương hiệu: cao 52, bo 12, bóng màu; dùng cho hành động
/// chính dính đáy màn chi tiết và nút đăng nhập.
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.loading = false,
    this.height = 52,
  });
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onPressed != null && !loading;
    final radius = BorderRadius.circular(AppRadius.tile);
    return _PressScale(
      enabled: enabled,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: enabled ? context.brandGradient : null,
          color: enabled ? null : scheme.primary.withValues(alpha: 0.45),
          borderRadius: radius,
          boxShadow: enabled && !context.isDark ? AppShadows.brand : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: radius,
            child: SizedBox(
              height: height,
              child: DefaultTextStyle(
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onPrimary,
                ),
                child: IconTheme(
                  data: const IconThemeData(
                    color: AppColors.onPrimary,
                    size: 20,
                  ),
                  child: Center(
                    child: loading
                        ? SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.onPrimary,
                            ),
                          )
                        : _ButtonContent(
                            label: label,
                            icon: icon,
                            loading: false,
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// FAB extended gradient thương hiệu, bo 16, chữ 15/700, bóng màu.
class GradientFab extends StatelessWidget {
  const GradientFab({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.heroTag,
  });
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.card);
    final child = DecoratedBox(
      decoration: BoxDecoration(
        gradient: context.brandGradient,
        borderRadius: radius,
        boxShadow: AppShadows.brand,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 22, color: AppColors.onPrimary),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (heroTag == null) return child;
    return Hero(tag: heroTag!, child: child);
  }
}
