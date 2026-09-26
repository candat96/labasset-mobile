import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:labasset_mobile/core/theme/tokens.dart';
import 'package:labasset_mobile/modules/home/widgets/home_stat_tile.dart';

import '../../helpers/test_helpers.dart';

void main() {
  testWidgets('HomeStatTile: icon tròn nền màu, số 24/600, nhãn 14/500', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      wrap(
        Scaffold(
          body: HomeStatTile(
            icon: Icons.warning_amber_outlined,
            value: '3',
            label: 'Máy hỏng',
            accent: AppAccent.red,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('3'), findsOneWidget);
    expect(find.text('Máy hỏng'), findsOneWidget);

    final value = tester.widget<Text>(find.text('3'));
    expect(value.style!.fontSize, 24);
    expect(value.style!.fontWeight, FontWeight.w600);

    final label = tester.widget<Text>(find.text('Máy hỏng'));
    expect(label.style!.fontSize, 14);
    expect(label.style!.fontWeight, FontWeight.w500);

    // Biểu tượng nằm trong ô tròn nền màu token [AppAccent.red].
    final circles = tester.widgetList<Container>(find.byType(Container)).where((
      c,
    ) {
      final d = c.decoration;
      return d is BoxDecoration &&
          d.shape == BoxShape.circle &&
          d.color == AppAccent.red.background;
    });
    expect(circles, isNotEmpty);

    await tester.tap(find.text('3'));
    expect(tapped, isTrue);
  });
}
