import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../format/decimal_input.dart';
import 'field_shell.dart';

/// Ô nhập tiền VND: hiển thị nhóm `1.500.000`, giá trị thật lấy bằng [raw].
class MoneyField extends StatelessWidget {
  const MoneyField({
    super.key,
    required this.controller,
    this.focusNode,
    this.label,
    this.hintText,
    this.validator,
    this.enabled = true,
    this.required = false,
    this.suffixText = '₫',
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
  final String? suffixText;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onChanged;

  /// Lỗi hiện dưới ô (ngoài validator của Form).
  final String? errorText;

  /// Chuỗi gửi API từ text đang hiển thị (bỏ dấu nhóm).
  static String raw(String display) => digitsOnly(display);

  /// Số tiền hiện tại dạng chuỗi API ('' nếu trống).
  String get value => raw(controller.text);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) FieldLabel(label: label!, required: required),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          keyboardType: TextInputType.number,
          inputFormatters: const [_VndInputFormatter()],
          textInputAction: textInputAction,
          onChanged: onChanged,
          decoration: appFieldDecoration(
            context,
            hintText: hintText,
            errorText: errorText,
            suffixText: suffixText,
          ),
          validator: validator ?? defaultValidator,
        ),
      ],
    );
  }

  String? defaultValidator(String? v) {
    final digits = raw(v ?? '');
    if (digits.isEmpty) return required ? 'field.moneyRequired'.tr : null;
    if (digits.length > 15) return 'field.moneyInvalid'.tr;
    return null;
  }
}

/// Nhóm chữ số khi gõ, giữ con trỏ ở cuối.
class _VndInputFormatter extends TextInputFormatter {
  const _VndInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = digitsOnly(newValue.text);
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }
    final trimmed = digits.length > 15 ? digits.substring(0, 15) : digits;
    final grouped = groupDigits(trimmed);
    return TextEditingValue(
      text: grouped,
      selection: TextSelection.collapsed(offset: grouped.length),
    );
  }
}
