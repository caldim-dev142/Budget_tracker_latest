import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';

import '../../../core/utils/month.dart';
import '../../../core/utils/money.dart';
import '../../../domain/engine/waterfall.dart';
import '../../../domain/engine/budget.dart';
import '../../../domain/entities/month_snapshot.dart';
import '../../../domain/entities/entry.dart';
import '../../../data/local/database.dart';
import '../../auth/providers/auth_providers.dart';

class SelectedMonthNotifier extends StateNotifier<YearMonth> {
  SelectedMonthNotifier() : super(YearMonth.now());
  void select(YearMonth ym) => state = ym;
}

final selectedMonthProvider =
    StateNotifierProvider<SelectedMonthNotifier, YearMonth>(
  (ref) => SelectedMonthNotifier(),
);

final showBudgetProvider = StateProvider<bool>((_) => true);
final showTrackingProvider = StateProvider<bool>((_) => true);

final trendRangeProvider = StateProvider<(YearMonth, YearMonth)>(
  (_) => (YearMonth.now().addMonths(-5), YearMonth.now()),
);

final isCurrentMonthClosedProvider = StreamProvider<bool>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final ym = ref.watch(selectedMonthProvider);
  final authState = ref.watch(authStateProvider).valueOrNull;
  final householdId = authState?.householdId ?? 'local';
  
  return db.snapshotDao.watchForMonth(ym.toString(), householdId: householdId).map((snap) {
    if (snap == null) return false;
    return snap.status == 'closed';
  });
});

class DashboardVM {
  final WaterfallResult waterfall;
  final List<LayerBudget> layerBudgets;
  final Money totalAvailable;
  final Money ccOutstanding;
  final Money returnAwaited;
  final Money toBePaid;
  final Money unbudgetedIncome;
  final Money unspentBudget;
  final MonthSnapshot? snapshot;

  const DashboardVM({
    required this.waterfall,
    required this.layerBudgets,
    required this.totalAvailable,
    required this.ccOutstanding,
    required this.returnAwaited,
    required this.toBePaid,
    required this.unbudgetedIncome,
    required this.unspentBudget,
    this.snapshot,
  });
}

