import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:labasset_mobile/core/widgets/date_field.dart';
import 'package:labasset_mobile/core/widgets/money_field.dart';
import 'package:labasset_mobile/core/widgets/qty_field.dart';

import '../../helpers/test_helpers.dart';

void main() {
  testWidgets('QtyField nhận số thập phân , và .', (tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(
      wrap(
        Scaffold(
          body: Form(
            child: QtyField(controller: controller, label: 'Số lượng'),
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField), '10,5');
    final field = tester.widget<QtyField>(find.byType(QtyField));
    expect(field.value, Decimal.parse('10.5'));
    await tester.enterText(find.byType(TextFormField), '3.25');
    expect(field.value, Decimal.parse('3.25'));
  });

  testWidgets('QtyField báo lỗi khi trống/sai', (tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(
      wrap(
        Scaffold(
          body: Form(child: QtyField(controller: controller)),
        ),
      ),
    );
    await tester.pump();
    // Gọi validate trực tiếp qua form state.
    final form = tester.state<FormState>(find.byType(Form));
    expect(form.validate(), isFalse);
    await tester.pump();
    expect(find.text('Nhập số lượng'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), '..');
    expect(
      controller.text,
      isNotEmpty,
    ); // formatter cho phép nhưng validate chặn
    expect(form.validate(), isFalse);
    await tester.pump();
    expect(find.text('Số lượng không hợp lệ'), findsOneWidget);
  });

  testWidgets('MoneyField nhóm nghìn khi gõ, raw() bỏ dấu', (tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(
      wrap(Scaffold(body: MoneyField(controller: controller))),
    );
    await tester.enterText(find.byType(TextFormField), '1500000');
    expect(controller.text, '1.500.000');
    expect(MoneyField.raw(controller.text), '1500000');

    final field = tester.widget<MoneyField>(find.byType(MoneyField));
    expect(field.value, '1500000');
  });

  testWidgets('MoneyField bắt buộc khi required', (tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(
      wrap(
        Scaffold(
          body: Form(child: MoneyField(controller: controller, required: true)),
        ),
      ),
    );
    final form = tester.state<FormState>(find.byType(Form));
    expect(form.validate(), isFalse);
    await tester.pump();
    expect(find.text('Nhập số tiền'), findsOneWidget);
  });

  test('DateField.toIso chuyển dd/MM/yyyy → ISO', () {
    expect(DateField.toIso('19/09/2026'), '2026-09-19');
    expect(DateField.toIso('1/2/2026'), '2026-02-01');
    expect(DateField.toIso(''), isNull);
    expect(DateField.toIso('sai'), isNull);
  });

  testWidgets('DateField validate và mở date picker', (tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(
      wrap(
        Scaffold(
          body: Form(child: DateField(controller: controller, required: true)),
        ),
      ),
    );
    final form = tester.state<FormState>(find.byType(Form));
    expect(form.validate(), isFalse);
    await tester.pump();
    expect(find.text('Chọn ngày'), findsOneWidget);

    await tester.tap(find.byType(TextFormField));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(controller.text, matches(RegExp(r'^\d{2}/\d{2}/\d{4}$')));
  });
}
