import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/routes/app_routes.dart';
import 'notifications_controller.dart';

class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<NotificationsController>();
    return Obx(() {
      final n = c.unreadCount.value;
      return IconButton(
        tooltip: 'notifications.title'.tr + (n > 0 ? ' ($n)' : ''),
        icon: Badge(
          isLabelVisible: n > 0,
          label: Text(n > 99 ? '99+' : '$n'),
          child: const Icon(Icons.notifications_outlined),
        ),
        onPressed: () => Get.toNamed(Routes.notifications),
      );
    });
  }
}
