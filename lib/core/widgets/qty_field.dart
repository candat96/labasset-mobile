import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../format/decimal_input.dart';

/// Ô nhập số lượng: chuỗi thập phân (cho phép `,`/`.`), trả [Decimal] — không dùng double.
class QtyField extends StatelessWidget {
  const QtyField({
    super.key,
    required this.controller,
    this.label,
    this.hintText,
    this.validator,
    this.enabled = true,
    this.required = true,
    this.suffix,
    this.textInputAction = TextInputAction.next,
    this.onChanged,
  });

  final TextEditingController controller;
  final String? label;
  final String? hintText;
  final String? Function(String?)? validator;
  final bool enabled;
  final bool required;
  final Widget? suffix;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onChanged;

  /// Giá trị đã nhập (null nếu chưa hợp lệ).
  Decimal? get value => parseDecimalInput(controller.text);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      textInputAction: textInputAction,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        suffix: suffix,
      ),
      validator: validator ?? defaultValidator,
    );
  }

  String? defaultValidator(String? v) {
    if (v == null || v.trim().isEmpty) {
      return required ? 'field.qtyRequired'.tr : null;
    }
    final d = parseDecimalInput(v);
    if (d == null || d < Decimal.zero) return 'field.qtyInvalid'.tr;
    return null;
  }
}
