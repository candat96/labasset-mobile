import 'package:flutter/material.dart';

/// Token màu theo docs/superpowers/specs/2026-09-19-design-system.md (mục 2).
class AppColors {
  AppColors._();

  static const primary = Color(0xFF0369A1);
  static const primaryContainer = Color(0xFFE0F2FE);
  static const onPrimaryContainer = Color(0xFF075985);
  static const primaryDark = Color(0xFF38BDF8);
  static const primaryContainerDark = Color(0xFF0C2A3F);
  static const onPrimaryContainerDark = Color(0xFFBAE6FD);

  static const background = Color(0xFFF1F5F9);
  static const foreground = Color(0xFF0F172A);
  static const card = Color(0xFFFFFFFF);
  static const subtle = Color(0xFF94A3B8);
  static const muted = Color(0xFFF1F5F9);
  static const mutedForeground = Color(0xFF64748B);
  static const border = Color(0xFFE2E8F0);
  static const divider = Color(0xFFEEF2F7);

  static const backgroundDark = Color(0xFF0B1220);
  static const foregroundDark = Color(0xFFE5EAF2);
  static const cardDark = Color(0xFF151E2E);
  static const mutedDark = Color(0xFF1C2739);
  static const mutedForegroundDark = Color(0xFF94A3B8);
  static const subtleDark = Color(0xFF64748B);
  static const borderDark = Color(0xFF26334D);
  static const dividerDark = Color(0xFF1C2739);

  static const success = Color(0xFF15803D);
  static const successBackground = Color(0xFFDCFCE7);
  static const successForeground = Color(0xFF166534);
  static const warning = Color(0xFFB45309);
  static const warningBackground = Color(0xFFFEF3C7);
  static const warningForeground = Color(0xFF92400E);
  static const danger = Color(0xFFB91C1C);
  static const dangerBackground = Color(0xFFFEE2E2);
  static const dangerForeground = Color(0xFF991B1B);
  static const info = Color(0xFF0369A1);
  static const infoBackground = Color(0xFFE0F2FE);
  static const infoForeground = Color(0xFF075985);
  static const neutralBackground = Color(0xFFF1F5F9);
  static const neutralForeground = Color(0xFF475569);

  static const successDark = Color(0xFF4ADE80);
  static const successBackgroundDark = Color(0xFF0F2A1A);
  static const warningDark = Color(0xFFFBBF24);
  static const warningBackgroundDark = Color(0xFF2E2109);
  static const dangerDark = Color(0xFFF87171);
  static const dangerBackgroundDark = Color(0xFF341417);
  static const infoDark = Color(0xFF38BDF8);
  static const infoBackgroundDark = Color(0xFF0C2A3F);
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
  static const sm = 4.0;
  static const md = 6.0;
  static const lg = 8.0;
}
