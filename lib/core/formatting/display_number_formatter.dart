String formatDisplayDecimal(
  num value, {
  int fractionDigits = 2,
  bool trimTrailingZeros = false,
}) {
  final absoluteValue = value.abs();
  final fixed = absoluteValue.toStringAsFixed(fractionDigits);
  final parts = fixed.split('.');
  final integerPart = _groupThousands(parts.first);
  var decimalPart = parts.length > 1 ? parts[1] : '';

  if (trimTrailingZeros && decimalPart.isNotEmpty) {
    decimalPart = decimalPart.replaceFirst(RegExp(r'0+$'), '');
  }

  final sign = value < 0 ? '-' : '';
  if (decimalPart.isEmpty) {
    return '$sign$integerPart';
  }

  return '$sign$integerPart,$decimalPart';
}

String formatDisplayCurrency(num value) {
  return '${formatDisplayDecimal(value, fractionDigits: 2)} zl';
}

String formatDisplayNumber(num value) {
  final normalizedValue = value.toDouble();
  final hasFraction =
      (normalizedValue - normalizedValue.truncateToDouble()).abs() > 0.0000001;

  return formatDisplayDecimal(
    normalizedValue,
    fractionDigits: hasFraction ? 2 : 0,
  );
}

String _groupThousands(String digits) {
  final buffer = StringBuffer();

  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) {
      buffer.write(' ');
    }
    buffer.write(digits[index]);
  }

  return buffer.toString();
}
