import 'package:intl/intl.dart';

final _date = DateFormat('dd/MM/yyyy');
final _dateTime = DateFormat('HH:mm dd/MM/yyyy');

DateTime? _parse(Object? v) {
  if (v == null) return null;
  if (v is DateTime) return v.toLocal();
  return DateTime.tryParse(v.toString())?.toLocal();
}

String formatDate(Object? v) {
  final d = _parse(v);
  return d == null ? '' : _date.format(d);
}

String formatDateTime(Object? v) {
  final d = _parse(v);
  return d == null ? '' : _dateTime.format(d);
}

/// "3 phút trước", "2 ngày nữa".
String formatRelative(Object? v, {DateTime? now}) {
  final d = _parse(v);
  if (d == null) return '';
  final diff = d.difference(now ?? DateTime.now());
  final past = diff.isNegative;
  final abs = diff.abs();
  String unit;
  if (abs.inSeconds < 60) {
    unit = 'vài giây';
  } else if (abs.inMinutes < 60) {
    unit = '${abs.inMinutes} phút';
  } else if (abs.inHours < 24) {
    unit = '${abs.inHours} giờ';
  } else if (abs.inDays < 30) {
    unit = '${abs.inDays} ngày';
  } else if (abs.inDays < 365) {
    unit = '${abs.inDays ~/ 30} tháng';
  } else {
    unit = '${abs.inDays ~/ 365} năm';
  }
  return past ? '$unit trước' : '$unit nữa';
}

/// Đếm ngược SLA: "Còn 3 giờ" / "Quá hạn 2 ngày".
String formatSla(Object? v, {DateTime? now}) {
  final d = _parse(v);
  if (d == null) return '';
  final diff = d.difference(now ?? DateTime.now());
  final overdue = diff.isNegative;
  final abs = diff.abs();
  String unit;
  if (abs.inMinutes < 60) {
    unit = '${abs.inMinutes} phút';
  } else if (abs.inHours < 24) {
    unit = '${abs.inHours} giờ';
  } else {
    unit = '${abs.inDays} ngày';
  }
  return overdue ? 'Quá hạn $unit' : 'Còn $unit';
}

/// Tiền VND từ chuỗi số thập phân của API; không chuyển sang num.
String formatVnd(String? amount, {bool symbol = true}) {
  if (amount == null || amount.isEmpty) return '';
  final m = RegExp(r'^(-)?(\d+)(?:\.(\d+))?$').firstMatch(amount.trim());
  if (m == null) return amount;
  final sign = m.group(1) ?? '';
  final intPart = m.group(2) ?? '0';
  final dec = m.group(3);
  final grouped = intPart.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  final body = dec == null ? grouped : '$grouped,$dec';
  return '$sign$body${symbol ? ' ₫' : ''}';
}

String formatNumber(num? n, {int digits = 0}) {
  if (n == null) return '';
  return NumberFormat.decimalPatternDigits(
    locale: 'vi_VN',
    decimalDigits: digits,
  ).format(n);
}
