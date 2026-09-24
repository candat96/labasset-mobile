import 'package:flutter_test/flutter_test.dart';
import 'package:labasset_mobile/core/errors/api_error.dart';
import 'package:labasset_mobile/core/network/session_check.dart';
import 'package:labasset_mobile/core/storage/session_store.dart';
import 'package:labasset_mobile/data/repositories/auth_repository.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_helpers.dart';

class _MockAuth extends Mock implements AuthRepository {}

void main() {
  late _MockAuth auth;
  late SessionStore store;

  setUp(() {
    auth = _MockAuth();
    store = fakeStore()
      ..accessToken = 'A1'
      ..refreshToken = 'R1'
      ..tenantId = 'T1'
      ..user.value = fakeUser();
  });

  test('token còn hạn: cập nhật user mới nhất từ GET /me, giữ phiên', () async {
    when(
      () => auth.me(),
    ).thenAnswer((_) async => fakeUser(roles: ['EQUIPMENT_STAFF']));

    await validateSession(store: store, auth: auth);

    expect(store.isLoggedIn, isTrue);
    expect(store.user.value?.roles, ['EQUIPMENT_STAFF']);
  });

  test('token hết hạn (401): không ném, phiên do interceptor xử lý', () async {
    when(() => auth.me()).thenThrow(ApiError(401, 'UNAUTHORIZED', 'hết hạn'));

    await validateSession(store: store, auth: auth);

    expect(store.accessToken, 'A1');
  });

  test('mất mạng: giữ phiên đã lưu để dùng offline', () async {
    when(() => auth.me()).thenThrow(ApiError(0, 'NETWORK_ERROR', 'offline'));

    await validateSession(store: store, auth: auth);

    expect(store.isLoggedIn, isTrue);
    expect(store.accessToken, 'A1');
  });

  test('chưa đăng nhập: không gọi /me', () async {
    store.accessToken = null;
    store.user.value = null;

    await validateSession(store: store, auth: auth);

    verifyNever(() => auth.me());
  });
}
