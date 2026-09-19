import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:labasset_mobile/core/format/decimal_input.dart';

void main() {
  group('parseDecimalInput', () {
    test('số nguyên và thập phân với . hoặc ,', () {
      expect(parseDecimalInput('10'), Decimal.fromInt(10));
      expect(parseDecimalInput('10.5'), Decimal.parse('10.5'));
      expect(parseDecimalInput('10,5'), Decimal.parse('10.5'));
      expect(parseDecimalInput(' 1 000,25 '), Decimal.parse('1000.25'));
    });

    test('rỗng/sai định dạng → null', () {
      expect(parseDecimalInput(null), isNull);
      expect(parseDecimalInput(''), isNull);
      expect(parseDecimalInput('abc'), isNull);
      expect(parseDecimalInput('1.2.3'), isNull);
      expect(parseDecimalInput('10,5,1'), isNull);
    });

    test('âm chỉ khi cho phép', () {
      expect(parseDecimalInput('-5'), isNull);
      expect(parseDecimalInput('-5', allowNegative: true), Decimal.fromInt(-5));
    });
  });

  test('digitsOnly + groupDigits cho tiền VND', () {
    expect(digitsOnly('1.500.000 đ'), '1500000');
    expect(groupDigits('1500000'), '1.500.000');
    expect(groupDigits('999'), '999');
  });
}
