import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'core/i18n/app_translations.dart';
import 'core/theme/app_theme.dart';

class LabAssetApp extends StatelessWidget {
  const LabAssetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'LabAsset',
      debugShowCheckedModeBanner: false,
      translations: AppTranslations(),
      locale: const Locale('vi', 'VN'),
      fallbackLocale: const Locale('vi', 'VN'),
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: Scaffold(body: Center(child: Text('app.name'.tr))),
    );
  }
}
