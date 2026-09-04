import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/database.dart';
import '../../auth/providers/auth_providers.dart';

// ─── Receivables (Money Lent Out) ─────────────────────────────────────────────

/// Streams all receivables for the current household.
final receivablesStreamProvider =
    StreamProvider<List<ReceivablesTableData>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final auth = ref.watch(authStateProvider).valueOrNull;
  final householdId = auth?.householdId ?? 'local';
  return db.borrowLendDao.watchAll(householdId);
});

/// Streams only open (unsettled) receivables.
final openReceivablesProvider =
    StreamProvider<List<ReceivablesTableData>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final auth = ref.watch(authStateProvider).valueOrNull;
  final householdId = auth?.householdId ?? 'local';
  return db.borrowLendDao.watchOpen(householdId);
});

/// Streams only returned (settled) receivables.
final settledReceivablesProvider =
    StreamProvider<List<ReceivablesTableData>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final auth = ref.watch(authStateProvider).valueOrNull;
  final householdId = auth?.householdId ?? 'local';
  return db.borrowLendDao.watchSettled(householdId);
});

// ─── Planned Bills (Money Borrowed) ───────────────────────────────────────────

/// Streams all planned bills for the current household.
final plannedBillsStreamProvider =
    StreamProvider<List<PlannedBillsTableData>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final auth = ref.watch(authStateProvider).valueOrNull;
  final householdId = auth?.householdId ?? 'local';
  return db.borrowLendDao.watchAllBills(householdId);
});

/// Streams only unpaid planned bills.
final unpaidBillsProvider = StreamProvider<List<PlannedBillsTableData>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final auth = ref.watch(authStateProvider).valueOrNull;
  final householdId = auth?.householdId ?? 'local';
  return db.borrowLendDao.watchUnpaidBills(householdId);
});

/// Streams only paid planned bills.
final paidBillsProvider = StreamProvider<List<PlannedBillsTableData>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final auth = ref.watch(authStateProvider).valueOrNull;
  final householdId = auth?.householdId ?? 'local';
  return db.borrowLendDao.watchPaidBills(householdId);
});

// ─── Summary ──────────────────────────────────────────────────────────────────

class BorrowLendSummary {
  final int totalLentPaise;
  final int totalBorrowedPaise;
  final int openLentCount;
  final int openBorrowedCount;

  const BorrowLendSummary({
    required this.totalLentPaise,
    required this.totalBorrowedPaise,
    required this.openLentCount,
    required this.openBorrowedCount,
  });

  int get netPositionPaise => totalLentPaise - totalBorrowedPaise;
}

final borrowLendSummaryProvider =
    Provider<AsyncValue<BorrowLendSummary>>((ref) {
  final openRec = ref.watch(openReceivablesProvider);
  final unpaidBills = ref.watch(unpaidBillsProvider);

  return openRec.when(
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
    data: (recs) => unpaidBills.when(
      loading: () => const AsyncValue.loading(),
      error: (e, st) => AsyncValue.error(e, st),
      data: (bills) => AsyncValue.data(
        BorrowLendSummary(
          totalLentPaise: recs.fold(0, (s, r) => s + r.amountPaise),
          totalBorrowedPaise: bills.fold(0, (s, b) => s + b.amountPaise),
          openLentCount: recs.length,
          openBorrowedCount: bills.length,
        ),
      ),
    ),
  );
});
