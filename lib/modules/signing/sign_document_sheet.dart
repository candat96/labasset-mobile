import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/errors/api_error.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_sheet.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/field_shell.dart';
import '../../data/models/signing.dart';
import '../../data/repositories/signing_repository.dart';

/// Bottom sheet ký số một chứng từ.
///
/// Đọc hồ sơ chữ ký để biết đã lưu mật khẩu/PIN chưa: chỉ hiện ô cần nhập
/// (`passwordSet == false` / `pinSet == false`). Không bao giờ điền sẵn giá trị
/// đã lưu và luôn chặn bấm ký hai lần bằng cờ [_busy].
class SignDocumentSheet extends StatefulWidget {
  const SignDocumentSheet({
    super.key,
    required this.repo,
    required this.docType,
    required this.id,
    this.slots = const ['handler', 'department', 'leader', 'accounting'],
  });

  final SigningRepository repo;
  final String docType;
  final String id;
  final List<String> slots;

  /// Mở sheet; trả kết quả ký khi thành công, null khi huỷ.
  static Future<SignResult?> show(
    BuildContext context, {
    required SigningRepository repo,
    required String docType,
    required String id,
  }) => AppSheet.show<SignResult>(
    context,
    builder: (_) => SignDocumentSheet(repo: repo, docType: docType, id: id),
  );

  @override
  State<SignDocumentSheet> createState() => _SignDocumentSheetState();
}

class _SignDocumentSheetState extends State<SignDocumentSheet> {
  final _password = TextEditingController();
  final _pin = TextEditingController();

  SigningProfileResponse? _response;
  Object? _loadError;
  String? _error;
  bool _loading = true;
  bool _busy = false;
  bool _hidePassword = true;
  bool _hidePin = true;
  late String _slot = widget.slots.first;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _password.dispose();
    _pin.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final res = await widget.repo.profile();
      if (!mounted) return;
      setState(() {
        _response = res;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e;
        _loading = false;
      });
    }
  }

  Future<void> _sign() async {
    // Chặn bấm hai lần: lần bấm thứ hai thoát ngay khi lệnh trước còn chạy.
    if (_busy) return;
    final profile = _response?.profile;
    if (profile == null) return;
    final password = _password.text;
    final pin = _pin.text;
    if (!profile.passwordSet && password.isEmpty) {
      setState(() => _error = 'signing.passwordRequired'.tr);
      return;
    }
    if (!profile.pinSet && pin.isEmpty) {
      setState(() => _error = 'signing.needPin'.tr);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await widget.repo.sign(
        widget.docType,
        widget.id,
        slot: _slot,
        password: password.isEmpty ? null : password,
        pin: pin.isEmpty ? null : pin,
      );
      if (!mounted) return;
      AppSnackbar.success('signing.signSuccess'.tr);
      AppSheet.close<SignResult>(context, result);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ApiError.messageFor(e);
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SheetHeader(title: 'signing.signTitle'.tr),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_loadError != null)
                _LoadError(error: _loadError!, onRetry: _load)
              else
                ..._body(context),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _body(BuildContext context) {
    final res = _response!;
    if (!res.configured) return [_message('signing.notConfigured'.tr)];
    final profile = res.profile;
    if (profile == null) {
      return [
        _message('signing.profileMissing'.tr),
        const SizedBox(height: AppSpacing.xs),
        Text('signing.profileMissingHint'.tr, style: context.appText.caption),
        const SizedBox(height: AppSpacing.lg),
        AppButton.soft(
          label: 'signing.openSettings'.tr,
          icon: LucideIcons.settings,
          expand: true,
          onPressed: () {
            AppSheet.close(context);
            Get.toNamed(Routes.signingProfile);
          },
        ),
      ];
    }
    return [
      FieldLabel(label: 'signing.slot'.tr),
      Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: [
          for (final slot in widget.slots)
            ChoiceChip(
              label: Text('signing.slot.$slot'.tr),
              selected: _slot == slot,
              onSelected: _busy ? null : (_) => setState(() => _slot = slot),
            ),
        ],
      ),
      if (!profile.passwordSet) ...[
        const SizedBox(height: AppSpacing.md),
        FieldLabel(label: 'signing.password'.tr, required: true),
        TextField(
          controller: _password,
          obscureText: _hidePassword,
          enabled: !_busy,
          autocorrect: false,
          enableSuggestions: false,
          decoration: appFieldDecoration(
            context,
            suffixIcon: _toggle(
              hidden: _hidePassword,
              onTap: () => setState(() => _hidePassword = !_hidePassword),
            ),
          ),
        ),
      ],
      if (!profile.pinSet) ...[
        const SizedBox(height: AppSpacing.md),
        FieldLabel(label: 'signing.pin'.tr, required: true),
        TextField(
          controller: _pin,
          obscureText: _hidePin,
          enabled: !_busy,
          keyboardType: TextInputType.number,
          autocorrect: false,
          enableSuggestions: false,
          decoration: appFieldDecoration(
            context,
            suffixIcon: _toggle(
              hidden: _hidePin,
              onTap: () => setState(() => _hidePin = !_hidePin),
            ),
          ),
        ),
      ],
      if (_error != null) ...[
        const SizedBox(height: AppSpacing.md),
        Text(
          _error!,
          style: context.appText.caption.copyWith(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      ],
      const SizedBox(height: AppSpacing.lg),
      AppButton.primary(
        label: 'signing.sign'.tr,
        icon: LucideIcons.penLine,
        loading: _busy,
        expand: true,
        onPressed: _busy ? null : _sign,
      ),
    ];
  }

  Widget _toggle({required bool hidden, required VoidCallback onTap}) =>
      IconButton(
        tooltip: hidden ? 'signing.show'.tr : 'signing.hide'.tr,
        onPressed: onTap,
        icon: Icon(hidden ? LucideIcons.eye : LucideIcons.eyeOff, size: 20),
      );

  Widget _message(String text) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.sm),
    child: Text(text, style: context.appText.body),
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
    child: Column(
      children: [
        Text(
          ApiError.messageFor(error),
          textAlign: TextAlign.center,
          style: context.appText.body,
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton.soft(
          label: 'common.retry'.tr,
          icon: LucideIcons.refreshCw,
          onPressed: onRetry,
        ),
      ],
    ),
  );
}
