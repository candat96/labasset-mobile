import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'form_focus.dart';

/// Bottom sheet dùng chung cho toàn app.
///
/// Dùng `showModalBottomSheet` với **context của widget gọi** + `useRootNavigator`
/// thay cho `Get.bottomSheet` (route riêng của GetX bọc `Scaffold` + `Theme`
/// và đóng bằng `Get.back()` — `Get.back()` bị snackbar nuốt nên sheet không
/// đóng, rồi controller bị huỷ ngay sau `await` trong lúc sheet còn animation
/// → assertion `_dependents.isEmpty`). Đóng sheet bằng [close] với context
/// bên trong sheet.
class AppSheet {
  AppSheet._();

  /// Bán kính hai góc trên của sheet (Figma: 16). Ghi chú: `AppRadius.sheet`
  /// hiện là 12 — cần một token bo 16 ở đợt sau (B3 không sửa theme).
  static const double topRadius = 16;

  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    WidgetBuilder? footer,
    bool isScrollControlled = true,
    bool isDismissible = true,
    bool enableDrag = true,
    bool showHandle = true,
    bool safeArea = true,
    bool avoidKeyboard = true,
    double maxHeightFraction = 0.9,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      useRootNavigator: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * maxHeightFraction,
      ),
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      showDragHandle: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(topRadius)),
      ),
      builder: (ctx) {
        // Nội dung sheet có thể cuộn; [footer] (thanh nút) được ghim ở đáy.
        final body = footer == null
            ? builder(ctx)
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: builder(ctx)),
                  footer(ctx),
                ],
              );
        Widget child = body;
        if (safeArea) child = SafeArea(top: false, child: child);
        if (showHandle) {
          child = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SheetHandle(),
              Flexible(child: body),
            ],
          );
        }
        if (avoidKeyboard) {
          child = AnimatedPadding(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(ctx).bottom,
            ),
            child: child,
          );
        }
        return child;
      },
    );
  }

  /// Context của Overlay gốc — chỉ dùng khi sheet được mở từ controller
  /// (không có context widget); view luôn truyền context của mình.
  static BuildContext? get rootContext => Get.overlayContext;

  /// Đóng sheet/dialog đang chứa [context] (đúng navigator gốc), trả [result].
  static void close<T>(BuildContext context, [T? result]) {
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) nav.pop<T>(result);
  }
}

/// Vạch kéo 40×4 trên đầu sheet.
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xs),
    child: Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.borderDark : AppColors.border,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
}

/// Thanh nút hành động **dính đáy** sheet: nền trắng, đường kẻ trên `--divider`,
/// nút phụ bên trái, nút chính bên phải (chia đều). Dùng qua tham số `footer`
/// của [AppSheet.show] hoặc đặt trực tiếp cuối nội dung sheet.
class SheetActionBar extends StatelessWidget {
  const SheetActionBar({
    super.key,
    this.primary,
    this.secondary = const [],
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.md,
      AppSpacing.lg,
      AppSpacing.md,
    ),
  });

  /// Nút chính (thường là [FilledButton]).
  final Widget? primary;

  /// Nút phụ đặt trước nút chính (mỗi nút chiếm phần bằng nhau).
  final List<Widget> secondary;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      border: Border(
        top: BorderSide(
          color: context.isDark ? AppColors.dividerDark : AppColors.divider,
        ),
      ),
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: padding,
        child: Row(
          children: [
            for (final s in secondary) ...[
              Expanded(child: s),
              const SizedBox(width: AppSpacing.sm),
            ],
            if (primary != null)
              Expanded(flex: secondary.isEmpty ? 1 : 2, child: primary!),
          ],
        ),
      ),
    ),
  );
}

/// Tiêu đề sheet 16/700 + nút đóng tròn bên phải (+ [trailing] tuỳ chọn).
class SheetHeader extends StatelessWidget {
  const SheetHeader({
    super.key,
    required this.title,
    this.trailing,
    this.showClose = true,
  });

  final String title;
  final Widget? trailing;
  final bool showClose;

  @override
  Widget build(BuildContext context) {
    final status = context.status;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
          ?trailing,
          if (showClose)
            IconButton(
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              onPressed: () => AppSheet.close(context),
              style: IconButton.styleFrom(
                backgroundColor: status.mutedBackground,
                foregroundColor: status.mutedForeground,
                minimumSize: const Size(32, 32),
                padding: EdgeInsets.zero,
              ),
              icon: const Icon(Icons.close, size: 18),
            ),
        ],
      ),
    );
  }
}

/// Form trong sheet/dialog: **sở hữu** các `TextEditingController` theo khoá và
/// chỉ huỷ khi widget unmount (sau khi route đóng hẳn). Không tạo controller ở
/// hàm mở sheet rồi `dispose()` ngay sau `await` — route còn animation đóng sẽ
/// rebuild với controller đã huỷ.
class SheetForm extends StatefulWidget {
  const SheetForm({
    super.key,
    required this.builder,
    this.initial = const {},
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.sm,
      AppSpacing.lg,
      AppSpacing.lg,
    ),
  });

  final Widget Function(BuildContext context, SheetFormState form) builder;

  /// Giá trị ban đầu theo khoá ô nhập.
  final Map<String, String?> initial;
  final EdgeInsetsGeometry padding;

  @override
  State<SheetForm> createState() => SheetFormState();
}

