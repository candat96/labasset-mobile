import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:labasset_mobile/core/theme/tokens.dart';
import 'package:labasset_mobile/core/widgets/app_sheet.dart';
import 'package:labasset_mobile/core/widgets/app_snackbar.dart';
import 'package:labasset_mobile/core/widgets/confirm_sheet.dart';
import 'package:labasset_mobile/core/widgets/picker_sheet.dart';

import '../../helpers/test_helpers.dart';

/// Màn có một nút mở sheet qua [open]; trả kết quả vào [result].
Widget host(Future<Object?> Function(BuildContext) open, List<Object?> result) {
  return wrap(
    Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: FilledButton(
            onPressed: () async => result.add(await open(context)),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('ConfirmSheet mở/đóng không assertion, trả true/false', (
    tester,
  ) async {
    final result = <Object?>[];
    await tester.pumpWidget(
      host(
        (ctx) => ConfirmSheet.show(ctx, title: 'Xoá?', description: 'Mô tả'),
        result,
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Xoá?'), findsOneWidget);
    await tester.tap(find.text('Xác nhận'));
    await tester.pumpAndSettle();
    expect(find.text('Xoá?'), findsNothing);
    expect(result, [true]);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Huỷ'));
    await tester.pumpAndSettle();
    expect(result, [true, false]);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'PickerSheet mở, gõ tìm (bàn phím), chọn rồi đóng không assertion',
    (tester) async {
      final result = <Object?>[];
      await tester.pumpWidget(
        host(
          (ctx) => PickerSheet.show<String>(
            ctx,
            title: 'Chọn máy',
            kind: PickerKind.equipment,
            loader: (_) async => const [
              PickerOption(value: 'e1', code: 'TB-01', name: 'Máy A'),
            ],
          ),
          result,
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      // Bàn phím hiện rồi ẩn trong lúc sheet mở/đóng.
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.reset);
      await tester.enterText(find.byType(TextField), 'TB');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Máy A'));
      tester.view.viewInsets = FakeViewPadding.zero;
      await tester.pumpAndSettle();
      expect(find.text('Chọn máy'), findsNothing);
      expect((result.single as PickerSelection<String>).option?.value, 'e1');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'SheetForm: lưu (snackbar) rồi form.close() → sheet đóng, controller huỷ '
    'sau animation, không assertion',
    (tester) async {
      final result = <Object?>[];
      var saved = '';
      await tester.pumpWidget(
        host(
          (ctx) => AppSheet.show<bool>(
            ctx,
            builder: (_) => SheetForm(
              initial: const {'note': 'ban đầu'},
              builder: (context, form) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SheetHeader(title: 'Đổi trạng thái'),
                  TextField(
                    controller: form.field('note'),
                    autofocus: true,
                    decoration: InputDecoration(errorText: form.error('note')),
                  ),
                  FilledButton(
                    onPressed: () async {
                      if (form.text('note').isEmpty) {
                        form.setError('note', 'Bắt buộc');
                        return;
                      }
                      form.setBusy(true);
                      await Future<void>.delayed(
                        const Duration(milliseconds: 10),
                      );
                      saved = form.text('note');
                      // Snackbar trước khi đóng — trước đây Get.back() bị nuốt.
                      AppSnackbar.success('Đã lưu');
                      form.close(true);
                    },
                    child: const Text('Lưu'),
                  ),
                ],
              ),
            ),
          ),
          result,
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('ban đầu'), findsOneWidget);

      // Lỗi field giữ sheet.
      await tester.enterText(find.byType(TextField), '');
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();
      expect(find.text('Bắt buộc'), findsOneWidget);
      expect(find.text('Đổi trạng thái'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'ghi chú mới');
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.reset);
      await tester.tap(find.text('Lưu'));
      await tester.pump(const Duration(milliseconds: 20));
      tester.view.viewInsets = FakeViewPadding.zero;
      await tester.pumpAndSettle();
      expect(find.text('Đổi trạng thái'), findsNothing);
      expect(find.text('Đã lưu'), findsOneWidget);
      expect(saved, 'ghi chú mới');
      expect(result, [true]);
      expect(tester.takeException(), isNull);

      // Get.back() vẫn pop được khi toast đang hiện.
      expect(Get.isSnackbarOpen, isFalse);
      await tester.pump(const Duration(seconds: 4));
      expect(find.text('Đã lưu'), findsNothing);
    },
  );

  testWidgets('AppSheet: nền trắng, bo 16 hai góc trên, footer dính đáy', (
    tester,
  ) async {
    final result = <Object?>[];
    await tester.pumpWidget(
      host(
        (ctx) => AppSheet.show<void>(
          ctx,
          builder: (_) => const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Nội dung sheet'),
          ),
          footer: (_) => const SheetActionBar(primary: Text('Lưu')),
        ),
        result,
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final sheet = tester.widget<BottomSheet>(find.byType(BottomSheet));
    expect(sheet.backgroundColor, AppColors.card);
    final shape = sheet.shape! as RoundedRectangleBorder;
    expect(
      shape.borderRadius,
      const BorderRadius.vertical(top: Radius.circular(16)),
    );
    expect(AppRadius.sheetTop, 16);
    expect(find.text('Nội dung sheet'), findsOneWidget);
    expect(find.text('Lưu'), findsOneWidget);
  });

  testWidgets('AppDialog.prompt trả chuỗi, huỷ trả null', (tester) async {
    final result = <Object?>[];
    await tester.pumpWidget(
      host((ctx) => AppDialog.prompt(ctx, title: 'Người ký'), result),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu'));
    await tester.pump();
    expect(find.text('Bắt buộc'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Nguyễn A');
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    expect(result, ['Nguyễn A']);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Huỷ'));
    await tester.pumpAndSettle();
    expect(result, ['Nguyễn A', null]);
    expect(tester.takeException(), isNull);
  });
}
