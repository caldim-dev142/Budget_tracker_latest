import 'package:flutter_test/flutter_test.dart';
import 'package:budget_tracker/features/reports/utils/report_calculations.dart';

void main() {
  group('ReportCalculations — Phase 4 Pure Unit Tests', () {
    group('signedAdjustmentAmount', () {
      test('isDeduction: true produces negative adjustment (outflow)', () {
        final result = ReportCalculations.signedAdjustmentAmount(
          amountPaise: 50000,
          isDeduction: true,
        );
        expect(result, equals(-50000));
      });

      test('isDeduction: false produces positive adjustment (inflow)', () {
        final result = ReportCalculations.signedAdjustmentAmount(
          amountPaise: 25000,
          isDeduction: false,
        );
        expect(result, equals(25000));
      });

      test('negative input amount is treated as absolute magnitude', () {
        final resultDeduct = ReportCalculations.signedAdjustmentAmount(
          amountPaise: -30000,
          isDeduction: true,
        );
        expect(resultDeduct, equals(-30000));

        final resultAdd = ReportCalculations.signedAdjustmentAmount(
          amountPaise: -30000,
          isDeduction: false,
        );
        expect(resultAdd, equals(30000));
      });
    });

    group('computePlanAllocation', () {
      test('returns 0/0/0 when totalBudget is null or <= 0 (no synthetic defaults)', () {
        final nullResult = ReportCalculations.computePlanAllocation(
          totalBudgetPaise: null,
        );
        expect(nullResult['spending'], equals(0));
        expect(nullResult['saving'], equals(0));
        expect(nullResult['protection'], equals(0));

        final zeroResult = ReportCalculations.computePlanAllocation(
          totalBudgetPaise: 0,
        );
        expect(zeroResult['spending'], equals(0));
        expect(zeroResult['saving'], equals(0));
        expect(zeroResult['protection'], equals(0));
      });

      test('allocates 50/30/20 correctly preserving exact integer sum', () {
        final result = ReportCalculations.computePlanAllocation(
          totalBudgetPaise: 100000, // 1000 INR in paise
        );
        expect(result['spending'], equals(50000));
        expect(result['saving'], equals(30000));
        expect(result['protection'], equals(20000));
        expect(result['spending']! + result['saving']! + result['protection']!, equals(100000));
      });

      test('handles odd budget amounts without losing paise', () {
        const total = 99999;
        final result = ReportCalculations.computePlanAllocation(
          totalBudgetPaise: total,
        );
        final sum = result['spending']! + result['saving']! + result['protection']!;
        expect(sum, equals(total));
      });
    });

    group('computeSavingsTrajectory', () {
      test('returns empty list for empty savings input', () {
        final result = ReportCalculations.computeSavingsTrajectory([]);
        expect(result, isEmpty);
      });

      test('computes cumulative sum across monthly savings', () {
        final result = ReportCalculations.computeSavingsTrajectory([
          10000,
          15000,
          20000,
          5000,
        ]);
        expect(result, equals([10000, 25000, 45000, 50000]));
      });

      test('handles negative savings months (withdrawals) correctly', () {
        final result = ReportCalculations.computeSavingsTrajectory([
          20000,
          -5000,
          10000,
        ]);
        expect(result, equals([20000, 15000, 25000]));
      });
    });

    group('computeGoalProgress', () {
      test('returns 0.0 when target is null or zero', () {
        expect(ReportCalculations.computeGoalProgress(targetPaise: null, currentPaise: 5000), equals(0.0));
        expect(ReportCalculations.computeGoalProgress(targetPaise: 0, currentPaise: 5000), equals(0.0));
        expect(ReportCalculations.computeGoalProgress(targetPaise: -100, currentPaise: 5000), equals(0.0));
      });

      test('returns 0.0 when current amount is zero or negative', () {
        expect(ReportCalculations.computeGoalProgress(targetPaise: 100000, currentPaise: 0), equals(0.0));
        expect(ReportCalculations.computeGoalProgress(targetPaise: 100000, currentPaise: -500), equals(0.0));
      });

      test('computes accurate progress ratio', () {
        expect(
          ReportCalculations.computeGoalProgress(targetPaise: 100000, currentPaise: 50000),
          equals(0.5),
        );
        expect(
          ReportCalculations.computeGoalProgress(targetPaise: 200000, currentPaise: 150000),
          equals(0.75),
        );
        expect(
          ReportCalculations.computeGoalProgress(targetPaise: 100000, currentPaise: 100000),
          equals(1.0),
        );
      });
    });
  });
}
