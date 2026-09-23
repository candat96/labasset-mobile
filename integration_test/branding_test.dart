import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:labasset_mobile/app.dart';
import 'package:labasset_mobile/core/bootstrap.dart';
import 'package:labasset_mobile/core/routes/app_routes.dart';
import 'package:labasset_mobile/modules/auth/login_controller.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('MedOne branding screenshots', (tester) async {
    await bootstrap();
    await tester.pumpWidget(const MedOneApp());
    await tester.pumpAndSettle(const Duration(seconds: 2));
    if (Get.currentRoute == Routes.login) {
      final c = Get.find<LoginController>();
      c.hospitalCode.text = const String.fromEnvironment('E2E_HOSPITAL_CODE');
      c.username.text = const String.fromEnvironment('E2E_USERNAME');
      c.password.text = const String.fromEnvironment('E2E_PASSWORD');
      await c.submitUnchecked();
      await tester.pumpAndSettle(const Duration(seconds: 3));
    }
    expect(Get.currentRoute, Routes.shell);
    await binding.takeScreenshot('app-home');
    unawaited(Get.toNamed(Routes.scan));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await binding.takeScreenshot('app-scan');
  });
}
