import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:labasset_mobile/core/theme/tokens.dart';
import 'package:labasset_mobile/core/widgets/app_sheet.dart';
import 'package:labasset_mobile/core/widgets/form_focus.dart';

import '../../helpers/test_helpers.dart';

/// Màn có một nút mở sheet qua [open].
Widget host(Future<void> Function(BuildContext) open) => wrap(
  Scaffold(
    body: Builder(
      builder: (context) => Center(
        child: FilledButton(
          onPressed: () => open(context),
          child: const Text('open'),
        ),
      ),
    ),
  ),
);

/// Sheet có [fields] ô nhập (ô cuối đặt lỗi qua [SheetFormState.setError]).
Widget longSheet({required int fields}) => SheetForm(
  builder: (context, form) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SheetHeader(title: 'Form dài'),
      for (var i = 0; i < fields; i++) ...[
        TextField(
          controller: form.field('f$i'),
          focusNode: form.focusNode('f$i'),
          decoration: InputDecoration(
            labelText: 'Ô $i',
            errorText: form.error('f$i'),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
      FilledButton(onPressed: () {}, child: const Text('Lưu')),
    ],
  ),
);

Future<void> openSheet(WidgetTester tester, Widget sheet) async {
  await tester.pumpWidget(
    host((ctx) => AppSheet.show<void>(ctx, builder: (_) => sheet)),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('SheetForm.setError: focus ô lỗi + hiện lỗi dưới ô', (
    tester,
  ) async {
    await openSheet(tester, longSheet(fields: 1));
    final form = tester.state<SheetFormState>(find.byType(SheetForm));

    form.setError('f0', 'Bắt buộc');
    await tester.pumpAndSettle();

    expect(find.text('Bắt buộc'), findsOneWidget);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.focusNode?.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('SheetForm dài: ô lỗi dưới màn được cuộn vào vùng nhìn', (
    tester,
  ) async {
    await openSheet(tester, longSheet(fields: 12));
    final viewport = tester.getRect(find.byType(SingleChildScrollView));
    final field = find.widgetWithText(TextField, 'Ô 11');
    expect(
      tester.getRect(field).top,
      greaterThan(viewport.bottom),
      reason: 'ô lỗi phải đang nằm ngoài vùng nhìn trước khi validate',
    );

    tester
        .state<SheetFormState>(find.byType(SheetForm))
        .setError('f11', 'Bắt buộc');
    await tester.pumpAndSettle();

    final after = tester.getRect(field);
    expect(after.top, greaterThanOrEqualTo(viewport.top - 1));
    expect(after.bottom, lessThanOrEqualTo(viewport.bottom + 1));
    expect(tester.widget<TextField>(field).focusNode?.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('SheetForm dài + bàn phím mở: không tràn, ô lỗi vẫn hiện', (
    tester,
  ) async {
    await openSheet(tester, longSheet(fields: 12));
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.reset);
    await tester.pumpAndSettle();

    tester
        .state<SheetFormState>(find.byType(SheetForm))
        .setError('f11', 'Bắt buộc');
    await tester.pumpAndSettle();

    // Bàn phím (100 px logic) chiếm phần dưới: ô lỗi nằm trong vùng còn thấy.
    final field = tester.getRect(find.widgetWithText(TextField, 'Ô 11'));
    expect(field.bottom, lessThanOrEqualTo(600 - 100));
    expect(tester.takeException(), isNull);
  });

  testWidgets('FormFocus.firstError: ô lỗi đầu tiên, bỏ qua ô hợp lệ', (
    tester,
  ) async {
    final first = FocusNode();
    final valid = FocusNode();
    final last = FocusNode();
    addTearDown(first.dispose);
    addTearDown(valid.dispose);
    addTearDown(last.dispose);
    final formKey = GlobalKey<FormState>();
    String? required(String? v) =>
        (v == null || v.trim().isEmpty) ? 'Bắt buộc' : null;

    await tester.pumpWidget(
      wrap(
        Scaffold(
          body: Form(
            key: formKey,
            child: ListView(
              children: [
                TextFormField(focusNode: first, validator: required),
                TextFormField(
                  focusNode: valid,
                  initialValue: 'đã có',
                  validator: required,
                ),
                TextFormField(focusNode: last, validator: required),
              ],
            ),
          ),
        ),
      ),
    );

    expect(formKey.currentState?.validate(), isFalse);
    await tester.pump();
    expect(FormFocus.firstError([first, valid, last]), isTrue);
    await tester.pumpAndSettle();
    expect(first.hasFocus, isTrue);

    // Ô 1 hợp lệ → lần validate sau focus ô 3 (bỏ qua ô 2).
    await tester.enterText(find.byType(TextFormField).at(0), 'x');
    expect(formKey.currentState?.validate(), isFalse);
    await tester.pump();
    expect(FormFocus.firstError([first, valid, last]), isTrue);
    await tester.pumpAndSettle();
    expect(last.hasFocus, isTrue);

    await tester.enterText(find.byType(TextFormField).at(2), 'y');
    expect(formKey.currentState?.validate(), isTrue);
    expect(FormFocus.firstError([first, valid, last]), isFalse);
    expect(tester.takeException(), isNull);
  });
}
