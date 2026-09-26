import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:labasset_mobile/core/theme/tokens.dart';
import 'package:labasset_mobile/core/widgets/app_buttons.dart';

import '../../helpers/test_helpers.dart';

/// Lấy màu nền/chữ đã resolve của style nút.
Color? _bg(Widget widget) {
  final style = switch (widget) {
    FilledButton b => b.style,
    OutlinedButton b => b.style,
    IconButton b => b.style,
    _ => null,
  };
  return style?.backgroundColor?.resolve(<WidgetState>{});
}

Color? _fg(Widget widget) {
  final style = switch (widget) {
    FilledButton b => b.style,
    OutlinedButton b => b.style,
    IconButton b => b.style,
    _ => null,
  };
  return style?.foregroundColor?.resolve(<WidgetState>{});
}

void main() {
  group('AppButton đặc theo vai trò', () {
    Future<void> pump(WidgetTester tester, Widget button) =>
        tester.pumpWidget(wrap(Scaffold(body: button)));

    testWidgets('primary: nền AppColors.primary, chữ trắng', (tester) async {
      await pump(tester, const AppButton.primary(label: 'Lưu'));
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(_bg(button), AppColors.primary);
      expect(_fg(button), AppColors.onPrimary);
    });

    testWidgets('danger: nền AppColors.danger, chữ trắng', (tester) async {
      await pump(tester, const AppButton.danger(label: 'Xoá'));
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(_bg(button), AppColors.danger);
      expect(_fg(button), AppColors.onPrimary);
    });

    testWidgets('success: nền AppColors.success', (tester) async {
      await pump(tester, const AppButton.success(label: 'Hoàn thành'));
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(_bg(button), AppColors.success);
      expect(_fg(button), AppColors.foreground);
    });

    testWidgets('warning: nền AppColors.warning', (tester) async {
      await pump(tester, const AppButton.warning(label: 'Tạm dừng'));
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(_bg(button), AppColors.warning);
      expect(_fg(button), AppColors.foreground);
    });
  });

  testWidgets('AppButton.soft: nền nhạt cùng tông, KHÔNG viền', (tester) async {
    await tester.pumpWidget(
      wrap(const Scaffold(body: AppButton.soft(label: 'Sửa'))),
    );
    final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
    expect(_bg(button), AppColors.primaryContainer);
    expect(_fg(button), AppColors.onPrimaryContainer);
    expect(button.style?.side?.resolve(<WidgetState>{})?.width ?? 0, 0);
  });

  testWidgets('AppButton.soft tông danger dùng nền/chữ danger', (tester) async {
    await tester.pumpWidget(
      wrap(
        const Scaffold(
          body: AppButton.soft(label: 'Xoá', tone: AppButtonTone.danger),
        ),
      ),
    );
    final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
    expect(_bg(button), AppColors.dangerBackground);
    expect(_fg(button), AppColors.dangerForeground);
  });

  testWidgets('AppIconButton: tròn 36×36, nền nhạt theo tông', (tester) async {
    await tester.pumpWidget(
      wrap(
        Scaffold(
          body: AppIconButton(
            icon: Icons.delete_outline,
            tooltip: 'Xoá',
            tone: AppButtonTone.danger,
            onPressed: () {},
          ),
        ),
      ),
    );
    final button = tester.widget<IconButton>(find.byType(IconButton));
    expect(_bg(button), AppColors.dangerBackground);
    expect(_fg(button), AppColors.dangerForeground);
    expect(
      button.style?.fixedSize?.resolve(<WidgetState>{}),
      const Size(36, 36),
    );
    expect(button.style?.shape?.resolve(<WidgetState>{}), const CircleBorder());
  });
}
