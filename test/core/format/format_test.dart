import 'package:flutter_test/flutter_test.dart';
import 'package:labasset_mobile/core/format/format.dart';

void main() {
  test('formatVnd groups with dots and keeps precision', () {
    expect(formatVnd('1250000'), '1.250.000 ₫');
    expect(formatVnd('1250000.50'), '1.250.000,50 ₫');
    expect(formatVnd('-1000'), '-1.000 ₫');
    expect(formatVnd('12345678901234567890'), '12.345.678.901.234.567.890 ₫');
    expect(formatVnd('5000', symbol: false), '5.000');
    expect(formatVnd(''), '');
    expect(formatVnd(null), '');
  });

  test('formatDate / formatDateTime', () {
    expect(formatDate(DateTime(2026, 9, 19, 8, 5)), '19/09/2026');
    expect(formatDateTime(DateTime(2026, 9, 19, 8, 5)), '08:05 19/09/2026');
    expect(formatDate('garbage'), '');
    expect(formatDate(null), '');
  });

  test('formatRelative', () {
    final now = DateTime(2026, 9, 19, 12);
    expect(
      formatRelative(now.subtract(const Duration(minutes: 3)), now: now),
      '3 phút trước',
    );
    expect(
      formatRelative(now.add(const Duration(days: 2)), now: now),
      '2 ngày nữa',
    );
  });
}
