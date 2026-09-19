import 'package:decimal/decimal.dart';

/// Chuẩn hoá chuỗi người dùng nhập thành [Decimal] — không dùng `double`.
///
/// Chấp nhận `,` hoặc `.` làm dấu thập phân, bỏ khoảng trắng và ký tự phân nhóm.
Decimal? parseDecimalInput(String? raw, {bool allowNegative = false}) {
  if (raw == null) return null;
  var s = raw.trim().replaceAll(RegExp(r'\s'), '');
  if (s.isEmpty) return null;
  final negative = s.startsWith('-');
  if (negative) {
    if (!allowNegative) return null;
    s = s.substring(1);
  }
  s = s.replaceAll(',', '.');
  if (!RegExp(r'^\d+(\.\d+)?$').hasMatch(s)) return null;
  final d = Decimal.tryParse(s);
  if (d == null) return null;
  return negative ? -d : d;
}

/// Chuỗi gửi API: luôn dấu `.`, giữ nguyên phần thập phân người dùng nhập.
String decimalToApi(Decimal d) => d.toString();

/// Bỏ mọi ký tự không phải chữ số (tiền VND hiển thị nhóm bằng `.`).
String digitsOnly(String raw) => raw.replaceAll(RegExp(r'[^0-9]'), '');

/// Nhóm chữ số bằng dấu `.` kiểu vi_VN: 1500000 → 1.500.000.
String groupDigits(String digits) =>
    digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
