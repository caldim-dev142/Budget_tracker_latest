import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/entry.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../data/local/database.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'app_init_service.dart';

final syncServiceProvider = Provider<SyncService>((ref) => SyncService(ref));

class SyncService {
  final Ref _ref;
  final _dio = Dio(
    BaseOptions(
      contentType: 'application/json',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );
  final Connectivity _connectivity = Connectivity();
  bool _isSyncing = false;

  SyncService(this._ref) {
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.contains(ConnectivityResult.mobile) ||
          results.contains(ConnectivityResult.wifi) ||
          results.contains(ConnectivityResult.ethernet)) {
        triggerSync();
      }
    });
  }

  /// Fire-and-forget background sync triggered on any data mutation
  Future<void> triggerSync() async {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      await syncAllQueue();
    } catch (e) {
      print('Auto-sync triggered error: $e');
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> syncEntry(Entry entry) async {
    final serverUrl = _ref.read(serverUrlProvider);
    final authState = _ref.read(authStateProvider).valueOrNull;

    if (authState == null || authState.authMode != AuthMode.authenticated) {
      return;
    }

    final householdId = authState.householdId;
    if (householdId == null || householdId.isEmpty || entry.householdId != householdId) {
      return;
    }

    final token = authState.token;
    if (token == null) return;

    try {
      final payload = {
        'id': entry.id,
        'categoryId': entry.categoryId,
        'kind': entry.kind.name,
        'accountId': entry.accountId,
        'cardId': entry.cardId,
        'entryDate': entry.entryDate.toIso8601String(),
        'amountPaise': entry.amount.paise,
        'note': entry.note,
        'parentId': entry.parentId,
        'version': entry.version,
        'createdAt': entry.createdAt.toIso8601String(),
        'updatedAt': entry.updatedAt.toIso8601String(),
      };

      await _dio.post(
        '$serverUrl/entries/batch',
        data: [payload],
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
    } catch (e) {
      try {
        final db = _ref.read(appDatabaseProvider);
        await db.syncQueueDao.enqueue(
          id: entry.id,
          op: 'insert',
          entity: 'entry',
          entityId: entry.id,
          payload: {
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
            'version': entry.version,
            'createdAt': entry.createdAt.toIso8601String(),
            'updatedAt': entry.updatedAt.toIso8601String(),
          },
        );
      } catch (_) {}
    }
  }

  Future<int> syncAllQueue() async {
    final serverUrl = _ref.read(serverUrlProvider);
    final authState = _ref.read(authStateProvider).valueOrNull;

    if (authState == null || authState.authMode != AuthMode.authenticated) {
      return 0;
    }

    final householdId = authState.householdId;
    if (householdId == null || householdId.isEmpty) return 0;

    final token = authState.token;
    if (token == null) return 0;

    final db = _ref.read(appDatabaseProvider);
    final householdId = authState.householdId ?? 'default';

    // 1. Ensure any offline/local entities are migrated to active household
    await AppInitService.migrateLocalDataToHousehold(db, householdId);

    // 2. Ensure accounts with positive balances have opening balance entries so they are never lost
    await db.accountDao.ensureOpeningBalanceEntries(householdId);

    // 3. Process pending offline ops queue if any
    final pending = await db.syncQueueDao.getPending();
    int successCount = 0;
    for (final op in pending) {
      if (op.entity == 'entry') {
        try {
          final payload = jsonDecode(op.payload);
          // If payload contains householdId, verify it matches currently active household
          if (payload is Map && payload.containsKey('householdId') && payload['householdId'] != householdId) {
            continue; // Skip sync ops belonging to other households
          }

          if (op.op == 'insert') {
            await _dio.post(
              '$serverUrl/entries/batch',
              data: [payload],
              options: Options(
                headers: {
                  'Authorization': 'Bearer $token',
                },
              ),
            );
          }
          await db.syncQueueDao.markSynced(op.id);
          successCount++;
        } catch (e) {
          // Retry later on reconnection
        }
      }
    }

    // 4. Comprehensive multi-entity PUSH to backend POST /sync/batch FIRST
    try {
      // Categories
      final categories = await (db.select(db.categoriesTable)..where((c) => c.householdId.equals(householdId))).get();
      final categoriesPayload = categories.map((c) => {
        'id': c.id,
        'kind': c.kind,
        'groupCode': c.groupCode,
        'name': c.name,
        'needOrWant': c.needOrWant,
        'isDeduction': c.isDeduction,
        'isSystem': c.isSystem,
        'sortOrder': c.sortOrder,
      }).toList();

      // Accounts (preserve exact IDs for foreign-key consistency)
      final accounts = await (db.select(db.accountsTable)..where((a) => a.householdId.equals(householdId))).get();
      final accountsPayload = accounts.map((a) => {
        'id': a.id,
        'name': a.name,
        'type': a.type,
        'currentBalancePaise': a.currentBalancePaise,
        'isActive': a.isActive,
        'sortOrder': a.sortOrder,
      }).toList();

      // Credit Cards
      final cards = await (db.select(db.creditCardsTable)..where((c) => c.householdId.equals(householdId))).get();
      final cardsPayload = cards.map((c) => {
        'id': c.id,
        'name': c.name,
        'previousOutstandingPaise': c.previousOutstandingPaise,
        'isActive': c.isActive,
      }).toList();

      // Card Transactions
      final cardTxns = await (db.select(db.cardTransactionsTable)).get();
      final cardTxnsPayload = cardTxns.map((t) => {
        'id': t.id,
        'cardId': t.cardId,
        'txnDate': t.txnDate.toIso8601String(),
        'description': t.description,
        'amountPaise': t.amountPaise,
        'sNo': t.sNo,
      }).toList();

      // Planned Bills (Payables)
      final bills = await (db.select(db.plannedBillsTable)..where((b) => b.householdId.equals(householdId))).get();
      final billsPayload = bills.map((b) => {
        'id': b.id,
        'name': b.name,
        'amountPaise': b.amountPaise,
        'dueDate': b.dueDate?.toIso8601String(),
        'isPaid': b.isPaid,
        'entryId': b.entryId,
      }).toList();

      // Receivables
      final receivables = await (db.select(db.receivablesTable)..where((r) => r.householdId.equals(householdId))).get();
      final receivablesPayload = receivables.map((r) => {
        'id': r.id,
        'personName': r.personName,
        'amountPaise': r.amountPaise,
        'status': r.status,
        'dueDate': r.dueDate?.toIso8601String(),
        'entryId': r.entryId,
      }).toList();

      // Saving Goals
      final goals = await (db.select(db.savingGoalsTable)..where((g) => g.householdId.equals(householdId))).get();
      final goalsPayload = goals.map((g) => {
        'id': g.id,
        'bucket': g.bucket,
        'name': g.name,
        'targetPaise': g.targetPaise,
        'monthlyBudgetPaise': g.monthlyBudgetPaise,
        'archivedAt': g.archivedAt?.toIso8601String(),
      }).toList();

      // Sinking Funds
      final funds = await (db.select(db.sinkingFundsTable)..where((f) => f.householdId.equals(householdId))).get();
      final fundsPayload = funds.map((f) => {
        'id': f.id,
        'name': f.name,
        'openingReservePaise': f.openingReservePaise,
        'archivedAt': f.archivedAt?.toIso8601String(),
      }).toList();

      // Goal Contributions
      final goalContribs = await (db.select(db.goalContributionsTable)).get();
      final goalContribsPayload = goalContribs.map((gc) => {
        'id': gc.id,
        'goalId': gc.goalId,
        'amountPaise': gc.amountPaise,
        'contributionDate': gc.contributionDate.toIso8601String(),
        'note': gc.note,
      }).toList();

      // Fund Movements
      final fundMovements = await (db.select(db.fundMovementsTable)).get();
      final fundMovementsPayload = fundMovements.map((fm) => {
        'id': fm.id,
        'fundId': fm.fundId,
        'type': fm.type,
        'amountPaise': fm.amountPaise,
        'movementDate': fm.movementDate.toIso8601String(),
        'note': fm.note,
      }).toList();

      // Budgets
      final budgets = await (db.select(db.budgetsTable)..where((b) => b.householdId.equals(householdId))).get();
      final budgetsPayload = budgets.map((b) => {
        'id': b.id,
        'categoryId': b.categoryId,
        'yearMonth': b.yearMonth,
        'amountPaise': b.amountPaise,
      }).toList();

      // Entries
      final allEntries = await (db.select(db.entriesTable)..where((e) => e.householdId.equals(householdId))).get();
      final entriesPayload = allEntries.map((e) => {
        'id': e.id,
        'categoryId': e.categoryId,
        'kind': e.kind,
        'accountId': e.accountId,
        'cardId': e.cardId,
        'entryDate': e.entryDate.toIso8601String(),
        'amountPaise': e.amountPaise,
        'note': e.note,
        'parentId': e.parentId,
        'version': e.version,
        'createdAt': e.createdAt.toIso8601String(),
        'updatedAt': e.updatedAt.toIso8601String(),
      }).toList();

      final batchPayload = {
        'categories': categoriesPayload,
        'accounts': accountsPayload,
        'creditCards': cardsPayload,
        'cardTransactions': cardTxnsPayload,
        'plannedBills': billsPayload,
        'receivables': receivablesPayload,
        'savingGoals': goalsPayload,
        'goalContributions': goalContribsPayload,
        'sinkingFunds': fundsPayload,
        'fundMovements': fundMovementsPayload,
        'budgets': budgetsPayload,
        'entries': entriesPayload,
      };

      final res = await _dio.post(
        '$serverUrl/sync/batch',
        data: batchPayload,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
      print('Comprehensive Batch Sync to server successful: ${res.data}');

      // 5. AFTER pushing local data, pull any latest server-side changes to merge
      await pullFromServer();

      return successCount + allEntries.length;
    } catch (e) {
      print('Error during comprehensive batch sync: $e');
      return successCount;
    }
  }

  /// Pulls all household data from backend PostgreSQL into local SQLite (GET /sync/pull).
  Future<bool> pullFromServer() async {
    final serverUrl = _ref.read(serverUrlProvider);
    final authState = _ref.read(authStateProvider).valueOrNull;

    if (authState == null || authState.authMode != AuthMode.authenticated) {
      return false;
    }

    final token = authState.token;
    if (token == null) return false;

    final db = _ref.read(appDatabaseProvider);
    final householdId = authState.householdId ?? 'default';

    try {
      final res = await _dio.get(
        '$serverUrl/sync/pull',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final data = res.data;
      if (data == null || data is! Map) return false;

      await db.transaction(() async {
        // 1. Categories
        if (data['categories'] != null && data['categories'] is List) {
          final cats = (data['categories'] as List).map((c) => CategoriesTableCompanion.insert(
            id: c['id'] as String,
            householdId: (c['householdId'] ?? householdId) as String,
            kind: (c['kind'] ?? 'spending') as String,
            groupCode: Value(c['groupCode'] as String?),
            name: (c['name'] ?? 'Category') as String,
            needOrWant: Value(c['needOrWant'] as String?),
            isDeduction: Value((c['isDeduction'] as bool?) ?? false),
            isSystem: Value((c['isSystem'] as bool?) ?? false),
            sortOrder: Value((c['sortOrder'] as int?) ?? 0),
          )).toList();
          await db.categoryDao.upsertAll(cats);
        }

        // 2. Accounts
        if (data['accounts'] != null && data['accounts'] is List) {
          for (final a in data['accounts'] as List) {
            await db.accountDao.upsertAccount(AccountsTableCompanion.insert(
              id: a['id'] as String,
              householdId: (a['householdId'] ?? householdId) as String,
              name: (a['name'] ?? 'Account') as String,
              type: (a['type'] ?? 'bank') as String,
              currentBalancePaise: Value((a['currentBalancePaise'] as num?)?.toInt() ?? 0),
              isActive: Value((a['isActive'] as bool?) ?? true),
              sortOrder: Value((a['sortOrder'] as int?) ?? 0),
            ));
          }
        }

        // 3. Credit Cards
        if (data['creditCards'] != null && data['creditCards'] is List) {
          for (final c in data['creditCards'] as List) {
            await db.into(db.creditCardsTable).insertOnConflictUpdate(CreditCardsTableCompanion.insert(
              id: c['id'] as String,
              householdId: (c['householdId'] ?? householdId) as String,
              name: (c['name'] ?? 'Card') as String,
              previousOutstandingPaise: Value((c['previousOutstandingPaise'] as num?)?.toInt() ?? 0),
              isActive: Value((c['isActive'] as bool?) ?? true),
            ));
          }
        }

        // 4. Card Transactions
        if (data['cardTransactions'] != null && data['cardTransactions'] is List) {
          for (final t in data['cardTransactions'] as List) {
            await db.into(db.cardTransactionsTable).insertOnConflictUpdate(CardTransactionsTableCompanion.insert(
              id: t['id'] as String,
              cardId: t['cardId'] as String,
              txnDate: DateTime.parse(t['txnDate'] as String),
              description: (t['description'] ?? '') as String,
              amountPaise: (t['amountPaise'] as num?)?.toInt() ?? 0,
              sNo: Value(t['sNo'] as int?),
            ));
          }
        }

        // 5. Planned Bills
        if (data['plannedBills'] != null && data['plannedBills'] is List) {
          for (final b in data['plannedBills'] as List) {
            await db.into(db.plannedBillsTable).insertOnConflictUpdate(PlannedBillsTableCompanion.insert(
              id: b['id'] as String,
              householdId: (b['householdId'] ?? householdId) as String,
              name: (b['name'] ?? 'Bill') as String,
              amountPaise: (b['amountPaise'] as num?)?.toInt() ?? 0,
              dueDate: Value(b['dueDate'] != null ? DateTime.parse(b['dueDate'] as String) : null),
              isPaid: Value((b['isPaid'] as bool?) ?? false),
              entryId: Value((b['entryId'] ?? b['entry_id']) as String?),
            ));
          }
        }

        // 6. Receivables
        if (data['receivables'] != null && data['receivables'] is List) {
          for (final r in data['receivables'] as List) {
            await db.into(db.receivablesTable).insertOnConflictUpdate(ReceivablesTableCompanion.insert(
              id: r['id'] as String,
              householdId: (r['householdId'] ?? householdId) as String,
              personName: (r['personName'] ?? 'Person') as String,
              amountPaise: (r['amountPaise'] as num?)?.toInt() ?? 0,
              status: Value((r['status'] as String?) ?? 'open'),
              dueDate: Value(r['dueDate'] != null ? DateTime.parse(r['dueDate'] as String) : null),
              entryId: Value((r['entryId'] ?? r['entry_id']) as String?),
            ));
          }
        }

        // 7. Saving Goals
        if (data['savingGoals'] != null && data['savingGoals'] is List) {
          for (final g in data['savingGoals'] as List) {
            await db.into(db.savingGoalsTable).insertOnConflictUpdate(SavingGoalsTableCompanion.insert(
              id: g['id'] as String,
              householdId: (g['householdId'] ?? householdId) as String,
              bucket: (g['bucket'] ?? 'other_goals') as String,
              name: (g['name'] ?? 'Goal') as String,
              targetPaise: Value((g['targetPaise'] as num?)?.toInt()),
              monthlyBudgetPaise: Value((g['monthlyBudgetPaise'] as num?)?.toInt() ?? 0),
              archivedAt: Value(g['archivedAt'] != null ? DateTime.parse(g['archivedAt'] as String) : null),
            ));
          }
        }

        // 8. Sinking Funds
        if (data['sinkingFunds'] != null && data['sinkingFunds'] is List) {
          for (final f in data['sinkingFunds'] as List) {
            await db.into(db.sinkingFundsTable).insertOnConflictUpdate(SinkingFundsTableCompanion.insert(
              id: f['id'] as String,
              householdId: (f['householdId'] ?? householdId) as String,
              name: (f['name'] ?? 'Fund') as String,
              openingReservePaise: Value((f['openingReservePaise'] as num?)?.toInt() ?? 0),
              archivedAt: Value(f['archivedAt'] != null ? DateTime.parse(f['archivedAt'] as String) : null),
            ));
          }
        }

        // 9. Entries
        if (data['entries'] != null && data['entries'] is List) {
          for (final e in data['entries'] as List) {
            await db.entryDao.insertEntry(EntriesTableCompanion.insert(
              id: e['id'] as String,
              householdId: (e['householdId'] ?? householdId) as String,
              categoryId: e['categoryId'] as String,
              kind: (e['kind'] ?? 'spending') as String,
              accountId: Value(e['accountId'] as String?),
              cardId: Value(e['cardId'] as String?),
              entryDate: DateTime.parse(e['entryDate'] as String),
              amountPaise: (e['amountPaise'] as num?)?.toInt() ?? 0,
              note: Value(e['note'] as String?),
              parentId: Value(e['parentId'] as String?),
              createdBy: (e['createdBy'] ?? 'system') as String,
              version: Value((e['version'] as int?) ?? 1),
              createdAt: DateTime.parse((e['createdAt'] ?? e['entryDate']) as String),
              updatedAt: DateTime.parse((e['updatedAt'] ?? e['entryDate']) as String),
              deletedAt: Value(e['deletedAt'] != null ? DateTime.parse(e['deletedAt'] as String) : null),
            ));
          }
        }

        // 10. Goal Contributions
        if (data['goalContributions'] != null && data['goalContributions'] is List) {
          for (final gc in data['goalContributions'] as List) {
            await db.into(db.goalContributionsTable).insertOnConflictUpdate(GoalContributionsTableCompanion.insert(
              id: gc['id'] as String,
              goalId: gc['goalId'] as String,
              amountPaise: (gc['amountPaise'] as num?)?.toInt() ?? 0,
              contributionDate: DateTime.parse(gc['contributionDate'] as String),
              note: Value(gc['note'] as String?),
            ));
          }
        }

        // 11. Fund Movements
        if (data['fundMovements'] != null && data['fundMovements'] is List) {
          for (final fm in data['fundMovements'] as List) {
            await db.into(db.fundMovementsTable).insertOnConflictUpdate(FundMovementsTableCompanion.insert(
              id: fm['id'] as String,
              fundId: fm['fundId'] as String,
              type: (fm['type'] ?? 'contribution') as String,
              amountPaise: (fm['amountPaise'] as num?)?.toInt() ?? 0,
              movementDate: DateTime.parse(fm['movementDate'] as String),
              note: Value(fm['note'] as String?),
            ));
          }
        }

        // 12. Budgets
        if (data['budgets'] != null && data['budgets'] is List) {
          for (final b in data['budgets'] as List) {
            await db.into(db.budgetsTable).insertOnConflictUpdate(BudgetsTableCompanion.insert(
              id: b['id'] as String,
              householdId: (b['householdId'] ?? householdId) as String,
              categoryId: b['categoryId'] as String,
              yearMonth: b['yearMonth'] as String,
              amountPaise: Value((b['amountPaise'] as num?)?.toInt() ?? 0),
            ));
          }
        }

        // Recalculate account balances after all entries are restored
        await db.accountDao.recalculateAllAccountBalances();
      });

      print('Successfully pulled and synchronized all household data from server.');
      return true;
    } catch (e) {
      print('Failed to pull data from server: $e');
      return false;
    }
  }
}
