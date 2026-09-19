import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/tokens.dart';
import 'auth_scaffold.dart';
import 'login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AuthScaffold(
      title: 'auth.login.title'.tr,
      subtitle: 'app.tagline'.tr,
      child: Obx(() {
        if (controller.tenantMode.value == null) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return Form(
          key: controller.formKey,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (controller.notice.value != null) ...[
                  _Banner(
                    text: controller.notice.value!,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (controller.isMulti) ...[
                  TextFormField(
                    controller: controller.hospitalCode,
                    decoration: InputDecoration(
                      labelText: 'auth.login.hospitalCode'.tr,
                    ),
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.organizationName],
                    validator: controller.requiredValidator,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                TextFormField(
                  controller: controller.username,
                  decoration: InputDecoration(
                    labelText: 'auth.login.username'.tr,
                  ),
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  autofillHints: const [AutofillHints.username],
                  validator: controller.requiredValidator,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: controller.password,
                  decoration: InputDecoration(
                    labelText: 'auth.login.password'.tr,
                  ),
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  validator: controller.requiredValidator,
                  onFieldSubmitted: (_) => controller.submit(),
                ),
                if (controller.error.value != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _Banner(
                    text: controller.error.value!,
                    color: theme.colorScheme.error,
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: controller.submitting.value
                      ? null
                      : controller.submit,
                  child: controller.submitting.value
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('auth.login.submit'.tr),
                ),
                TextButton(
                  onPressed: () => Get.toNamed(Routes.forgotPassword),
                  child: Text('auth.login.forgot'.tr),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Text(text, style: TextStyle(color: color)),
      ),
    );
  }
}
