/// Pure calculation helpers used in Reports and Financial Insights.
///
/// Designed to be standalone, deterministic, and testable without DB or Flutter dependencies.
class ReportCalculations {
  ReportCalculations._();

  /// Classifies an adjustment entry based on category `isDeduction`.
  ///
  /// - `isDeduction == true`: Outflow adjustment (deduction / money leaving), net negative.
  /// - `isDeduction == false`: Inflow adjustment (addition / money entering), net positive.
  static int signedAdjustmentAmount({
    required int amountPaise,
    required bool isDeduction,
  }) {
    final absAmount = amountPaise.abs();
    return isDeduction ? -absAmount : absAmount;
  }

  /// Calculates cashflow plan allocation based on budget and target split percentages.
  ///
  /// When totalBudgetPaise is null or <= 0, allocations are strictly 0 (no synthetic defaults).
  static Map<String, int> computePlanAllocation({
    int? totalBudgetPaise,
    double spendingRatio = 0.50,
    double savingRatio = 0.30,
    double protectionRatio = 0.20,
  }) {
    if (totalBudgetPaise == null || totalBudgetPaise <= 0) {
      return {
        'spending': 0,
        'saving': 0,
        'protection': 0,
      };
    }

    final spending = (totalBudgetPaise * spendingRatio).round();
    final saving = (totalBudgetPaise * savingRatio).round();
    final protection = totalBudgetPaise - spending - saving; // Preserve exact total sum

    return {
      'spending': spending,
      'saving': saving,
      'protection': protection,
    };
  }

  /// Computes cumulative savings trajectory over time from closed monthly savings figures.
  ///
  /// Returns empty list if monthlySavingsPaise is empty.
  static List<int> computeSavingsTrajectory(List<int> monthlySavingsPaise) {
    if (monthlySavingsPaise.isEmpty) return [];

    final trajectory = <int>[];
    int cumulative = 0;
    for (final saving in monthlySavingsPaise) {
      cumulative += saving;
      trajectory.add(cumulative);
    }
    return trajectory;
  }

  /// Computes the progress ratio (0.0 to 1.0+) of a savings goal.
  ///
  /// If targetPaise is null or <= 0, returns 0.0.
  static double computeGoalProgress({
    int? targetPaise,
    required int currentPaise,
  }) {
    if (targetPaise == null || targetPaise <= 0) return 0.0;
    if (currentPaise <= 0) return 0.0;
    return currentPaise / targetPaise;
  }
}
