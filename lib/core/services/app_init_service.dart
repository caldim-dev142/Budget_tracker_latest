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
  static Future<void> migrateLocalDataToHousehold(AppDatabase db, String householdId) async {
    if (householdId.isEmpty || householdId == 'local') return;
    try {
      // DEF-FIN-09: guest entries/budgets reference 'local' category ids ('adj-05',
      // 'lend-system-cat-local'). Re-point them to the household's categories so deduction
      // flags (and category names) resolve after migration instead of defaulting to "add".
      await _remapLocalCategoryReferences(db, householdId);

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
      await db.accountDao.ensureOpeningBalanceEntries(householdId);
    } catch (_) {}
  }

  static Future<void> _remapLocalCategoryReferences(AppDatabase db, String householdId) async {
    final localEntries = await (db.select(db.entriesTable)..where((e) => e.householdId.equals('local'))).get();
    final localBudgets = await (db.select(db.budgetsTable)..where((b) => b.householdId.equals('local'))).get();
    if (localEntries.isEmpty && localBudgets.isEmpty) return;

    await ensureUserHouseholdSeed(db, householdId);
    final seedIds = buildSeedCategories('local').map((c) => c.id).toSet();
    final householdCatIds = (await (db.select(db.categoriesTable)
              ..where((c) => c.householdId.equals(householdId)))
            .get())
        .map((c) => c.id)
        .toSet();
    final localCats = await (db.select(db.categoriesTable)..where((c) => c.householdId.equals('local'))).get();

    final mapping = <String, String>{};
    for (final cat in localCats) {
      String? target;
      if (cat.id.endsWith('-system-cat-local')) {
        target = '${cat.id.substring(0, cat.id.length - 'local'.length)}$householdId';
      } else if (seedIds.contains(cat.id)) {
        target = '$householdId-${cat.id}';
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
            !cat.id.endsWith('-system-cat-local') && referenced.contains(cat.id)) {
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

  /// Wipes all user data from the local Drift database.
  ///
  /// Call this ONLY when the user's server-side account has been permanently
  /// deleted (i.e. DELETE /auth/me succeeded). Do NOT call on sign-out —
  /// on sign-out we keep local data so it survives until the next sync.
  ///
  /// After wiping, re-seeds the offline 'local' household so the app remains
  /// usable in guest mode immediately.
  static Future<void> clearAllUserData(AppDatabase db) async {
    try {
      // Delete in dependency order (children before parents) to avoid FK errors.
      await db.delete(db.syncQueueTable).go();
      await db.delete(db.monthSnapshotsTable).go();
      await db.delete(db.cardTransactionsTable).go();
      await db.delete(db.creditCardsTable).go();
      await db.delete(db.goalContributionsTable).go();
      await db.delete(db.savingGoalsTable).go();
      await db.delete(db.fundMovementsTable).go();
      await db.delete(db.sinkingFundsTable).go();
      await db.delete(db.receivablesTable).go();
      await db.delete(db.plannedBillsTable).go();
      await db.delete(db.reserveLinesTable).go();
      await db.delete(db.annualTargetsTable).go();
      await db.delete(db.budgetsTable).go();
      await db.delete(db.entriesTable).go();
      await db.delete(db.accountsTable).go();
      await db.delete(db.categoriesTable).go();
      await db.delete(db.usersTable).go();
    } catch (_) {}

    // Re-seed the local offline household so the app is usable in guest mode.
    try {
      await seed(db);
    } catch (_) {}
  }
}