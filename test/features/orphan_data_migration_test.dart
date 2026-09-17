import 'package:budget_tracker/core/services/app_init_service.dart';
import 'package:budget_tracker/data/local/database.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('migrateLocalDataToHousehold adopts orphaned accounts, cards, and entries into active household even if active household has entries', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(() => db.close());

    const activeHouseholdId = 'active-household-123';
    const oldHouseholdId = 'old-wiped-household-456';
    final now = DateTime.now();

    // Setup active household category & an existing entry
    await db.into(db.categoriesTable).insert(
      CategoriesTableCompanion.insert(
        id: '$activeHouseholdId-inc-01',
        householdId: activeHouseholdId,
        name: 'Salary',
        kind: 'income',
        needOrWant: const drift.Value('need'),
        isSystem: const drift.Value(false),
        sortOrder: const drift.Value(0),
      ),
    );

    await db.into(db.entriesTable).insert(
      EntriesTableCompanion.insert(
        id: 'new-active-entry-1',
        amountPaise: 100000,
        entryDate: now,
        categoryId: '$activeHouseholdId-inc-01',
        kind: 'income',
        householdId: activeHouseholdId,
        createdBy: 'user-1',
        createdAt: now,
        updatedAt: now,
        version: const drift.Value(1),
      ),
    );

    // Setup orphaned account and card under old household
    await db.into(db.accountsTable).insert(
      AccountsTableCompanion.insert(
        id: 'acc-indian-bank',
        householdId: oldHouseholdId,
        name: 'Indian Bank',
        type: 'savings',
        currentBalancePaise: const drift.Value(100000),
      ),
    );

    await db.into(db.creditCardsTable).insert(
      CreditCardsTableCompanion.insert(
        id: 'card-iscc',
        householdId: oldHouseholdId,
        name: 'iscc',
        previousOutstandingPaise: const drift.Value(30000),
      ),
    );

    // Call migration
    await AppInitService.migrateLocalDataToHousehold(db, activeHouseholdId);

    // Verify account and credit card are adopted into activeHouseholdId
    final migratedAcc = await (db.select(db.accountsTable)..where((a) => a.id.equals('acc-indian-bank'))).getSingle();
    expect(migratedAcc.householdId, equals(activeHouseholdId));

    final migratedCard = await (db.select(db.creditCardsTable)..where((c) => c.id.equals('card-iscc'))).getSingle();
    expect(migratedCard.householdId, equals(activeHouseholdId));
  });
}
