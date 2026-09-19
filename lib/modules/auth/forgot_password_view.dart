import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/config/env.dart';
import '../../core/errors/api_error.dart';
import '../../core/theme/tokens.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_scaffold.dart';

class ForgotPasswordController extends GetxController {
  ForgotPasswordController(this.auth);
  final AuthRepository auth;
  final formKey = GlobalKey<FormState>();
  final hospitalCode = TextEditingController();
  final username = TextEditingController();
  final RxBool submitting = false.obs;
  final RxBool sent = false.obs;
  final RxnString error = RxnString();

  Future<void> submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    submitting.value = true;
    error.value = null;
    try {
      await auth.forgotPassword(
        hospitalCode: Env.isMulti
            ? hospitalCode.text.trim().toUpperCase()
            : null,
        username: username.text.trim(),
      );
      sent.value = true;
    } catch (e) {
      error.value = ApiError.messageFor(e);
    } finally {
      submitting.value = false;
    }
  }

  @override
  void onClose() {
    hospitalCode.dispose();
    username.dispose();
    super.onClose();
  }
}

class ForgotPasswordView extends GetView<ForgotPasswordController> {
  const ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    String? required(String? v) =>
        (v == null || v.trim().isEmpty) ? 'auth.login.required'.tr : null;
    return AuthScaffold(
      title: 'auth.forgot.title'.tr,
      subtitle: 'auth.forgot.desc'.tr,
      showBack: true,
      child: Obx(() {
        if (controller.sent.value) {
          return Text('auth.forgot.sent'.tr);
        }
        return Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (Env.isMulti) ...[
                TextFormField(
                  controller: controller.hospitalCode,
                  decoration: InputDecoration(
                    labelText: 'auth.login.hospitalCode'.tr,
                  ),
                  textCapitalization: TextCapitalization.characters,
                  validator: required,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              TextFormField(
                controller: controller.username,
                decoration: InputDecoration(
                  labelText: 'auth.login.username'.tr,
                ),
                validator: required,
              ),
              if (controller.error.value != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  controller.error.value!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: controller.submitting.value
                    ? null
                    : controller.submit,
                child: Text('auth.forgot.submit'.tr),
              ),
            ],
          ),
        );
      }),
    );
  }
}
