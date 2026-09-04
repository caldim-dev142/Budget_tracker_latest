import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/tables.dart';

part 'goal_dao.g.dart';

@DriftAccessor(tables: [SavingGoalsTable, GoalContributionsTable])
class GoalDao extends DatabaseAccessor<AppDatabase> with _$GoalDaoMixin {
  GoalDao(super.db);

  Stream<List<SavingGoalsTableData>> watchActiveGoals({String? householdId}) {
    return (select(savingGoalsTable)
          ..where((g) {
            final isNotArchived = g.archivedAt.isNull();
            if (householdId != null && householdId.isNotEmpty) {
              return isNotArchived & g.householdId.equals(householdId);
            }
            return isNotArchived;
          }))
        .watch();
  }

  Future<List<SavingGoalsTableData>> getAllActive({String? householdId}) {
    return (select(savingGoalsTable)
          ..where((g) {
            final isNotArchived = g.archivedAt.isNull();
            if (householdId != null && householdId.isNotEmpty) {
              return isNotArchived & g.householdId.equals(householdId);
            }
            return isNotArchived;
          }))
        .get();
  }

  Stream<List<GoalContributionsTableData>> watchContributionsForGoal(String goalId) {
    return (select(goalContributionsTable)
          ..where((c) => c.goalId.equals(goalId))
          ..orderBy([(c) => OrderingTerm.desc(c.contributionDate)]))
        .watch();
  }

  Future<void> upsertGoal(SavingGoalsTableCompanion goal) {
    return into(savingGoalsTable).insertOnConflictUpdate(goal);
  }

  Future<void> insertContribution(GoalContributionsTableCompanion contrib) {
    return into(goalContributionsTable).insert(contrib);
  }
}
