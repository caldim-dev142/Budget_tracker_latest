import '../../core/utils/money.dart';
import '../../core/utils/month.dart';
import '../entities/month_snapshot.dart';

/// Month rollover engine (doc 01 §12, doc 06 §4).
///
/// When a month closes, the next month's opening is derived:
///   next.openingBalance = prior.closingBalance
///   next.lastMonthReserves = prior.reserves
///
/// Idempotent: re-running a closed month is a no-op (doc 06 §4).
class RolloverEngine {
  RolloverEngine._();

  /// Compute the closing balance from actuals.
  /// Closing Balance = Total Available − Reserves (doc 01 §7.4).
  static Money closingBalance({
    required Money totalAvailable,
    required Money reserves,
  }) {
    return totalAvailable - reserves;
  }

  /// Create the next month's initial snapshot from the closed month.
  /// This mirrors the server's rollover job (doc 06 §4) for offline use.
  static NextMonthOpening computeNextOpening({
    required MonthSnapshot closedMonth,
  }) {
    return NextMonthOpening(
      yearMonth: closedMonth.yearMonth.next,
      openingBalance: closedMonth.closingBalance,
      lastMonthReserves: closedMonth.reserves,
    );
  }
}

/// Data bag for the next month's opening values.
class NextMonthOpening {
  final YearMonth yearMonth;
  final Money openingBalance;
  final Money lastMonthReserves;

  const NextMonthOpening({
    required this.yearMonth,
    required this.openingBalance,
    required this.lastMonthReserves,
  });
}
