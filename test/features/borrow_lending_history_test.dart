import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:budget_tracker/data/local/database.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());

    for (final hh in ['household-alpha', 'household-beta']) {
      await db.into(db.categoriesTable).insert(
        CategoriesTableCompanion.insert(
          id: 'lend-system-cat-$hh',
          householdId: hh,
          kind: 'adjustment',
          name: 'Money Lent Out',
          isDeduction: const drift.Value(true),
          isSystem: const drift.Value(true),
        ),
      );
      await db.into(db.categoriesTable).insert(
        CategoriesTableCompanion.insert(
          id: 'borrow-system-cat-$hh',
          householdId: hh,
          kind: 'adjustment',
          name: 'Borrowed Money',
          isDeduction: const drift.Value(false),
          isSystem: const drift.Value(true),
        ),
      );
      await db.into(db.categoriesTable).insert(
        CategoriesTableCompanion.insert(
          id: 'return-received-system-cat-$hh',
          householdId: hh,
          kind: 'adjustment',
          name: 'Money Returned In',
          isDeduction: const drift.Value(false),
          isSystem: const drift.Value(true),
        ),
      );
      await db.into(db.categoriesTable).insert(
        CategoriesTableCompanion.insert(
          id: 'bill-pay-system-cat-$hh',
          householdId: hh,
          kind: 'spending',
          name: 'Bill / Loan Repayment',
          isDeduction: const drift.Value(false),
          isSystem: const drift.Value(true),
        ),
      );
    }
  });

  tearDown(() async {
    await db.close();
  });

  group('Borrow & Lending History Integration Tests', () {
    const hh1 = 'household-alpha';
    const hh2 = 'household-beta';

    test('watchAll receives newly created lending (receivable) records', () async {
      // Initially empty
      final initialRecs = await db.borrowLendDao.watchAll(hh1).first;
      expect(initialRecs, isEmpty);

      // Create a new lending record (open by default)
      await db.borrowLendDao.upsertReceivable(
        householdId: hh1,
        personName: 'Ramesh',
        amountPaise: 500000,
        dueDate: DateTime(2026, 8, 15),
      );

      // Verify it appears in watchAll (used by History)
      final recsAfterAdd = await db.borrowLendDao.watchAll(hh1).first;
      expect(recsAfterAdd.length, 1);
      expect(recsAfterAdd.first.personName, 'Ramesh');
      expect(recsAfterAdd.first.amountPaise, 500000);
      expect(recsAfterAdd.first.status, 'open');
    });

    test('watchAllBills receives newly created borrowing (planned bill) records', () async {
      // Initially empty
      final initialBills = await db.borrowLendDao.watchAllBills(hh1).first;
      expect(initialBills, isEmpty);

      // Create a new borrowing record (unpaid by default)
      await db.borrowLendDao.upsertPlannedBill(
        householdId: hh1,
        name: 'Electric Bill Loan',
        amountPaise: 250000,
        dueDate: DateTime(2026, 8, 20),
      );

      // Verify it appears in watchAllBills (used by History)
      final billsAfterAdd = await db.borrowLendDao.watchAllBills(hh1).first;
      expect(billsAfterAdd.length, 1);
      expect(billsAfterAdd.first.name, 'Electric Bill Loan');
      expect(billsAfterAdd.first.amountPaise, 250000);
      expect(billsAfterAdd.first.isPaid, false);
    });

    test('Settling a record updates status in watchAll / watchAllBills', () async {
      // Insert receivable
      await db.borrowLendDao.upsertReceivable(
        householdId: hh1,
        id: 'rec-1',
        personName: 'Suresh',
        amountPaise: 300000,
      );

      var recs = await db.borrowLendDao.watchAll(hh1).first;
      expect(recs.first.status, 'open');

      // Settle (returned)
      await db.borrowLendDao.settleReceivable('rec-1');

      recs = await db.borrowLendDao.watchAll(hh1).first;
      expect(recs.length, 1);
      expect(recs.first.status, 'returned');

      // Insert bill
      await db.borrowLendDao.upsertPlannedBill(
        householdId: hh1,
        id: 'bill-1',
        name: 'Friend Loan',
        amountPaise: 150000,
      );

      var bills = await db.borrowLendDao.watchAllBills(hh1).first;
      expect(bills.first.isPaid, false);

      // Settle (paid)
      await db.borrowLendDao.settlePlannedBill('bill-1');

      bills = await db.borrowLendDao.watchAllBills(hh1).first;
      expect(bills.length, 1);
      expect(bills.first.isPaid, true);
    });

    test('Deleting a record removes it from watchAll and watchAllBills', () async {
      await db.borrowLendDao.upsertReceivable(
        householdId: hh1,
        id: 'rec-del',
        personName: 'Temporary Loan',
        amountPaise: 100000,
      );
      await db.borrowLendDao.upsertPlannedBill(
        householdId: hh1,
        id: 'bill-del',
        name: 'Temporary Debt',
        amountPaise: 100000,
      );

      expect((await db.borrowLendDao.watchAll(hh1).first).length, 1);
      expect((await db.borrowLendDao.watchAllBills(hh1).first).length, 1);

      await db.borrowLendDao.deleteReceivable('rec-del');
      await db.borrowLendDao.deletePlannedBill('bill-del');

      expect((await db.borrowLendDao.watchAll(hh1).first), isEmpty);
      expect((await db.borrowLendDao.watchAllBills(hh1).first), isEmpty);
    });

    test('Household isolation: History never leaks across households', () async {
      await db.borrowLendDao.upsertReceivable(
        householdId: hh1,
        personName: 'Secret Loan HH1',
        amountPaise: 500000,
      );
      await db.borrowLendDao.upsertPlannedBill(
        householdId: hh1,
        name: 'Secret Debt HH1',
        amountPaise: 300000,
      );

      // Household 2 queries should return empty
      final hh2Recs = await db.borrowLendDao.watchAll(hh2).first;
      final hh2Bills = await db.borrowLendDao.watchAllBills(hh2).first;

      expect(hh2Recs, isEmpty);
      expect(hh2Bills, isEmpty);
    });
  });
}
