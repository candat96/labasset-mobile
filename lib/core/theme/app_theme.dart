import 'package:flutter/material.dart';

import 'tokens.dart';

/// Màu trạng thái ngoài ColorScheme (success/warning/info + nền nhạt).
@immutable
class AppStatusColors extends ThemeExtension<AppStatusColors> {
  const AppStatusColors({
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.muted,
  });

  final Color success;
  final Color warning;
  final Color danger;
  final Color info;
  final Color muted;

  static const light = AppStatusColors(
    success: AppColors.success,
    warning: AppColors.warning,
    danger: AppColors.danger,
    info: AppColors.info,
    muted: AppColors.mutedForeground,
  );

  static const dark = AppStatusColors(
    success: AppColors.successDark,
    warning: AppColors.warningDark,
    danger: AppColors.dangerDark,
    info: AppColors.infoDark,
    muted: AppColors.mutedForegroundDark,
  );

  @override
  AppStatusColors copyWith({
    Color? success,
    Color? warning,
    Color? danger,
    Color? info,
    Color? muted,
  }) => AppStatusColors(
    success: success ?? this.success,
    warning: warning ?? this.warning,
    danger: danger ?? this.danger,
    info: info ?? this.info,
    muted: muted ?? this.muted,
  );

  @override
  AppStatusColors lerp(AppStatusColors? other, double t) {
    if (other == null) return this;
    return AppStatusColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      info: Color.lerp(info, other.info, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
    );
  }
}

extension AppThemeX on BuildContext {
  AppStatusColors get status => Theme.of(this).extension<AppStatusColors>()!;
}

class AppTheme {
  AppTheme._();

  static const _fontFamily = 'Inter';

  static TextTheme _textTheme(Color fg, Color muted) => TextTheme(
    headlineSmall: TextStyle(
      fontSize: 24,
      height: 32 / 24,
      fontWeight: FontWeight.w600,
      color: fg,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      height: 28 / 20,
      fontWeight: FontWeight.w600,
      color: fg,
    ),
    titleMedium: TextStyle(
      fontSize: 18,
      height: 28 / 18,
      fontWeight: FontWeight.w600,
      color: fg,
    ),
    titleSmall: TextStyle(
      fontSize: 16,
      height: 24 / 16,
      fontWeight: FontWeight.w500,
      color: fg,
    ),
    bodyLarge: TextStyle(fontSize: 16, height: 24 / 16, color: fg),
    bodyMedium: TextStyle(fontSize: 14, height: 20 / 14, color: fg),
    bodySmall: TextStyle(fontSize: 12, height: 16 / 12, color: muted),
    labelLarge: TextStyle(
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w500,
      color: fg,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      height: 16 / 12,
      fontWeight: FontWeight.w500,
      color: fg,
    ),
  ).apply(fontFamily: _fontFamily);

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme scheme,
    required Color background,
    required Color card,
    required Color border,
    required Color muted,
    required Color mutedFg,
    required AppStatusColors status,
  }) {
    final text = _textTheme(scheme.onSurface, mutedFg);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: _fontFamily,
      textTheme: text,
      scaffoldBackgroundColor: background,
      dividerColor: border,
      appBarTheme: AppBarTheme(
        backgroundColor: card,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleMedium,
        shape: Border(bottom: BorderSide(color: border)),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        labelStyle: text.bodyMedium,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(44),
          shape: shape,
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(44),
          shape: shape,
          side: BorderSide(color: border),
          foregroundColor: scheme.onSurface,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(shape: shape),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: muted,
        labelStyle: text.labelMedium,
        side: BorderSide.none,
        shape: const StadiumBorder(),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: card,
        selectedItemColor: scheme.primary,
        unselectedItemColor: mutedFg,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: text.labelMedium,
        unselectedLabelStyle: text.labelMedium,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: shape,
        contentTextStyle: text.bodyMedium?.copyWith(color: scheme.surface),
      ),
      listTileTheme: ListTileThemeData(
        titleTextStyle: text.bodyMedium,
        subtitleTextStyle: text.bodySmall,
      ),
      extensions: [status],
    );
  }

  static ThemeData light() => _build(
    brightness: Brightness.light,
    scheme: const ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onPrimaryDark,
      surface: AppColors.card,
      onSurface: AppColors.foreground,
      onSurfaceVariant: AppColors.mutedForeground,
      surfaceContainerHighest: AppColors.muted,
      outline: AppColors.border,
      error: AppColors.danger,
      onError: Colors.white,
    ),
    background: AppColors.background,
    card: AppColors.card,
    border: AppColors.border,
    muted: AppColors.muted,
    mutedFg: AppColors.mutedForeground,
    status: AppStatusColors.light,
  );

  static ThemeData dark() => _build(
    brightness: Brightness.dark,
    scheme: const ColorScheme.dark(
      primary: AppColors.primaryDark,
      onPrimary: AppColors.onPrimaryDark,
      secondary: AppColors.onPrimaryDark,
      onSecondary: AppColors.secondary,
      surface: AppColors.cardDark,
      onSurface: AppColors.foregroundDark,
      onSurfaceVariant: AppColors.mutedForegroundDark,
      surfaceContainerHighest: AppColors.mutedDark,
      outline: AppColors.borderDark,
      error: AppColors.dangerDark,
      onError: AppColors.backgroundDark,
    ),
    background: AppColors.backgroundDark,
    card: AppColors.cardDark,
    border: AppColors.borderDark,
    muted: AppColors.mutedDark,
    mutedFg: AppColors.mutedForegroundDark,
    status: AppStatusColors.dark,
  );
}
