import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../format/format.dart';

/// Ô chọn ngày: hiển thị `dd/MM/yyyy`, giá trị trong controller là ISO `yyyy-MM-dd`.
class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.controller,
    this.label,
    this.hintText,
    this.validator,
    this.enabled = true,
    this.required = false,
    this.firstDate,
    this.lastDate,
    this.onChanged,
  });

  final TextEditingController controller;
  final String? label;
  final String? hintText;
  final String? Function(String?)? validator;
  final bool enabled;
  final bool required;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final ValueChanged<String>? onChanged;

  /// ISO `yyyy-MM-dd` từ chuỗi hiển thị `dd/MM/yyyy`.
  static String? toIso(String? display) {
    if (display == null || display.trim().isEmpty) return null;
    final parts = display.trim().split('/');
    if (parts.length != 3) return null;
    return '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
  }

  DateTime? _parseDisplay(String text) {
    final iso = toIso(text);
    return iso == null ? null : DateTime.tryParse(iso);
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      readOnly: true,
      onTap: enabled ? () => _pick(context) : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText ?? 'dd/MM/yyyy',
        suffixIcon: const Icon(Icons.event_outlined),
      ),
      validator: validator ?? defaultValidator,
    );
  }

  String? defaultValidator(String? v) {
    if (v == null || v.trim().isEmpty) {
      return required ? 'field.dateRequired'.tr : null;
    }
    return toIso(v) == null ? 'field.dateInvalid'.tr : null;
  }

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final initial = _parseDisplay(controller.text) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate ?? DateTime(now.year - 30),
      lastDate: lastDate ?? DateTime(now.year + 30),
      helpText: label,
    );
    if (picked == null) return;
    controller.text = formatDate(picked);
    onChanged?.call(toIso(controller.text) ?? '');
  }
}
