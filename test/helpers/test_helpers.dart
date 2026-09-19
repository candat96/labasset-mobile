import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:labasset_mobile/core/cache/kv_cache.dart';
import 'package:labasset_mobile/core/i18n/app_translations.dart';
import 'package:labasset_mobile/core/storage/session_store.dart';
import 'package:labasset_mobile/core/theme/app_theme.dart';
import 'package:labasset_mobile/data/models/login_result.dart';
import 'package:labasset_mobile/data/models/user_view.dart';
import 'package:mocktail/mocktail.dart';

class MockStorage extends Mock implements FlutterSecureStorage {}

class FakeKvCache implements KvCache {
  final Map<String, CachedValue> store = {};

  @override
  Future<void> init() async {}

  @override
  Future<void> put(String key, Map<String, dynamic> value) async {
    store[key] = CachedValue(value, DateTime.now());
  }

  @override
  Future<CachedValue?> get(String key) async => store[key];

  @override
  Future<void> delete(String key) async => store.remove(key);
}

SessionStore fakeStore() {
  final storage = MockStorage();
  when(
    () => storage.read(key: any(named: 'key')),
  ).thenAnswer((_) async => null);
  when(
    () => storage.write(
      key: any(named: 'key'),
      value: any(named: 'value'),
    ),
  ).thenAnswer((_) async {});
  when(() => storage.delete(key: any(named: 'key'))).thenAnswer((_) async {});
  return SessionStore(storage: storage);
}

UserView fakeUser({
  List<String> roles = const ['HOSPITAL_ADMIN'],
  bool mustChange = false,
}) => UserView(
  id: 'u1',
  username: 'admin',
  fullName: 'Quản trị viên',
  roles: roles,
  mustChangePassword: mustChange,
);

LoginResult fakeLogin({List<String> roles = const ['HOSPITAL_ADMIN']}) =>
    LoginResult(
      accessToken: 'A1',
      refreshToken: 'R1',
      tenantId: 'T1',
      user: fakeUser(roles: roles),
    );

/// Bọc widget trong GetMaterialApp có theme + i18n để test.
Widget wrap(Widget child, {List<GetPage<dynamic>> pages = const []}) =>
    GetMaterialApp(
      translations: AppTranslations(),
      locale: const Locale('vi', 'VN'),
      theme: AppTheme.light(),
      home: child,
      getPages: pages,
    );
