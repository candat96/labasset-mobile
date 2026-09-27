import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:labasset_mobile/data/models/signing.dart';
import 'package:labasset_mobile/data/repositories/signing_repository.dart';
import 'package:labasset_mobile/modules/signing/signing_profile_controller.dart';
import 'package:labasset_mobile/modules/signing/signing_profile_view.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_helpers.dart';

class _MockSigning extends Mock implements SigningRepository {}

void main() {
  tearDown(Get.reset);

  testWidgets('configured == false → báo chưa cấu hình nhà cung cấp ký số', (
    tester,
  ) async {
    final repo = _MockSigning();
    when(() => repo.profile()).thenAnswer(
      (_) async =>
          const SigningProfileResponse(profile: null, configured: false),
    );
    final c = Get.put(SigningProfileController(repo: repo));
    await tester.pumpWidget(wrap(const SigningProfileView()));
    await tester.pumpAndSettle();

    expect(
      find.text('Bệnh viện chưa cấu hình nhà cung cấp ký số'),
      findsOneWidget,
    );
    expect(c.configured.value, isFalse);
  });

  testWidgets(
    'configured == true → hiện ô tên đăng nhập, không điền mật khẩu',
    (tester) async {
      final repo = _MockSigning();
      when(() => repo.profile()).thenAnswer(
        (_) async => SigningProfileResponse(
          profile: SigningProfile(
            userId: 'u1',
            providerKey: 'intrust',
            username: 'ICA.1',
            credentialId: 'k1',
            certSerial: 'S1',
            certSubject: 'CN=A',
            certValidFrom: '2025-01-01T00:00:00.000Z',
            certValidTo: '2030-01-01T00:00:00.000Z',
            rememberPin: true,
            expiringSoon: false,
            passwordSet: true,
            pinSet: true,
          ),
          configured: true,
        ),
      );
      final c = Get.put(SigningProfileController(repo: repo));
      await tester.pumpWidget(wrap(const SigningProfileView()));
      await tester.pumpAndSettle();

      expect(find.textContaining('Tên đăng nhập'), findsOneWidget);
      expect(c.username.text, 'ICA.1');
      // Không bao giờ hiển thị lại mật khẩu/PIN đã lưu.
      expect(c.password.text, isEmpty);
      expect(c.pin.text, isEmpty);
    },
  );
}
