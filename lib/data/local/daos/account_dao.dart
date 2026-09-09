import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/tables.dart';

part 'account_dao.g.dart';

@DriftAccessor(tables: [AccountsTable])
class AccountDao extends DatabaseAccessor<AppDatabase> with _$AccountDaoMixin {
  AccountDao(super.db);

  Stream<List<AccountsTableData>> watchActiveAccounts({String? householdId}) {
    return (select(accountsTable)
          ..where((a) {
            final isActive = a.isActive.equals(true);
            if (householdId != null && householdId.isNotEmpty) {
              return isActive & a.householdId.equals(householdId);
            }
            return isActive;
          })
          ..orderBy([(a) => OrderingTerm.asc(a.sortOrder)]))
        .watch();
  }

  Future<List<AccountsTableData>> getAllActive({String? householdId}) {
    return (select(accountsTable)
          ..where((a) {
            final isActive = a.isActive.equals(true);
            if (householdId != null && householdId.isNotEmpty) {
              return isActive & a.householdId.equals(householdId);
            }
            return isActive;
          })
          ..orderBy([(a) => OrderingTerm.asc(a.sortOrder)]))
        .get();
  }

  Future<void> upsertAccount(AccountsTableCompanion account) {
    return into(accountsTable).insertOnConflictUpdate(account);
  }

  Future<void> updateBalance(String id, int balancePaise) {
    return (update(accountsTable)..where((a) => a.id.equals(id))).write(
      AccountsTableCompanion(currentBalancePaise: Value(balancePaise)),
    );
  }

  /// Automatically recalculates the balance of an account from all linked non-deleted entries
  Future<void> recalculateAccountBalance(String accountId) async {
    final account = await (select(accountsTable)..where((a) => a.id.equals(accountId))).getSingleOrNull();
    if (account == null) return;

    final entries = await (db.select(db.entriesTable)..where((e) => e.accountId.equals(accountId) & e.deletedAt.isNull())).get();
    if (entries.isEmpty) return;
    final categories = await select(db.categoriesTable).get();
    final categoryMap = {for (var c in categories) c.id: c};

    int balance = 0;
    for (final e in entries) {
      final amount = e.amountPaise;
      final cat = categoryMap[e.categoryId];
      final isDeduction = cat?.isDeduction ?? false;

      switch (e.kind) {
        case 'income':
          balance += amount;
          break;
        case 'incomeDeduction':
        case 'spending':
        case 'protection':
        case 'saving':
          balance -= amount;
          break;
        case 'adjustment':
          if (isDeduction) {
            balance -= amount;
          } else {
            balance += amount;
          }
          break;
      }
    }

    await updateBalance(accountId, balance);
  }

  /// Automatically recalculates balances for all active accounts
  Future<void> recalculateAllAccountBalances() async {
    final accounts = await select(accountsTable).get();
    for (final acc in accounts) {
      await recalculateAccountBalance(acc.id);
    }
  }

  /// Ensures any account with a positive balance has an opening balance entry so its balance is never lost
  Future<void> ensureOpeningBalanceEntries(String householdId) async {
    final accounts = await (select(accountsTable)..where((a) => a.householdId.equals(householdId))).get();
    for (final acc in accounts) {
      if (acc.currentBalancePaise > 0) {
        final entries = await (db.select(db.entriesTable)..where((e) => e.accountId.equals(acc.id) & e.deletedAt.isNull())).get();
        if (entries.isEmpty) {
          final incomeCat = await (db.select(db.categoriesTable)
                ..where((c) => c.householdId.equals(householdId) & c.kind.equals('income'))
                ..limit(1))
              .getSingleOrNull();
          final catId = incomeCat?.id ?? 'inc-05-$householdId';

          await db.entryDao.insertEntry(
            EntriesTableCompanion.insert(
              id: 'ob-${acc.id}',
              householdId: householdId,
              categoryId: catId,
              kind: 'income',
              accountId: Value(acc.id),
              entryDate: DateTime.now(),
              amountPaise: acc.currentBalancePaise,
              note: Value('Opening Balance - ${acc.name}'),
              createdBy: 'system',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
        }
      }
    }
  }
}
