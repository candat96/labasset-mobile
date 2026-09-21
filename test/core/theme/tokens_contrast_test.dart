import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:labasset_mobile/core/theme/tokens.dart';

double _contrast(Color a, Color b) {
  final lighter = a.computeLuminance() > b.computeLuminance() ? a : b;
  final darker = identical(lighter, a) ? b : a;
  return (lighter.computeLuminance() + 0.05) /
      (darker.computeLuminance() + 0.05);
}

void main() {
  test('màu chữ thường đạt contrast tối thiểu 4.5:1', () {
    final pairs = <(Color, Color)>[
      (AppColors.foreground, AppColors.background),
      (AppColors.mutedForeground, AppColors.card),
      (AppColors.onPrimaryContainer, AppColors.primaryContainer),
      (AppColors.successForeground, AppColors.successBackground),
      (AppColors.warningForeground, AppColors.warningBackground),
      (AppColors.dangerForeground, AppColors.dangerBackground),
      (AppColors.infoForeground, AppColors.infoBackground),
      (AppColors.neutralForeground, AppColors.neutralBackground),
      (AppColors.foregroundDark, AppColors.backgroundDark),
      (AppColors.mutedForegroundDark, AppColors.cardDark),
      (AppColors.onPrimaryContainerDark, AppColors.primaryContainerDark),
      (AppColors.successDark, AppColors.successBackgroundDark),
      (AppColors.warningDark, AppColors.warningBackgroundDark),
      (AppColors.dangerDark, AppColors.dangerBackgroundDark),
      (AppColors.infoDark, AppColors.infoBackgroundDark),
      (AppColors.neutralForegroundDark, AppColors.neutralBackgroundDark),
    ];

    for (final (foreground, background) in pairs) {
      expect(
        _contrast(foreground, background),
        greaterThanOrEqualTo(4.5),
        reason: '$foreground trên $background',
      );
    }
  });

  test('màu icon và viền đạt contrast tối thiểu 3:1', () {
    expect(
      _contrast(AppColors.primary, AppColors.primaryContainer),
      greaterThanOrEqualTo(3),
    );
    expect(
      _contrast(AppColors.primaryDark, AppColors.primaryContainerDark),
      greaterThanOrEqualTo(3),
    );
  });
}
