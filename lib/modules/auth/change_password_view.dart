import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/errors/api_error.dart';
import '../../core/routes/app_routes.dart';
import '../../core/storage/session_store.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/form_focus.dart';
import '../../data/repositories/auth_repository.dart';

class ChangePasswordController extends GetxController {
  ChangePasswordController({required this.auth, required this.store});
  final AuthRepository auth;
  final SessionStore store;
  final formKey = GlobalKey<FormState>();
  final current = TextEditingController();
  final next = TextEditingController();
  final confirm = TextEditingController();
  final currentFocus = FocusNode();
  final nextFocus = FocusNode();
  final confirmFocus = FocusNode();
  final RxBool submitting = false.obs;
  final RxnString error = RxnString();

  static final _rule = RegExp(r'^(?=.*[A-Za-z])(?=.*\d).{8,}$');

  String? currentValidator(String? v) =>
      (v == null || v.isEmpty) ? 'auth.login.required'.tr : null;
  String? nextValidator(String? v) =>
      _rule.hasMatch(v ?? '') ? null : 'auth.change.rule'.tr;
  String? confirmValidator(String? v) =>
      v == next.text ? null : 'auth.change.mismatch'.tr;

  Future<void> submit() async {
    if (!(formKey.currentState?.validate() ?? false)) {
      FormFocus.firstError([currentFocus, nextFocus, confirmFocus]);
      return;
    }
    submitting.value = true;
    error.value = null;
    try {
      await auth.changePassword(current.text, next.text);
      AppSnackbar.success('auth.change.success'.tr);
      // API thu hồi mọi phiên → đăng nhập lại.
      await store.clear(reason: 'password-changed');
      await Get.offAllNamed(
        Routes.login,
        arguments: {'reason': 'password-changed'},
      );
    } catch (e) {
      error.value = ApiError.messageFor(e);
    } finally {
      submitting.value = false;
    }
  }

  @override
  void onClose() {
    current.dispose();
    next.dispose();
    confirm.dispose();
    currentFocus.dispose();
    nextFocus.dispose();
    confirmFocus.dispose();
    super.onClose();
  }
}

class ChangePasswordView extends GetView<ChangePasswordController> {
  const ChangePasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final must = controller.store.user.value?.mustChangePassword == true;
    return Scaffold(
      appBar: AppBar(
        title: Text('auth.change.title'.tr),
        automaticallyImplyLeading: !must,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: controller.formKey,
          child: Obx(
            () => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (must) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Text('auth.change.mustChange'.tr),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                TextFormField(
                  controller: controller.current,
                  focusNode: controller.currentFocus,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'auth.change.current'.tr,
                  ),
                  validator: controller.currentValidator,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: controller.next,
                  focusNode: controller.nextFocus,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'auth.change.next'.tr,
                    helperText: 'auth.change.rule'.tr,
                  ),
                  validator: controller.nextValidator,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: controller.confirm,
                  focusNode: controller.confirmFocus,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'auth.change.confirm'.tr,
                  ),
                  validator: controller.confirmValidator,
                ),
                if (controller.error.value != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    controller.error.value!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: controller.submitting.value
                      ? null
                      : controller.submit,
                  child: Text('auth.change.submit'.tr),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
