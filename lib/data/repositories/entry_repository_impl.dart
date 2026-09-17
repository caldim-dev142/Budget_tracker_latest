import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils/money.dart';
import '../../domain/entities/entry.dart';
import '../../domain/usecases/add_entry.dart';
import '../local/database.dart';

const _uuid = Uuid();

class EntryRepositoryImpl implements EntryRepository {
  final AppDatabase _db;

  EntryRepositoryImpl(this._db);

  @override
  Future<void> insertLocal(Entry entry) async {
    await _db.entryDao.insertEntry(
      EntriesTableCompanion(
        id: Value(entry.id),
        householdId: Value(entry.householdId),
        categoryId: Value(entry.categoryId),
        kind: Value(entry.kind.name),
        accountId: Value(entry.accountId),
        cardId: Value(entry.cardId),
        entryDate: Value(entry.entryDate),
        amountPaise: Value(entry.amount.paise),
        note: Value(entry.note),
        parentId: Value(entry.parentId),
        createdBy: Value(entry.createdBy),
        version: Value(entry.version),
        createdAt: Value(entry.createdAt),
        updatedAt: Value(entry.updatedAt),
      ),
    );

    await syncAllVaults();
    await _db.accountDao.recalculateAllAccountBalances();
  }

  Future<void> syncAllVaults() async {
    // 1. Protection entries -> SinkingFunds & FundMovements
    final protectionEntries = await (_db.select(_db.entriesTable)..where((e) => e.kind.equals('protection'))).get();
    for (final entry in protectionEntries) {
      final category = await (_db.select(_db.categoriesTable)..where((c) => c.id.equals(entry.categoryId))).getSingleOrNull();
      final catName = category?.name ?? 'Protection Fund';
      
      // Normalize fund name (e.g. "To MF for Vacation" / "Spending for Vacation" -> "Vacation")
      String fundName = catName;
      if (fundName.startsWith('To MF for ')) {
        fundName = fundName.substring('To MF for '.length).trim();
      } else if (fundName.startsWith('Spending for ')) {
        fundName = fundName.substring('Spending for '.length).trim();
      }

      // DEF-SYNC-08: scope by the entry's household and tolerate duplicate names (getSingleOrNull threw).
      var fund = await (_db.select(_db.sinkingFundsTable)
                ..where((f) => f.name.equals(fundName) & f.householdId.equals(entry.householdId))
                ..limit(1)).getSingleOrNull();
      if (fund == null) {
        final fundId = _uuid.v4();
        await _db.into(_db.sinkingFundsTable).insert(
          SinkingFundsTableCompanion(
            id: Value(fundId),
            householdId: Value(entry.householdId),
            name: Value(fundName),
            openingReservePaise: const Value(0),
          ),
        );
        fund = await (_db.select(_db.sinkingFundsTable)..where((f) => f.id.equals(fundId))).getSingle();
      }

      // Determine movement type: "Spending for X" or withdrawal note = withdrawal, otherwise contribution
      final isWithdrawal = catName.toLowerCase().startsWith('spending for') ||
          (entry.note != null &&
              (entry.note!.toLowerCase().contains('spending') ||
                  entry.note!.toLowerCase().contains('withdraw')));
      final movementType = isWithdrawal ? 'withdrawal' : 'contribution';

      final existingMovement = await (_db.select(_db.fundMovementsTable)..where((m) => m.fundId.equals(fund!.id) & m.amountPaise.equals(entry.amountPaise) & m.movementDate.equals(entry.entryDate))..limit(1)).getSingleOrNull();
      if (existingMovement == null) {
        await _db.into(_db.fundMovementsTable).insert(
          FundMovementsTableCompanion(
            id: Value(_uuid.v4()),
            fundId: Value(fund.id),
            type: Value(movementType),
            amountPaise: Value(entry.amountPaise),
            movementDate: Value(entry.entryDate),
            note: Value(entry.note),
          ),
        );
      }
    }

    // 2. Saving entries -> SavingGoals & GoalContributions
    final savingEntries = await (_db.select(_db.entriesTable)..where((e) => e.kind.equals('saving'))).get();
    for (final entry in savingEntries) {
      final category = await (_db.select(_db.categoriesTable)..where((c) => c.id.equals(entry.categoryId))).getSingleOrNull();
      final catName = category?.name ?? 'Savings Goal';
      
      var goal = await (_db.select(_db.savingGoalsTable)
                ..where((g) => g.name.equals(catName) & g.householdId.equals(entry.householdId))
                ..limit(1)).getSingleOrNull();
      if (goal == null) {
        final goalId = _uuid.v4();
        await _db.into(_db.savingGoalsTable).insert(
          SavingGoalsTableCompanion(
            id: Value(goalId),
            householdId: Value(entry.householdId),
            bucket: const Value('other_goals'),
            name: Value(catName),
            monthlyBudgetPaise: const Value(0),
          ),
        );
        goal = await (_db.select(_db.savingGoalsTable)..where((g) => g.id.equals(goalId))).getSingle();
      }
      
      final existingContrib = await (_db.select(_db.goalContributionsTable)..where((c) => c.goalId.equals(goal!.id) & c.amountPaise.equals(entry.amountPaise) & c.contributionDate.equals(entry.entryDate))..limit(1)).getSingleOrNull();
      if (existingContrib == null) {
        await _db.into(_db.goalContributionsTable).insert(
          GoalContributionsTableCompanion(
            id: Value(_uuid.v4()),
            goalId: Value(goal.id),
            amountPaise: Value(entry.amountPaise),
            contributionDate: Value(entry.entryDate),
            note: Value(entry.note),
          ),
        );
      }
    }

    // 3. Adjustment entries → Borrow / Lend bidirectional sync
    //    isDeduction=true  → money going OUT (lent out)  → receivablesTable
    //    isDeduction=false → money coming IN (borrowed)  → plannedBillsTable
    final adjustmentEntries = await (_db.select(_db.entriesTable)
          ..where((e) => e.kind.equals('adjustment')))
        .get();

    for (final entry in adjustmentEntries) {
      final isSoftDeleted = entry.deletedAt != null;
      final category = await (_db.select(_db.categoriesTable)
            ..where((c) => c.id.equals(entry.categoryId)))
          .getSingleOrNull();
      final isDeduction = category?.isDeduction ?? false;
      final catName = category?.name ?? 'Adjustment';
      final personOrName = entry.note?.isNotEmpty == true ? entry.note! : catName;

      if (isSoftDeleted) {
        // Clean up any linked receivable/planned bill on soft delete (and propagate the hard deletes)
        final linkedRecs = await (_db.select(_db.receivablesTable)..where((r) => r.entryId.equals(entry.id))).get();
        for (final r in linkedRecs) {
          await _db.syncQueueDao.enqueueDeletion(entity: 'receivable', entityId: r.id);
        }
        final linkedBills = await (_db.select(_db.plannedBillsTable)..where((b) => b.entryId.equals(entry.id))).get();
        for (final b in linkedBills) {
          await _db.syncQueueDao.enqueueDeletion(entity: 'planned_bill', entityId: b.id);
        }
        await (_db.delete(_db.receivablesTable)
              ..where((r) => r.entryId.equals(entry.id)))
            .go();
        await (_db.delete(_db.plannedBillsTable)
              ..where((b) => b.entryId.equals(entry.id)))
            .go();
      } else if (isDeduction) {
        // Money lent out → receivablesTable
        final existing = await (_db.select(_db.receivablesTable)
              ..where((r) => r.entryId.equals(entry.id)))
            .getSingleOrNull();
        if (existing == null) {
          await _db.into(_db.receivablesTable).insertOnConflictUpdate(
            ReceivablesTableCompanion.insert(
              id: _uuid.v4(),
              householdId: entry.householdId,
              personName: personOrName,
              amountPaise: entry.amountPaise.abs(),
              status: const Value('open'),
              dueDate: Value(entry.entryDate),
              entryId: Value(entry.id),
            ),
          );
        } else {
          // Update if amount or name changed
          if (existing.amountPaise != entry.amountPaise.abs() ||
              existing.personName != personOrName) {
            await (_db.update(_db.receivablesTable)
                  ..where((r) => r.id.equals(existing.id)))
                .write(ReceivablesTableCompanion(
              personName: Value(personOrName),
              amountPaise: Value(entry.amountPaise.abs()),
            ));
          }
        }
      } else {
        // Money borrowed → plannedBillsTable
        final existing = await (_db.select(_db.plannedBillsTable)
              ..where((b) => b.entryId.equals(entry.id)))
            .getSingleOrNull();
        if (existing == null) {
          await _db.into(_db.plannedBillsTable).insertOnConflictUpdate(
            PlannedBillsTableCompanion.insert(
              id: _uuid.v4(),
              householdId: entry.householdId,
              name: personOrName,
              amountPaise: entry.amountPaise.abs(),
              dueDate: Value(entry.entryDate),
              isPaid: const Value(false),
              entryId: Value(entry.id),
            ),
          );
        } else {
          // Update if amount or name changed
          if (existing.amountPaise != entry.amountPaise.abs() ||
              existing.name != personOrName) {
            await (_db.update(_db.plannedBillsTable)
                  ..where((b) => b.id.equals(existing.id)))
                .write(PlannedBillsTableCompanion(
              name: Value(personOrName),
              amountPaise: Value(entry.amountPaise.abs()),
            ));
          }
        }
      }
    }
  }

