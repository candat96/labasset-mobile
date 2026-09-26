import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:labasset_mobile/core/theme/tokens.dart';
import 'package:labasset_mobile/core/widgets/status_badge.dart';

import '../../helpers/test_helpers.dart';

void main() {
  testWidgets('StatusBadge LUÔN có chữ, nền nhạt + chữ đậm theo vai trò', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const Scaffold(
          body: StatusBadge(tone: StatusTone.danger, label: 'Quá hạn'),
        ),
      ),
    );

    // Luôn có chữ — không bao giờ chỉ dùng màu.
    final label = tester.widget<Text>(find.text('Quá hạn'));
    expect(label.style?.fontSize, 12.5);
    expect(label.style?.color, AppColors.dangerForeground);

    final container = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(StatusBadge),
            matching: find.byType(Container),
          )
          .first,
    );
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.color, AppColors.dangerBackground);
    // Bo tròn hoàn toàn.
    expect(decoration.borderRadius, BorderRadius.circular(999));
  });

  testWidgets('StatusBadge đổi nền/chữ theo tone', (tester) async {
    await tester.pumpWidget(
      wrap(
        const Scaffold(
          body: StatusBadge(tone: StatusTone.success, label: 'Đang dùng'),
        ),
      ),
    );
    final label = tester.widget<Text>(find.text('Đang dùng'));
    expect(label.style?.color, AppColors.successForeground);
  });
}
