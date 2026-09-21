import 'package:get/get.dart';

import '../../modules/auth/auth_pages.dart';
import '../../modules/feature_pages.dart';
import '../../modules/account/account_controller.dart';
import '../../modules/account/my_stats_controller.dart';
import '../../modules/home/home_controller.dart';
import '../../modules/placeholder/placeholder_view.dart';
import '../../modules/repairs/repairs_controller.dart';
import '../../modules/stock/stock_overview_controller.dart';
import '../../modules/shell/shell_controller.dart';
import '../../modules/shell/shell_view.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/me_repository.dart';
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
            me: Get.find<MeRepository>(),
            settings: Get.find<SettingsRepository>(),
            cache: Get.find<KvCache>(),
          ),
        );
        Get.lazyPut(
          () => RepairsController(
            repairs: Get.find<RepairsRepository>(),
            userId: Get.find<SessionStore>().user.value?.id ?? '',
          ),
        );
        Get.lazyPut(
          () => StockOverviewController(
            stock: Get.find<StockRepository>(),
            requests: Get.find<RequestsRepository>(),
          ),
        );
        Get.lazyPut(
          () => MyStatsController(
            repairs: Get.find<RepairsRepository>(),
            tasks: Get.find<TasksRepository>(),
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
