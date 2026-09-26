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

/// Vai trò màu của nút theo nghĩa hành động
/// (docs/superpowers/plans/2026-09-26-theme-medone.md → "Quy tắc suy ra" mục 3).
enum AppButtonTone { primary, danger, success, warning, neutral }

/// Cặp màu nền/chữ của từng vai trò, lấy từ [AppColors] — không hard-code hex.
extension AppButtonToneColors on AppButtonTone {
  Color solidColor(bool dark) => switch (this) {
    AppButtonTone.primary => dark ? AppColors.primaryDark : AppColors.primary,
    AppButtonTone.danger => dark ? AppColors.dangerDark : AppColors.danger,
    AppButtonTone.success => dark ? AppColors.successDark : AppColors.success,
    AppButtonTone.warning => dark ? AppColors.warningDark : AppColors.warning,
    AppButtonTone.neutral => dark ? AppColors.mutedDark : AppColors.muted,
  };

  Color onSolidColor(bool dark) => switch (this) {
    AppButtonTone.primary =>
      dark ? AppColors.onPrimaryDark : AppColors.onPrimary,
    AppButtonTone.danger =>
      dark ? AppColors.foregroundDark : AppColors.onPrimary,
    AppButtonTone.success || AppButtonTone.warning || AppButtonTone.neutral =>
      dark ? AppColors.foregroundDark : AppColors.foreground,
  };

  Color softBackground(bool dark) => switch (this) {
    AppButtonTone.primary =>
      dark ? AppColors.primaryContainerDark : AppColors.primaryContainer,
    AppButtonTone.danger =>
      dark ? AppColors.dangerBackgroundDark : AppColors.dangerBackground,
    AppButtonTone.success =>
      dark ? AppColors.successBackgroundDark : AppColors.successBackground,
    AppButtonTone.warning =>
      dark ? AppColors.warningBackgroundDark : AppColors.warningBackground,
    AppButtonTone.neutral =>
      dark ? AppColors.neutralBackgroundDark : AppColors.neutralBackground,
  };

  Color softForeground(bool dark) => switch (this) {
    AppButtonTone.primary =>
      dark ? AppColors.onPrimaryContainerDark : AppColors.onPrimaryContainer,
    AppButtonTone.danger =>
      dark ? AppColors.dangerDark : AppColors.dangerForeground,
    AppButtonTone.success =>
      dark ? AppColors.successDark : AppColors.successForeground,
    AppButtonTone.warning =>
      dark ? AppColors.warningDark : AppColors.warningForeground,
    AppButtonTone.neutral =>
      dark ? AppColors.neutralForegroundDark : AppColors.neutralForeground,
  };
}

/// Nút có màu theo vai trò hành động. Chọn bằng named constructor:
/// - [AppButton.primary] hành động chính của màn — nền `primary`, chữ trắng.
/// - [AppButton.danger] hành động phá huỷ (Huỷ phiếu, Xoá, Từ chối).
/// - [AppButton.success] hành động hoàn tất (Hoàn thành, Duyệt, Nghiệm thu).
/// - [AppButton.warning] hành động tạm dừng/cảnh báo.
/// - [AppButton.soft] nút phụ nền nhạt cùng tông, KHÔNG viền xám đơn điệu.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.loading = false,
    this.expand = false,
    this.tone = AppButtonTone.primary,
    this.soft = false,
  });

  const AppButton.primary({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.loading = false,
    this.expand = false,
  }) : tone = AppButtonTone.primary,
       soft = false;

  const AppButton.danger({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.loading = false,
    this.expand = false,
  }) : tone = AppButtonTone.danger,
       soft = false;

  const AppButton.success({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.loading = false,
    this.expand = false,
  }) : tone = AppButtonTone.success,
       soft = false;

  const AppButton.warning({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.loading = false,
    this.expand = false,
  }) : tone = AppButtonTone.warning,
       soft = false;

  const AppButton.soft({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.loading = false,
    this.expand = false,
    this.tone = AppButtonTone.primary,
  }) : soft = true;

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;
  final bool expand;
  final AppButtonTone tone;
  final bool soft;

  @override
  Widget build(BuildContext context) {
    final style = styleFor(context, tone, soft: soft);
    final child = _ButtonContent(label: label, icon: icon, loading: loading);
    final button = soft
        ? OutlinedButton(
            onPressed: loading ? null : onPressed,
            style: style,
            child: child,
          )
        : FilledButton(
            onPressed: loading ? null : onPressed,
            style: style,
            child: child,
          );
    final scaled = _PressScale(
      enabled: onPressed != null && !loading,
      child: button,
    );
    return expand ? SizedBox(width: double.infinity, child: scaled) : scaled;
  }

  /// Style dùng lại cho trường hợp nút cần `child` tuỳ biến (không theo
  /// [AppButton] mặc định): `FilledButton(style: AppButton.styleFor(context, tone), ...)`.
  static ButtonStyle styleFor(
    BuildContext context,
    AppButtonTone tone, {
    bool soft = false,
  }) {
    final dark = context.isDark;
    final background = soft ? tone.softBackground(dark) : tone.solidColor(dark);
    final foreground = soft
        ? tone.softForeground(dark)
        : tone.onSolidColor(dark);
    return FilledButton.styleFrom(
      backgroundColor: background,
      foregroundColor: foreground,
      disabledBackgroundColor: background.withValues(alpha: 0.45),
      disabledForegroundColor: foreground.withValues(alpha: 0.7),
      minimumSize: const Size(72, 44),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      side: soft ? BorderSide.none : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.tile),
      ),
    );
  }
}

/// Nút chỉ có biểu tượng, tròn 36×36, nền nhạt theo [tone] — thay cho
/// `IconButton` mặc định để không còn nút icon xám vô nghĩa.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.tone = AppButtonTone.primary,
    this.size = 36,
    this.iconSize = 18,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final AppButtonTone tone;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      iconSize: iconSize,
      padding: EdgeInsets.zero,
      style: IconButton.styleFrom(
        backgroundColor: tone.softBackground(dark),
        foregroundColor: tone.softForeground(dark),
        disabledBackgroundColor: tone
            .softBackground(dark)
            .withValues(alpha: 0.5),
        disabledForegroundColor: tone
            .softForeground(dark)
            .withValues(alpha: 0.5),
        minimumSize: Size.square(size),
        fixedSize: Size.square(size),
        shape: const CircleBorder(),
      ),
      icon: Icon(icon),
    );
  }
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
                  fontSize: 16,
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
                    fontSize: 16,
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
