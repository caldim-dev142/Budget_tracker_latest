import '../../core/utils/money.dart';
import '../../core/utils/month.dart';
import '../entities/entry.dart';

/// Budget vs Actual calculation engine (doc 01 §6, doc 02 §FR-BUD).
///
/// Budget is authored at item level and rolls up.
/// Actual is always computed from entries (never stored).
class BudgetEngine {
  BudgetEngine._();

  /// Compute budget line for one category.
  /// doc 01 §6: difference = actual − budget (positive = overspent for expenses).
  static BudgetLine computeLine({
    required String categoryId,
    required Money budget,
    required YearMonth ym,
    required List<Entry> entries,
  }) {
    final actual = _actualForCategory(categoryId, ym, entries);
    return BudgetLine(
      categoryId: categoryId,
      budget: budget,
      actual: actual,
    );
  }

  /// Aggregate budget lines for a layer.
  static LayerBudget computeLayer({
    required String layerName,
    required List<BudgetLine> lines,
  }) {
    final totalBudget = lines.fold<Money>(Money.zero, (s, l) => s + l.budget);
    final totalActual = lines.fold<Money>(Money.zero, (s, l) => s + l.actual);
    return LayerBudget(
      name: layerName,
      budget: totalBudget,
      actual: totalActual,
      lines: lines,
    );
  }

  static Money _actualForCategory(
    String categoryId,
    YearMonth ym,
    List<Entry> entries,
  ) {
    return entries
        .where((e) =>
            e.categoryId == categoryId &&
            e.yearMonth == ym &&
            e.deletedAt == null)
        .fold<Money>(Money.zero, (s, e) => s + e.amount);
  }
}

/// One category's budget vs actual line (doc 01 §6, doc 09 S7/S8).
class BudgetLine {
  final String categoryId;
  final Money budget;
  final Money actual;

  const BudgetLine({
    required this.categoryId,
    required this.budget,
    required this.actual,
  });

  /// Difference = Actual − Budget.
  /// > 0 means overspent for expenses (bad), but means earned more for income (good).
  /// The UI must colour by category kind, not by raw sign (doc 01 §6, doc 02 §5 edge 4).
  Money get difference => actual - budget;

  /// Fraction used. Returns > 1.0 if over budget.
  double get pctUsed {
    if (budget.isZero) return 0.0;
    return actual.paise / budget.paise;
  }

  bool get isOverBudget => pctUsed > 1.0;
  bool get isNearBudget => pctUsed >= 0.8 && pctUsed <= 1.0;
}

/// Aggregated budget for a layer/group.
class LayerBudget {
  final String name;
  final Money budget;
  final Money actual;
  final List<BudgetLine> lines;

  const LayerBudget({
    required this.name,
    required this.budget,
    required this.actual,
    required this.lines,
  });

  Money get difference => actual - budget;

  double get pctUsed {
    if (budget.isZero) return 0.0;
    return actual.paise / budget.paise;
  }

  bool get isOverBudget => pctUsed > 1.0;
}
