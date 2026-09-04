import 'package:equatable/equatable.dart';

/// A calendar month value type: year + month (1-12).
/// Used everywhere in place of raw DateTime to avoid day/timezone ambiguity.
/// Maps to `YYYY-MM` strings in the API and `DATE` first-of-month in the DB.
class YearMonth extends Equatable {
  final int year;
  final int month; // 1–12

  const YearMonth(this.year, this.month)
      : assert(month >= 1 && month <= 12);

  factory YearMonth.now() {
    final dt = DateTime.now();
    return YearMonth(dt.year, dt.month);
  }

  factory YearMonth.fromDate(DateTime dt) => YearMonth(dt.year, dt.month);

  /// Parse from 'YYYY-MM' API format
  factory YearMonth.parse(String s) {
    final parts = s.split('-');
    return YearMonth(int.parse(parts[0]), int.parse(parts[1]));
  }

  /// Parse from a DATE string 'YYYY-MM-DD' (first of month)
  factory YearMonth.fromDateString(String s) {
    final parts = s.split('-');
    return YearMonth(int.parse(parts[0]), int.parse(parts[1]));
  }

  /// Returns the first day of this month as a DateTime.
  DateTime get firstDay => DateTime(year, month, 1);

  /// Returns the last day of this month.
  DateTime get lastDay {
    final next = addMonths(1).firstDay;
    return next.subtract(const Duration(days: 1));
  }

  /// Number of days in this month (handles short/long months; doc 02 §5 edge-case 1).
  int get daysInMonth => lastDay.day;

  YearMonth addMonths(int n) {
    int m = month + n;
    int y = year;
    while (m > 12) {
      m -= 12;
      y++;
    }
    while (m < 1) {
      m += 12;
      y--;
    }
    return YearMonth(y, m);
  }

  YearMonth get previous => addMonths(-1);
  YearMonth get next => addMonths(1);

  bool isBefore(YearMonth other) =>
      year < other.year || (year == other.year && month < other.month);

  bool isAfter(YearMonth other) => other.isBefore(this);

  bool isSameOrBefore(YearMonth other) => !isAfter(other);

  bool containsDate(DateTime d) => d.year == year && d.month == month;

  /// API/DB string: '2023-11'
  String toApiString() =>
      '$year-${month.toString().padLeft(2, '0')}';

  /// DB first-of-month DATE string: '2023-11-01'
  String toDbDateString() =>
      '$year-${month.toString().padLeft(2, '0')}-01';

  /// Display label: 'Nov 2023'
  String toDisplayString() {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[month - 1]} $year';
  }

  @override
  List<Object> get props => [year, month];

  @override
  String toString() => toApiString();
}
