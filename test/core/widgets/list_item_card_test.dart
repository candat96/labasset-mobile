import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:labasset_mobile/core/theme/tokens.dart';
import 'package:labasset_mobile/core/widgets/app_card.dart';
import 'package:labasset_mobile/core/widgets/list_item_card.dart';
import 'package:labasset_mobile/core/widgets/status_badge.dart';

import '../../helpers/test_helpers.dart';

void main() {
  testWidgets('ListItemCard: tiêu đề, mã, badge, dòng phụ + nhận tap', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      wrap(
        Scaffold(
          body: ListItemCard(
            title: 'Máy X-quang',
            code: 'TB-001',
            badge: const StatusBadge(
              tone: StatusTone.success,
              label: 'Đang dùng',
            ),
            metas: const [ListMeta(LucideIcons.mapPin, 'Khoa Chẩn đoán')],
            onTap: () => taps++,
          ),
        ),
      ),
    );

    expect(find.text('Máy X-quang'), findsOneWidget);
    expect(find.text('TB-001'), findsOneWidget);
    expect(find.text('Đang dùng'), findsOneWidget);
    expect(find.text('Khoa Chẩn đoán'), findsOneWidget);

    await tester.tap(find.text('Máy X-quang'));
    expect(taps, 1);
  });

  testWidgets('ListItemCard dùng viền `--border`, bo 12, nền trắng', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(const Scaffold(body: ListItemCard(title: 'Thiết bị'))),
    );

    final box = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(AppCard),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    final decoration = box.decoration as BoxDecoration;
    expect(decoration.color, AppColors.card);
    final side = (decoration.border! as Border).top;
    expect(side.color, AppColors.border);
    expect(side.width, 1);
    expect(decoration.borderRadius, BorderRadius.circular(AppRadius.card));
    expect(decoration.boxShadow, isNotEmpty);
  });
}
