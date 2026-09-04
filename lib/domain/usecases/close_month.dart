import '../../core/utils/money.dart';
import '../../core/utils/month.dart';
import '../../core/utils/result.dart';
import '../engine/rollover.dart';
import '../entities/month_snapshot.dart';

/// Use-case: Close the current month and create next month's opening.
/// Implements the rollover authority (doc 06 §4, doc 02 WF-3).
///
/// Steps:
/// 1. Freeze actuals (totals computed from entries by engine)
/// 2. Compute reserves (Annexure total)
/// 3. Compute closing balance = TotalAvailable − Reserves
/// 4. Write month_snapshot with status=closed
/// 5. Create next month with opening = prior closing, lastMonthReserves = prior reserves
/// 6. Prior month becomes read-only
///
/// Idempotent: re-closing an already-closed month is a no-op (doc 06 §4).
class CloseMonthUseCase {
  final MonthSnapshotRepository _repo;

  CloseMonthUseCase({required MonthSnapshotRepository repo}) : _repo = repo;

  Future<Result<CloseMonthResult>> execute({
    required YearMonth yearMonth,
    required String householdId,
    required MonthActuals actuals,
    required Money totalAvailable,
    required Money reserves,
  }) async {
    // Idempotency check
    final existing = await _repo.getSnapshot(yearMonth);
    if (existing != null && existing.isClosed) {
      // Re-closing is a no-op (doc 06 §4)
      return Success(CloseMonthResult(
        closedSnapshot: existing,
        nextMonthOpening: RolloverEngine.computeNextOpening(closedMonth: existing),
      ));
    }

    final closingBalance = RolloverEngine.closingBalance(
      totalAvailable: totalAvailable,
      reserves: reserves,
    );

    // The waterfall Remaining (computed by engine, not stored — just for the snapshot record)
    final remaining = actuals.openingBalance +
        actuals.lastMonthReserves +
        actuals.income +
        actuals.adjustments -
        actuals.spending -
        actuals.protection -
        actuals.saving -
        actuals.reservesSetAside;

    // Build closed snapshot
    final now = DateTime.now();
    final snapshot = MonthSnapshot(
      id: 'snap-${yearMonth.toApiString()}',
      householdId: householdId,
      yearMonth: yearMonth,
      openingBalance: actuals.openingBalance,
      lastMonthReserves: actuals.lastMonthReserves,
      income: actuals.income,
      adjustments: actuals.adjustments,
      spending: actuals.spending,
      protection: actuals.protection,
      saving: actuals.saving,
      reserves: reserves,
      closingBalance: closingBalance,
      remaining: remaining,
      status: MonthStatus.closed,
      closedAt: now,
    );

    try {
      await _repo.saveSnapshot(snapshot);
      await _repo.createNextMonthOpening(yearMonth.next, closingBalance, reserves);

      return Success(CloseMonthResult(
        closedSnapshot: snapshot,
        nextMonthOpening: RolloverEngine.computeNextOpening(closedMonth: snapshot),
      ));
    } catch (e) {
      return Failure(UnexpectedFailure('Failed to close month.', cause: e));
    }
  }
}

class CloseMonthResult {
  final MonthSnapshot closedSnapshot;
  final NextMonthOpening nextMonthOpening;
  const CloseMonthResult({required this.closedSnapshot, required this.nextMonthOpening});
}

abstract interface class MonthSnapshotRepository {
  Future<MonthSnapshot?> getSnapshot(YearMonth ym);
  Future<void> saveSnapshot(MonthSnapshot snapshot);
  Future<void> createNextMonthOpening(
    YearMonth ym,
    Money openingBalance,
    Money lastMonthReserves,
  );
}
