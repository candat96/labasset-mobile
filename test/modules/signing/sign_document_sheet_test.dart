import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:labasset_mobile/core/errors/api_error.dart';
import 'package:labasset_mobile/data/models/signing.dart';
import 'package:labasset_mobile/data/repositories/signing_repository.dart';
import 'package:labasset_mobile/modules/signing/sign_document_sheet.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_helpers.dart';

class _MockSigning extends Mock implements SigningRepository {}

SigningProfile _profile({bool passwordSet = true, bool pinSet = true}) =>
    SigningProfile(
      userId: 'u1',
      providerKey: 'intrust',
      username: 'ICA.0108357319',
      credentialId: 'key-1',
      certSerial: 'SER-1',
      certSubject: 'CN=Nguyễn Văn A',
      certValidFrom: '2025-01-01T00:00:00.000Z',
      certValidTo: '2030-01-01T00:00:00.000Z',
      rememberPin: false,
      expiringSoon: false,
      passwordSet: passwordSet,
      pinSet: pinSet,
    );

Future<void> _pumpSheet(
  WidgetTester tester,
  _MockSigning repo, {
  bool passwordSet = true,
  bool pinSet = true,
}) async {
  when(() => repo.profile()).thenAnswer(
    (_) async => SigningProfileResponse(
      profile: _profile(passwordSet: passwordSet, pinSet: pinSet),
      configured: true,
    ),
  );
  await tester.pumpWidget(
    wrap(
      SignDocumentSheet(
        key: UniqueKey(),
        repo: repo,
        docType: SigningDocType.repairCompletion,
        id: 'r1',
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  tearDown(Get.reset);

  testWidgets('chặn bấm ký hai lần — lệnh ký chỉ chạy một lần', (tester) async {
    final repo = _MockSigning();
    final pending = Completer<SignResult>();
    when(
      () => repo.sign(
        any(),
        any(),
        slot: any(named: 'slot'),
        password: any(named: 'password'),
        pin: any(named: 'pin'),
      ),
    ).thenAnswer((_) => pending.future);

    await _pumpSheet(tester, repo);

    // Hai lần bấm liên tiếp không chờ dựng lại cây: lần thứ hai phải bị chặn.
    await tester.tap(find.text('Ký số'));
    await tester.tap(find.text('Ký số'));
    await tester.pump();

    verify(
      () => repo.sign(
        any(),
        any(),
        slot: any(named: 'slot'),
        password: any(named: 'password'),
        pin: any(named: 'pin'),
      ),
    ).called(1);
  });

  testWidgets('ô PIN chỉ hiện khi pinSet == false', (tester) async {
    final repo = _MockSigning();
    await _pumpSheet(tester, repo, pinSet: false);
    expect(find.textContaining('Mã PIN'), findsOneWidget);

    final repo2 = _MockSigning();
    await _pumpSheet(tester, repo2, pinSet: true);
    expect(find.textContaining('Mã PIN'), findsNothing);
  });

  testWidgets('lỗi SIGNING_PIN_REQUIRED hiện thông báo tiếng Việt', (
    tester,
  ) async {
    final repo = _MockSigning();
    when(
      () => repo.sign(
        any(),
        any(),
        slot: any(named: 'slot'),
        password: any(named: 'password'),
        pin: any(named: 'pin'),
      ),
    ).thenThrow(ApiError(400, 'SIGNING_PIN_REQUIRED', 'Cần mã PIN để ký'));

    await _pumpSheet(tester, repo);

    await tester.tap(find.text('Ký số'));
    await tester.pumpAndSettle();

    expect(find.text('Cần mã PIN để ký'), findsOneWidget);
  });
}
