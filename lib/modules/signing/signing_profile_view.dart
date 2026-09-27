import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/format/format.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_list_tile.dart';
import '../../core/widgets/app_sheet.dart';
import '../../core/widgets/confirm_sheet.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/field_shell.dart';
import '../../core/widgets/loading_list.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/status_badge.dart';
import '../../data/models/signing.dart';
import 'signing_profile_controller.dart';

/// Màn Cài đặt chữ ký số của tài khoản: tài khoản, mật khẩu, PIN, nhớ PIN,
/// tra và chọn chứng thư, đăng xuất phiên nhà cung cấp.
class SigningProfileView extends GetView<SigningProfileController> {
  const SigningProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('signing.title'.tr)),
      body: Obx(() {
        if (controller.loading.value && controller.profile.value == null) {
          return const LoadingList();
        }
        final err = controller.error.value;
        if (err != null && controller.profile.value == null) {
          return ErrorState(error: err, onRetry: controller.load);
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          children: [
            if (!controller.configured.value) const _NotConfiguredBanner(),
            if (controller.configured.value) ...[
              _AccountCard(controller: controller),
              const SizedBox(height: AppSpacing.md),
              _CertificateCard(controller: controller),
              const SizedBox(height: AppSpacing.md),
              _SessionCard(controller: controller),
            ],
          ],
        );
      }),
    );
  }
}

class _NotConfiguredBanner extends StatelessWidget {
  const _NotConfiguredBanner();

