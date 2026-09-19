import 'package:get/get.dart';

import '../../modules/home/home_controller.dart';
import '../../modules/placeholder/placeholder_view.dart';
import '../../modules/shell/shell_controller.dart';
import '../../modules/shell/shell_view.dart';
import '../../data/repositories/settings_repository.dart';
import '../storage/session_store.dart';
import 'app_routes.dart';
import 'middlewares.dart';

/// Nguồn duy nhất cho route + binding + middleware.
class AppPages {
  AppPages._();

  static final List<GetMiddleware> _protected = [
    AuthMiddleware(),
    RoleMiddleware(),
    PasswordMiddleware(),
  ];

  static final pages = <GetPage<dynamic>>[
    GetPage(
      name: Routes.shell,
      page: () => const ShellView(),
      middlewares: _protected,
      binding: BindingsBuilder(() {
        Get.lazyPut(ShellController.new);
        Get.lazyPut(
          () => HomeController(
            store: Get.find<SessionStore>(),
            settings: Get.find<SettingsRepository>(),
          ),
        );
      }),
    ),
    GetPage(
      name: Routes.placeholder,
      page: () => const PlaceholderView(),
      middlewares: _protected,
    ),
    ...authPages,
    ...featurePages,
  ];

  /// Điền ở Task 4–6.
  static List<GetPage<dynamic>> authPages = [];
  static List<GetPage<dynamic>> featurePages = [];
}
