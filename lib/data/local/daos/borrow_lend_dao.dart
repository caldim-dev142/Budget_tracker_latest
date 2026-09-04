import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database.dart';
import '../tables/tables.dart';

part 'borrow_lend_dao.g.dart';

const _uuid = Uuid();

/// DAO for Borrow & Lending operations.
///
/// Every create/update of a receivable or planned bill is mirrored to the
/// [entries] table (kind='adjustment') so that borrow/lending records appear
/// in the Transactions module. The [entryId] column on each table tracks
/// the linked entry to prevent duplicates.
///
/// System category IDs (seeded in database.dart _seedSystemCategories):
///   'lend-system-cat-<householdId>'  — isDeduction=true  (reduces adjustments = money going OUT)
///   'borrow-system-cat-<householdId>'— isDeduction=false (adds to adjustments = money coming IN)
///
/// Note: These entries appear in the Adjustments bucket of the waterfall.
/// The amounts are informational — the primary receivables/plannedBills
/// tables remain the authoritative source for returnAwaited/toBePaid
/// calculations in the dashboard.
@DriftAccessor(tables: [ReceivablesTable, PlannedBillsTable, EntriesTable])
class BorrowLendDao extends DatabaseAccessor<AppDatabase>
    with _$BorrowLendDaoMixin {
  BorrowLendDao(super.db);

  // --- Receivables (Return Awaited / Money Lent) ------------------------------

  Stream<List<ReceivablesTableData>> watchAll(String householdId) {
    return (select(receivablesTable)
          ..where((r) => r.householdId.equals(householdId))
          ..orderBy([(r) => OrderingTerm.desc(r.rowId)]))
        .watch();
  }

  Stream<List<ReceivablesTableData>> watchOpen(String householdId) {
    return (select(receivablesTable)
          ..where((r) =>
              r.householdId.equals(householdId) & r.status.equals('open'))
          ..orderBy([(r) => OrderingTerm.desc(r.rowId)]))
        .watch();
  }

  Stream<List<ReceivablesTableData>> watchSettled(String householdId) {
    return (select(receivablesTable)
          ..where((r) =>
              r.householdId.equals(householdId) &
              r.status.equals('returned'))
          ..orderBy([(r) => OrderingTerm.desc(r.rowId)]))
        .watch();
  }

  Future<ReceivablesTableData?> getReceivable(String id) {
    return (select(receivablesTable)..where((r) => r.id.equals(id)))
        .getSingleOrNull();
  }

  /// Upsert a receivable AND create/update the linked entry in the entries table.
  Future<void> upsertReceivable({
    required String householdId,
    String? id,
    required String personName,
    required int amountPaise,
    DateTime? dueDate,
    String? createdBy,
    String? existingEntryId,
  }) async {
    final recId = id ?? _uuid.v4();
    final now = DateTime.now();
    final effectiveCreatedBy = createdBy ?? householdId;

    final existingRec = id != null ? await getReceivable(id) : null;
    final entryId = existingEntryId ?? existingRec?.entryId ?? _uuid.v4();

    final lendCatId = 'lend-system-cat-$householdId';

    await into(entriesTable).insertOnConflictUpdate(
      EntriesTableCompanion.insert(
        id: entryId,
        householdId: householdId,
        categoryId: lendCatId,
        kind: 'adjustment',
        entryDate: dueDate ?? now,
        amountPaise: amountPaise,
        note: Value('Lent to: $personName'),
        createdBy: effectiveCreatedBy,
        version: const Value(1),
        createdAt: now,
        updatedAt: now,
      ),
    );

    await into(receivablesTable).insertOnConflictUpdate(
      ReceivablesTableCompanion.insert(
        id: recId,
        householdId: householdId,
        personName: personName,
        amountPaise: amountPaise,
        status: existingRec != null ? Value(existingRec.status) : const Value('open'),
        dueDate: Value(dueDate),
        entryId: Value(entryId),
      ),
    );
  }

  /// Mark a receivable as returned and soft-delete its linked entry.
  Future<void> settleReceivable(String id) async {
    final rec = await getReceivable(id);
    if (rec == null) return;

    if (rec.entryId != null) {
      await (update(entriesTable)..where((e) => e.id.equals(rec.entryId!)))
          .write(EntriesTableCompanion(deletedAt: Value(DateTime.now())));
    }

    await (update(receivablesTable)..where((r) => r.id.equals(id))).write(
      const ReceivablesTableCompanion(status: Value('returned')),
    );
  }

  /// Delete a receivable and its linked entry permanently.
  Future<void> deleteReceivable(String id) async {
    final rec = await getReceivable(id);
    if (rec?.entryId != null) {
      await (delete(entriesTable)
            ..where((e) => e.id.equals(rec!.entryId!)))
          .go();
    }
    await (delete(receivablesTable)..where((r) => r.id.equals(id))).go();
  }

  // --- Planned Bills (To Be Paid / Borrowed Money) ----------------------------

  Stream<List<PlannedBillsTableData>> watchAllBills(String householdId) {
    return (select(plannedBillsTable)
          ..where((b) => b.householdId.equals(householdId))
          ..orderBy([(b) => OrderingTerm.desc(b.rowId)]))
        .watch();
  }

  Stream<List<PlannedBillsTableData>> watchUnpaidBills(String householdId) {
    return (select(plannedBillsTable)
          ..where((b) =>
              b.householdId.equals(householdId) & b.isPaid.equals(false))
          ..orderBy([(b) => OrderingTerm.desc(b.rowId)]))
        .watch();
  }

  Stream<List<PlannedBillsTableData>> watchPaidBills(String householdId) {
    return (select(plannedBillsTable)
          ..where((b) =>
              b.householdId.equals(householdId) & b.isPaid.equals(true))
          ..orderBy([(b) => OrderingTerm.desc(b.rowId)]))
        .watch();
  }

  Future<PlannedBillsTableData?> getBill(String id) {
    return (select(plannedBillsTable)..where((b) => b.id.equals(id)))
        .getSingleOrNull();
  }

  /// Upsert a planned bill AND create/update the linked entry in the entries table.
  Future<void> upsertPlannedBill({
    required String householdId,
    String? id,
    required String name,
    required int amountPaise,
    DateTime? dueDate,
    String? createdBy,
    String? existingEntryId,
  }) async {
    final billId = id ?? _uuid.v4();
    final now = DateTime.now();
    final effectiveCreatedBy = createdBy ?? householdId;

    final existingBill = id != null ? await getBill(id) : null;
    final entryId = existingEntryId ?? existingBill?.entryId ?? _uuid.v4();

    final borrowCatId = 'borrow-system-cat-$householdId';

    await into(entriesTable).insertOnConflictUpdate(
      EntriesTableCompanion.insert(
        id: entryId,
        householdId: householdId,
        categoryId: borrowCatId,
        kind: 'adjustment',
        entryDate: dueDate ?? now,
        amountPaise: amountPaise,
        note: Value('Borrowed: $name'),
        createdBy: effectiveCreatedBy,
        version: const Value(1),
        createdAt: now,
        updatedAt: now,
      ),
    );

    await into(plannedBillsTable).insertOnConflictUpdate(
      PlannedBillsTableCompanion.insert(
        id: billId,
        householdId: householdId,
        name: name,
        amountPaise: amountPaise,
        dueDate: Value(dueDate),
        isPaid: existingBill != null ? Value(existingBill.isPaid) : const Value(false),
        entryId: Value(entryId),
      ),
    );
  }

  /// Mark a planned bill as paid and soft-delete its linked entry.
  Future<void> settlePlannedBill(String id) async {
    final bill = await getBill(id);
    if (bill == null) return;

    if (bill.entryId != null) {
      await (update(entriesTable)..where((e) => e.id.equals(bill.entryId!)))
          .write(EntriesTableCompanion(deletedAt: Value(DateTime.now())));
    }

    await (update(plannedBillsTable)..where((b) => b.id.equals(id))).write(
      const PlannedBillsTableCompanion(isPaid: Value(true)),
    );
  }

  /// Delete a planned bill and its linked entry permanently.
  Future<void> deletePlannedBill(String id) async {
    final bill = await getBill(id);
    if (bill?.entryId != null) {
      await (delete(entriesTable)
            ..where((e) => e.id.equals(bill!.entryId!)))
          .go();
    }
    await (delete(plannedBillsTable)..where((b) => b.id.equals(id))).go();
  }

  /// Syncs any unlinked receivables or planned bills (where entryId is null) to entriesTable.
  Future<void> syncUnlinkedRecords(String householdId) async {
    final unlinkedRecs = await (select(receivablesTable)
          ..where((r) => r.householdId.equals(householdId) & r.entryId.isNull()))
        .get();

    for (final rec in unlinkedRecs) {
      final lendCatId = 'lend-system-cat-$householdId';
      final entryId = _uuid.v4();
      final now = DateTime.now();

      await into(entriesTable).insertOnConflictUpdate(
        EntriesTableCompanion.insert(
          id: entryId,
          householdId: householdId,
          categoryId: lendCatId,
          kind: 'adjustment',
          entryDate: rec.dueDate ?? now,
          amountPaise: rec.amountPaise,
          note: Value('Lent to: ${rec.personName}'),
          createdBy: householdId,
          version: const Value(1),
          createdAt: now,
          updatedAt: now,
          deletedAt: rec.status == 'returned' ? Value(now) : const Value.absent(),
        ),
      );

      await (update(receivablesTable)..where((r) => r.id.equals(rec.id)))
          .write(ReceivablesTableCompanion(entryId: Value(entryId)));
    }

    final unlinkedBills = await (select(plannedBillsTable)
          ..where((b) => b.householdId.equals(householdId) & b.entryId.isNull()))
        .get();

    for (final bill in unlinkedBills) {
      final borrowCatId = 'borrow-system-cat-$householdId';
      final entryId = _uuid.v4();
      final now = DateTime.now();

      await into(entriesTable).insertOnConflictUpdate(
        EntriesTableCompanion.insert(
          id: entryId,
          householdId: householdId,
          categoryId: borrowCatId,
          kind: 'adjustment',
          entryDate: bill.dueDate ?? now,
          amountPaise: bill.amountPaise,
          note: Value('Borrowed: ${bill.name}'),
          createdBy: householdId,
          version: const Value(1),
          createdAt: now,
          updatedAt: now,
          deletedAt: bill.isPaid ? Value(now) : const Value.absent(),
        ),
      );

      await (update(plannedBillsTable)..where((b) => b.id.equals(bill.id)))
          .write(PlannedBillsTableCompanion(entryId: Value(entryId)));
    }
  }
}

