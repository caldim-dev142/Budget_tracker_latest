import 'package:flutter/services.dart';

/// Standard input formatters for consistent text and numeric validation across forms.
class AppInputFormatters {
  AppInputFormatters._();

  /// Restricts input to positive decimal numbers with up to [decimalRange] decimal places.
  /// Prevents negative signs, multiple decimal points, and letters.
  static TextInputFormatter positiveDecimal({int decimalRange = 2}) =>
      _DecimalTextInputFormatter(decimalRange: decimalRange);

  /// Allows only whole integer digits (0-9).
  static final TextInputFormatter digitsOnly =
      FilteringTextInputFormatter.digitsOnly;
}

class _DecimalTextInputFormatter extends TextInputFormatter {
  final int decimalRange;

  const _DecimalTextInputFormatter({this.decimalRange = 2});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }
    // Allow digits and at most one decimal point with up to `decimalRange` digits after it
    final regex = RegExp('^\\d*\\.?\\d{0,$decimalRange}\$');
    if (regex.hasMatch(newValue.text)) {
      return newValue;
    }
    return oldValue;
  }
}
