import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:labasset_mobile/core/routes/app_routes.dart';
import 'package:labasset_mobile/core/routes/middlewares.dart';
import 'package:labasset_mobile/core/storage/session_store.dart';

import '../../helpers/test_helpers.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  SessionStore loggedIn(List<String> roles) => fakeStore()
    ..accessToken = 'A1'
    ..user.value = fakeUser(roles: roles);

  test('DEPT_HEAD được vào app sau khi mở allowedRoles', () {
    Get.put<SessionStore>(loggedIn(const ['DEPT_HEAD']));
    expect(RoleMiddleware().redirect(Routes.shell), isNull);
  });

  test('DEPT_USER được vào app', () {
    Get.put<SessionStore>(loggedIn(const ['DEPT_USER']));
    expect(RoleMiddleware().redirect(Routes.shell), isNull);
  });

  test('vai trò lạ vẫn bị đưa tới màn không có quyền', () {
    Get.put<SessionStore>(loggedIn(const ['NURSE']));
    expect(RoleMiddleware().redirect(Routes.shell)?.name, Routes.noAccess);
  });
}
