import 'package:flutter_test/flutter_test.dart';
import 'package:labasset_mobile/core/format/format.dart';

void main() {
  _qtyTests();
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

  test('formatDecimal bỏ số 0 thừa, dấu phẩy kiểu Việt', () {
    expect(formatDecimal('100.0000'), '100');
    expect(formatDecimal('2.5000'), '2,5');
    expect(formatDecimal('0.5'), '0,5');
    expect(formatDecimal(null), '');
    expect(formatDecimal(''), '');
  });

  test('validityTone: quá hạn đỏ, ≤ 60 ngày vàng', () {
    final now = DateTime(2026, 9, 19, 12);
    expect(validityTone(null, now: now), ValidityTone.none);
    expect(
      validityTone('2026-11-17', now: now, withinDays: 60),
      ValidityTone.soon,
    );
    expect(
      validityTone('2026-09-18', now: now, withinDays: 60),
      ValidityTone.expired,
    );
    expect(
      validityTone('2027-01-01', now: now, withinDays: 60),
      ValidityTone.none,
    );
  });
}

void _qtyTests() {
  group('formatQty', () {
    test('số lượng không bị đọc nhầm thành hàng nghìn', () {
      // numeric(14,3): mười cái về từ API là "10.000".
      expect(formatQty('10.000'), '10');
      expect(formatQty('250.000'), '250');
      expect(formatQty('1500.500'), '1.500,5');
      expect(formatQty('0.250'), '0,25');
    });

    test('rỗng và chuỗi lạ giữ nguyên', () {
      expect(formatQty(null), '');
      expect(formatQty(''), '');
      expect(formatQty('—'), '—');
    });
  });
}
