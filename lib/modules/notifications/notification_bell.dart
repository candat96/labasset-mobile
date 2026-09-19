import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/routes/app_routes.dart';

class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'notifications.title'.tr,
      icon: const Icon(Icons.notifications_outlined),
      onPressed: () => Get.toNamed(Routes.notifications),
    );
  }
}
