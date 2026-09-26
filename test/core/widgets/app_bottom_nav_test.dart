import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:labasset_mobile/core/theme/tokens.dart';
import 'package:labasset_mobile/core/widgets/app_bottom_nav.dart';

import '../../helpers/test_helpers.dart';

void main() {
  testWidgets('AppBottomNav: bo tròn, nút giữa nền primary, mục nhận tap', (
    tester,
  ) async {
    var selected = -1;
    var centerTaps = 0;
    await tester.pumpWidget(
      wrap(
        Scaffold(
          bottomNavigationBar: AppBottomNav(
            items: const [
              AppNavItem(icon: Icons.home_outlined, label: 'Nhà'),
              AppNavItem(icon: Icons.build_outlined, label: 'Sửa chữa'),
              AppNavItem(icon: Icons.inventory_2_outlined, label: 'Kho'),
              AppNavItem(icon: Icons.person_outline, label: 'Tài khoản'),
            ],
            selectedIndex: 0,
            onSelected: (i) => selected = i,
            centerIcon: Icons.qr_code_scanner,
            centerLabel: 'Quét',
            onCenterTap: () => centerTaps++,
          ),
        ),
      ),
    );

    // Thanh dưới bo tròn nhẹ.
    final bar = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(AppBottomNav),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    final decoration = bar.decoration as BoxDecoration;
    expect(decoration.borderRadius, isNotNull);

    // Nút quét giữa nền primary.
    final centerButton = tester
        .widgetList<Container>(find.byType(Container))
        .where((c) {
          final d = c.decoration;
          return d is BoxDecoration &&
              d.shape == BoxShape.circle &&
              d.color == AppColors.primary;
        });
    expect(centerButton, isNotEmpty);

    await tester.tap(find.text('Kho'));
    expect(selected, 2);

    await tester.tap(find.byIcon(Icons.qr_code_scanner));
    expect(centerTaps, 1);
  });
}
