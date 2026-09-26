import 'package:flutter/material.dart';

/// Token màu theo docs/superpowers/specs/2026-09-19-design-system.md (mục 2).
class AppColors {
  AppColors._();

  static const primary = Color(0xFF006FEE);
  static const primaryHover = Color(0xFF005BC4);
  static const primaryPressed = Color(0xFF004A9E);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFFE6F1FE);
  static const onPrimaryContainer = Color(0xFF005BC4);
  static const link = Color(0xFF005BC4);
  static const primaryDark = Color(0xFF4C9DFF);
  static const primaryHoverDark = Color(0xFF6FB2FF);
  static const onPrimaryDark = Color(0xFF08182E);
  static const primaryContainerDark = Color(0xFF0A2A52);
  static const onPrimaryContainerDark = Color(0xFFBFD9FF);
  static const linkDark = Color(0xFF6FB2FF);

  /// Nền màn hình: trắng thuần (người dùng chốt 2026-09-21); card tách lớp
  /// bằng viền [cardBorder] + bóng [AppShadows.card], không dùng nền xám.
  static const background = Color(0xFFFFFFFF);

  /// Nền vùng nội dung (Figma: default-100).
  static const surfaceAlt = Color(0xFFF4F4F5);

  /// Màu nhấn phụ (Figma: colors/base/secondary).
  static const accentPurple = Color(0xFF7828C8);
  static const accentPurpleContainer = Color(0xFFF2EAFA);
  static const foreground = Color(0xFF11181C);
  static const card = Color(0xFFFFFFFF);
  static const cardBorder = Color(0x0F101828);
  static const subtle = Color(0xFFA1A1AA);

  /// Vùng phụ (chip, nền ô tìm, segment, chip icon trung tính).
  static const muted = Color(0xFFF4F4F5);
  static const segment = Color(0xFFEFEFF1);
  static const mutedForeground = Color(0xFF71717A);
  static const border = Color(0xFFD4D4D8);
  static const divider = Color(0xFFE4E4E7);
  static const timelineLine = Color(0xFFE4E4E7);

  static const backgroundDark = Color(0xFF0B1220);
  static const foregroundDark = Color(0xFFE5EAF2);
  static const cardDark = Color(0xFF151E2E);
  static const cardBorderDark = Color(0xFF22304A);
  static const mutedDark = Color(0xFF1C2739);
  static const segmentDark = Color(0xFF1C2739);
  static const mutedForegroundDark = Color(0xFF94A3B8);
  static const subtleDark = Color(0xFF64748B);
  static const borderDark = Color(0xFF26334D);
  static const dividerDark = Color(0xFF1C2739);

  static const success = Color(0xFF17C964);
  static const successBackground = Color(0xFFE8FAF0);
  static const successForeground = Color(0xFF0E7A3C);
  static const warning = Color(0xFFF5A524);
  static const warningBackground = Color(0xFFFEFCE8);
  static const warningForeground = Color(0xFFA35F06);
  static const danger = Color(0xFFF31260);
  static const dangerBackground = Color(0xFFFEE7EF);
  static const dangerForeground = Color(0xFFC40F4C);
  static const info = Color(0xFF006FEE);
  static const infoBackground = Color(0xFFE6F1FE);
  static const infoForeground = Color(0xFF1747A6);
  static const neutralBackground = Color(0xFFF6F8FC);
  static const neutralForeground = Color(0xFF475569);

  static const successDark = Color(0xFF45D483);
  static const successBackgroundDark = Color(0xFF0F2A1A);
  static const warningDark = Color(0xFFF7B74D);
  static const warningBackgroundDark = Color(0xFF2E2109);
  static const dangerDark = Color(0xFFF87171);
  static const dangerBackgroundDark = Color(0xFF341417);
  static const infoDark = Color(0xFF4C9DFF);
  static const infoBackgroundDark = Color(0xFF0A2A52);
  static const neutralBackgroundDark = Color(0xFF1C2739);
  static const neutralForegroundDark = Color(0xFF94A3B8);
}

class AppSpacing {
  AppSpacing._();
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

class AppRadius {
  AppRadius._();
  static const card = 16.0;
  static const tile = 12.0;
  static const chip = 999.0;
  static const sheet = 20.0;
  static const hero = 24.0;

  // Bí danh tương thích cho widget cũ; vẫn quy về bốn bán kính chuẩn.
  static const sm = tile;
  static const md = tile;
  static const lg = card;
}

class AppShadows {
  AppShadows._();

  /// Card trên nền trắng: `0 1px 2px .04` + `0 6px 16px -8px .12`.
  static const card = [
    BoxShadow(color: Color(0x0A101828), offset: Offset(0, 1), blurRadius: 2),
    BoxShadow(
      color: Color(0x1F101828),
      offset: Offset(0, 6),
      blurRadius: 16,
      spreadRadius: -8,
    ),
  ];

  /// Bí danh cũ.
  static const cardElevated = card;

  /// Card nổi đè lên hero (ô tìm, form đăng nhập).
  static const floating = [
    BoxShadow(color: Color(0x0F101828), offset: Offset(0, 2), blurRadius: 4),
    BoxShadow(
      color: Color(0x29101828),
      offset: Offset(0, 12),
      blurRadius: 28,
      spreadRadius: -10,
    ),
  ];

