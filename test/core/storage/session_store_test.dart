import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:labasset_mobile/core/storage/session_store.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_helpers.dart';

class MockStorage extends Mock implements FlutterSecureStorage {}

/// Stub secure storage bằng map thật (read/write/delete).
void stubStorage(MockStorage storage, Map<String, String> values) {
  when(
    () => storage.read(key: any(named: 'key')),
  ).thenAnswer((i) async => values[i.namedArguments[#key] as String?]);
  when(
    () => storage.write(
      key: any(named: 'key'),
      value: any(named: 'value'),
    ),
  ).thenAnswer((i) async {
    values[i.namedArguments[#key] as String] =
        i.namedArguments[#value] as String;
  });
  when(
    () => storage.delete(key: any(named: 'key')),
  ).thenAnswer((i) async => values.remove(i.namedArguments[#key] as String?));
}

void main() {
  test('load khôi phục phiên đã lưu (token + user)', () async {
    final storage = MockStorage();
    final values = <String, String>{
      'accessToken': 'A1',
      'refreshToken': 'R1',
      'tenantId': 'T1',
      'user': jsonEncode(fakeUser().toJson()),
    };
    stubStorage(storage, values);

    final store = await SessionStore(storage: storage).load();

    expect(store.isLoggedIn, isTrue);
    expect(store.accessToken, 'A1');
    expect(store.user.value?.username, 'admin');
  });

  test('saveSession ghi token + user để lần sau vào thẳng', () async {
    final storage = MockStorage();
    final values = <String, String>{};
    stubStorage(storage, values);

    final store = SessionStore(storage: storage);
    await store.saveSession(fakeLogin());

    final again = await SessionStore(storage: storage).load();
    expect(again.isLoggedIn, isTrue);
    expect(values['refreshToken'], 'R1');
    expect(values['tenantId'], 'T1');
  });

  test('clear xoá phiên nhưng giữ tuỳ chọn giao diện/sinh trắc', () async {
    final storage = MockStorage();
    final values = <String, String>{
      'accessToken': 'A1',
      'refreshToken': 'R1',
      'tenantId': 'T1',
      'user': jsonEncode(fakeUser().toJson()),
      'biometricEnabled': 'true',
      'themeMode': 'dark',
    };
    stubStorage(storage, values);

    final store = await SessionStore(storage: storage).load();
    await store.clear(reason: 'manual');

    expect(store.isLoggedIn, isFalse);
    expect(values.containsKey('accessToken'), isFalse);
    expect(values['biometricEnabled'], 'true');
    expect(values['themeMode'], 'dark');
  });
}