final dashboardProvider =
    StreamProvider.family<DashboardVM, (YearMonth, String)>((ref, args) {
  final ym = args.$1;
  final householdId = args.$2;
  final db = ref.watch(appDatabaseProvider);

  return db.customSelect(
    'SELECT 1',
    readsFrom: {
      db.entriesTable,
      db.sinkingFundsTable,
      db.fundMovementsTable,
      db.cardTransactionsTable,
      db.receivablesTable,
      db.plannedBillsTable,
      db.accountsTable,
      db.creditCardsTable,
      db.categoriesTable,
      db.budgetsTable,
      db.monthSnapshotsTable,
    },
  ).watch().asyncMap((_) async {
    final entries = await db.entryDao.getMonth(ym.toString(), householdId: householdId);
    int grossIncomePaise = 0;
    int incomeDeductionPaise = 0;
    int adjustmentsPaise = 0;
    int spendingPaise = 0;
    int protectionPaise = 0;
    int savingPaise = 0;

    final categories = await (db.select(db.categoriesTable)..where((c) => c.householdId.equals(householdId))).get();
    final categoryMap = {for (var c in categories) c.id: c};

    for (final entry in entries) {
      final amount = entry.amountPaise;
      final cat = categoryMap[entry.categoryId];
      final isDeduction = cat?.isDeduction ?? false;

      switch (entry.kind) {
        case 'income':
          grossIncomePaise += amount;
          break;
        case 'incomeDeduction':
          incomeDeductionPaise += amount;
          break;
        case 'adjustment':
          if (isDeduction) {
            adjustmentsPaise -= amount;
          } else {
            adjustmentsPaise += amount;
          }
          break;
        case 'spending':
          spendingPaise += amount;
          break;
        case 'protection':
          protectionPaise += amount;
          break;
        case 'saving':
          savingPaise += amount;
          break;
      }
    }

    final netIncomePaise = grossIncomePaise - incomeDeductionPaise;

    final snap = await db.snapshotDao.getForMonth(ym.toString(), householdId: householdId);
    final prevSnap = await db.snapshotDao.getForMonth(ym.addMonths(-1).toString(), householdId: householdId);

    // Query active accounts & cards
    final accounts = await db.accountDao.watchActiveAccounts(householdId: householdId).first;
    final cards = await db.cardDao.watchActiveCards(householdId: householdId).first;

    int totalAvailablePaise = 0;
    for (final acc in accounts) {
      totalAvailablePaise += acc.currentBalancePaise;
    }

    int ccOutstandingPaise = 0;
    int cardBorrowDeltaPaise = 0;
    for (final card in cards) {
      final txns = await (db.select(db.cardTransactionsTable)..where((t) => t.cardId.equals(card.id))).get();
      final delta = txns.fold<int>(0, (s, t) => s + t.amountPaise);
      ccOutstandingPaise += card.previousOutstandingPaise + delta;
      cardBorrowDeltaPaise += delta;
    }

    final receivables = await (db.select(db.receivablesTable)..where((r) => r.householdId.equals(householdId))).get();
    int returnAwaitedPaise = 0;
    for (final rec in receivables) {
      if (rec.status == 'open') {
        returnAwaitedPaise += rec.amountPaise;
      }
    }

    final plannedBills = await (db.select(db.plannedBillsTable)..where((b) => b.householdId.equals(householdId))).get();
    int toBePaidPaise = 0;
    for (final bill in plannedBills) {
      if (!bill.isPaid) {
        toBePaidPaise += bill.amountPaise;
      }
    }

    final funds = await db.fundDao.getAllActive(householdId: householdId);
    int fundReservesPaise = 0;
    for (final f in funds) {
      fundReservesPaise += f.openingReservePaise;
    }
    // B3: Total Reserve pool includes sinking funds opening reserves + CC outstanding - return awaited (Excel Annexure!E18)
    final reservesSetAsidePaise = fundReservesPaise + ccOutstandingPaise - returnAwaitedPaise;

    final budgets = await (db.select(db.budgetsTable)..where((b) {
      final cond = b.yearMonth.equals(ym.toString()) & b.householdId.equals(householdId);
      return cond;
    })).get();

    final entriesDomain = entries.map((e) {
      return Entry(
        id: e.id,
        householdId: e.householdId,
        categoryId: e.categoryId,
        kind: EntryKind.values.firstWhere((k) => k.name == e.kind),
        accountId: e.accountId,
        cardId: e.cardId,
        entryDate: e.entryDate,
        amount: Money(e.amountPaise),
        note: e.note,
        parentId: e.parentId,
        createdBy: e.createdBy,
        version: e.version,
        createdAt: e.createdAt,
        updatedAt: e.updatedAt,
        deletedAt: e.deletedAt,
      );
    }).toList();

    final budgetLines = <BudgetLine>[];
    int incomeBudgetPaise = 0;
    int spendingBudgetPaise = 0;

    for (final cat in categories) {
      final matchingBudget = budgets.where((b) => b.categoryId == cat.id);
      final budgetAmount = matchingBudget.isNotEmpty ? matchingBudget.first.amountPaise : 0;
      
      if (cat.kind == 'income') {
        incomeBudgetPaise += budgetAmount;
      } else if (cat.kind == 'spending') {
        spendingBudgetPaise += budgetAmount;
      }
      
      final line = BudgetEngine.computeLine(
        categoryId: cat.id,
        budget: Money(budgetAmount),
        ym: ym,
        entries: entriesDomain,
      );
      budgetLines.add(line);
    }

    final spendingLines = budgetLines.where((l) {
      final cat = categories.firstWhere((c) => c.id == l.categoryId);
      return cat.kind == 'spending';
    }).toList();

    final protectionLines = budgetLines.where((l) {
      final cat = categories.firstWhere((c) => c.id == l.categoryId);
      return cat.kind == 'protection';
    }).toList();

    final savingLines = budgetLines.where((l) {
      final cat = categories.firstWhere((c) => c.id == l.categoryId);
      return cat.kind == 'saving';
    }).toList();

    final layerBudgets = [
      BudgetEngine.computeLayer(layerName: 'Spending', lines: spendingLines),
      BudgetEngine.computeLayer(layerName: 'Protection', lines: protectionLines),
      BudgetEngine.computeLayer(layerName: 'Saving', lines: savingLines),
    ];

    final openingBalancePaise = snap?.openingBalancePaise ?? prevSnap?.closingBalancePaise ?? 0;
    final lastMonthReservesPaise = snap?.lastMonthReservesPaise ?? prevSnap?.reservesPaise ?? 0;

    final actuals = MonthActuals(
      yearMonth: ym,
      openingBalance: Money(openingBalancePaise.toInt()),
      lastMonthReserves: Money(lastMonthReservesPaise.toInt()),
      income: Money(netIncomePaise),
      adjustments: Money(adjustmentsPaise),
      spending: Money(spendingPaise),
      protection: Money(protectionPaise),
      saving: Money(savingPaise),
      reservesSetAside: Money(reservesSetAsidePaise),
      totalAvailable: Money(totalAvailablePaise),
      ccOutstanding: Money(ccOutstandingPaise),
      returnAwaited: Money(returnAwaitedPaise),
      toBePaid: Money(toBePaidPaise),
    );

    final waterfall = WaterfallEngine.compute(actuals);

    final unbudgetedIncome = waterfall.unbudgetedIncome(Money(incomeBudgetPaise));
    final unspentBudget = waterfall.unspentBudget(Money(spendingBudgetPaise));

    MonthSnapshot? snapshotDomain;
    if (snap != null) {
      snapshotDomain = MonthSnapshot(
        id: snap.id,
        householdId: snap.householdId,
        yearMonth: YearMonth.parse(snap.yearMonth),
        openingBalance: Money(snap.openingBalancePaise),
        lastMonthReserves: Money(snap.lastMonthReservesPaise),
        income: Money(snap.incomePaise),
        adjustments: Money(snap.adjustmentsPaise),
        spending: Money(snap.spendingPaise),
        protection: Money(snap.protectionPaise),
        saving: Money(snap.savingPaise),
        reserves: Money(snap.reservesPaise),
        closingBalance: Money(snap.closingBalancePaise),
        remaining: Money(snap.remainingPaise),
        status: snap.status == 'closed' ? MonthStatus.closed : MonthStatus.open,
        closedAt: snap.closedAt,
      );
    }

    return DashboardVM(
      waterfall: waterfall,
      layerBudgets: layerBudgets,
      totalAvailable: Money(totalAvailablePaise),
      ccOutstanding: Money(ccOutstandingPaise),
      returnAwaited: Money(returnAwaitedPaise),
      toBePaid: Money(toBePaidPaise),
      unbudgetedIncome: unbudgetedIncome,
      unspentBudget: unspentBudget,
      snapshot: snapshotDomain,
    );
  });
});
