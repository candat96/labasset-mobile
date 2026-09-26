import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'app_buttons.dart';
import 'app_sheet.dart';
import 'empty_state.dart';
import 'error_state.dart';
import 'loading_list.dart';

/// Loại tham chiếu đang chọn → icon chip trong dòng.
enum PickerKind {
  generic,
  supply,
  equipment,
  department,
  user,
  warehouse,
  supplier,
}

/// Một dòng chọn tham chiếu: `code — name`.
class PickerOption<T> {
  const PickerOption({
    required this.value,
    required this.code,
    required this.name,
    this.subtitle,
  });

  final T value;
  final String code;
  final String name;
  final String? subtitle;

  String get label => code.isEmpty ? name : '$code — $name';
}

/// Kết quả chọn: [cleared] = người dùng bấm "Bỏ chọn".
class PickerSelection<T> {
  const PickerSelection(this.option) : cleared = false;
  const PickerSelection.cleared() : option = null, cleared = true;

  final PickerOption<T>? option;
  final bool cleared;
}

/// Bottom sheet chọn tham chiếu dùng chung: ô tìm (debounce 300 ms) gọi API list `q`,
/// hiển thị `code — name`; hỗ trợ nút quét mã khi truyền [onScan].
class PickerSheet {
  PickerSheet._();

  static Future<PickerSelection<T>?> show<T>(
    BuildContext context, {
    required String title,
    required Future<List<PickerOption<T>>> Function(String query) loader,
    bool showClear = false,
    Future<String?> Function()? onScan,
    String? searchHint,
    PickerKind kind = PickerKind.generic,
    T? selected,
    Widget Function(BuildContext context)? footer,
  }) {
    return AppSheet.show<PickerSelection<T>>(
      context,
      showHandle: false,
      maxHeightFraction: 0.85,
      builder: (ctx) => _PickerContent<T>(
        title: title,
        loader: loader,
        showClear: showClear,
        onScan: onScan,
        searchHint: searchHint,
        kind: kind,
        selected: selected,
        footer: footer,
      ),
    );
  }
}

class _PickerContent<T> extends StatefulWidget {
  const _PickerContent({
    required this.title,
    required this.loader,
    required this.showClear,
    required this.onScan,
    required this.searchHint,
    required this.kind,
    required this.selected,
    required this.footer,
  });

  final String title;
  final Future<List<PickerOption<T>>> Function(String query) loader;
  final bool showClear;
  final Future<String?> Function()? onScan;
  final String? searchHint;
  final PickerKind kind;
  final T? selected;
  final Widget Function(BuildContext context)? footer;

  @override
  State<_PickerContent<T>> createState() => _PickerContentState<T>();
}

class _PickerContentState<T> extends State<_PickerContent<T>> {
  final TextEditingController _query = TextEditingController();
  Timer? _debounce;
  List<PickerOption<T>> _items = const [];
  bool _loading = true;
  Object? _error;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _load('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _load(value));
  }

  Future<void> _load(String q) async {
    final gen = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await widget.loader(q);
      if (!mounted || gen != _generation) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || gen != _generation) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _scan() async {
    final code = await widget.onScan!.call();
    if (code == null || code.trim().isEmpty || !mounted) return;
    _query.text = code;
    await _load(code);
    if (!mounted) return;
    // Khớp chính xác mã → chọn luôn.
    final match = _items.where(
      (o) => o.code.toUpperCase() == code.toUpperCase(),
    );
    if (match.length == 1) {
      AppSheet.close(context, PickerSelection<T>(match.first));
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.85;
    return SizedBox(
      height: height,
      child: Column(
        children: [
          const SheetHandle(),
          SheetHeader(
            title: widget.title,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.onScan != null)
                  AppIconButton(
                    tooltip: 'picker.scan'.tr,
                    icon: LucideIcons.scanLine,
                    onPressed: _scan,
                  ),
                if (widget.showClear) ...[
                  if (widget.onScan != null)
                    const SizedBox(width: AppSpacing.sm),
                  AppButton.soft(
                    label: 'common.clear'.tr,
                    tone: AppButtonTone.neutral,
                    onPressed: () =>
                        AppSheet.close(context, PickerSelection<T>.cleared()),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: TextField(
              controller: _query,
              autofocus: widget.onScan == null,
              onChanged: _onQueryChanged,
              decoration: InputDecoration(
                prefixIcon: const Icon(LucideIcons.search, size: 20),
                hintText: widget.searchHint ?? 'picker.searchHint'.tr,
                filled: true,
                fillColor: context.isDark
                    ? AppColors.mutedDark
                    : AppColors.muted,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                border: _searchBorder,
                enabledBorder: _searchBorder,
                focusedBorder: _searchBorder,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(child: _body()),
          if (widget.footer != null)
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: widget.footer!(context),
            ),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading && _items.isEmpty) return const LoadingList(rows: 6);
    if (_error != null && _items.isEmpty) {
      return ErrorState(error: _error!, onRetry: () => _load(_query.text));
    }
    if (_items.isEmpty) {
      return EmptyState(icon: LucideIcons.searchX, title: 'picker.empty'.tr);
    }
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      itemCount: _items.length,
      separatorBuilder: (_, _) => const Divider(
        height: 1,
        indent: AppSpacing.lg + 36 + AppSpacing.md,
        endIndent: AppSpacing.lg,
        color: AppColors.divider,
      ),
      itemBuilder: (_, i) {
        final o = _items[i];
        final selected = o.value == widget.selected;
        final meta = [
          if (o.code.isNotEmpty) o.code,
          if (o.subtitle?.trim().isNotEmpty ?? false) o.subtitle!.trim(),
        ].join(' · ');
        return InkWell(
          onTap: () => AppSheet.close(context, PickerSelection<T>(o)),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                _KindIcon(kind: widget.kind),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(o.name, style: context.appText.bodyStrong),
                      if (meta.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          meta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.appText.caption,
                        ),
                      ],
                    ],
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    LucideIcons.check,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

const _searchBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(AppRadius.chip)),
  borderSide: BorderSide.none,
);

class _KindIcon extends StatelessWidget {
  const _KindIcon({required this.kind});

  final PickerKind kind;

  IconData get icon => switch (kind) {
    PickerKind.supply => LucideIcons.package2,
    PickerKind.equipment => LucideIcons.monitorCog,
    PickerKind.department => LucideIcons.building2,
    PickerKind.user => LucideIcons.userRound,
    PickerKind.warehouse => LucideIcons.warehouse,
    PickerKind.supplier => LucideIcons.truck,
    PickerKind.generic => LucideIcons.listFilter,
  };

  @override
  Widget build(BuildContext context) => Container(
    width: 36,
    height: 36,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(AppRadius.tile),
    ),
    child: Icon(
      icon,
      size: 18,
      color: Theme.of(context).colorScheme.onPrimaryContainer,
    ),
  );
}
