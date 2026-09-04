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
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
        try {
          await customStatement('PRAGMA foreign_keys = ON');
        } catch (_) {}
        await _seedDefaultUsers();
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
        await _seedDefaultUsers();
        await _seedSystemCategories();
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
        await _seedDefaultUsers();
        await _seedSystemCategories();
      },
    );
  }

  Future<void> _seedDefaultUsers() async {
    try {
      final existingAdmin = await (select(usersTable)..where((u) => u.email.equals('admin@budget.app'))).get();
      if (existingAdmin.isEmpty) {
        await into(usersTable).insert(
          UsersTableCompanion.insert(
            id: 'admin-001',
            email: 'admin@budget.app',
            password: Value(PasswordHasher.hash('admin123')),
            displayName: 'Super Admin',
            householdId: 'hsh-admin',
            authProvider: const Value('email'),
            createdAt: DateTime.now(),
          ),
        );
      }
      final existingUser = await (select(usersTable)..where((u) => u.email.equals('user@budget.app'))).get();
      if (existingUser.isEmpty) {
        await into(usersTable).insert(
          UsersTableCompanion.insert(
            id: 'user-001',
            email: 'user@budget.app',
            password: Value(PasswordHasher.hash('user123')),
            displayName: 'Demo User',
            householdId: 'local-household',
            authProvider: const Value('email'),
            createdAt: DateTime.now(),
          ),
        );
      }
    } catch (_) {}
  }

  /// Seed the two system categories used for borrow/lending transaction sync
  /// AND sync any unlinked receivables or planned bills.
  /// These are idempotent — safe to call multiple times.
  Future<void> _seedSystemCategories() async {
    const households = ['hsh-admin', 'local-household', 'local'];
    for (final hh in households) {
      try {
        final existing = await (select(categoriesTable)
              ..where((c) => c.id.equals('lend-system-cat-$hh')))
            .getSingleOrNull();
        if (existing == null) {
          await into(categoriesTable).insert(
            CategoriesTableCompanion.insert(
              id: 'lend-system-cat-$hh',
              householdId: hh,
              kind: 'adjustment',
              name: 'Money Lent Out',
              isDeduction: const Value(true),
              isSystem: const Value(true),
              sortOrder: const Value(9990),
            ),
          );
        }
      } catch (_) {}
      try {
        final existing2 = await (select(categoriesTable)
              ..where((c) => c.id.equals('borrow-system-cat-$hh')))
            .getSingleOrNull();
        if (existing2 == null) {
          await into(categoriesTable).insert(
            CategoriesTableCompanion.insert(
              id: 'borrow-system-cat-$hh',
              householdId: hh,
              kind: 'adjustment',
              name: 'Borrowed Money',
              isDeduction: const Value(false),
              isSystem: const Value(true),
              sortOrder: const Value(9991),
            ),
          );
        }
      } catch (_) {}
      try {
        await borrowLendDao.syncUnlinkedRecords(hh);
      } catch (_) {}
    }
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
