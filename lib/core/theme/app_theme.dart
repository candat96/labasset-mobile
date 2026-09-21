import 'package:flutter/material.dart';

import 'tokens.dart';

/// Màu trạng thái ngoài ColorScheme (success/warning/info + nền nhạt).
@immutable
class AppStatusColors extends ThemeExtension<AppStatusColors> {
  const AppStatusColors({
    required this.success,
    required this.successBackground,
    required this.successForeground,
    required this.warning,
    required this.warningBackground,
    required this.warningForeground,
    required this.danger,
    required this.dangerBackground,
    required this.dangerForeground,
    required this.info,
    required this.infoBackground,
    required this.infoForeground,
    required this.muted,
    required this.mutedBackground,
    required this.mutedForeground,
  });

  final Color success;
  final Color successBackground;
  final Color successForeground;
  final Color warning;
  final Color warningBackground;
  final Color warningForeground;
  final Color danger;
  final Color dangerBackground;
  final Color dangerForeground;
  final Color info;
  final Color infoBackground;
  final Color infoForeground;
  final Color muted;
  final Color mutedBackground;
  final Color mutedForeground;

  static const light = AppStatusColors(
    success: AppColors.success,
    successBackground: AppColors.successBackground,
    successForeground: AppColors.successForeground,
    warning: AppColors.warning,
    warningBackground: AppColors.warningBackground,
    warningForeground: AppColors.warningForeground,
    danger: AppColors.danger,
    dangerBackground: AppColors.dangerBackground,
    dangerForeground: AppColors.dangerForeground,
    info: AppColors.info,
    infoBackground: AppColors.infoBackground,
    infoForeground: AppColors.infoForeground,
    muted: AppColors.mutedForeground,
    mutedBackground: AppColors.neutralBackground,
    mutedForeground: AppColors.neutralForeground,
  );

  static const dark = AppStatusColors(
    success: AppColors.successDark,
    successBackground: AppColors.successBackgroundDark,
    successForeground: AppColors.successDark,
    warning: AppColors.warningDark,
    warningBackground: AppColors.warningBackgroundDark,
    warningForeground: AppColors.warningDark,
    danger: AppColors.dangerDark,
    dangerBackground: AppColors.dangerBackgroundDark,
    dangerForeground: AppColors.dangerDark,
    info: AppColors.infoDark,
    infoBackground: AppColors.infoBackgroundDark,
    infoForeground: AppColors.infoDark,
    muted: AppColors.mutedForegroundDark,
    mutedBackground: AppColors.neutralBackgroundDark,
    mutedForeground: AppColors.neutralForegroundDark,
  );

  @override
  AppStatusColors copyWith({
    Color? success,
    Color? successBackground,
    Color? successForeground,
    Color? warning,
    Color? warningBackground,
    Color? warningForeground,
    Color? danger,
    Color? dangerBackground,
    Color? dangerForeground,
    Color? info,
    Color? infoBackground,
    Color? infoForeground,
    Color? muted,
    Color? mutedBackground,
    Color? mutedForeground,
  }) => AppStatusColors(
    success: success ?? this.success,
    successBackground: successBackground ?? this.successBackground,
    successForeground: successForeground ?? this.successForeground,
    warning: warning ?? this.warning,
    warningBackground: warningBackground ?? this.warningBackground,
    warningForeground: warningForeground ?? this.warningForeground,
    danger: danger ?? this.danger,
    dangerBackground: dangerBackground ?? this.dangerBackground,
    dangerForeground: dangerForeground ?? this.dangerForeground,
    info: info ?? this.info,
    infoBackground: infoBackground ?? this.infoBackground,
    infoForeground: infoForeground ?? this.infoForeground,
    muted: muted ?? this.muted,
    mutedBackground: mutedBackground ?? this.mutedBackground,
    mutedForeground: mutedForeground ?? this.mutedForeground,
  );

  @override
  AppStatusColors lerp(AppStatusColors? other, double t) {
    if (other == null) return this;
    return AppStatusColors(
      success: Color.lerp(success, other.success, t)!,
      successBackground: Color.lerp(
        successBackground,
        other.successBackground,
        t,
      )!,
      successForeground: Color.lerp(
        successForeground,
        other.successForeground,
        t,
      )!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningBackground: Color.lerp(
        warningBackground,
        other.warningBackground,
        t,
      )!,
      warningForeground: Color.lerp(
        warningForeground,
        other.warningForeground,
        t,
      )!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerBackground: Color.lerp(
        dangerBackground,
        other.dangerBackground,
        t,
      )!,
      dangerForeground: Color.lerp(
        dangerForeground,
        other.dangerForeground,
        t,
      )!,
      info: Color.lerp(info, other.info, t)!,
      infoBackground: Color.lerp(infoBackground, other.infoBackground, t)!,
      infoForeground: Color.lerp(infoForeground, other.infoForeground, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      mutedBackground: Color.lerp(mutedBackground, other.mutedBackground, t)!,
      mutedForeground: Color.lerp(mutedForeground, other.mutedForeground, t)!,
    );
  }
}

extension AppThemeX on BuildContext {
  AppStatusColors get status => Theme.of(this).extension<AppStatusColors>()!;
  AppText get appText => Theme.of(this).extension<AppText>()!;
}

class AppTheme {
  AppTheme._();

  static const _fontFamily = 'Inter';

  static TextTheme _textTheme(AppText appText) => TextTheme(
    displaySmall: appText.display,
    headlineSmall: appText.title,
    titleLarge: appText.title,
    titleMedium: appText.section,
    titleSmall: appText.bodyStrong,
    bodyLarge: appText.body,
    bodyMedium: appText.body,
    bodySmall: appText.caption,
    labelLarge: appText.bodyStrong,
    labelMedium: appText.label,
    labelSmall: appText.caption,
  ).apply(fontFamily: _fontFamily);

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme scheme,
    required Color background,
    required Color card,
    required Color border,
    required Color muted,
    required Color mutedFg,
    required Color subtle,
    required AppStatusColors status,
  }) {
    final appText = AppText.forColors(
      foreground: scheme.onSurface,
      mutedForeground: mutedFg,
      subtle: subtle,
    );
    final text = _textTheme(appText);
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
      extensions: [status, appText],
    );
  }

  static ThemeData light() => _build(
    brightness: Brightness.light,
    scheme: const ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.primaryContainer,
      onSecondary: AppColors.onPrimaryContainer,
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
    subtle: AppColors.subtle,
    status: AppStatusColors.light,
  );

  static ThemeData dark() => _build(
    brightness: Brightness.dark,
    scheme: const ColorScheme.dark(
      primary: AppColors.primaryDark,
      onPrimary: AppColors.backgroundDark,
      secondary: AppColors.primaryContainerDark,
      onSecondary: AppColors.onPrimaryContainerDark,
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
    subtle: AppColors.subtleDark,
    status: AppStatusColors.dark,
  );
}
