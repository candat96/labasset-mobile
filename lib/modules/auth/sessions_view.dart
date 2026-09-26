import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:get/get.dart';

import '../../core/format/format.dart';
import '../../core/routes/app_routes.dart';
import '../../core/storage/session_store.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/confirm_sheet.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_list.dart';
import '../../data/models/session_view.dart';
import '../../data/repositories/auth_repository.dart';

class SessionsController extends GetxController {
  SessionsController({required this.auth, required this.store});
  final AuthRepository auth;
  final SessionStore store;

  final RxList<SessionView> items = <SessionView>[].obs;
  final RxBool loading = true.obs;
  final Rxn<Object> error = Rxn<Object>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      items.assignAll(await auth.sessions());
    } catch (e) {
      error.value = e;
    } finally {
      loading.value = false;
    }
  }

  Future<void> revoke(BuildContext context, SessionView s) async {
    final ok = await ConfirmSheet.show(
      context,
      title: 'auth.sessions.revoke'.tr,
      description: s.deviceInfo ?? 'auth.sessions.unknownDevice'.tr,
      destructive: true,
    );
    if (!ok) return;
    try {
      await auth.revokeSession(s.id);
      await load();
    } catch (e) {
      AppSnackbar.error(e);
    }
  }

  Future<void> revokeAll(BuildContext context) async {
    final ok = await ConfirmSheet.show(
      context,
      title: 'auth.sessions.revokeAll'.tr,
      description: 'auth.sessions.revokeAllDesc'.tr,
      destructive: true,
    );
    if (!ok) return;
    try {
      await auth.logout(all: true, refreshToken: store.refreshToken);
    } catch (_) {
      // best-effort
    }
    await store.clear(reason: 'manual');
    await Get.offAllNamed(Routes.login);
  }
}

class SessionsView extends GetView<SessionsController> {
  const SessionsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('auth.sessions.title'.tr),
        actions: [
          AppButton.soft(
            tone: AppButtonTone.danger,
            label: 'auth.sessions.revokeAll'.tr,
            onPressed: () => controller.revokeAll(context),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.loading.value) return const LoadingList();
        if (controller.error.value != null) {
          return ErrorState(
            error: controller.error.value!,
            onRetry: controller.load,
          );
        }
        if (controller.items.isEmpty) {
          return EmptyState(title: 'common.empty'.tr);
        }
        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: controller.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (_, i) {
              final s = controller.items[i];
              return AppCard(
                padding: EdgeInsets.zero,
                child: ListTile(
                  title: Text(
                    s.deviceInfo ?? 'auth.sessions.unknownDevice'.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${s.ip ?? '—'} · ${'auth.sessions.lastUsed'.tr}: '
                    '${s.lastUsedAt != null ? formatRelative(s.lastUsedAt) : '—'}\n'
                    '${'auth.sessions.expires'.tr}: ${formatDateTime(s.expiresAt)}',
                  ),
                  isThreeLine: true,
                  trailing: AppIconButton(
                    icon: LucideIcons.logOut,
                    tooltip: 'auth.sessions.revoke'.tr,
                    tone: AppButtonTone.danger,
                    onPressed: () => controller.revoke(context, s),
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
