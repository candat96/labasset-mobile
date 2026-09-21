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
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  /// Gradient thương hiệu theo theme hiện tại.
  LinearGradient get brandGradient =>
      isDark ? AppGradients.brandDark : AppGradients.brand;

  /// Viền card 1px mờ theo theme hiện tại.
  Color get cardBorder =>
      isDark ? AppColors.cardBorderDark : AppColors.cardBorder;

  /// Bóng card (dark không dùng bóng, chỉ viền).
  List<BoxShadow> get cardShadow => isDark ? const [] : AppShadows.card;
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
    required Color cardBorder,
    required Color border,
    required Color divider,
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
    final isDark = brightness == Brightness.dark;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.tile),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: _fontFamily,
      textTheme: text,
      scaffoldBackgroundColor: background,
      dividerColor: divider,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: divider,
        surfaceTintColor: background,
        centerTitle: false,
        titleTextStyle: appText.title.copyWith(fontFamily: _fontFamily),
      ),
      // Card: nền card + viền 1px mờ + bóng nhẹ (light) — tách lớp trên nền trắng.
      cardTheme: CardThemeData(
        color: card,
        elevation: isDark ? 0 : 2,
        shadowColor: isDark ? Colors.transparent : const Color(0x1F101828),
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: cardBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: isDark ? card : muted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.tile),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.tile),
          borderSide: BorderSide(color: isDark ? border : cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.tile),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        labelStyle: text.bodyMedium,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: shape,
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: shape,
          side: BorderSide(color: border),
          foregroundColor: scheme.onSurface,
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        highlightElevation: 0,
        extendedTextStyle: text.labelLarge?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
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
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: card,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        backgroundColor: card,
        indicatorColor: scheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStatePropertyAll(appText.caption),
      ),
      // TabBar kiểu pill: item chọn nền card + bóng, không underline.
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.onSurface,
        unselectedLabelColor: mutedFg,
        labelStyle: appText.label.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: appText.label.copyWith(fontSize: 14),
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(AppRadius.chip),
          boxShadow: isDark ? null : AppShadows.selected,
        ),
        dividerColor: Colors.transparent,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        splashFactory: NoSplash.splashFactory,
        labelPadding: const EdgeInsets.symmetric(horizontal: 14),
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
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
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
    cardBorder: AppColors.cardBorder,
    border: AppColors.border,
    divider: AppColors.divider,
    muted: AppColors.muted,
    mutedFg: AppColors.mutedForeground,
    subtle: AppColors.subtle,
    status: AppStatusColors.light,
  );

  static ThemeData dark() => _build(
    brightness: Brightness.dark,
    scheme: const ColorScheme.dark(
      primary: AppColors.primaryDark,
      onPrimary: AppColors.onPrimaryDark,
      primaryContainer: AppColors.primaryContainerDark,
      onPrimaryContainer: AppColors.onPrimaryContainerDark,
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
    cardBorder: AppColors.cardBorderDark,
    border: AppColors.borderDark,
    divider: AppColors.dividerDark,
    muted: AppColors.mutedDark,
    mutedFg: AppColors.mutedForegroundDark,
    subtle: AppColors.subtleDark,
    status: AppStatusColors.dark,
  );
}
