import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/routes/app_routes.dart';
import '../../core/storage/session_store.dart';
import '../../core/widgets/empty_state.dart';

class NoAccessView extends StatelessWidget {
  const NoAccessView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: EmptyState(
          icon: Icons.phonelink_lock_outlined,
          title: 'auth.noAccess.title'.tr,
          description: 'auth.noAccess.desc'.tr,
          action: FilledButton(
            onPressed: () async {
              await Get.find<SessionStore>().clear(reason: 'manual');
              await Get.offAllNamed(Routes.login);
            },
            child: Text('auth.logout'.tr),
          ),
        ),
      ),
    );
  }
}
