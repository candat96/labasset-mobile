import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:labasset_mobile/core/errors/api_error.dart';
import 'package:labasset_mobile/core/i18n/app_translations.dart';
import 'package:labasset_mobile/data/models/login_result.dart';
import 'package:labasset_mobile/data/repositories/auth_repository.dart';
import 'package:labasset_mobile/modules/auth/login_controller.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_helpers.dart';

class _MockAuth extends Mock implements AuthRepository {}

void main() {
  late _MockAuth auth;
  late LoginController c;

  setUp(() {
    Get.testMode = true;
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('vi', 'VN');
    auth = _MockAuth();
    c = LoginController(
      auth: auth,
      store: fakeStore(),
      push: (_, _) async {},
      replaceAll: (_) async {},
    );
    c.tenantMode.value = 'multi';
  });

  tearDown(Get.reset);

  test('maps AUTH_INVALID_CREDENTIALS to Vietnamese message', () async {
    when(
      () => auth.login(
        hospitalCode: any(named: 'hospitalCode'),
        username: any(named: 'username'),
        password: any(named: 'password'),
        deviceInfo: any(named: 'deviceInfo'),
      ),
    ).thenThrow(ApiError(401, 'AUTH_INVALID_CREDENTIALS', 'nope'));
    c.hospitalCode.text = 'bvdemo';
    c.username.text = 'admin';
    c.password.text = 'x';
    // Không có Form trong test unit → gọi thẳng phần submit sau validate.
    await c.submitUnchecked();
    expect(c.error.value, 'Tài khoản hoặc mật khẩu không đúng');
    final captured = verify(
      () => auth.login(
        hospitalCode: captureAny(named: 'hospitalCode'),
        username: any(named: 'username'),
        password: any(named: 'password'),
        deviceInfo: any(named: 'deviceInfo'),
      ),
    ).captured;
    expect(captured.first, 'BVDEMO');
  });

  test('stores session on success', () async {
    when(
      () => auth.login(
        hospitalCode: any(named: 'hospitalCode'),
        username: any(named: 'username'),
        password: any(named: 'password'),
        deviceInfo: any(named: 'deviceInfo'),
      ),
    ).thenAnswer((_) async => LoggedIn(fakeLogin()));
    c.username.text = 'admin';
    c.password.text = 'x';
    c.hospitalCode.text = 'BVDEMO';
    await c.submitUnchecked();
    expect(c.store.accessToken, 'A1');
    expect(c.error.value, isNull);
  });

  test('OTP challenge does not store session', () async {
    when(
      () => auth.login(
        hospitalCode: any(named: 'hospitalCode'),
        username: any(named: 'username'),
        password: any(named: 'password'),
        deviceInfo: any(named: 'deviceInfo'),
      ),
    ).thenAnswer(
      (_) async =>
          const OtpRequired(OtpChallenge(otpRequired: true, otpToken: 'tok')),
    );
    c.username.text = 'admin';
    c.password.text = 'x';
    c.hospitalCode.text = 'BVDEMO';
    await c.submitUnchecked();
    expect(c.store.accessToken, isNull);
    expect(c.lastOtpToken, 'tok');
  });
}
