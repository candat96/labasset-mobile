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
    this.focusNode,
    this.label,
    this.hintText,
    this.validator,
    this.enabled = true,
    this.required = true,
    this.suffix,
    this.textInputAction = TextInputAction.next,
    this.onChanged,
    this.errorText,
  });

  final TextEditingController controller;

  /// Node do `SheetForm.focusNode(key)` cấp — để focus + cuộn tới ô khi lỗi.
  final FocusNode? focusNode;
  final String? label;
  final String? hintText;
  final String? Function(String?)? validator;
  final bool enabled;
  final bool required;
  final Widget? suffix;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onChanged;

  /// Lỗi hiện dưới ô (ngoài validator của Form).
  final String? errorText;

  /// Giá trị đã nhập (null nếu chưa hợp lệ).
  Decimal? get value => parseDecimalInput(controller.text);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      textInputAction: textInputAction,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        errorText: errorText,
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
