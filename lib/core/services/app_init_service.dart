import 'package:drift/drift.dart';
import '../../core/constants/category_seed.dart';
import '../../data/local/database.dart';

/// Seeds the database with initial category taxonomy on first launch.
/// All seeding is idempotent — safe to call multiple times.
class AppInitService {
  AppInitService._();

  /// Bootstrap seed — called at app startup from main.dart.
  /// Seeds the offline 'local' household with the full category taxonomy
  /// and system categories so the app is usable before login.
  static Future<void> seed(AppDatabase db) async {
    // ── 1. Default categories for 'local' offline household ────────────────
    const localHouseholdId = 'local';
    final localCats = await (db.select(db.categoriesTable)
          ..where((c) => c.householdId.equals(localHouseholdId)))
        .get();

    if (localCats.isEmpty) {
      // Fresh install — seed the full taxonomy for the offline 'local' household
      final seedCats = buildSeedCategories(localHouseholdId);
      final companions = seedCats.map((c) {
        return CategoriesTableCompanion.insert(
          id: c.id,   // 'inc-01', 'spd-f01', etc. (no household prefix for 'local')
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

    // ── 2. Upgrade patch — ensure deduction flags are correct ──────────────
    await (db.update(db.categoriesTable)
          ..where((c) => c.name.equals('Lending/Return(-)') | c.name.equals('Others(Outflow)')))
        .write(const CategoriesTableCompanion(isDeduction: Value(true)));

    // ── 3. System categories for 'local' offline household ─────────────────
    await db.ensureSystemCategoriesForHousehold(localHouseholdId);
  }

  /// Clears only explicit demo-user dummy data (never deletes real user data).
  static Future<void> clearAllDummyData(AppDatabase db) async {
    try {
      await (db.delete(db.entriesTable)
            ..where((e) => e.createdBy.equals('demo-user')))
          .go();

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
  /// Safely migrates any offline/local or orphaned local entities to the authenticated householdId
  static Future<void> migrateLocalDataToHousehold(AppDatabase db, String householdId) async {
    if (householdId.isEmpty || householdId == 'local') return;
    try {
      // DEF-FIN-09: guest entries/budgets reference 'local' category ids ('adj-05',
      // 'lend-system-cat-local'). Re-point them to the household's categories so deduction
      // flags (and category names) resolve after migration instead of defaulting to "add".
      await _remapLocalCategoryReferences(db, householdId, 'local');

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
      await (db.update(db.budgetsTable)..where((b) => b.householdId.equals('local')))
          .write(BudgetsTableCompanion(householdId: Value(householdId)));
      await (db.update(db.reserveLinesTable)..where((r) => r.householdId.equals('local')))
          .write(ReserveLinesTableCompanion(householdId: Value(householdId)));
      await (db.update(db.monthSnapshotsTable)..where((m) => m.householdId.equals('local')))
          .write(MonthSnapshotsTableCompanion(householdId: Value(householdId)));

      // Orphaned data adoption: If any local records (accounts, cards, entries, etc.) belong to an
      // old household ID (e.g. from before a DB wipe or session recreation), adopt them into the
      // currently authenticated household so the user never loses their offline/device data.
      final orphanedAccs = await (db.select(db.accountsTable)..where((a) => a.householdId.equals(householdId).not() & a.householdId.equals('local').not())).get();
      final orphanedCards = await (db.select(db.creditCardsTable)..where((c) => c.householdId.equals(householdId).not() & c.householdId.equals('local').not())).get();
      final orphanedEntries = await (db.select(db.entriesTable)..where((e) => e.householdId.equals(householdId).not() & e.householdId.equals('local').not())).get();

      final oldHouseholdIds = {
        ...orphanedAccs.map((a) => a.householdId),
        ...orphanedCards.map((c) => c.householdId),
        ...orphanedEntries.map((e) => e.householdId),
      };

      for (final oldId in oldHouseholdIds) {
        if (oldId.isEmpty) continue;
        await _remapLocalCategoryReferences(db, householdId, oldId);
        await (db.update(db.accountsTable)..where((a) => a.householdId.equals(oldId)))
            .write(AccountsTableCompanion(householdId: Value(householdId)));
        await (db.update(db.entriesTable)..where((e) => e.householdId.equals(oldId)))
            .write(EntriesTableCompanion(householdId: Value(householdId)));
        await (db.update(db.creditCardsTable)..where((c) => c.householdId.equals(oldId)))
            .write(CreditCardsTableCompanion(householdId: Value(householdId)));
        await (db.update(db.plannedBillsTable)..where((b) => b.householdId.equals(oldId)))
            .write(PlannedBillsTableCompanion(householdId: Value(householdId)));
        await (db.update(db.receivablesTable)..where((r) => r.householdId.equals(oldId)))
            .write(ReceivablesTableCompanion(householdId: Value(householdId)));
        await (db.update(db.savingGoalsTable)..where((g) => g.householdId.equals(oldId)))
            .write(SavingGoalsTableCompanion(householdId: Value(householdId)));
        await (db.update(db.sinkingFundsTable)..where((f) => f.householdId.equals(oldId)))
            .write(SinkingFundsTableCompanion(householdId: Value(householdId)));
        await (db.update(db.budgetsTable)..where((b) => b.householdId.equals(oldId)))
            .write(BudgetsTableCompanion(householdId: Value(householdId)));
        await (db.update(db.reserveLinesTable)..where((r) => r.householdId.equals(oldId)))
            .write(ReserveLinesTableCompanion(householdId: Value(householdId)));
        await (db.update(db.monthSnapshotsTable)..where((m) => m.householdId.equals(oldId)))
            .write(MonthSnapshotsTableCompanion(householdId: Value(householdId)));
      }

      await db.accountDao.ensureOpeningBalanceEntries(householdId);
    } catch (_) {}
  }

  static Future<void> _remapLocalCategoryReferences(AppDatabase db, String householdId, [String sourceHousehold = 'local']) async {
    final localEntries = await (db.select(db.entriesTable)..where((e) => e.householdId.equals(sourceHousehold))).get();
    final localBudgets = await (db.select(db.budgetsTable)..where((b) => b.householdId.equals(sourceHousehold))).get();
    if (localEntries.isEmpty && localBudgets.isEmpty) return;

    await ensureUserHouseholdSeed(db, householdId);
    final seedIds = buildSeedCategories(sourceHousehold).map((c) => c.id).toSet();
    final householdCatIds = (await (db.select(db.categoriesTable)
              ..where((c) => c.householdId.equals(householdId)))
            .get())
        .map((c) => c.id)
        .toSet();
    final localCats = await (db.select(db.categoriesTable)..where((c) => c.householdId.equals(sourceHousehold))).get();

    final mapping = <String, String>{};
    for (final cat in localCats) {
      String? target;
      if (cat.id.endsWith('-system-cat-$sourceHousehold')) {
        target = '${cat.id.substring(0, cat.id.length - sourceHousehold.length)}$householdId';
      } else if (seedIds.contains(cat.id)) {
        target = '$householdId-${cat.id}';
      } else if (cat.id.startsWith('$sourceHousehold-')) {
        target = '$householdId-${cat.id.substring(sourceHousehold.length + 1)}';
      }
      if (target != null && householdCatIds.contains(target)) mapping[cat.id] = target;
    }

    await db.transaction(() async {
      for (final e in localEntries) {
        final target = mapping[e.categoryId];
        if (target != null) {
          await (db.update(db.entriesTable)..where((t) => t.id.equals(e.id)))
              .write(EntriesTableCompanion(categoryId: Value(target)));
        }
      }
      for (final b in localBudgets) {
        final target = mapping[b.categoryId];
        if (target != null) {
          await (db.update(db.budgetsTable)..where((t) => t.id.equals(b.id)))
              .write(BudgetsTableCompanion(categoryId: Value(target)));
        }
      }
      // User-created guest categories still referenced by migrated rows move with them.
      final referenced = {
        ...localEntries.map((e) => e.categoryId),
        ...localBudgets.map((b) => b.categoryId),
      };
      for (final cat in localCats) {
        if (!mapping.containsKey(cat.id) && !seedIds.contains(cat.id) &&
            !cat.id.endsWith('-system-cat-$sourceHousehold') && referenced.contains(cat.id)) {
          await (db.update(db.categoriesTable)..where((c) => c.id.equals(cat.id)))
              .write(CategoriesTableCompanion(householdId: Value(householdId)));
        }
      }
    });
  }

  /// Seeds the full category taxonomy for a specific authenticated household.
  ///
  /// Uses [buildSeedCategories] directly — does NOT copy from 'local'.
  /// Category IDs use the '{householdId}-{id}' format to match the backend
  /// (e.g. '{householdId}-inc-01').
  ///
  /// Idempotent — skips seeding if categories already exist for this household.
  static Future<void> seedForHousehold(AppDatabase db, String householdId) async {
    if (householdId.isEmpty || householdId == 'local') return;

    final existing = await (db.select(db.categoriesTable)
          ..where((c) => c.householdId.equals(householdId)))
        .get();

    if (existing.isEmpty) {
      // Use buildSeedCategories directly with '{householdId}-{id}' format
      // matching what the backend creates (e.g. '{householdId}-inc-01')
      final seedCats = buildSeedCategories(householdId);
      final companions = seedCats.map((c) {
        return CategoriesTableCompanion.insert(
          id: '${householdId}-${c.id}',   // e.g. '{uuid}-inc-01' — matches backend
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
  }

  /// Called after login/register/Google sign-in.
  /// Ensures the authenticated household has the full category taxonomy
  /// and all 4 system categories present in the local DB.
  static Future<void> ensureUserHouseholdSeed(AppDatabase db, String householdId) async {
    if (householdId.isEmpty || householdId == 'local') return;
    await seedForHousehold(db, householdId);
    // Ensure system categories (lend, borrow, bill-pay, return-received) exist for this household.
    await db.ensureSystemCategoriesForHousehold(householdId);
  }
}