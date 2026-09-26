import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../errors/api_error.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

enum _ToastKind { success, error, info }

/// Thông báo nổi (toast) đặt trực tiếp vào [Overlay] gốc.
///
/// Không dùng `Get.rawSnackbar`: khi snackbar GetX đang hiện, `Get.back()`
/// chỉ đóng snackbar rồi **return** — sheet/dialog/form không pop (lỗi
/// "lưu xong sheet không đóng", "Báo hỏng gửi xong không quay lại").
class AppSnackbar {
  AppSnackbar._();

  static OverlayEntry? _entry;

  static void success(String message) => _show(message, _ToastKind.success);

  static void error(Object e) =>
      _show(ApiError.messageFor(e), _ToastKind.error);

  static void info(String message) => _show(message, _ToastKind.info);

  /// Ẩn toast đang hiện (nếu có).
  static void dismiss() {
    final entry = _entry;
    _entry = null;
    if (entry != null && entry.mounted) entry.remove();
  }

  static void _show(String message, _ToastKind kind) {
    OverlayState? overlay;
    try {
      overlay =
          Get.key.currentState?.overlay; // null khi chưa runApp / unit test
    } catch (_) {
      return;
    }
    if (overlay == null) return;
    dismiss();
    final entry = OverlayEntry(
      builder: (context) =>
          _Toast(message: message, kind: kind, onTap: dismiss),
    );
    _entry = entry;
    overlay.insert(entry);
  }
}

/// Tự ẩn sau 3 s; timer thuộc State nên bị huỷ cùng cây widget (test không
/// còn timer treo).
class _Toast extends StatefulWidget {
  const _Toast({
    required this.message,
    required this.kind,
    required this.onTap,
  });

  final String message;
  final _ToastKind kind;
  final VoidCallback onTap;

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 3), widget.onTap);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final kind = widget.kind;
    final onTap = widget.onTap;
    final status = context.status;
    final scheme = Theme.of(context).colorScheme;
    final (Color bg, Color fg, IconData icon) = switch (kind) {
      _ToastKind.success => (
        status.success,
        scheme.onPrimary,
        Icons.check_circle_outline,
      ),
      _ToastKind.error => (scheme.error, scheme.onError, Icons.error_outline),
      _ToastKind.info => (
        scheme.inverseSurface,
        scheme.onInverseSurface,
        Icons.info_outline,
      ),
    };
    return Positioned(
      left: AppSpacing.md,
      right: AppSpacing.md,
      bottom:
          MediaQuery.viewInsetsOf(context).bottom +
          MediaQuery.paddingOf(context).bottom +
          AppSpacing.md,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        builder: (context, t, child) => Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 16),
            child: child,
          ),
        ),
        child: Material(
          color: bg,
          elevation: 6,
          shadowColor: AppShadows.toastColor,
          borderRadius: BorderRadius.circular(AppRadius.tile),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.tile),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  Icon(icon, color: fg, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      message,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: fg,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
