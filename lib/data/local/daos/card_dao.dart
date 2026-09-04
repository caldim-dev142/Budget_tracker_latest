import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/tables.dart';

part 'card_dao.g.dart';

@DriftAccessor(tables: [CreditCardsTable, CardTransactionsTable])
class CardDao extends DatabaseAccessor<AppDatabase> with _$CardDaoMixin {
  CardDao(super.db);

  Stream<List<CreditCardsTableData>> watchActiveCards({String? householdId}) {
    return (select(creditCardsTable)
          ..where((c) {
            final isActive = c.isActive.equals(true);
            if (householdId != null && householdId.isNotEmpty) {
              return isActive & c.householdId.equals(householdId);
            }
            return isActive;
          }))
        .watch();
  }

  Stream<List<CardTransactionsTableData>> watchTransactionsForCard(String cardId) {
    return (select(cardTransactionsTable)
          ..where((t) => t.cardId.equals(cardId))
          ..orderBy([(t) => OrderingTerm.desc(t.txnDate)]))
        .watch();
  }

  Future<void> upsertCard(CreditCardsTableCompanion card) {
    return into(creditCardsTable).insertOnConflictUpdate(card);
  }

  Future<void> insertTransaction(CardTransactionsTableCompanion txn) {
    return into(cardTransactionsTable).insert(txn);
  }
}
