import 'package:equatable/equatable.dart';
import '../../core/utils/money.dart';
import 'category.dart';

/// A saving goal (Saving sheet, doc 01 §5).
class SavingGoal extends Equatable {
  final String id;
  final String householdId;
  final SavingBucket bucket;     // retirement | children | otherGoals
  final String name;
  final Money? target;           // optional target corpus
  final Money monthlyBudget;     // planned contribution
  final List<GoalContribution> contributions;
  final DateTime? archivedAt;

  const SavingGoal({
    required this.id,
    required this.householdId,
    required this.bucket,
    required this.name,
    this.target,
    required this.monthlyBudget,
    this.contributions = const [],
    this.archivedAt,
  });

  Money get contributedThisMonth {
    // Filtered by caller for the active month; contributions here = this month's
    return contributions.fold(Money.zero, (s, c) => s + c.amount);
  }

  Money get lifetimeContributed =>
      contributions.fold(Money.zero, (s, c) => s + c.amount);

  double? get progressFraction {
    if (target == null || target!.isZero) return null;
    return lifetimeContributed.paise / target!.paise;
  }

  @override
  List<Object?> get props => [id, bucket, name, target, monthlyBudget, contributions];
}

class GoalContribution extends Equatable {
  final String id;
  final String goalId;
  final Money amount;
  final DateTime contributionDate;
  final String? note;

  const GoalContribution({
    required this.id,
    required this.goalId,
    required this.amount,
    required this.contributionDate,
    this.note,
  });

  @override
  List<Object?> get props => [id, goalId, amount, contributionDate];
}