class SheetFormState extends State<SheetForm> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};
  final Map<String, String> _errors = {};
  bool busy = false;

  /// Controller cho ô [key] (tạo lần đầu với giá trị trong `initial`).
  TextEditingController field(String key) => _controllers.putIfAbsent(
    key,
    () => TextEditingController(text: widget.initial[key] ?? ''),
  );

  /// FocusNode cho ô [key] — truyền vào `focusNode:` của ô nhập để [setError]
  /// tự focus + cuộn tới ô lỗi.
  FocusNode focusNode(String key) =>
      _focusNodes.putIfAbsent(key, FocusNode.new);

  /// Focus + cuộn tới ô [key] (khi cần chỉ đúng ô lỗi).
  void focusField(String key) {
    if (!mounted) return;
    final node = _focusNodes[key];
    if (node != null) FormFocus.reveal(node);
  }

  /// Chuỗi đã trim của ô [key].
  String text(String key) => field(key).text.trim();

  /// Chuỗi đã trim hoặc null khi rỗng.
  String? textOrNull(String key) {
    final v = text(key);
    return v.isEmpty ? null : v;
  }

  /// Lỗi hiện dưới ô [key] (null = không lỗi).
  String? error(String key) => _errors[key];

  /// Gắn lỗi dưới ô [key]; mặc định focus + cuộn tới ô đó (bàn phím không che).
  void setError(String key, String? message, {bool focus = true}) {
    refresh(() {
      if (message == null) {
        _errors.remove(key);
      } else {
        _errors[key] = message;
      }
    });
    if (message != null && focus) focusField(key);
  }

  void clearErrors() => refresh(_errors.clear);

  /// Gán nhiều lỗi field (từ `ApiError.fieldErrors`), focus ô lỗi đầu tiên.
  void setErrors(Map<String, String> errors, {bool focus = true}) {
    refresh(() {
      _errors
        ..clear()
        ..addAll(errors);
    });
    if (focus && errors.isNotEmpty) focusField(errors.keys.first);
  }

  /// Đánh dấu đang gửi (khoá nút).
  void setBusy(bool value) => refresh(() => busy = value);

  /// `setState` an toàn (bỏ qua khi đã unmount).
  void refresh(VoidCallback fn) {
    if (!mounted) {
      fn();
      return;
    }
    setState(fn);
  }

  /// Đóng sheet chứa form.
  void close<T>([T? result]) {
    if (mounted) AppSheet.close<T>(context, result);
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final n in _focusNodes.values) {
      n.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: widget.padding,
    // Tự cuộn: bàn phím hiện làm sheet thấp đi nhưng form dài vẫn xem/sửa được
    // hết ô (trước đây sheet dùng Column trần nên tràn khi bàn phím mở).
    child: SingleChildScrollView(child: widget.builder(context, this)),
  );
}

/// Hộp thoại nhập một chuỗi (tên người ký, lý do…). Controller do dialog sở
/// hữu; trả chuỗi đã trim hoặc null khi huỷ.
class AppDialog {
  AppDialog._();

  static Future<String?> prompt(
    BuildContext context, {
    required String title,
    String? label,
    String? initial,
    String? confirmLabel,
    bool required = true,
    int maxLines = 1,
  }) {
    return showDialog<String>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => _PromptDialog(
        title: title,
        label: label,
        initial: initial,
        confirmLabel: confirmLabel,
        required: required,
        maxLines: maxLines,
      ),
    );
  }
}

class _PromptDialog extends StatefulWidget {
  const _PromptDialog({
    required this.title,
    required this.label,
    required this.initial,
    required this.confirmLabel,
    required this.required,
    required this.maxLines,
  });

  final String title;
  final String? label;
  final String? initial;
  final String? confirmLabel;
  final bool required;
  final int maxLines;

  @override
  State<_PromptDialog> createState() => _PromptDialogState();
}

class _PromptDialogState extends State<_PromptDialog> {
  late final TextEditingController _text = TextEditingController(
    text: widget.initial ?? '',
  );
  final FocusNode _focus = FocusNode();
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    final v = _text.text.trim();
    if (widget.required && v.isEmpty) {
      setState(() => _error = 'common.required'.tr);
      // Giữ focus + cuộn ô lên khi bàn phím che mất.
      FormFocus.reveal(_focus);
      return;
    }
    Navigator.of(context, rootNavigator: true).pop(v);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: TextField(
      controller: _text,
      focusNode: _focus,
      autofocus: true,
      maxLines: widget.maxLines,
      onSubmitted: (_) => _submit(),
      decoration: InputDecoration(
        labelText: widget.label ?? widget.title,
        errorText: _error,
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
        child: Text('common.cancel'.tr),
      ),
      FilledButton(
        onPressed: _submit,
        child: Text(widget.confirmLabel ?? 'common.save'.tr),
      ),
    ],
  );
}
