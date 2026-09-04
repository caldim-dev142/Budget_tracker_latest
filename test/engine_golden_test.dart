import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:budget_tracker/domain/engine/waterfall.dart';
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
}
