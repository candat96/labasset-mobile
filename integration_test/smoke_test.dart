// Smoke trên API dev thật. Chạy:
//   flutter test integration_test -d <device> \
//     --dart-define=API_URL=http://<ip-lan>:3000 --dart-define=E2E_PASSWORD=... \
//     --dart-define=E2E_HOSPITAL_CODE=BVDEMO --dart-define=E2E_USERNAME=admin --dart-define=E2E_EQUIPMENT_CODE=<mã máy>
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:labasset_mobile/app.dart';
import 'package:labasset_mobile/core/bootstrap.dart';

const _password = String.fromEnvironment('E2E_PASSWORD');
const _hospital = String.fromEnvironment(
  'E2E_HOSPITAL_CODE',
  defaultValue: 'BVDEMO',
);
const _username = String.fromEnvironment('E2E_USERNAME', defaultValue: 'admin');
const _equipmentCode = String.fromEnvironment('E2E_EQUIPMENT_CODE');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('login → home → nhập mã máy → hồ sơ máy', (tester) async {
    if (_password.isEmpty) {
      markTestSkipped('E2E_PASSWORD chưa đặt');
      return;
    }
    await bootstrap();
    await tester.pumpWidget(const LabAssetApp());
    await tester.pumpAndSettle(const Duration(seconds: 2));

    final hospital = find.widgetWithText(TextFormField, 'Mã bệnh viện');
    if (hospital.evaluate().isNotEmpty) {
      await tester.enterText(hospital, _hospital);
    }
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Tài khoản'),
      _username,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Mật khẩu'),
      _password,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.text('Việc của tôi hôm nay'), findsOneWidget);

    if (_equipmentCode.isEmpty) return;
    await tester.tap(find.byIcon(Icons.qr_code_scanner));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await tester.enterText(
      find.widgetWithText(TextField, 'Nhập mã tay'),
      _equipmentCode,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Tra cứu'));
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.text('Hồ sơ máy'), findsOneWidget);
  });
}
