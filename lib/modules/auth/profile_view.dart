import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/storage/session_store.dart';
import '../../core/theme/tokens.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final store = Get.find<SessionStore>();
    return Scaffold(
      appBar: AppBar(title: Text('account.profile'.tr)),
      body: Obx(() {
        final u = store.user.value;
        if (u == null) return const SizedBox.shrink();
        final rows = [
          ('profile.username'.tr, u.username),
          ('profile.fullName'.tr, u.fullName),
          ('profile.email'.tr, u.email ?? '—'),
          ('profile.phone'.tr, u.phone ?? '—'),
          (
            'profile.roles'.tr,
            u.roles.map((r) => 'auth.roles.$r'.tr).join(', '),
          ),
        ];
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Card(
              child: Column(
                children: [
                  for (final (k, v) in rows)
                    ListTile(
                      dense: true,
                      title: Text(
                        k,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      subtitle: Text(
                        v,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}
