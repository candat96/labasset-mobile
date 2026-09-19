import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:labasset_mobile/core/widgets/kpi_tile.dart';
import 'package:labasset_mobile/core/widgets/section_card.dart';
import 'package:labasset_mobile/core/widgets/status_badge.dart';
import 'package:labasset_mobile/core/widgets/timeline_list.dart';

import '../../helpers/test_helpers.dart';

void main() {
  testWidgets('SectionCard hiện tiêu đề + hành động + nội dung', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const Scaffold(
          body: SectionCard(
            title: 'Thông số',
            actions: [Icon(Icons.edit)],
            child: Text('voltage 220V'),
          ),
        ),
      ),
    );
    expect(find.text('Thông số'), findsOneWidget);
    expect(find.byIcon(Icons.edit), findsOneWidget);
    expect(find.text('voltage 220V'), findsOneWidget);
  });

  testWidgets('KpiTile hiện nhãn + giá trị + nhận tap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      wrap(
        Scaffold(
          body: KpiTile(
            label: 'Máy hỏng',
            value: '3',
            icon: Icons.warning_amber_outlined,
            tone: StatusTone.danger,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );
    expect(find.text('3'), findsOneWidget);
    await tester.tap(find.text('3'));
    expect(tapped, isTrue);
  });

  testWidgets('TimelineList hiện mốc theo thứ tự', (tester) async {
    await tester.pumpWidget(
      wrap(
        Scaffold(
          body: TimelineList(
            items: [
              TimelineEntry(
                title: 'Tạo máy',
                at: '2026-09-19T08:00:00Z',
                summary: 'Khởi tạo hồ sơ',
                by: 'admin',
              ),
              const TimelineEntry(title: 'Đổi trạng thái'),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Tạo máy'), findsOneWidget);
    expect(find.text('Khởi tạo hồ sơ'), findsOneWidget);
    expect(find.text('Đổi trạng thái'), findsOneWidget);
    expect(find.textContaining('admin'), findsOneWidget);
  });
}
