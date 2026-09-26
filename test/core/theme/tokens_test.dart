import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:labasset_mobile/core/theme/tokens.dart';

/// Khoá giá trị token theo thiết kế Figma Medone (Z3jY6G2YHCOtXGda5fz0fD) —
/// xem docs/superpowers/plans/2026-09-26-theme-medone.md §"Bảng token chuẩn".
void main() {
  test('màu vai trò theo Medone', () {
    expect(AppColors.primary, const Color(0xFF006FEE));
    expect(AppColors.primaryHover, const Color(0xFF005BC4));
    expect(AppColors.primaryContainer, const Color(0xFFE6F1FE));
    expect(AppColors.danger, const Color(0xFFF31260));
    expect(AppColors.success, const Color(0xFF17C964));
    expect(AppColors.warning, const Color(0xFFF5A524));
    expect(AppColors.accentPurple, const Color(0xFF7828C8));
  });
  test('thang xám và nền theo Medone', () {
    expect(AppColors.foreground, const Color(0xFF11181C));
    expect(AppColors.mutedForeground, const Color(0xFF71717A));
    expect(AppColors.subtle, const Color(0xFFA1A1AA));
    expect(AppColors.muted, const Color(0xFFF4F4F5));
    expect(AppColors.border, const Color(0xFFD4D4D8));
    expect(AppColors.surfaceAlt, const Color(0xFFF4F4F5));
  });
  test('không còn màu thương hiệu cũ', () {
    expect(AppColors.primary, isNot(const Color(0xFF2977FF)));
  });
}
