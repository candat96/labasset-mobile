import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:labasset_mobile/core/widgets/picker_sheet.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../helpers/test_helpers.dart';

void main() {
  testWidgets('PickerSheet tìm kiếm (debounce) và trả lựa chọn', (
    tester,
  ) async {
    final queries = <String>[];
    PickerSelection<String>? selection;

    await tester.pumpWidget(
      wrap(
        Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () async {
                  selection = await PickerSheet.show<String>(
                    context,
                    title: 'Chọn khoa',
                    loader: (q) async {
                      queries.add(q);
                      if (q.isEmpty) {
                        return const [
                          PickerOption(
                            value: 'd1',
                            code: 'XN',
                            name: 'Khoa XN',
                          ),
                          PickerOption(
                            value: 'd2',
                            code: 'VTTB',
                            name: 'Vật tư',
                          ),
                        ];
                      }
                      return const [
                        PickerOption(value: 'd2', code: 'VTTB', name: 'Vật tư'),
                      ];
                    },
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Khoa XN'), findsOneWidget);
    expect(find.text('XN'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'VT');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(queries.last, 'VT');
    expect(find.text('Vật tư'), findsOneWidget);
    expect(find.text('VTTB'), findsOneWidget);

    await tester.tap(find.text('Vật tư'));
    await tester.pumpAndSettle();
    expect(selection?.option?.value, 'd2');
    expect(selection?.cleared, isFalse);
  });

  testWidgets('PickerSheet hiện thông tin phụ và check mục đã chọn', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () => PickerSheet.show<String>(
                context,
                title: 'Chọn vật tư',
                kind: PickerKind.supply,
                selected: 's1',
                loader: (_) async => const [
                  PickerOption(
                    value: 's1',
                    code: 'VT-01',
                    name: 'Hoá chất A',
                    subtitle: 'Tồn 12 · chai',
                  ),
                ],
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Hoá chất A'), findsOneWidget);
    expect(find.text('VT-01 · Tồn 12 · chai'), findsOneWidget);
    expect(find.byIcon(LucideIcons.check), findsOneWidget);
  });

  testWidgets('PickerSheet bỏ chọn trả cleared', (tester) async {
    PickerSelection<String>? selection;
    await tester.pumpWidget(
      wrap(
        Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () async {
                  selection = await PickerSheet.show<String>(
                    context,
                    title: 'Chọn',
                    showClear: true,
                    loader: (_) async => const [],
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bỏ chọn'));
    await tester.pumpAndSettle();
    expect(selection?.cleared, isTrue);
    expect(selection?.option, isNull);
  });
}
