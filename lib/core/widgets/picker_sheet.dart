import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/tokens.dart';
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
  }) {
    return AppSheet.show<PickerSelection<T>>(
      context,
      showHandle: false,
      builder: (ctx) => _PickerContent<T>(
        title: title,
        loader: loader,
        showClear: showClear,
        onScan: onScan,
        searchHint: searchHint,
        kind: kind,
        selected: selected,
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
  });

  final String title;
  final Future<List<PickerOption<T>>> Function(String query) loader;
  final bool showClear;
  final Future<String?> Function()? onScan;
  final String? searchHint;
  final PickerKind kind;
  final T? selected;

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
    final theme = Theme.of(context);
    final height = MediaQuery.sizeOf(context).height * 0.75;
    return SizedBox(
      height: height,
      child: Column(
        children: [
          const SheetHandle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.sm,
              0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(widget.title, style: theme.textTheme.titleMedium),
                ),
                if (widget.onScan != null)
                  IconButton(
                    tooltip: 'picker.scan'.tr,
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: _scan,
                  ),
                if (widget.showClear)
                  TextButton(
                    onPressed: () =>
                        AppSheet.close(context, PickerSelection<T>.cleared()),
                    child: Text('common.clear'.tr),
                  ),
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
                prefixIcon: const Icon(Icons.search),
                hintText: widget.searchHint ?? 'picker.searchHint'.tr,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(child: _body()),
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
      return EmptyState(icon: Icons.search_off, title: 'picker.empty'.tr);
    }
    return ListView.separated(
      itemCount: _items.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final o = _items[i];
        return ListTile(
          title: Text(o.label),
          subtitle: o.subtitle == null ? null : Text(o.subtitle!),
          onTap: () => AppSheet.close(context, PickerSelection<T>(o)),
        );
      },
    );
  }
}
