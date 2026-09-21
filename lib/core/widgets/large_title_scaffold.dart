import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// Khung màn danh sách: tiêu đề lớn 28/800 thu về 17/700 trên thanh khi
/// [body] cuộn (nghe ScrollNotification trục dọc), hàng nút tròn 40 bên phải,
/// [header] (SegmentTabs/lọc) đặt ngay dưới tiêu đề.
class LargeTitleScaffold extends StatefulWidget {
  const LargeTitleScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions = const [],
    this.header,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.leading,
    this.automaticallyImplyLeading = true,
  });

  final String title;
  final Widget body;
  final List<Widget> actions;
  final Widget? header;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Widget? leading;
  final bool automaticallyImplyLeading;

  @override
  State<LargeTitleScaffold> createState() => _LargeTitleScaffoldState();
}

class _LargeTitleScaffoldState extends State<LargeTitleScaffold> {
  var _collapsed = false;

  bool _onScroll(ScrollNotification n) {
    if (n.metrics.axis != Axis.vertical) return false;
    final collapsed = n.metrics.pixels > 8;
    if (collapsed != _collapsed) setState(() => _collapsed = collapsed);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canPop =
        widget.leading != null ||
        (widget.automaticallyImplyLeading &&
            (ModalRoute.of(context)?.impliesAppBarDismissal ?? false));
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: context.isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        floatingActionButton: widget.floatingActionButton,
        bottomNavigationBar: widget.bottomNavigationBar,
        body: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                border: Border(
                  bottom: BorderSide(
                    color: _collapsed ? theme.dividerColor : Colors.transparent,
                  ),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Thanh gọn: thấp khi chưa cuộn và không có nút nào.
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: _collapsed || canPop || widget.actions.isNotEmpty
                          ? 48
                          : 12,
                      clipBehavior: Clip.hardEdge,
                      decoration: const BoxDecoration(),
                      child: Row(
                        children: [
                          const SizedBox(width: AppSpacing.lg),
                          if (canPop) ...[
                            widget.leading ??
                                CircleIconButton(
                                  icon: LucideIcons.chevronLeft,
                                  tooltip: MaterialLocalizations.of(
                                    context,
                                  ).backButtonTooltip,
                                  onTap: () => Navigator.of(context).maybePop(),
                                ),
                            const SizedBox(width: AppSpacing.sm),
                          ],
                          Expanded(
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 150),
                              opacity: _collapsed ? 1 : 0,
                              child: Text(
                                widget.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.appText.title.copyWith(
                                  fontSize: 17,
                                ),
                              ),
                            ),
                          ),
                          for (final a in widget.actions) ...[
                            a,
                            const SizedBox(width: AppSpacing.sm),
                          ],
                          if (widget.actions.isEmpty)
                            const SizedBox(width: AppSpacing.lg)
                          else
                            const SizedBox(width: AppSpacing.sm),
                        ],
                      ),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      alignment: Alignment.topCenter,
                      child: _collapsed
                          ? const SizedBox(width: double.infinity)
                          : Padding(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.lg,
                                AppSpacing.xs,
                                AppSpacing.lg,
                                AppSpacing.md,
                              ),
                              child: Text(
                                widget.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.appText.display,
                              ),
                            ),
                    ),
                    if (widget.header != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          0,
                          AppSpacing.lg,
                          AppSpacing.md,
                        ),
                        child: widget.header,
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: _onScroll,
                child: widget.body,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nút icon tròn 40 nền card + viền mờ (lọc, quay lại, hành động AppBar).
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.badge = false,
    this.color,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final bool badge;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget child = Icon(icon, size: 20, color: color ?? scheme.onSurface);
    if (badge) {
      child = Stack(
        clipBehavior: Clip.none,
        children: [
          child,
          Positioned(
            right: -3,
            top: -3,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: context.status.danger,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      );
    }
    final button = DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        shape: BoxShape.circle,
        border: Border.all(color: context.cardBorder),
        boxShadow: context.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(width: 40, height: 40, child: Center(child: child)),
        ),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}
