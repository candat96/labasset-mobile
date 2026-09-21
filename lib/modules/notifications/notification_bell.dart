import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/routes/app_routes.dart';
import 'notifications_controller.dart';

class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key, this.color});

  /// Màu icon (trắng khi đặt trên hero gradient).
  final Color? color;

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
          child: Icon(LucideIcons.bell, color: color),
        ),
        onPressed: () => Get.toNamed(Routes.notifications),
      );
    });
  }
}