  @override
  Widget build(BuildContext context) {
    final status = context.status;
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.alertTriangle, color: status.warning, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'signing.notConfigured'.tr,
              style: context.appText.body,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.controller});
  final SigningProfileController controller;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'signing.account'.tr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FieldLabel(label: 'signing.username'.tr, required: true),
          TextField(
            controller: controller.username,
            keyboardType: TextInputType.text,
            autocorrect: false,
            decoration: appFieldDecoration(
              context,
              hintText: 'signing.usernameHint'.tr,
              errorText: controller.usernameError.value,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FieldLabel(label: 'signing.password'.tr),
          TextField(
            controller: controller.password,
            obscureText: controller.hidePassword.value,
            autocorrect: false,
            enableSuggestions: false,
            decoration: appFieldDecoration(
              context,
              hintText: controller.currentProfile?.passwordSet == true
                  ? 'signing.passwordKeep'.tr
                  : null,
              errorText: controller.passwordError.value,
              suffixIcon: _VisibilityToggle(
                hidden: controller.hidePassword,
                showLabel: 'signing.show'.tr,
                hideLabel: 'signing.hide'.tr,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FieldLabel(label: 'signing.pin'.tr),
          TextField(
            controller: controller.pin,
            obscureText: controller.hidePin.value,
            keyboardType: TextInputType.number,
            autocorrect: false,
            enableSuggestions: false,
            decoration: appFieldDecoration(
              context,
              hintText: 'signing.pinHint'.tr,
              errorText: controller.pinError.value,
              suffixIcon: _VisibilityToggle(
                hidden: controller.hidePin,
                showLabel: 'signing.show'.tr,
                hideLabel: 'signing.hide'.tr,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'signing.rememberPin'.tr,
                      style: context.appText.bodyStrong,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'signing.rememberPinDesc'.tr,
                      style: context.appText.caption,
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: controller.rememberPin.value,
                onChanged: (v) => controller.rememberPin.value = v,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton.soft(
            label: 'signing.lookup'.tr,
            icon: LucideIcons.search,
            loading: controller.lookingUp.value,
            expand: true,
            onPressed: () => _lookup(context, controller),
          ),
          if (controller.usernameError.value == null &&
              controller.certError.value != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              controller.certError.value!,
              style: context.appText.caption.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _lookup(BuildContext context, SigningProfileController c) async {
    final list = await c.lookup();
    if (!context.mounted || list.isEmpty) return;
    final picked = await AppSheet.show<SigningCertificate>(
      context,
      builder: (ctx) => _CertificatePicker(certificates: list),
    );
    if (picked != null) c.pickCertificate(picked);
  }
}

class _VisibilityToggle extends StatelessWidget {
  const _VisibilityToggle({
    required this.hidden,
    required this.showLabel,
    required this.hideLabel,
  });

  final RxBool hidden;
  final String showLabel;
  final String hideLabel;

  @override
  Widget build(BuildContext context) => Obx(
    () => IconButton(
      tooltip: hidden.value ? showLabel : hideLabel,
      onPressed: () => hidden.value = !hidden.value,
      icon: Icon(hidden.value ? LucideIcons.eye : LucideIcons.eyeOff, size: 20),
    ),
  );
}

class _CertificatePicker extends StatelessWidget {
  const _CertificatePicker({required this.certificates});
  final List<SigningCertificate> certificates;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetHeader(title: 'signing.pickCertificate'.tr),
        Flexible(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            itemCount: certificates.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
            itemBuilder: (_, i) {
              final c = certificates[i];
              return AppListTile(
                icon: LucideIcons.badgeCheck,
                title: c.displayName,
                value: c.serial,
                onTap: () => AppSheet.close(context, c),
              );
            },
          ),
        ),
      ],
    ),
  );
}

class _CertificateCard extends StatelessWidget {
  const _CertificateCard({required this.controller});
  final SigningProfileController controller;

  @override
  Widget build(BuildContext context) {
    final p = controller.currentProfile;
    final picked = controller.selected.value;
    final hasCert = picked != null || p != null;
    return SectionCard(
      title: 'signing.certificate'.tr,
      trailing: hasCert ? _statusBadge(context) : null,
      child: !hasCert
          ? Text('signing.noCertificate'.tr, style: context.appText.caption)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  picked?.displayName ?? p!.certSubject,
                  style: context.appText.bodyStrong,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${'signing.serial'.tr}: '
                  '${picked?.serial ?? p!.certSerial}',
                  style: context.appText.caption,
                ),
                const SizedBox(height: 2),
                Text(
                  '${'signing.validFrom'.tr}: '
                  '${formatDate(picked?.validFrom ?? p!.certValidFrom)}',
                  style: context.appText.caption,
                ),
                Text(
                  '${'signing.validTo'.tr}: '
                  '${formatDate(picked?.validTo ?? p!.certValidTo)}',
                  style: context.appText.caption,
                ),
              ],
            ),
    );
  }

  Widget _statusBadge(BuildContext context) {
    if (controller.expired) {
      return StatusBadge(tone: StatusTone.danger, label: 'signing.expired'.tr);
    }
    if (controller.expiringSoon) {
      return StatusBadge(
        tone: StatusTone.warning,
        label: 'signing.expiringSoon'.tr,
      );
    }
    return StatusBadge(tone: StatusTone.success, label: 'signing.active'.tr);
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.controller});
  final SigningProfileController controller;

  @override
  Widget build(BuildContext context) {
    final p = controller.currentProfile;
    if (p == null) return const SizedBox.shrink();
    return SectionCard(
      title: 'signing.status'.tr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              if (p.passwordSet)
                StatusBadge(
                  tone: StatusTone.success,
                  label: 'signing.passwordSet'.tr,
                ),
              if (p.pinSet)
                StatusBadge(
                  tone: StatusTone.success,
                  label: 'signing.pinSet'.tr,
                ),
              if (p.sessionExpiresAt != null)
                StatusBadge(
                  tone: StatusTone.info,
                  label: 'signing.sessionActive'.tr,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton.soft(
            label: 'signing.save'.tr,
            icon: LucideIcons.save,
            loading: controller.saving.value,
            expand: true,
            onPressed: () => _save(context, controller),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton.soft(
            tone: AppButtonTone.danger,
            label: 'signing.clearSession'.tr,
            icon: LucideIcons.logOut,
            expand: true,
            onPressed: () => _clearSession(context, controller),
          ),
        ],
      ),
    );
  }

  Future<void> _save(BuildContext context, SigningProfileController c) async {
    await c.save();
  }

  Future<void> _clearSession(
    BuildContext context,
    SigningProfileController c,
  ) async {
    final ok = await ConfirmSheet.show(
      context,
      title: 'signing.clearSessionConfirm'.tr,
      description: 'signing.clearSessionDesc'.tr,
      destructive: true,
    );
    if (!ok) return;
    await c.clearSession();
  }
}