  static const selected = [
    BoxShadow(color: Color(0x14101828), offset: Offset(0, 1), blurRadius: 3),
  ];

  /// Bóng màu thương hiệu cho nút gradient / nút Quét.
  static const brand = [
    BoxShadow(
      color: Color(0x592977FF),
      offset: Offset(0, 8),
      blurRadius: 20,
      spreadRadius: -4,
    ),
  ];

  /// Bóng hắt lên của bottom nav.
  static const navUp = [
    BoxShadow(
      color: Color(0x14101828),
      offset: Offset(0, -4),
      blurRadius: 16,
      spreadRadius: -4,
    ),
  ];
}

/// Gradient thương hiệu (135°, `#2977FF → #5C9BFF`).
class AppGradients {
  AppGradients._();

  static const brand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primary, AppColors.primaryDark],
  );

  static const brandDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF005BC4), AppColors.primaryDark],
  );
}

/// Thang chữ duy nhất của ứng dụng; màu được áp theo light/dark theme.
@immutable
class AppText extends ThemeExtension<AppText> {
  const AppText({
    required this.display,
    required this.title,
    required this.section,
    required this.body,
    required this.bodyStrong,
    required this.label,
    required this.caption,
    required this.kpi,
  });

  final TextStyle display;
  final TextStyle title;
  final TextStyle section;
  final TextStyle body;
  final TextStyle bodyStrong;
  final TextStyle label;
  final TextStyle caption;
  final TextStyle kpi;

  factory AppText.forColors({
    required Color foreground,
    required Color mutedForeground,
    required Color subtle,
  }) => AppText(
    display: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
      height: 1.15,
      color: foreground,
    ),
    title: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
      color: foreground,
    ),
    // Tiêu đề khối: 13/700 viết hoa, tracking .06em, màu muted.
    section: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.78,
      color: mutedForeground,
    ),
    body: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      height: 1.4,
      color: foreground,
    ),
    bodyStrong: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      height: 1.35,
      color: foreground,
    ),
    label: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: mutedForeground,
    ),
    caption: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: subtle,
    ),
    kpi: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
      color: foreground,
      fontFeatures: const [FontFeature.tabularFigures()],
    ),
  );

  @override
  AppText copyWith({
    TextStyle? display,
    TextStyle? title,
    TextStyle? section,
    TextStyle? body,
    TextStyle? bodyStrong,
    TextStyle? label,
    TextStyle? caption,
    TextStyle? kpi,
  }) => AppText(
    display: display ?? this.display,
    title: title ?? this.title,
    section: section ?? this.section,
    body: body ?? this.body,
    bodyStrong: bodyStrong ?? this.bodyStrong,
    label: label ?? this.label,
    caption: caption ?? this.caption,
    kpi: kpi ?? this.kpi,
  );

  @override
  AppText lerp(AppText? other, double t) {
    if (other == null) return this;
    return AppText(
      display: TextStyle.lerp(display, other.display, t)!,
      title: TextStyle.lerp(title, other.title, t)!,
      section: TextStyle.lerp(section, other.section, t)!,
      body: TextStyle.lerp(body, other.body, t)!,
      bodyStrong: TextStyle.lerp(bodyStrong, other.bodyStrong, t)!,
      label: TextStyle.lerp(label, other.label, t)!,
      caption: TextStyle.lerp(caption, other.caption, t)!,
      kpi: TextStyle.lerp(kpi, other.kpi, t)!,
    );
  }
}

/// Cặp màu nhấn cho chip icon lối tắt: nền nhạt + icon đậm (light); dark suy
/// ra từ màu icon (nền 20% alpha, icon sáng hơn) để dùng lại cho KPI/Badge.
class AppAccent {
  const AppAccent({required this.background, required this.foreground});

  final Color background;
  final Color foreground;

  /// Nền dark = màu icon 20% alpha.
  Color get darkBackground => foreground.withValues(alpha: 0.2);

  /// Icon dark = màu icon pha trắng cho nổi trên nền tối.
  Color get darkForeground => Color.lerp(foreground, Colors.white, 0.35)!;

  Color backgroundFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? darkBackground
      : background;

  Color foregroundFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? darkForeground
      : foreground;

  static const red = AppAccent(
    background: Color(0xFFFEE2E2),
    foreground: Color(0xFFB91C1C),
  );
  static const orange = AppAccent(
    background: Color(0xFFFFEDD5),
    foreground: Color(0xFFC2410C),
  );
  static const green = AppAccent(
    background: Color(0xFFDCFCE7),
    foreground: Color(0xFF15803D),
  );
  static const purple = AppAccent(
    background: Color(0xFFEDE9FE),
    foreground: Color(0xFF6D28D9),
  );
  static const teal = AppAccent(
    background: Color(0xFFCCFBF1),
    foreground: Color(0xFF0F766E),
  );
  static const brand = AppAccent(
    background: Color(0xFFE8F0FF),
    foreground: Color(0xFF1747A6),
  );
  static const indigo = AppAccent(
    background: Color(0xFFE0E7FF),
    foreground: Color(0xFF4338CA),
  );
  static const yellow = AppAccent(
    background: Color(0xFFFEF3C7),
    foreground: Color(0xFFB45309),
  );
  static const pink = AppAccent(
    background: Color(0xFFFCE7F3),
    foreground: Color(0xFFBE185D),
  );
}
