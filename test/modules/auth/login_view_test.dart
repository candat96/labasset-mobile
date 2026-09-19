import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:labasset_mobile/core/config/env.dart';
import 'package:labasset_mobile/data/repositories/auth_repository.dart';
import 'package:labasset_mobile/modules/auth/login_controller.dart';
import 'package:labasset_mobile/modules/auth/login_view.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_helpers.dart';

class _MockAuth extends Mock implements AuthRepository {}

void main() {
  tearDown(() {
    Env.tenantMode.value = null;
    Get.reset();
  });

  Future<LoginController> pump(WidgetTester tester, String mode) async {
    Env.tenantMode.value = mode;
    final c = LoginController(auth: _MockAuth(), store: fakeStore());
    Get.put(c);
    await tester.pumpWidget(wrap(const LoginView()));
    await tester.pumpAndSettle();
    return c;
  }

  testWidgets('multi mode shows hospital code field', (tester) async {
    await pump(tester, 'multi');
    expect(find.text('Mã bệnh viện'), findsOneWidget);
    expect(find.text('Tài khoản'), findsOneWidget);
  });

  testWidgets('single mode hides hospital code and validates required', (
    tester,
  ) async {
    await pump(tester, 'single');
    expect(find.text('Mã bệnh viện'), findsNothing);
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pumpAndSettle();
    expect(find.text('Bắt buộc'), findsNWidgets(2));
  });
}
