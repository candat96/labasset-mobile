import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../storage/session_store.dart';
import 'app_routes.dart';

/// Chưa đăng nhập → /login (giữ đường về).
class AuthMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    final store = Get.find<SessionStore>();
    if (!store.isLoggedIn) {
      return RouteSettings(name: Routes.login, arguments: {'returnTo': route});
    }
    return null;
  }
}

/// User ngoài phòng Vật tư – TBYT không dùng app.
class RoleMiddleware extends GetMiddleware {
  @override
  int? get priority => 2;

  @override
  RouteSettings? redirect(String? route) {
    final store = Get.find<SessionStore>();
    if (store.isLoggedIn && !store.hasRole(Routes.allowedRoles)) {
      return const RouteSettings(name: Routes.noAccess);
    }
    return null;
  }
}

/// API không chặn khi mustChangePassword; app ép đổi trước.
class PasswordMiddleware extends GetMiddleware {
  @override
  int? get priority => 3;

  @override
  RouteSettings? redirect(String? route) {
    final store = Get.find<SessionStore>();
    if (store.user.value?.mustChangePassword == true &&
        route != Routes.changePassword) {
      return const RouteSettings(name: Routes.changePassword);
    }
    return null;
  }
}
