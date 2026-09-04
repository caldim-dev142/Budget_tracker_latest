import '../../core/utils/money.dart';
import '../entities/month_snapshot.dart';

/// The waterfall calculation engine (doc 01 §7.2, doc 06 §3).
///
/// The waterfall walks left→right:
///   Opening + LastMonthReserves
///   + Income
///   + Adjustments (signed)
///   − Spending
///   − Protection
///   − Saving
///   − Reserves (set aside)
///   = Remaining
///
/// This function is the single most important computation in the app (doc 01 §12).
/// It must be tested against the golden fixtures from the workbook.
class WaterfallEngine {
  WaterfallEngine._();

  /// Compute Remaining from MonthActuals.
  /// All values in integer paise (BIGINT equivalent). No floating point.
  ///
  /// Dart equivalent of TypeScript engine/waterfall.ts (doc 06 §3):
  ///   let bal = openingBalance + lastMonthReserves;
  ///   bal += income;
  ///   bal += adjustments;  // signed
  ///   bal -= spending;
  ///   bal -= protection;
  ///   bal -= saving;
  ///   bal -= reserves;
  ///   return bal;
  static Money remaining(MonthActuals m) {
    var bal = m.openingBalance + m.lastMonthReserves;
    bal = bal + m.income;
    bal = bal + m.adjustments; // signed: can be negative (doc 01 §7.2, doc 06 §3)
    bal = bal - m.spending;
    bal = bal - m.protection;
    bal = bal - m.saving;
    bal = bal - m.reservesSetAside;
    return bal;
  }

  /// Compute the waterfall as a list of steps for the UI strip.
  static WaterfallResult compute(MonthActuals m) {
    final opening = m.openingBalance + m.lastMonthReserves;
    final afterIncome = opening + m.income;
    final afterAdjustments = afterIncome + m.adjustments;
    final afterSpending = afterAdjustments - m.spending;
    final afterProtection = afterSpending - m.protection;
    final afterSaving = afterProtection - m.saving;
    final afterReserves = afterSaving - m.reservesSetAside;

    return WaterfallResult(
      opening: opening,
      income: m.income,
      adjustments: m.adjustments,
      spending: m.spending,
      protection: m.protection,
      saving: m.saving,
      reserves: m.reservesSetAside,
      remaining: afterReserves,
      // Running values at each step
      steps: [
        WaterfallStep('Opening', opening, isAddition: true),
        WaterfallStep('Income', m.income, isAddition: true),
        WaterfallStep('Adjustments', m.adjustments, isAddition: m.adjustments.isPositive),
        WaterfallStep('Spending', m.spending, isAddition: false),
        WaterfallStep('Protection', m.protection, isAddition: false),
        WaterfallStep('Saving', m.saving, isAddition: false),
        WaterfallStep('Reserves', m.reservesSetAside, isAddition: false),
        WaterfallStep('Remaining', afterReserves, isAddition: true, isFinal: true),
      ],
    );
  }
}

class WaterfallResult {
  final Money opening;
  final Money income;
  final Money adjustments;
  final Money spending;
  final Money protection;
  final Money saving;
  final Money reserves;
  final Money remaining;
  final List<WaterfallStep> steps;

  const WaterfallResult({
    required this.opening,
    required this.income,
    required this.adjustments,
    required this.spending,
    required this.protection,
    required this.saving,
    required this.reserves,
    required this.remaining,
    required this.steps,
  });

  /// Layer share of income (doc 01 §7.3)
  /// Excel: Y16 = Y11 / $Y$14 where $Y$14 = opening + income
  double layerShareOfIncome(Money layerAmount) {
    final totalIncome = opening + income;
    if (totalIncome.isZero) return 0.0;
    return layerAmount.paise / totalIncome.paise;
  }

  /// Unbudgeted income (doc 01 §7.5)
  Money unbudgetedIncome(Money incomeBudget) {
    if (income.paise > incomeBudget.paise) {
      return income - incomeBudget;
    }
    return Money.zero;
  }

  /// Unspent budget (doc 01 §7.5)
  Money unspentBudget(Money spendingBudget) => spendingBudget - spending;
}

class WaterfallStep {
  final String label;
  final Money amount;
  final bool isAddition; // true = rising bar, false = falling bar
  final bool isFinal;    // final "Remaining" bar

  const WaterfallStep(
    this.label,
    this.amount, {
    required this.isAddition,
    this.isFinal = false,
  });
}
