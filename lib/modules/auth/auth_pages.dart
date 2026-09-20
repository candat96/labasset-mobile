import 'package:get/get.dart';

import '../../core/routes/app_routes.dart';
import '../../core/routes/middlewares.dart';
import '../../core/storage/session_store.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/settings_repository.dart';
import 'change_password_view.dart';
import 'forgot_password_view.dart';
import 'login_controller.dart';
import 'login_view.dart';
import 'no_access_view.dart';
import 'otp_controller.dart';
import 'otp_view.dart';
import 'profile_view.dart';
import 'sessions_view.dart';

List<GetPage<dynamic>> authPages() => [
  GetPage(
    name: Routes.login,
    page: () => const LoginView(),
    binding: BindingsBuilder(
      () => Get.lazyPut(
        () => LoginController(
          auth: Get.find<AuthRepository>(),
          store: Get.find<SessionStore>(),
          settings: Get.find<SettingsRepository>(),
        ),
      ),
    ),
  ),
  GetPage(
    name: Routes.otp,
    page: () => const OtpView(),
    binding: BindingsBuilder(
      () => Get.lazyPut(
        () => OtpController(
          auth: Get.find<AuthRepository>(),
          store: Get.find<SessionStore>(),
        ),
      ),
    ),
  ),
  GetPage(
    name: Routes.forgotPassword,
    page: () => const ForgotPasswordView(),
    binding: BindingsBuilder(
      () => Get.lazyPut(
        () => ForgotPasswordController(Get.find<AuthRepository>()),
      ),
    ),
  ),
  GetPage(
    name: Routes.changePassword,
    page: () => const ChangePasswordView(),
    middlewares: [AuthMiddleware()],
    binding: BindingsBuilder(
      () => Get.lazyPut(
        () => ChangePasswordController(
          auth: Get.find<AuthRepository>(),
          store: Get.find<SessionStore>(),
        ),
      ),
    ),
  ),
  GetPage(
    name: Routes.sessions,
    page: () => const SessionsView(),
    middlewares: [AuthMiddleware(), PasswordMiddleware()],
    binding: BindingsBuilder(
      () => Get.lazyPut(
        () => SessionsController(
          auth: Get.find<AuthRepository>(),
          store: Get.find<SessionStore>(),
        ),
      ),
    ),
  ),
  GetPage(
    name: Routes.profile,
    page: () => const ProfileView(),
    middlewares: [AuthMiddleware(), PasswordMiddleware()],
  ),
  GetPage(name: Routes.noAccess, page: () => const NoAccessView()),
];
