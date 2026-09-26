import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/app_buttons.dart';
import 'auth_scaffold.dart';
import 'otp_controller.dart';

class OtpView extends GetView<OtpController> {
  const OtpView({super.key});

  @override
  Widget build(BuildContext context) {
    if (controller.otpToken == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => Get.back());
      return const SizedBox.shrink();
    }
    return AuthScaffold(
      title: 'auth.otp.title'.tr,
      subtitle: 'auth.otp.desc'.tr,
      showBack: true,
      child: Form(
        key: controller.formKey,
        child: Obx(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: controller.code,
                focusNode: controller.codeFocus,
                autofocus: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                autofillHints: const [AutofillHints.oneTimeCode],
                decoration: InputDecoration(
                  labelText: 'auth.otp.code'.tr,
                  counterText: '',
                ),
                validator: controller.validator,
                onFieldSubmitted: (_) => controller.submit(),
              ),
              if (controller.error.value != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  controller.error.value!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              AppButton.primary(
                label: 'auth.otp.submit'.tr,
                loading: controller.submitting.value,
                onPressed: controller.submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
