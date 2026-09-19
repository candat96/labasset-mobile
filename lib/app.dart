import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'core/i18n/app_translations.dart';
import 'core/routes/app_pages.dart';
import 'core/routes/app_routes.dart';
import 'core/storage/session_store.dart';
import 'core/theme/app_theme.dart';

class LabAssetApp extends StatelessWidget {
  const LabAssetApp({super.key});

  @override
  Widget build(BuildContext context) {
    final store = Get.find<SessionStore>();
    return Obx(
      () => GetMaterialApp(
        title: 'LabAsset',
        debugShowCheckedModeBanner: false,
        translations: AppTranslations(),
        locale: const Locale('vi', 'VN'),
        fallbackLocale: const Locale('vi', 'VN'),
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: store.themeMode.value,
        initialRoute: store.isLoggedIn ? Routes.shell : Routes.login,
        getPages: AppPages.pages,
        defaultTransition: Transition.cupertino,
      ),
    );
  }
}
