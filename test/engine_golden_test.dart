import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:budget_tracker/domain/engine/waterfall.dart';
import 'package:budget_tracker/domain/engine/rollups.dart';
import 'package:budget_tracker/domain/entities/entry.dart';
import 'package:budget_tracker/domain/entities/month_snapshot.dart';
import 'package:budget_tracker/core/utils/money.dart';
import 'package:budget_tracker/core/utils/month.dart';

void main() {
  test('waterfall matches golden remaining', () {
    final file = File('test/golden_fixtures.json');
    expect(file.existsSync(), isTrue, reason: 'golden_fixtures.json should exist');
    
    final json = jsonDecode(file.readAsStringSync());
    final List scenarios = json['scenarios'];
    
    for (final s in scenarios) {
      final expected = s['expected'] as Map<String, dynamic>;
      if (expected['remaining'] == null) continue;
      
      final id = s['id'] as String;
      final input = s['input'] as Map<String, dynamic>;
      
      final netIncome = input['income'] - input['incomeDeductions'];
      final expectedNetIncome = expected['netIncome'];
      
      final actuals = MonthActuals(
        yearMonth: YearMonth.now(),
        openingBalance: Money(input['openingBalance']),
        lastMonthReserves: Money(input['lastMonthReserves']),
        income: Money(netIncome),
        adjustments: Money(input['adjustments']),
        spending: Money(input['spending']),
        protection: Money(input['protection']),
        saving: Money(input['saving']),
        reservesSetAside: Money(input['reservesSetAside']),
        totalAvailable: Money.zero,
        ccOutstanding: Money.zero,
        returnAwaited: Money.zero,
        toBePaid: Money.zero,
      );
      
      final remaining = WaterfallEngine.remaining(actuals);
      
      expect(netIncome, expectedNetIncome, reason: '$id: netIncome mismatch');
      expect(remaining.paise, expected['remaining'], reason: '$id: remaining mismatch');
    }
  });

  group('Adjustment Deduction Sign Verification (Phase 2)', () {
    test('Case A — Positive adjustment: Income-style (+1000 paise) produces +1000 paise', () {
      final entries = [
        Entry(
          id: 'adj1',
          householdId: 'h1',
          categoryId: 'cat_inflow',
          kind: EntryKind.adjustment,
          entryDate: DateTime(2023, 11, 1),
          amount: const Money(1000),
          createdBy: 'u1',
          createdAt: DateTime(2023, 11, 1),
          updatedAt: DateTime(2023, 11, 1),
        ),
      ];
      final net = RollupEngine.netAdjustments(
        YearMonth(2023, 11),
        entries,
        isDeductionLookup: (catId) => false,
      );
      expect(net.paise, equals(1000));
    });

    test('Case B — Deduction adjustment: Lending/Outflow (1000 paise) produces -1000 paise', () {
      final entries = [
        Entry(
          id: 'adj2',
          householdId: 'h1',
          categoryId: 'cat_outflow',
          kind: EntryKind.adjustment,
          entryDate: DateTime(2023, 11, 2),
          amount: const Money(1000),
          createdBy: 'u1',
          createdAt: DateTime(2023, 11, 1),
          updatedAt: DateTime(2023, 11, 1),
        ),
      ];
      final net = RollupEngine.netAdjustments(
        YearMonth(2023, 11),
        entries,
        isDeductionLookup: (catId) => catId == 'cat_outflow',
      );
      expect(net.paise, equals(-1000));
    });

    test('Case C — Mixed adjustments: +5000 paise, -2000 paise, +1000 paise produces +4000 paise', () {
      final entries = [
        Entry(
          id: 'adj_p1',
          householdId: 'h1',
          categoryId: 'cat_borrow',
          kind: EntryKind.adjustment,
          entryDate: DateTime(2023, 11, 1),
          amount: const Money(5000),
          createdBy: 'u1',
          createdAt: DateTime(2023, 11, 1),
          updatedAt: DateTime(2023, 11, 1),
        ),
        Entry(
          id: 'adj_d',
          householdId: 'h1',
          categoryId: 'cat_lending',
          kind: EntryKind.adjustment,
          entryDate: DateTime(2023, 11, 2),
          amount: const Money(2000),
          createdBy: 'u1',
          createdAt: DateTime(2023, 11, 1),
          updatedAt: DateTime(2023, 11, 1),
        ),
        Entry(
          id: 'adj_p2',
          householdId: 'h1',
          categoryId: 'cat_temp_in',
          kind: EntryKind.adjustment,
          entryDate: DateTime(2023, 11, 3),
          amount: const Money(1000),
          createdBy: 'u1',
          createdAt: DateTime(2023, 11, 1),
          updatedAt: DateTime(2023, 11, 1),
        ),
      ];
      final net = RollupEngine.netAdjustments(
        YearMonth(2023, 11),
        entries,
        isDeductionLookup: (catId) => catId == 'cat_lending',
      );
      expect(net.paise, equals(4000));
    });
  });
}
