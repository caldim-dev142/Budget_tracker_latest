import 'package:equatable/equatable.dart';
import '../../core/utils/money.dart';
import '../../core/utils/month.dart';

/// Frozen snapshot of a closed month (doc 05 month_snapshots, doc 06 §4).
/// This is the rollover authority: next month's opening is derived from here.
class MonthSnapshot extends Equatable {
  final String id;
  final String householdId;
  final YearMonth yearMonth;
  final Money openingBalance;          // = prior closing balance
  final Money lastMonthReserves;       // = prior reserves
  final Money income;                  // frozen actuals at close
  final Money adjustments;
  final Money spending;
  final Money protection;
  final Money saving;
  final Money reserves;                // Annexure total reserve at close
  final Money closingBalance;          // Total Available − Reserves
  final Money remaining;               // waterfall Remaining
  final MonthStatus status;
  final DateTime? closedAt;

  const MonthSnapshot({
    required this.id,
    required this.householdId,
    required this.yearMonth,
    required this.openingBalance,
    required this.lastMonthReserves,
    required this.income,
    required this.adjustments,
    required this.spending,
    required this.protection,
    required this.saving,
    required this.reserves,
    required this.closingBalance,
    required this.remaining,
    required this.status,
    this.closedAt,
  });

  bool get isClosed => status == MonthStatus.closed;
  bool get isOpen => status == MonthStatus.open;
  Money get reconciliationDifference => remaining - closingBalance;

  @override
  List<Object?> get props => [id, householdId, yearMonth, status];
}

enum MonthStatus { open, closed }

/// Live (not-yet-closed) month actuals — all values computed on-the-fly by the engine.
/// Never persisted on the client (doc 03 §3 "Recompute over store-totals").
class MonthActuals {
  final YearMonth yearMonth;
  final Money openingBalance;
  final Money lastMonthReserves;
  final Money income;
  final Money adjustments;    // signed — can be negative
  final Money spending;
  final Money protection;
  final Money saving;
  final Money reservesSetAside; // Annexure total reserve

  // Accounts panel (doc 01 §7.4)
  final Money totalAvailable;
  final Money ccOutstanding;
  final Money returnAwaited;
  final Money toBePaid;

  const MonthActuals({
    required this.yearMonth,
    required this.openingBalance,
    required this.lastMonthReserves,
    required this.income,
    required this.adjustments,
    required this.spending,
    required this.protection,
    required this.saving,
    required this.reservesSetAside,
    required this.totalAvailable,
    required this.ccOutstanding,
    required this.returnAwaited,
    required this.toBePaid,
  });
}
