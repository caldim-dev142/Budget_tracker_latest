import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/tables.dart';

part 'fund_dao.g.dart';

@DriftAccessor(tables: [SinkingFundsTable, FundMovementsTable])
class FundDao extends DatabaseAccessor<AppDatabase> with _$FundDaoMixin {
  FundDao(super.db);

  Stream<List<SinkingFundsTableData>> watchActiveFunds({String? householdId}) {
    return (select(sinkingFundsTable)
          ..where((f) {
            final isNotArchived = f.archivedAt.isNull();
            if (householdId != null && householdId.isNotEmpty) {
              return isNotArchived & f.householdId.equals(householdId);
            }
            return isNotArchived;
          }))
        .watch();
  }

  Future<List<SinkingFundsTableData>> getAllActive({String? householdId}) {
    return (select(sinkingFundsTable)
          ..where((f) {
            final isNotArchived = f.archivedAt.isNull();
            if (householdId != null && householdId.isNotEmpty) {
              return isNotArchived & f.householdId.equals(householdId);
            }
            return isNotArchived;
          }))
        .get();
  }

  Future<List<FundMovementsTableData>> getMovements(String fundId) {
    return (select(fundMovementsTable)
          ..where((m) => m.fundId.equals(fundId)))
        .get();
  }

  Stream<List<FundMovementsTableData>> watchMovementsForFund(String fundId, String yearMonth) {
    // yearMonth = 'YYYY-MM' — filter by month
    return (select(fundMovementsTable)
          ..where((m) => m.fundId.equals(fundId)))
        .watch();
  }

  Future<void> upsertFund(SinkingFundsTableCompanion fund) {
    return into(sinkingFundsTable).insertOnConflictUpdate(fund);
  }

  Future<void> insertMovement(FundMovementsTableCompanion movement) {
    return into(fundMovementsTable).insert(movement);
  }
}
