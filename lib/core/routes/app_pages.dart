import 'package:get/get.dart';

import '../../modules/auth/auth_pages.dart';
import '../../modules/feature_pages.dart';
import '../../modules/account/account_controller.dart';
import '../../modules/home/home_controller.dart';
import '../../modules/placeholder/placeholder_view.dart';
import '../../modules/shell/shell_controller.dart';
import '../../modules/shell/shell_view.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/equipment_repository.dart';
import '../../data/repositories/repairs_repository.dart';
import '../../data/repositories/requests_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/stock_repository.dart';
import '../../data/repositories/tasks_repository.dart';
import '../cache/kv_cache.dart';
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
          () => AccountController(
            store: Get.find<SessionStore>(),
            auth: Get.find<AuthRepository>(),
          ),
        );
        Get.lazyPut(
          () => HomeController(
            store: Get.find<SessionStore>(),
            settings: Get.find<SettingsRepository>(),
            repairs: Get.find<RepairsRepository>(),
            tasks: Get.find<TasksRepository>(),
            requests: Get.find<RequestsRepository>(),
            equipment: Get.find<EquipmentRepository>(),
            stock: Get.find<StockRepository>(),
            cache: Get.find<KvCache>(),
          ),
        );
      }),
    ),
    GetPage(
      name: Routes.placeholder,
      page: () => const PlaceholderView(),
      middlewares: _protected,
    ),
    ...authPages(),
    ...featurePages(),
  ];
}
