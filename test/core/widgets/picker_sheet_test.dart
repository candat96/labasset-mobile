import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:labasset_mobile/core/widgets/picker_sheet.dart';

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
    expect(find.text('XN — Khoa XN'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'VT');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(queries.last, 'VT');
    expect(find.text('VTTB — Vật tư'), findsOneWidget);

    await tester.tap(find.text('VTTB — Vật tư'));
    await tester.pumpAndSettle();
    expect(selection?.option?.value, 'd2');
    expect(selection?.cleared, isFalse);
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
