import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/category_seed.dart';
import '../../data/local/database.dart';
import '../../core/utils/month.dart';

const _uuid = Uuid();

/// Seeds the database with initial category taxonomy and demo data on first launch.
class AppInitService {
  AppInitService._();

  static Future<void> seed(AppDatabase db) async {
    // ── 1. Categories ──────────────────────────────────────────────────────────
    final cats = await db.categoryDao.getAllActive();
    if (cats.isEmpty) {
      const householdId = 'local'; // Will be updated after first login
      final seedCats = buildSeedCategories(householdId);
      final companions = seedCats.map((c) {
        return CategoriesTableCompanion.insert(
          id: c.id,
          householdId: c.householdId,
          kind: c.kind.name,
          groupCode: Value(c.groupCode),
          name: c.name,
          needOrWant: Value(c.needOrWant?.name),
          isDeduction: Value(c.isDeduction),
          isSystem: Value(c.isSystem),
          sortOrder: Value(c.sortOrder),
        );
      }).toList();
      await db.categoryDao.upsertAll(companions);
    }
    // Upgrade existing Lending/Return(-) & Others(Outflow) categories to isDeduction = true
    await (db.update(db.categoriesTable)
          ..where((c) => c.name.equals('Lending/Return(-)') | c.name.equals('Others(Outflow)')))
        .write(const CategoriesTableCompanion(isDeduction: Value(true)));
    // ── 2. Default Accounts (Zero Balance) ──────────────────────────────────
    final accounts = await db.accountDao.getAllActive();
    if (accounts.isEmpty) {
      await db.accountDao.upsertAccount(
        AccountsTableCompanion.insert(
          id: 'acc-savings',
          householdId: 'local',
          name: 'Savings Account',
          type: 'bank',
          currentBalancePaise: const Value(0),
          isActive: const Value(true),
          sortOrder: const Value(1),
        ),
      );
      await db.accountDao.upsertAccount(
        AccountsTableCompanion.insert(
          id: 'acc-cash',
          householdId: 'local',
          name: 'Cash Wallet',
          type: 'cash',
          currentBalancePaise: const Value(0),
          isActive: const Value(true),
          sortOrder: const Value(2),
        ),
      );
    }
  }

  /// Clears any leftover dummy/demo data from previous app versions.
  static Future<void> clearAllDummyData(AppDatabase db) async {
    try {
      // Delete dummy entries
      await (db.delete(db.entriesTable)
            ..where((e) => e.createdBy.equals('demo-user') | e.householdId.equals('local')))
          .go();

      // Reset default local account balances to zero
      await (db.update(db.accountsTable)
            ..where((a) => a.householdId.equals('local')))
          .write(const AccountsTableCompanion(currentBalancePaise: Value(0)));

      // Delete dummy sinking funds & goals with local householdId
      await (db.delete(db.sinkingFundsTable)
            ..where((f) => f.householdId.equals('local')))
          .go();

      await (db.delete(db.savingGoalsTable)
            ..where((g) => g.householdId.equals('local')))
          .go();
    } catch (_) {}
  }

  /// Ensures that default category taxonomy and accounts exist for an authenticated household.
  static Future<void> ensureUserHouseholdSeed(AppDatabase db, String householdId) async {
    if (householdId.isEmpty || householdId == 'local') return;

    // 1. Categories
    final existingCats = await (db.select(db.categoriesTable)
          ..where((c) => c.householdId.equals(householdId)))
        .get();

    if (existingCats.isEmpty) {
      final seedCats = buildSeedCategories(householdId);
      final companions = seedCats.map((c) {
        return CategoriesTableCompanion.insert(
          id: '${c.id}-$householdId',
          householdId: householdId,
          kind: c.kind.name,
          groupCode: Value(c.groupCode),
          name: c.name,
          needOrWant: Value(c.needOrWant?.name),
          isDeduction: Value(c.isDeduction),
          isSystem: Value(c.isSystem),
          sortOrder: Value(c.sortOrder),
        );
      }).toList();
      await db.categoryDao.upsertAll(companions);
    }

    // 2. Default Accounts for Household
    final existingAccounts = await (db.select(db.accountsTable)
          ..where((a) => a.householdId.equals(householdId)))
        .get();

    if (existingAccounts.isEmpty) {
      await db.accountDao.upsertAccount(
        AccountsTableCompanion.insert(
          id: 'acc-savings-$householdId',
          householdId: householdId,
          name: 'Savings Account',
          type: 'bank',
          currentBalancePaise: const Value(0),
          isActive: const Value(true),
          sortOrder: const Value(1),
        ),
      );
      await db.accountDao.upsertAccount(
        AccountsTableCompanion.insert(
          id: 'acc-cash-$householdId',
          householdId: householdId,
          name: 'Cash Wallet',
          type: 'cash',
          currentBalancePaise: const Value(0),
          isActive: const Value(true),
          sortOrder: const Value(2),
        ),
      );
    }
  }
}
