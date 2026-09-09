import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/core/utils/money.dart';
import '../../lib/core/utils/month.dart';
import '../../lib/domain/engine/waterfall.dart';
import '../../lib/domain/engine/budget.dart';
import '../../lib/domain/engine/rollups.dart';
import '../../lib/domain/engine/rollover.dart';
import '../../lib/domain/engine/reserves.dart';
import '../../lib/domain/entities/month_snapshot.dart';
import '../../lib/domain/entities/entry.dart';
import '../../lib/domain/entities/category.dart';

void main() {
  // Load golden fixtures
  late Map<String, dynamic> fixtures;
  late List<Map<String, dynamic>> scenarios;

  setUpAll(() {
    final file = File('test/golden_fixtures.json');
    fixtures = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    scenarios =
        (fixtures['scenarios'] as List<dynamic>).cast<Map<String, dynamic>>();
  });

  // ─── Waterfall Engine Tests ────────────────────────────────────────────────

  group('WaterfallEngine', () {
    MonthActuals _makeActuals(Map<String, dynamic> input) {
      final income = (input['income'] as int) - (input['incomeDeductions'] as int? ?? 0);
      return MonthActuals(
        yearMonth: YearMonth(2023, 11),
        openingBalance: Money(input['openingBalance'] as int),
        lastMonthReserves: Money(input['lastMonthReserves'] as int),
        income: Money(income),
        adjustments: Money(input['adjustments'] as int),
        spending: Money(input['spending'] as int),
        protection: Money(input['protection'] as int),
        saving: Money(input['saving'] as int),
        reservesSetAside: Money(input['reservesSetAside'] as int),
        totalAvailable: Money.zero, // not needed for waterfall
        ccOutstanding: Money.zero,
        returnAwaited: Money.zero,
        toBePaid: Money.zero,
      );
    }

    test('base_case: waterfall remaining equals golden fixture', () {
      final s = scenarios.firstWhere((s) => s['id'] == 'base_case');
      final actuals = _makeActuals(s['input'] as Map<String, dynamic>);
      final result = WaterfallEngine.compute(actuals);
      final expected = (s['expected'] as Map<String, dynamic>)['remaining'] as int;
      expect(result.remaining.paise, equals(expected),
          reason: 'Remaining must be paise-exact: ${s['expected']['comment']}');
    });

    test('with_opening_balance: waterfall remaining correct', () {
      final s = scenarios.firstWhere((s) => s['id'] == 'with_opening_balance');
      final actuals = _makeActuals(s['input'] as Map<String, dynamic>);
      final result = WaterfallEngine.compute(actuals);
      final expected = (s['expected'] as Map<String, dynamic>)['remaining'] as int;
      expect(result.remaining.paise, equals(expected));
    });

    test('edge_negative_remaining: allows negative remaining', () {
      final s = scenarios.firstWhere((s) => s['id'] == 'edge_negative_remaining');
      final actuals = _makeActuals(s['input'] as Map<String, dynamic>);
      final result = WaterfallEngine.compute(actuals);
      final expected = (s['expected'] as Map<String, dynamic>)['remaining'] as int;
      expect(result.remaining.paise, equals(expected));
      expect(result.remaining.isNegative, isTrue);
    });

    test('edge_zero_income: handles zero income month', () {
      final s = scenarios.firstWhere((s) => s['id'] == 'edge_zero_income');
      final actuals = _makeActuals(s['input'] as Map<String, dynamic>);
      final result = WaterfallEngine.compute(actuals);
      final expected = (s['expected'] as Map<String, dynamic>)['remaining'] as int;
      expect(result.remaining.paise, equals(expected));
    });

    test('edge_negative_adjustment: handles net negative adjustments', () {
      final s = scenarios.firstWhere((s) => s['id'] == 'edge_negative_adjustment');
      final actuals = _makeActuals(s['input'] as Map<String, dynamic>);
      final result = WaterfallEngine.compute(actuals);
      final expected = (s['expected'] as Map<String, dynamic>)['remaining'] as int;
      expect(result.remaining.paise, equals(expected));
    });

    test('waterfall result has 8 steps', () {
      final actuals = MonthActuals(
        yearMonth: YearMonth(2023, 11),
        openingBalance: const Money(5000000),
        lastMonthReserves: const Money(1000000),
        income: const Money(8000000),
        adjustments: const Money(500000),
        spending: const Money(3000000),
        protection: const Money(1000000),
        saving: const Money(1000000),
        reservesSetAside: const Money(2000000),
        totalAvailable: Money.zero,
        ccOutstanding: Money.zero,
        returnAwaited: Money.zero,
        toBePaid: Money.zero,
      );
      final result = WaterfallEngine.compute(actuals);
      expect(result.steps.length, equals(8));
    });

    test('property: waterfall is balance-conserving (no money created/destroyed)', () {
      // Property: remaining = opening + reserves + income + adj - spend - prot - save - res
      final actuals = MonthActuals(
        yearMonth: YearMonth(2023, 11),
        openingBalance: const Money(3000000),
        lastMonthReserves: const Money(1000000),
        income: const Money(9000000),
        adjustments: const Money(-500000),
        spending: const Money(4000000),
        protection: const Money(2000000),
        saving: const Money(1500000),
        reservesSetAside: const Money(3000000),
        totalAvailable: Money.zero,
        ccOutstanding: Money.zero,
        returnAwaited: Money.zero,
        toBePaid: Money.zero,
      );
      final result = WaterfallEngine.compute(actuals);
      final manual = actuals.openingBalance +
          actuals.lastMonthReserves +
          actuals.income +
          actuals.adjustments -
          actuals.spending -
          actuals.protection -
          actuals.saving -
          actuals.reservesSetAside;
      expect(result.remaining.paise, equals(manual.paise));
    });

    test('property: no floating point in money math', () {
      // All arithmetic on integer paise — no doubles involved
      final m = Money.fromRupees(1554.19);
      // 1554.19 rupees = 155419 paise
      expect(m.paise, equals(155419));
      // Round-trip
      expect(m.inRupees, closeTo(1554.19, 0.001));
    });
  });

  // ─── Budget Engine Tests ───────────────────────────────────────────────────

  group('BudgetEngine', () {
    test('budget_pct_over: isOverBudget when actual > budget', () {
      final s = scenarios.firstWhere((s) => s['id'] == 'budget_pct_over');
      final input = s['input'] as Map<String, dynamic>;
      final expected = s['expected'] as Map<String, dynamic>;

      final line = BudgetLine(
        categoryId: 'test',
        budget: Money(input['budget'] as int),
        actual: Money(input['actual'] as int),
      );

      expect(line.difference.paise, equals(expected['difference'] as int));
      expect(line.pctUsed, closeTo(expected['pctUsed'] as double, 0.001));
      expect(line.isOverBudget, isTrue);
    });

    test('budget_pct_near: isNearBudget at 80-100%', () {
      final s = scenarios.firstWhere((s) => s['id'] == 'budget_pct_near');
      final input = s['input'] as Map<String, dynamic>;

      final line = BudgetLine(
        categoryId: 'test',
        budget: Money(input['budget'] as int),
        actual: Money(input['actual'] as int),
      );

      expect(line.isOverBudget, isFalse);
      expect(line.isNearBudget, isTrue);
    });

    test('budget_pct_zero: handles zero budget without division by zero', () {
      final line = BudgetLine(
        categoryId: 'test',
        budget: Money.zero,
        actual: const Money(500000),
      );
      expect(line.pctUsed, equals(0.0));
      expect(line.isOverBudget, isFalse);
    });
  });

  // ─── Reserve Engine Tests ──────────────────────────────────────────────────

  group('ReservesEngine', () {
    test('edge_negative_reserve: closingReserve can be negative (doc 02 §5 edge 5)', () {
      final s = scenarios.firstWhere((s) => s['id'] == 'edge_negative_reserve');
      final input = s['input'] as Map<String, dynamic>;
      final expected = s['expected'] as Map<String, dynamic>;

      final closing = ReservesEngine.closingReserve(
        openingReserve: Money(input['fundOpeningReserve'] as int),
        contributions: Money(input['fundContributions'] as int),
        withdrawals: Money(input['fundWithdrawals'] as int),
      );

      expect(closing.paise, equals(expected['closingReserve'] as int));
      expect(closing.isNegative, isTrue);
    });
  });

  // ─── Rollup Engine Tests ───────────────────────────────────────────────────

  group('RollupEngine', () {
    test('rollup_group_total: groupTotal equals sum of items', () {
      final s = scenarios.firstWhere((s) => s['id'] == 'rollup_group_total');
      final items = (s['input']['itemAmounts'] as List).cast<int>();
      final expected = (s['expected'] as Map<String, dynamic>)['groupTotal'] as int;

      final total = items.fold(Money.zero, (acc, v) => acc + Money(v));
      expect(total.paise, equals(expected));
    });

    test('property: groupTotal = sum of itemTotals', () {
      // Any partitioning must preserve total
      final amounts = [100000, 200000, 300000, 400000, 500000];
      final total = amounts.fold(Money.zero, (s, v) => s + Money(v));
      expect(total.paise, equals(1500000));
    });

    group('netAdjustments sign logic', () {
      final ym = YearMonth(2023, 11);
      final catBorrow = const Category(
        id: 'cat_borrow',
        householdId: 'hh1',
        kind: EntryKind.adjustment,
        name: 'Borrow / Return',
        isDeduction: false,
      );
      final catLending = const Category(
        id: 'cat_lending',
        householdId: 'hh1',
        kind: EntryKind.adjustment,
        name: 'Lending / Return',
        isDeduction: true,
      );
      final catCcBorrow = const Category(
        id: 'cat_cc_borrow',
        householdId: 'hh1',
        kind: EntryKind.adjustment,
        name: 'Credit Card Borrow / Payment',
        isDeduction: false,
      );
      final categoryMap = {
        'cat_borrow': catBorrow,
        'cat_lending': catLending,
        'cat_cc_borrow': catCcBorrow,
      };

      test('Case A — Positive adjustment: Income-style adjustment +1000 paise', () {
        final entries = [
          Entry(
            id: 'e1',
            householdId: 'hh1',
            categoryId: 'cat_borrow',
            kind: EntryKind.adjustment,
            entryDate: DateTime(2023, 11, 5),
            amount: const Money(1000),
            createdBy: 'u1',
            createdAt: DateTime(2023, 11, 1),
            updatedAt: DateTime(2023, 11, 1),
          ),
        ];

        final net = RollupEngine.netAdjustments(ym, entries, categoryMap: categoryMap);
        expect(net.paise, equals(1000));
      });

      test('Case B — Deduction adjustment: Lending adjustment -1000 paise', () {
        final entries = [
          Entry(
            id: 'e2',
            householdId: 'hh1',
            categoryId: 'cat_lending',
            kind: EntryKind.adjustment,
            entryDate: DateTime(2023, 11, 6),
            amount: const Money(1000),
            createdBy: 'u1',
            createdAt: DateTime(2023, 11, 1),
            updatedAt: DateTime(2023, 11, 1),
          ),
        ];

        final net = RollupEngine.netAdjustments(ym, entries, categoryMap: categoryMap);
        expect(net.paise, equals(-1000));
      });

      test('Case C — Mixed adjustments: +5000, -2000, +1000 = +4000 paise', () {
        final entries = [
          Entry(
            id: 'e3',
            householdId: 'hh1',
            categoryId: 'cat_borrow',
            kind: EntryKind.adjustment,
            entryDate: DateTime(2023, 11, 1),
            amount: const Money(5000),
            createdBy: 'u1',
            createdAt: DateTime(2023, 11, 1),
            updatedAt: DateTime(2023, 11, 1),
          ),
          Entry(
            id: 'e4',
            householdId: 'hh1',
            categoryId: 'cat_lending',
            kind: EntryKind.adjustment,
            entryDate: DateTime(2023, 11, 2),
            amount: const Money(2000),
            createdBy: 'u1',
            createdAt: DateTime(2023, 11, 1),
            updatedAt: DateTime(2023, 11, 1),
          ),
          Entry(
            id: 'e5',
            householdId: 'hh1',
            categoryId: 'cat_cc_borrow',
            kind: EntryKind.adjustment,
            entryDate: DateTime(2023, 11, 3),
            amount: const Money(1000),
            createdBy: 'u1',
            createdAt: DateTime(2023, 11, 1),
            updatedAt: DateTime(2023, 11, 1),
          ),
        ];

        final net = RollupEngine.netAdjustments(ym, entries, categoryMap: categoryMap);
        expect(net.paise, equals(4000));

        // Also test using isDeductionLookup
        final netLookup = RollupEngine.netAdjustments(
          ym,
          entries,
          isDeductionLookup: (catId) => catId == 'cat_lending',
        );
        expect(netLookup.paise, equals(4000));
      });
    });
  });

  // ─── Rollover Engine Tests ─────────────────────────────────────────────────

  group('RolloverEngine', () {
    test('rollover_next_month: closingBalance = totalAvailable - reserves', () {
      final s = scenarios.firstWhere((s) => s['id'] == 'rollover_next_month');
      final input = s['input'] as Map<String, dynamic>;
      final expected = s['expected'] as Map<String, dynamic>;

      final closing = RolloverEngine.closingBalance(
        totalAvailable: Money(input['totalAvailable'] as int),
        reserves: Money(input['reservesAtClose'] as int),
      );

      expect(closing.paise, equals(expected['closingBalance'] as int));
    });

    test('rollover idempotency: re-computing next opening from same data produces same result', () {
      final snapshot = MonthSnapshot(
        id: 'test-snap',
        householdId: 'hh1',
        yearMonth: YearMonth(2023, 11),
        openingBalance: const Money(5000000),
        lastMonthReserves: const Money(2000000),
        income: const Money(8000000),
        adjustments: const Money(500000),
        spending: const Money(3000000),
        protection: const Money(1000000),
        saving: const Money(1000000),
        reserves: const Money(4000000),
        closingBalance: const Money(3000000),
        remaining: const Money(3000000),
        status: MonthStatus.closed,
        closedAt: DateTime(2023, 11, 30),
      );

      final first = RolloverEngine.computeNextOpening(closedMonth: snapshot);
      final second = RolloverEngine.computeNextOpening(closedMonth: snapshot);

      expect(first.openingBalance.paise, equals(second.openingBalance.paise));
      expect(first.lastMonthReserves.paise, equals(second.lastMonthReserves.paise));
      expect(first.yearMonth, equals(second.yearMonth));
    });
  });

  // ─── Money Formatting Tests ────────────────────────────────────────────────

  group('MoneyFormatter', () {
    test('formats with Indian digit grouping', () {
      final m = const Money(15541900); // ₹1,55,419.00
      expect(MoneyFormatter.formatCompact(m), contains('1,55,419'));
    });

    test('signed format shows + for positive', () {
      final m = const Money(100000);
      expect(MoneyFormatter.formatSigned(m), startsWith('+'));
    });

    test('signed format shows - for negative', () {
      final m = const Money(-100000);
      expect(MoneyFormatter.formatSigned(m), startsWith('-'));
    });

    test('fromRupees converts correctly', () {
      final m = Money.fromRupees(1234.56);
      expect(m.paise, equals(123456));
    });
  });
}
