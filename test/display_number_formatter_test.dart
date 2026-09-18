import 'package:flutter_test/flutter_test.dart';
import 'package:finovo/core/formatting/display_number_formatter.dart';

void main() {
  test('formats display currency with grouped thousands', () {
    expect(formatDisplayCurrency(2000), '2 000,00 zl');
    expect(formatDisplayCurrency(1000000), '1 000 000,00 zl');
    expect(formatDisplayCurrency(-12345.67), '-12 345,67 zl');
  });

  test('formats display numbers with grouped thousands', () {
    expect(formatDisplayNumber(2000), '2 000');
    expect(formatDisplayNumber(1000000), '1 000 000');
    expect(formatDisplayNumber(12345.67), '12 345,67');
  });
}