  @override
  void enqueueSyncInsert(Entry entry) {
    final payload = {
      'id': entry.id,
      'householdId': entry.householdId,
      'categoryId': entry.categoryId,
      'kind': entry.kind.name,
      'accountId': entry.accountId,
      'cardId': entry.cardId,
      'entryDate': entry.entryDate.toIso8601String(),
      'amountPaise': entry.amount.paise,
      'note': entry.note,
      'parentId': entry.parentId,
      'createdBy': entry.createdBy,
      'version': entry.version,
      'createdAt': entry.createdAt.toIso8601String(),
      'updatedAt': entry.updatedAt.toIso8601String(),
    };

    _db.into(_db.syncQueueTable).insert(
      SyncQueueTableCompanion.insert(
        id: _uuid.v4(),
        op: 'insert',
        entity: 'entry',
        entityId: entry.id,
        payload: jsonEncode(payload),
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> updateLocal(Entry entry) async {
    final existing = await _db.entryDao.getById(entry.id);
    final now = DateTime.now();
    final currentVer = existing?.version ?? entry.version;
    final newVersion = currentVer + 1;

    await _db.entryDao.updateEntry(
      EntriesTableCompanion(
        id: Value(entry.id),
        categoryId: Value(entry.categoryId),
        kind: Value(entry.kind.name),
        accountId: Value(entry.accountId),
        cardId: Value(entry.cardId),
        entryDate: Value(entry.entryDate),
        amountPaise: Value(entry.amount.paise),
        note: Value(entry.note),
        parentId: Value(entry.parentId),
        version: Value(newVersion),
        updatedAt: Value(now),
      ),
    );

    final payload = {
      'id': entry.id,
      'householdId': existing?.householdId ?? entry.householdId,
      'categoryId': entry.categoryId,
      'kind': entry.kind.name,
      'accountId': entry.accountId,
      'cardId': entry.cardId,
      'entryDate': entry.entryDate.toIso8601String(),
      'amountPaise': entry.amount.paise,
      'note': entry.note,
      'parentId': entry.parentId,
      'createdBy': existing?.createdBy ?? entry.createdBy,
      'version': newVersion,
      'createdAt': (existing?.createdAt ?? entry.createdAt).toIso8601String(),
      'updatedAt': now.toIso8601String(),
    };

    await _db.into(_db.syncQueueTable).insert(
      SyncQueueTableCompanion.insert(
        id: _uuid.v4(),
        op: 'update',
        entity: 'entry',
        entityId: entry.id,
        payload: jsonEncode(payload),
        createdAt: now,
      ),
    );

    await syncAllVaults();
    await _db.accountDao.recalculateAllAccountBalances();
  }

  @override
  Future<void> softDeleteLocal(String entryId) async {
    final existing = await _db.entryDao.getById(entryId);
    final now = DateTime.now();
    final currentVer = existing?.version ?? 1;
    final newVersion = currentVer + 1;

    await (_db.update(_db.entriesTable)..where((e) => e.id.equals(entryId))).write(
      EntriesTableCompanion(
        version: Value(newVersion),
        updatedAt: Value(now),
        deletedAt: Value(now),
      ),
    );

    if (existing != null) {
      final payload = {
        'id': existing.id,
        'householdId': existing.householdId,
        'categoryId': existing.categoryId,
        'kind': existing.kind,
        'accountId': existing.accountId,
        'cardId': existing.cardId,
        'entryDate': existing.entryDate.toIso8601String(),
        'amountPaise': existing.amountPaise,
        'note': existing.note,
        'parentId': existing.parentId,
        'createdBy': existing.createdBy,
        'version': newVersion,
        'createdAt': existing.createdAt.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'deletedAt': now.toIso8601String(),
      };

      await _db.into(_db.syncQueueTable).insert(
        SyncQueueTableCompanion.insert(
          id: _uuid.v4(),
          op: 'delete',
          entity: 'entry',
          entityId: existing.id,
          payload: jsonEncode(payload),
          createdAt: now,
        ),
      );
    }

    await syncAllVaults();
    await _db.accountDao.recalculateAllAccountBalances();
  }
}

class MonthStatusRepositoryImpl implements MonthStatusRepository {
  final AppDatabase _db;

  MonthStatusRepositoryImpl(this._db);

  @override
  Future<bool> isMonthOpen(int year, int month, {String? householdId}) async {
    final ymStr = '$year-${month.toString().padLeft(2, '0')}';
    return _db.snapshotDao.isMonthOpen(ymStr, householdId: householdId);
  }
}
