import 'package:intl/intl.dart';

/// Represents monetary values as integer paise (1 INR = 100 paise).
/// Never use double for stored or derived money values (doc 03 §5, doc 05).
/// All arithmetic must remain in integer paise to avoid floating-point drift.
extension type const Money(int paise) {
  static const zero = Money(0);

  Money operator +(Money other) => Money(paise + other.paise);
  Money operator -(Money other) => Money(paise - other.paise);
  Money operator -() => Money(-paise);
  Money abs() => Money(paise.abs());

  bool get isNegative => paise < 0;
  bool get isZero => paise == 0;
  bool get isPositive => paise > 0;

  /// Convert from rupees (double input from user) to paise, rounded.
  /// Only used at the UI boundary — never internally.
  static Money fromRupees(double rupees) => Money((rupees * 100).round());

  /// Convert from a rupee string like "1,55,419.50"
  static Money fromRupeeString(String s) {
    final cleaned = s.replaceAll(',', '').replaceAll('₹', '').trim();
    return fromRupees(double.parse(cleaned));
  }

  double get inRupees => paise / 100.0;
}

/// INR formatter with Indian digit grouping: ₹1,55,419
///
/// Indian grouping: last 3 digits, then groups of 2.
/// e.g. 15541900 paise = ₹1,55,419.00
class MoneyFormatter {
  MoneyFormatter._();

  static final _indiaLocale = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final _indiaNoDecimals = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  /// Full format: ₹1,55,419.00
  static String format(Money money) =>
      _indiaLocale.format(money.inRupees);

  /// Compact: ₹1,55,419 (no paise decimals when whole rupees)
  static String formatCompact(Money money) {
    if (money.paise % 100 == 0) {
      return _indiaNoDecimals.format(money.inRupees);
    }
    return _indiaLocale.format(money.inRupees);
  }

  /// Signed: +₹1,000 / -₹1,000
  static String formatSigned(Money money) {
    final s = formatCompact(money.abs());
    return money.isNegative ? '-$s' : '+$s';
  }

  /// Plain number: 1,55,419
  static String formatAmount(Money money) {
    return NumberFormat('#,##,###.##', 'en_IN').format(money.inRupees);
  }
}
