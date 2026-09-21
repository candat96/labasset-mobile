import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:labasset_mobile/core/widgets/app_list_tile.dart';
import 'package:labasset_mobile/core/widgets/kpi_tile.dart';
import 'package:labasset_mobile/core/widgets/segment_tabs.dart';
import 'package:labasset_mobile/core/widgets/section_card.dart';
import 'package:labasset_mobile/core/widgets/shortcut_tile.dart';
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
    final tileSize = tester.getSize(find.byType(KpiTile));
    expect(tileSize.height, 120);
    final label = tester.widget<Text>(find.text('Máy hỏng'));
    expect(label.maxLines, 2);
    expect(label.overflow, TextOverflow.ellipsis);
    expect(
      tester.getTopLeft(find.byIcon(Icons.warning_amber_outlined)).dy,
      lessThan(tester.getTopLeft(find.text('Máy hỏng')).dy),
    );
    expect(
      tester.getTopLeft(find.text('Máy hỏng')).dy,
      lessThan(tester.getTopLeft(find.text('3')).dy),
    );
    await tester.tap(find.text('3'));
    expect(tapped, isTrue);
  });

  testWidgets('KpiTile số 0 tự dùng neutral tone', (tester) async {
    await tester.pumpWidget(
      wrap(
        const Scaffold(
          body: KpiTile(label: 'Cảnh báo', value: '0', tone: StatusTone.danger),
        ),
      ),
    );
    final material = tester.widget<Material>(find.byType(Material).last);
    expect(material.color, isNotNull);
  });

  testWidgets('ShortcutTile và AppListTile nhận tap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      wrap(
        Scaffold(
          body: Column(
            children: [
              ShortcutTile(
                icon: Icons.qr_code,
                label: 'Quét',
                onTap: () => taps++,
              ),
              AppListTile(
                icon: Icons.lock_outline,
                title: 'Bảo mật',
                value: 'Bật',
                onTap: () => taps++,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('Quét'));
    await tester.tap(find.text('Bảo mật'));
    expect(taps, 2);
  });

  testWidgets('SegmentTabs đổi lựa chọn', (tester) async {
    var selected = 0;
    await tester.pumpWidget(
      wrap(
        Scaffold(
          body: SegmentTabs<int>(
            tabs: const [
              SegmentTab(value: 0, label: 'Của tôi'),
              SegmentTab(value: 1, label: 'Tất cả'),
            ],
            selected: selected,
            onChanged: (value) => selected = value,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Tất cả'));
    expect(selected, 1);
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
