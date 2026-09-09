import 'package:drift/drift.dart';
import '../../core/constants/category_seed.dart';
import '../../data/local/database.dart';

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
    // (Default accounts seeding removed - user creates accounts explicitly)
  }

  /// Clears only explicit demo-user dummy data (never deletes real user data).
  static Future<void> clearAllDummyData(AppDatabase db) async {
    try {
      // Delete only explicit demo entries
      await (db.delete(db.entriesTable)
            ..where((e) => e.createdBy.equals('demo-user')))
          .go();

      // Remove default empty accounts ('acc-savings%' or 'acc-cash%') if balance is 0 and no transactions exist
      final defaultAccs = await (db.select(db.accountsTable)
            ..where((a) => a.id.like('acc-savings%') | a.id.like('acc-cash%')))
          .get();
      for (final acc in defaultAccs) {
        if (acc.currentBalancePaise == 0) {
          final entriesCount = await (db.select(db.entriesTable)..where((e) => e.accountId.equals(acc.id))).get();
          if (entriesCount.isEmpty) {
            await (db.delete(db.accountsTable)..where((a) => a.id.equals(acc.id))).go();
          }
        }
      }
    } catch (_) {}
  }

  /// Safely migrates any offline/local entities to the authenticated householdId
  static Future<void> migrateLocalDataToHousehold(AppDatabase db, String householdId) async {
    if (householdId.isEmpty || householdId == 'local') return;
    try {
      await (db.update(db.accountsTable)..where((a) => a.householdId.equals('local')))
          .write(AccountsTableCompanion(householdId: Value(householdId)));
      await (db.update(db.entriesTable)..where((e) => e.householdId.equals('local')))
          .write(EntriesTableCompanion(householdId: Value(householdId)));
      await (db.update(db.creditCardsTable)..where((c) => c.householdId.equals('local')))
          .write(CreditCardsTableCompanion(householdId: Value(householdId)));
      await (db.update(db.plannedBillsTable)..where((b) => b.householdId.equals('local')))
          .write(PlannedBillsTableCompanion(householdId: Value(householdId)));
      await (db.update(db.receivablesTable)..where((r) => r.householdId.equals('local')))
          .write(ReceivablesTableCompanion(householdId: Value(householdId)));
      await (db.update(db.savingGoalsTable)..where((g) => g.householdId.equals('local')))
          .write(SavingGoalsTableCompanion(householdId: Value(householdId)));
      await (db.update(db.sinkingFundsTable)..where((f) => f.householdId.equals('local')))
          .write(SinkingFundsTableCompanion(householdId: Value(householdId)));
      await db.accountDao.ensureOpeningBalanceEntries(householdId);
    } catch (_) {}
  }

  /// Seeds categories for a specific household if not already present.
  static Future<void> seedForHousehold(AppDatabase db, String householdId) async {
    final existingCategories = await (db.select(db.categoriesTable)
          ..where((c) => c.householdId.equals(householdId)))
        .get();

    if (existingCategories.isEmpty) {
      final defaultCats = await (db.select(db.categoriesTable)
            ..where((c) => c.householdId.equals('local')))
          .get();

      final companions = defaultCats.map((c) {
        return CategoriesTableCompanion.insert(
          id: '${c.id}-$householdId',
          householdId: householdId,
          kind: c.kind,
          groupCode: Value(c.groupCode),
          name: c.name,
          needOrWant: Value(c.needOrWant),
          isDeduction: Value(c.isDeduction),
          isSystem: Value(c.isSystem),
          sortOrder: Value(c.sortOrder),
        );
      }).toList();
      await db.categoryDao.upsertAll(companions);
    }
  }

  /// Ensures that default category taxonomy exists for an authenticated household.
  static Future<void> ensureUserHouseholdSeed(AppDatabase db, String householdId) async {
    await seedForHousehold(db, householdId);
  }
}
