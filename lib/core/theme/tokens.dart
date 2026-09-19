import 'package:flutter/material.dart';

/// Token màu theo docs/superpowers/specs/2026-09-19-design-system.md (mục 2).
class AppColors {
  AppColors._();

  static const primary = Color(0xFF0284C7);
  static const primaryDark = Color(0xFF38BDF8);
  static const onPrimaryDark = Color(0xFF0C4A6E);

  static const background = Color(0xFFF8FAFC);
  static const foreground = Color(0xFF0F172A);
  static const card = Color(0xFFFFFFFF);
  static const muted = Color(0xFFF1F5F9);
  static const mutedForeground = Color(0xFF64748B);
  static const border = Color(0xFFE2E8F0);
  static const secondary = Color(0xFFE0F2FE);

  static const backgroundDark = Color(0xFF0F172A);
  static const foregroundDark = Color(0xFFF1F5F9);
  static const cardDark = Color(0xFF1E293B);
  static const mutedDark = Color(0xFF1E293B);
  static const mutedForegroundDark = Color(0xFF94A3B8);
  static const borderDark = Color(0xFF334155);

  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFD97706);
  static const danger = Color(0xFFDC2626);
  static const info = Color(0xFF0284C7);
  static const successDark = Color(0xFF4ADE80);
  static const warningDark = Color(0xFFFBBF24);
  static const dangerDark = Color(0xFFF87171);
  static const infoDark = Color(0xFF38BDF8);
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
