import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tables/tables.dart';
import 'daos/entry_dao.dart';
import 'daos/category_dao.dart';
import 'daos/snapshot_dao.dart';
import 'daos/sync_queue_dao.dart';
import 'daos/fund_dao.dart';
import 'daos/goal_dao.dart';
import 'daos/card_dao.dart';
import 'daos/account_dao.dart';
import 'daos/borrow_lend_dao.dart';
import 'connection/connection.dart';
import '../../core/security/password_hasher.dart';

part 'database.g.dart';

/// Drift database — the offline source of truth (doc 11).
/// Cross-platform support for Android, iOS, Windows, macOS, Linux, and Web (Chrome/Edge/Safari).
/// Schema mirrors the server tables (doc 05) minus RLS, plus sync_queue.
/// All money columns are INTEGER (paise). Derived totals never stored.
@DriftDatabase(
  tables: [
    AccountsTable,
    CategoriesTable,
    BudgetsTable,
    EntriesTable,
    SinkingFundsTable,
    FundMovementsTable,
    SavingGoalsTable,
    GoalContributionsTable,
    CreditCardsTable,
    CardTransactionsTable,
    ReceivablesTable,
    PlannedBillsTable,
    ReserveLinesTable,
    MonthSnapshotsTable,
    SyncQueueTable,
    AnnualTargetsTable,
    UsersTable,
  ],
  daos: [
    EntryDao,
    CategoryDao,
    SnapshotDao,
    SyncQueueDao,
    FundDao,
    GoalDao,
    CardDao,
    AccountDao,
    BorrowLendDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
        try {
          await customStatement('PRAGMA foreign_keys = ON');
        } catch (_) {}
        // Fresh install: seed system categories for the offline 'local' household.
        // Regular categories (141 entries) are seeded by AppInitService.seed() in main.dart.
        await ensureSystemCategoriesForHousehold('local');
      },
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          try {
            await m.createTable(usersTable);
          } catch (_) {}
        }
        if (from < 3) {
          // Schema v3: add entryId link columns for borrow/lending transaction sync
          try {
            await customStatement('ALTER TABLE receivables ADD COLUMN entry_id TEXT');
          } catch (_) {}
          try {
            await customStatement('ALTER TABLE planned_bills ADD COLUMN entry_id TEXT');
          } catch (_) {}
        }
        if (from < 4) {
          // Schema v4: create annual_targets table (was missing from prior migrations)
          try {
            await customStatement('''
              CREATE TABLE IF NOT EXISTS "annual_targets" (
                "id" TEXT NOT NULL PRIMARY KEY,
                "household_id" TEXT NOT NULL,
                "title" TEXT NOT NULL,
                "target_paise" INTEGER NOT NULL,
                "type" TEXT NOT NULL DEFAULT 'income'
              );
            ''');
          } catch (_) {}
        }
        // Ensure 'local' bootstrap household has its system categories after any upgrade.
        // Auth household system cats are seeded by ensureUserHouseholdSeed() on login.
        await ensureSystemCategoriesForHousehold('local');
      },
      beforeOpen: (details) async {
        try {
          await customStatement('''
            CREATE TABLE IF NOT EXISTS "users" (
              "id" TEXT NOT NULL PRIMARY KEY,
              "email" TEXT NOT NULL,
              "password" TEXT,
              "display_name" TEXT NOT NULL,
              "household_id" TEXT NOT NULL,
              "auth_provider" TEXT NOT NULL DEFAULT 'email',
              "created_at" INTEGER NOT NULL
            );
          ''');
        } catch (_) {}
        // Always ensure 'local' bootstrap system categories exist.
        await ensureSystemCategoriesForHousehold('local');
      },
    );
  }


  /// Ensures all 4 system categories exist for the given household.
  /// Called after login so dynamic householdIds are handled correctly.
  Future<void> ensureSystemCategoriesForHousehold(String householdId) async {
    final sysCats = [
      CategoriesTableCompanion.insert(
        id: 'lend-system-cat-$householdId',
        householdId: householdId,
        kind: 'adjustment',
        name: 'Money Lent Out',
        isDeduction: const Value(true),
        isSystem: const Value(true),
        sortOrder: const Value(9990),
      ),
      CategoriesTableCompanion.insert(
        id: 'borrow-system-cat-$householdId',
        householdId: householdId,
        kind: 'adjustment',
        name: 'Borrowed Money',
        isDeduction: const Value(false),
        isSystem: const Value(true),
        sortOrder: const Value(9991),
      ),
      CategoriesTableCompanion.insert(
        id: 'bill-pay-system-cat-$householdId',
        householdId: householdId,
        kind: 'spending',
        name: 'Bill Payment',
        isDeduction: const Value(false),
        isSystem: const Value(true),
        sortOrder: const Value(9992),
      ),
      CategoriesTableCompanion.insert(
        id: 'return-received-system-cat-$householdId',
        householdId: householdId,
        kind: 'adjustment',
        name: 'Money Returned Back',
        isDeduction: const Value(false),
        isSystem: const Value(true),
        sortOrder: const Value(9993),
      ),
    ];
    for (final cat in sysCats) {
      try {
        await into(categoriesTable).insertOnConflictUpdate(cat);
      } catch (_) {}
    }
    try {
      await borrowLendDao.syncUnlinkedRecords(householdId);
    } catch (_) {}
  }

  /// Open database cross-platform.
  static Future<AppDatabase> open() async {
    return AppDatabase(connect());
  }
}

/// Riverpod provider for the database instance.
final appDatabaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('Override in main.dart ProviderScope'),
);
