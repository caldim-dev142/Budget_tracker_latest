import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../domain/entities/entry.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../data/local/database.dart';
import '../../data/local/daos/sync_queue_dao.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../security/secure_store.dart';
import 'app_init_service.dart';

final syncServiceProvider = Provider<SyncService>((ref) => SyncService(ref));
const _uuid = Uuid();

/// Storage key for the timestamp of the last fully-successful sync.
const String kLastSuccessfulSyncKey = 'last_successful_sync_at';

/// Timestamp of the last successful sync, or null if this device has never
/// completed one. Seeded from storage on first read and updated in-memory after
/// each successful run so the UI reacts immediately.
final lastSyncAtProvider = StateProvider<DateTime?>((_) => null);

/// Loads the persisted last-sync time once into [lastSyncAtProvider].
final lastSyncBootstrapProvider = FutureProvider<DateTime?>((ref) async {
  final raw = await SecureStore.read(kLastSuccessfulSyncKey);
  if (raw == null || raw.isEmpty) return null;
  final parsed = DateTime.tryParse(raw)?.toLocal();
  if (parsed != null) {
    ref.read(lastSyncAtProvider.notifier).state = parsed;
  }
  return parsed;
});

/// Live count of changes not yet accepted by the server.
final pendingSyncCountProvider = StreamProvider<int>((ref) {
  return ref.watch(appDatabaseProvider).syncQueueDao.watchPendingCount();
});

/// How worried the user should be about their backup state.
enum SyncHealth {
  /// Nothing queued — everything the app knows about has reached the server.
  healthy,

  /// Changes are queued but the last sync was recent: normal transient state.
  pending,

  /// Nothing has synced for a long time, or this device has never synced while
  /// holding data. The user's records exist only on this phone.
  stale,
}

/// Beyond this, un-backed-up data is treated as a real problem, not a blip.
const Duration kStaleSyncThreshold = Duration(hours: 24);

/// Combines queue depth and last-sync age into one signal for the UI.
final syncHealthProvider = Provider<SyncHealth>((ref) {
  final pending = ref.watch(pendingSyncCountProvider).valueOrNull ?? 0;
  final lastSync = ref.watch(lastSyncAtProvider);

  if (pending == 0) return SyncHealth.healthy;
  // Queued work and no successful sync ever recorded: nothing is backed up.
  if (lastSync == null) return SyncHealth.stale;

  return DateTime.now().difference(lastSync) > kStaleSyncThreshold
      ? SyncHealth.stale
      : SyncHealth.pending;
});

/// Why a sync run ended the way it did.
///
/// CRITICAL HISTORY: syncAllQueue() used to return a bare `int`, returning 0 for
/// FOUR different situations — nothing to sync, no server URL configured, not
/// authenticated, and "the push threw and we swallowed it". Force Sync mapped 0
/// to "Already up to date. No pending changes to sync.", so a user whose sync
/// had been failing for weeks was actively reassured their data was safe. That
/// is the path that lost real user data: they believed the message, reinstalled
/// the app, and their local-only records were gone.
///
/// A caller must never be able to mistake failure for success.
enum SyncStatus {
  /// Push and pull both completed against the server.
  success,

  /// No server URL configured — nothing was attempted.
  notConfigured,

  /// Not signed in, or no household yet — nothing was attempted.
  notAuthenticated,

  /// The server was reached for, but the run threw. Data is still local-only.
  failed,

  /// The sync operation timed out. Data is still saved locally.
  timedOut,

  /// The sync operation was explicitly cancelled. Data is still saved locally.
  cancelled,

  /// Another sync operation is already in progress for this client.
  inProgress,
}

/// Result of one sync run. Deliberately not an int.
class SyncOutcome {
  final SyncStatus status;

  /// Records the server accepted during the push.
  final int pushedCount;

  /// Operations still queued AFTER the run. Non-zero after a success means some
  /// items were rejected or skipped and need attention.
  final int pendingAfter;

  /// The underlying error, when [status] is [SyncStatus.failed] or [SyncStatus.timedOut].
  final Object? error;

  const SyncOutcome({
    required this.status,
    this.pushedCount = 0,
    this.pendingAfter = 0,
    this.error,
  });

  bool get isSuccess => status == SyncStatus.success;

  /// True when this device holds changes the server has not acknowledged.
  bool get hasUnsyncedData => pendingAfter > 0;

  /// A short, honest, user-facing description. Never claims success.
  String get message {
    if (status == SyncStatus.notConfigured) {
      return 'No server is configured, so nothing has been backed up. '
          'Your data is only on this device.';
    }
    if (status == SyncStatus.notAuthenticated) {
      return 'You are not signed in, so nothing has been backed up. '
          'Your data is only on this device.';
    }
    if (status == SyncStatus.timedOut) {
      return 'Sync timed out. Your changes are saved on this device but are '
          'NOT backed up yet.';
    }
    if (status == SyncStatus.cancelled) {
      return 'Sync was cancelled. Your changes remain saved on this device.';
    }
    if (status == SyncStatus.inProgress) {
      return 'A sync is already in progress.';
    }
    if (status == SyncStatus.failed) {
      return 'Could not reach the server. Your changes are saved on this '
          'device but are NOT backed up yet.';
    }
    if (pendingAfter > 0) {
      final s = pushedCount == 1 ? '' : 's';
      return 'Synced $pushedCount change$s, but $pendingAfter could not be '
          'saved to the server.';
    }
    if (pushedCount > 0) {
      final s = pushedCount == 1 ? '' : 's';
      return 'Synced $pushedCount change$s.';
    }
    return 'Everything is already backed up.';
  }
}

class SyncService {
  final Ref _ref;
  Dio get _dio => _ref.read(authenticatedDioProvider);
  final Connectivity _connectivity = Connectivity();
  bool _isSyncing = false;
  // Set when triggerSync() is called while a sync is already in flight, so the mutation
  // that arrived mid-sync isn't silently dropped (data-persistence audit fix, 2026-09-17):
  // a rapid second mutation (e.g. creating a card right after an account) used to hit
  // `if (_isSyncing) return;` and vanish — the item stayed correctly saved locally but never
  // got pushed until some unrelated later action happened to trigger another sync.
  bool _hasPendingSync = false;

  // Mutual exclusion lock, active cancel token, and generation counter for concurrency & cancellation protection
  bool _isSyncRunning = false;
  int _activeOperationId = 0;
  CancelToken? _activeCancelToken;

  /// Whether a sync operation is currently in flight.
  bool get isSyncRunning => _isSyncRunning;

  /// Cancels the currently active sync operation if one is in flight.
  void cancelCurrentSync([String? reason]) {
    if (_activeCancelToken != null && !_activeCancelToken!.isCancelled) {
      _activeCancelToken!.cancel(reason ?? 'Sync cancelled');
    }
  }

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
    if (_isSyncing) {
      _hasPendingSync = true;
      return;
    }
    _isSyncing = true;
    try {
      do {
        _hasPendingSync = false;
        await syncAllQueue();
      } while (_hasPendingSync);
    } catch (e) {
      debugPrint('Auto-sync triggered error: $e');
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> syncEntry(Entry entry) async {
    final serverUrl = _ref.read(serverUrlProvider);
    final authState = _ref.read(authStateProvider).valueOrNull;

    if (serverUrl.isEmpty || authState == null || authState.authMode != AuthMode.authenticated) {
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

  Future<SyncOutcome> syncAllQueue({
    CancelToken? cancelToken,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    // Concurrency / duplicate sync protection:
    // Prevent multiple sync operations from running concurrently.
    if (_isSyncRunning) {
      return SyncOutcome(
        status: SyncStatus.inProgress,
        pendingAfter: await _safePendingCount(),
      );
    }

    _isSyncRunning = true;
    final opId = ++_activeOperationId;

    // Link provided cancelToken or create a new one
    final effectiveCancelToken = cancelToken ?? CancelToken();
    _activeCancelToken = effectiveCancelToken;

    // Explicit timeout: aborts underlying network operations via CancelToken
    bool isTimedOut = false;
    final timer = Timer(timeout, () {
      isTimedOut = true;
      if (!effectiveCancelToken.isCancelled) {
        effectiveCancelToken.cancel('Sync operation timed out after ${timeout.inSeconds}s');
      }
    });

    final serverUrl = _ref.read(serverUrlProvider);
    final authState = _ref.read(authStateProvider).valueOrNull;

    try {
      // Each bail-out now reports WHY. These all used to return 0, which the UI
      // could not distinguish from "nothing needed syncing".
      if (serverUrl.isEmpty) {
        return SyncOutcome(
          status: SyncStatus.notConfigured,
          pendingAfter: await _safePendingCount(),
        );
      }

      if (authState == null || authState.authMode != AuthMode.authenticated) {
        return SyncOutcome(
          status: SyncStatus.notAuthenticated,
          pendingAfter: await _safePendingCount(),
        );
      }

      final householdId = authState.householdId;
      if (householdId == null || householdId.isEmpty) {
        return SyncOutcome(
          status: SyncStatus.notAuthenticated,
          pendingAfter: await _safePendingCount(),
        );
      }

      final token = authState.token;
      if (token == null) {
        return SyncOutcome(
          status: SyncStatus.notAuthenticated,
          pendingAfter: await _safePendingCount(),
        );
      }

      if (effectiveCancelToken.isCancelled || opId != _activeOperationId) {
        return SyncOutcome(
          status: isTimedOut ? SyncStatus.timedOut : SyncStatus.cancelled,
          pendingAfter: await _safePendingCount(),
        );
      }

      final db = _ref.read(appDatabaseProvider);

      // 1. Ensure any offline/local entities are migrated to active household
      await AppInitService.migrateLocalDataToHousehold(db, householdId);

      // 2. Ensure accounts with positive balances have opening balance entries so they are never lost
      await db.accountDao.ensureOpeningBalanceEntries(householdId);

      if (effectiveCancelToken.isCancelled || opId != _activeOperationId) {
        return SyncOutcome(
          status: isTimedOut ? SyncStatus.timedOut : SyncStatus.cancelled,
          pendingAfter: await _safePendingCount(),
        );
      }

      // 3. Process pending offline ops queue if any
      final pending = await db.syncQueueDao.getPending();
      int successCount = 0;
      for (final op in pending) {
        if (effectiveCancelToken.isCancelled || opId != _activeOperationId) {
          return SyncOutcome(
            status: isTimedOut ? SyncStatus.timedOut : SyncStatus.cancelled,
            pushedCount: successCount,
            pendingAfter: await _safePendingCount(),
          );
        }
        if (op.entity == 'entry') {
          // An op the server keeps rejecting (e.g. an entry in a closed month) is not retried forever.
          if (op.attempts >= SyncQueueDao.maxAttempts) continue;
          try {
            final payload = jsonDecode(op.payload);
            // If payload contains householdId, verify it matches currently active household
            if (payload is Map && payload.containsKey('householdId') && payload['householdId'] != householdId) {
              continue; // Skip sync ops belonging to other households
            }

            if (op.op == 'insert' || op.op == 'update' || op.op == 'delete') {
              final res = await _dio.post(
                '$serverUrl/entries/batch',
                data: [payload],
                cancelToken: effectiveCancelToken,
                options: Options(
                  headers: {
                    'Authorization': 'Bearer $token',
                  },
                ),
              );
              // The endpoint returns 201 with {synced, failed}; a rejected entry must stay queued.
              final body = res.data;
              final failed = body is Map ? ((body['failed'] as num?)?.toInt() ?? 0) : 0;
              if (failed > 0) {
                await db.syncQueueDao.incrementAttempts(op.id);
                continue;
              }
            }
            await db.syncQueueDao.markSynced(op.id);
            successCount++;
          } catch (e) {
            if (effectiveCancelToken.isCancelled || isTimedOut) {
              return SyncOutcome(
                status: isTimedOut ? SyncStatus.timedOut : SyncStatus.cancelled,
                pushedCount: successCount,
                pendingAfter: await _safePendingCount(),
                error: e,
              );
            }
            // Retry later on reconnection
            try {
              await db.syncQueueDao.incrementAttempts(op.id);
            } catch (_) {}
          }
        }
      }

      if (effectiveCancelToken.isCancelled || opId != _activeOperationId) {
        return SyncOutcome(
          status: isTimedOut ? SyncStatus.timedOut : SyncStatus.cancelled,
          pushedCount: successCount,
          pendingAfter: await _safePendingCount(),
        );
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

        // Card Transactions (scoped strictly to active household's cards)
        final cardIds = cards.map((c) => c.id).toSet();
        final cardTxns = cardIds.isEmpty
            ? <CardTransactionsTableData>[]
            : await (db.select(db.cardTransactionsTable)..where((t) => t.cardId.isIn(cardIds))).get();
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

        // Goal Contributions (scoped strictly to active household's goals)
        final goalIds = goals.map((g) => g.id).toSet();
        final goalContribs = goalIds.isEmpty
            ? <GoalContributionsTableData>[]
            : await (db.select(db.goalContributionsTable)..where((c) => c.goalId.isIn(goalIds))).get();
        final goalContribsPayload = goalContribs.map((c) => {
          'id': c.id,
          'goalId': c.goalId,
          'amountPaise': c.amountPaise,
          'contributionDate': c.contributionDate.toIso8601String(),
          'note': c.note,
        }).toList();

        // Sinking Funds
        final funds = await (db.select(db.sinkingFundsTable)..where((f) => f.householdId.equals(householdId))).get();
        final fundsPayload = funds.map((f) => {
          'id': f.id,
          'name': f.name,
          'openingReservePaise': f.openingReservePaise,
          'archivedAt': f.archivedAt?.toIso8601String(),
        }).toList();

        // Fund Movements (scoped strictly to active household's funds)
        final fundIds = funds.map((f) => f.id).toSet();
        final fundMovements = fundIds.isEmpty
            ? <FundMovementsTableData>[]
            : await (db.select(db.fundMovementsTable)..where((m) => m.fundId.isIn(fundIds))).get();
        final fundMovementsPayload = fundMovements.map((m) => {
          'id': m.id,
          'fundId': m.fundId,
          'type': m.type,
          'amountPaise': m.amountPaise,
          'movementDate': m.movementDate.toIso8601String(),
          'note': m.note,
        }).toList();

        // Budgets
        final budgets = await (db.select(db.budgetsTable)..where((b) => b.householdId.equals(householdId))).get();
        final budgetsPayload = budgets.map((b) => {
          'id': b.id,
          'categoryId': b.categoryId,
          'yearMonth': b.yearMonth,
          'amountPaise': b.amountPaise,
        }).toList();

        // Reserve Lines
        final reserveLines = await (db.select(db.reserveLinesTable)..where((r) => r.householdId.equals(householdId))).get();
        final reserveLinesPayload = reserveLines.map((r) => {
          'id': r.id,
          'yearMonth': r.yearMonth,
          'name': r.name,
          'amountPaise': r.amountPaise,
          'source': r.source,
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
          'deletedAt': e.deletedAt?.toIso8601String(),
        }).toList();

        // Annual Targets
        final annualTargets = await (db.select(db.annualTargetsTable)..where((t) => t.householdId.equals(householdId))).get();
        final annualTargetsPayload = annualTargets.map((t) => {
          'id': t.id,
          'title': t.title,
          'targetPaise': t.targetPaise,
          'type': t.type,
        }).toList();

        // Pending hard deletions from syncQueue (all deletable entities, incl. annual targets)
        final pendingAll = await db.syncQueueDao.getPending();
        final deletionOps = pendingAll
            .where((op) => op.op == 'delete' && SyncQueueDao.deletableEntities.contains(op.entity))
            .toList();
        final deletionsPayload = deletionOps
            .map((op) => {'entity': op.entity, 'id': op.entityId})
            .toList();

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
          'reserveLines': reserveLinesPayload,
          'annualTargets': annualTargetsPayload,
          'entries': entriesPayload,
          if (deletionsPayload.isNotEmpty) 'deletions': deletionsPayload,
        };

        final res = await _dio.post(
          '$serverUrl/sync/batch',
          data: batchPayload,
          cancelToken: effectiveCancelToken,
          options: Options(
            headers: {
              'Authorization': 'Bearer $token',
            },
            sendTimeout: const Duration(seconds: 45),
            receiveTimeout: const Duration(seconds: 45),
          ),
        );
        debugPrint('Comprehensive Batch Sync to server successful: ${res.data}');

        // Mark delete ops as synced (the server applied them or they were already tombstoned)
        for (final op in deletionOps) {
          await db.syncQueueDao.markSynced(op.id);
        }

        // 4b. Replay month closes/reopens the server has not accepted yet (after the push, so a
        //     server-side close sees this device's entries).
        await _replayMonthStatusOps(db, serverUrl, token, householdId, cancelToken: effectiveCancelToken);

        if (effectiveCancelToken.isCancelled || opId != _activeOperationId) {
          return SyncOutcome(
            status: isTimedOut ? SyncStatus.timedOut : SyncStatus.cancelled,
            pushedCount: successCount + allEntries.length,
            pendingAfter: await _safePendingCount(),
          );
        }

        // 5. AFTER pushing local data, pull any latest server-side changes to merge
        await pullFromServer(cancelToken: effectiveCancelToken);

        // Only now may this be called a success — and verify generation counter hasn't been superseded
        if (opId != _activeOperationId || effectiveCancelToken.isCancelled || isTimedOut) {
          return SyncOutcome(
            status: isTimedOut ? SyncStatus.timedOut : SyncStatus.cancelled,
            pushedCount: successCount + allEntries.length,
            pendingAfter: await _safePendingCount(),
          );
        }

        await _recordSuccessfulSync();

        return SyncOutcome(
          status: SyncStatus.success,
          pushedCount: successCount + allEntries.length,
          pendingAfter: await _safePendingCount(),
        );
      } catch (e) {
        debugPrint('Error during comprehensive batch sync: $e');

        // If cancelled or timed out, do NOT perform fallback pull!
        if (effectiveCancelToken.isCancelled || isTimedOut) {
          return SyncOutcome(
            status: isTimedOut ? SyncStatus.timedOut : SyncStatus.cancelled,
            pushedCount: successCount,
            pendingAfter: await _safePendingCount(),
            error: e,
          );
        }

        // Even if batch push encounters an issue, attempt to pull latest server data
        try {
          await pullFromServer(cancelToken: effectiveCancelToken);
        } catch (pullErr) {
          debugPrint('Fallback pull error: $pullErr');
        }
        // The failure is REPORTED, not swallowed. Returning successCount here is
        // what let a failed push masquerade as "0 changes needed syncing".
        // NOTE: the fallback pull above does NOT make this a success — the user's
        // own changes still have not reached the server.
        return SyncOutcome(
          status: SyncStatus.failed,
          pushedCount: successCount,
          pendingAfter: await _safePendingCount(),
          error: e,
        );
      }
    } finally {
      timer.cancel();
      if (_activeCancelToken == effectiveCancelToken) {
        _activeCancelToken = null;
      }
      _isSyncRunning = false;
    }
  }

  /// Reads queue depth without ever throwing — this runs on error paths where a
  /// second exception would mask the original failure.
  Future<int> _safePendingCount() async {
    try {
      return await _ref.read(appDatabaseProvider).syncQueueDao.pendingCount();
    } catch (_) {
      return 0;
    }
  }

  /// Persists the moment of the last fully-successful sync, so the app can tell
  /// the user how long their data has been un-backed-up.
  Future<void> _recordSuccessfulSync() async {
    final now = DateTime.now();
    // Update the in-memory state FIRST, unconditionally. The push/pull above
    // already succeeded — the secure-storage write below only persists the
    // timestamp for a fresh cold start, and it can stall (e.g. keystore
    // access hanging while the app is backgrounded). A slow or failed write
    // must never leave a genuinely successful sync looking unsynced.
    _ref.read(lastSyncAtProvider.notifier).state = now;
    try {
      await SecureStore.write(
        kLastSuccessfulSyncKey,
        now.toUtc().toIso8601String(),
      ).timeout(const Duration(seconds: 5));
    } catch (_) {
      // Never let bookkeeping break a sync that actually worked. Only the
      // persisted timestamp is lost; this session's UI is already correct.
    }
  }

  /// Pulls all household data from backend PostgreSQL into local SQLite (GET /sync/pull).
  Future<bool> pullFromServer({CancelToken? cancelToken}) async {
    final serverUrl = _ref.read(serverUrlProvider);
    final authState = _ref.read(authStateProvider).valueOrNull;

    if (serverUrl.isEmpty || authState == null || authState.authMode != AuthMode.authenticated) {
      return false;
    }

    final token = authState.token;
    if (token == null) return false;

    if (cancelToken?.isCancelled ?? false) return false;

    final db = _ref.read(appDatabaseProvider);
    final householdId = authState.householdId ?? 'default';

    try {
      final res = await _dio.get(
        '$serverUrl/sync/pull',
        cancelToken: cancelToken,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
          sendTimeout: const Duration(seconds: 45),
          receiveTimeout: const Duration(seconds: 45),
        ),
      );

      final data = res.data;
      if (data == null || data is! Map) return false;
      if (cancelToken?.isCancelled ?? false) return false;
      final unsentCloses = <String>[];

      await db.transaction(() async {
        if (cancelToken?.isCancelled ?? false) return;
        await db.batch((b) {
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
              archivedAt: Value(c['archivedAt'] != null ? DateTime.parse(c['archivedAt'] as String) : null),
            )).toList();
            b.insertAllOnConflictUpdate(db.categoriesTable, cats);
          }

          // 2. Accounts
          if (data['accounts'] != null && data['accounts'] is List) {
            final accounts = (data['accounts'] as List).map((a) => AccountsTableCompanion.insert(
              id: a['id'] as String,
              householdId: (a['householdId'] ?? householdId) as String,
              name: (a['name'] ?? 'Account') as String,
              type: (a['type'] ?? 'bank') as String,
              currentBalancePaise: Value((a['currentBalancePaise'] as num?)?.toInt() ?? 0),
              isActive: Value((a['isActive'] as bool?) ?? true),
              sortOrder: Value((a['sortOrder'] as int?) ?? 0),
            )).toList();
            b.insertAllOnConflictUpdate(db.accountsTable, accounts);
          }

          // 3. Credit Cards
          if (data['creditCards'] != null && data['creditCards'] is List) {
            final cards = (data['creditCards'] as List).map((c) => CreditCardsTableCompanion.insert(
              id: c['id'] as String,
              householdId: (c['householdId'] ?? householdId) as String,
              name: (c['name'] ?? 'Card') as String,
              previousOutstandingPaise: Value((c['previousOutstandingPaise'] as num?)?.toInt() ?? 0),
              isActive: Value((c['isActive'] as bool?) ?? true),
            )).toList();
            b.insertAllOnConflictUpdate(db.creditCardsTable, cards);
          }

          // 4. Card Transactions
          if (data['cardTransactions'] != null && data['cardTransactions'] is List) {
            final cardTxns = (data['cardTransactions'] as List).map((t) => CardTransactionsTableCompanion.insert(
              id: t['id'] as String,
              cardId: t['cardId'] as String,
              txnDate: DateTime.parse(t['txnDate'] as String),
              description: (t['description'] ?? '') as String,
              amountPaise: (t['amountPaise'] as num?)?.toInt() ?? 0,
              sNo: Value(t['sNo'] as int?),
            )).toList();
            b.insertAllOnConflictUpdate(db.cardTransactionsTable, cardTxns);
          }

          // 5. Planned Bills
          if (data['plannedBills'] != null && data['plannedBills'] is List) {
            final bills = (data['plannedBills'] as List).map((bl) => PlannedBillsTableCompanion.insert(
              id: bl['id'] as String,
              householdId: (bl['householdId'] ?? householdId) as String,
              name: (bl['name'] ?? 'Bill') as String,
              amountPaise: (bl['amountPaise'] as num?)?.toInt() ?? 0,
              dueDate: Value(bl['dueDate'] != null ? DateTime.parse(bl['dueDate'] as String) : null),
              isPaid: Value((bl['isPaid'] as bool?) ?? false),
              entryId: Value((bl['entryId'] ?? bl['entry_id']) as String?),
            )).toList();
            b.insertAllOnConflictUpdate(db.plannedBillsTable, bills);
          }

          // 6. Receivables
          if (data['receivables'] != null && data['receivables'] is List) {
            final recs = (data['receivables'] as List).map((r) => ReceivablesTableCompanion.insert(
              id: r['id'] as String,
              householdId: (r['householdId'] ?? householdId) as String,
              personName: (r['personName'] ?? 'Person') as String,
              amountPaise: (r['amountPaise'] as num?)?.toInt() ?? 0,
              status: Value((r['status'] as String?) ?? 'open'),
              dueDate: Value(r['dueDate'] != null ? DateTime.parse(r['dueDate'] as String) : null),
              entryId: Value((r['entryId'] ?? r['entry_id']) as String?),
            )).toList();
            b.insertAllOnConflictUpdate(db.receivablesTable, recs);
          }

          // 7. Saving Goals
          if (data['savingGoals'] != null && data['savingGoals'] is List) {
            final goals = (data['savingGoals'] as List).map((g) => SavingGoalsTableCompanion.insert(
              id: g['id'] as String,
              householdId: (g['householdId'] ?? householdId) as String,
              bucket: (g['bucket'] ?? 'other_goals') as String,
              name: (g['name'] ?? 'Goal') as String,
              targetPaise: Value((g['targetPaise'] as num?)?.toInt()),
              monthlyBudgetPaise: Value((g['monthlyBudgetPaise'] as num?)?.toInt() ?? 0),
              archivedAt: Value(g['archivedAt'] != null ? DateTime.parse(g['archivedAt'] as String) : null),
            )).toList();
            b.insertAllOnConflictUpdate(db.savingGoalsTable, goals);
          }

          // 8. Sinking Funds
          if (data['sinkingFunds'] != null && data['sinkingFunds'] is List) {
            final funds = (data['sinkingFunds'] as List).map((f) => SinkingFundsTableCompanion.insert(
              id: f['id'] as String,
              householdId: (f['householdId'] ?? householdId) as String,
              name: (f['name'] ?? 'Fund') as String,
              openingReservePaise: Value((f['openingReservePaise'] as num?)?.toInt() ?? 0),
              archivedAt: Value(f['archivedAt'] != null ? DateTime.parse(f['archivedAt'] as String) : null),
            )).toList();
            b.insertAllOnConflictUpdate(db.sinkingFundsTable, funds);
          }

          // 9. Entries
          if (data['entries'] != null && data['entries'] is List) {
            final entries = (data['entries'] as List).map((e) => EntriesTableCompanion.insert(
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
            )).toList();
            b.insertAllOnConflictUpdate(db.entriesTable, entries);
          }

          // 10. Goal Contributions
          if (data['goalContributions'] != null && data['goalContributions'] is List) {
            final contribs = (data['goalContributions'] as List).map((gc) => GoalContributionsTableCompanion.insert(
              id: gc['id'] as String,
              goalId: gc['goalId'] as String,
              amountPaise: (gc['amountPaise'] as num?)?.toInt() ?? 0,
              contributionDate: DateTime.parse(gc['contributionDate'] as String),
              note: Value(gc['note'] as String?),
            )).toList();
            b.insertAllOnConflictUpdate(db.goalContributionsTable, contribs);
          }

          // 11. Fund Movements
          if (data['fundMovements'] != null && data['fundMovements'] is List) {
            final movements = (data['fundMovements'] as List).map((fm) => FundMovementsTableCompanion.insert(
              id: fm['id'] as String,
              fundId: fm['fundId'] as String,
              type: (fm['type'] ?? 'contribution') as String,
              amountPaise: (fm['amountPaise'] as num?)?.toInt() ?? 0,
              movementDate: DateTime.parse(fm['movementDate'] as String),
              note: Value(fm['note'] as String?),
            )).toList();
            b.insertAllOnConflictUpdate(db.fundMovementsTable, movements);
          }

          // 12. Budgets
          if (data['budgets'] != null && data['budgets'] is List) {
            final budgets = (data['budgets'] as List).map((bg) => BudgetsTableCompanion.insert(
              id: bg['id'] as String,
              householdId: (bg['householdId'] ?? householdId) as String,
              categoryId: bg['categoryId'] as String,
              yearMonth: bg['yearMonth'] as String,
              amountPaise: Value((bg['amountPaise'] as num?)?.toInt() ?? 0),
            )).toList();
            b.insertAllOnConflictUpdate(db.budgetsTable, budgets);
          }

          // 13. Reserve Lines
          if (data['reserveLines'] != null && data['reserveLines'] is List) {
            final lines = (data['reserveLines'] as List).map((rl) => ReserveLinesTableCompanion.insert(
              id: rl['id'] as String,
              householdId: (rl['householdId'] ?? householdId) as String,
              yearMonth: rl['yearMonth'] as String,
              name: (rl['name'] ?? 'Reserve') as String,
              amountPaise: (rl['amountPaise'] as num?)?.toInt() ?? 0,
              source: Value((rl['source'] as String?) ?? 'manual'),
            )).toList();
            b.insertAllOnConflictUpdate(db.reserveLinesTable, lines);
          }

          // 14. Annual Targets
          if (data['annualTargets'] != null && data['annualTargets'] is List) {
            final targets = (data['annualTargets'] as List).map((at) => AnnualTargetsTableCompanion.insert(
              id: at['id'] as String,
              householdId: (at['householdId'] ?? householdId) as String,
              title: (at['title'] ?? '') as String,
              targetPaise: (at['targetPaise'] as num?)?.toInt() ?? 0,
              type: Value((at['type'] as String?) ?? 'income'),
            )).toList();
            b.insertAllOnConflictUpdate(db.annualTargetsTable, targets);
          }
        });

        // 15. Propagation of deleted entries (prevents resurrection of locally cached records)
        if (data['deletedEntryIds'] != null && data['deletedEntryIds'] is List) {
          for (final id in data['deletedEntryIds'] as List) {
            if (id is String) {
              await (db.update(db.entriesTable)..where((e) => e.id.equals(id))).write(
                EntriesTableCompanion(
                  deletedAt: Value(DateTime.now()),
                ),
              );
            }
          }
        }
        if (data['deletedEntries'] != null && data['deletedEntries'] is List) {
          for (final de in data['deletedEntries'] as List) {
            final id = de['id'] as String?;
            if (id != null) {
              final deletedAtStr = de['deletedAt'] as String?;
              final delDate = deletedAtStr != null ? DateTime.tryParse(deletedAtStr) : DateTime.now();
              await (db.update(db.entriesTable)..where((e) => e.id.equals(id))).write(
                EntriesTableCompanion(
                  deletedAt: Value(delDate),
                ),
              );
            }
          }
        }

        // 16. Propagation of deleted annual targets from server
        if (data['deletedAnnualTargetIds'] != null && data['deletedAnnualTargetIds'] is List) {
          for (final id in data['deletedAnnualTargetIds'] as List) {
            if (id is String) {
              await (db.delete(db.annualTargetsTable)..where((t) => t.id.equals(id))).go();
            }
          }
        }

        // 17. Hard deletions made on other devices (server tombstones)
        final deletedRecords = data['deletedRecords'];
        if (deletedRecords is Map) {
          List<String> idsFor(String key) => deletedRecords[key] is List
              ? (deletedRecords[key] as List).whereType<String>().toList()
              : const <String>[];
          final bills = idsFor('plannedBills');
          if (bills.isNotEmpty) await (db.delete(db.plannedBillsTable)..where((t) => t.id.isIn(bills))).go();
          final recs = idsFor('receivables');
          if (recs.isNotEmpty) await (db.delete(db.receivablesTable)..where((t) => t.id.isIn(recs))).go();
          final txns = idsFor('cardTransactions');
          if (txns.isNotEmpty) await (db.delete(db.cardTransactionsTable)..where((t) => t.id.isIn(txns))).go();
          final buds = idsFor('budgets');
          if (buds.isNotEmpty) await (db.delete(db.budgetsTable)..where((t) => t.id.isIn(buds))).go();
          final lines = idsFor('reserveLines');
          if (lines.isNotEmpty) await (db.delete(db.reserveLinesTable)..where((t) => t.id.isIn(lines))).go();
          final contribs = idsFor('goalContributions');
          if (contribs.isNotEmpty) await (db.delete(db.goalContributionsTable)..where((t) => t.id.isIn(contribs))).go();
          final moves = idsFor('fundMovements');
          if (moves.isNotEmpty) await (db.delete(db.fundMovementsTable)..where((t) => t.id.isIn(moves))).go();
          final targets = idsFor('annualTargets');
          if (targets.isNotEmpty) await (db.delete(db.annualTargetsTable)..where((t) => t.id.isIn(targets))).go();
          // Categories are archived server-side (never hard-deleted), so no tombstone-hard-delete
          // is needed here. The `categories` list above (step 1) already carries each category's
          // current archivedAt, so an archive made on another device applies via the normal
          // upsert in that step, not through deletedRecords.
        }

        // 18. Month close/reopen made on other devices (DEF-SYNC-07). Applied only to snapshots that
        //     exist locally (local closing figures are never replaced) and never over a local
        //     close/reopen that is still waiting in the sync queue.
        if (data['monthStatuses'] is List) {
          final pendingMonths = (await db.syncQueueDao.getPending())
              .where((op) => op.entity == 'month_status')
              .map((op) => op.entityId)
              .toSet();
          for (final ms in data['monthStatuses'] as List) {
            if (ms is! Map) continue;
            final ym = ms['yearMonth'];
            final status = ms['status'];
            if (ym is! String || pendingMonths.contains(ym)) continue;
            final changedAt = ms['statusChangedAt'] is String ? DateTime.tryParse(ms['statusChangedAt'] as String) : null;
            final local = await (db.select(db.monthSnapshotsTable)
                  ..where((t) => t.householdId.equals(householdId) & t.yearMonth.equals(ym)))
                .getSingleOrNull();
            if (local == null) {
              // A closed month with no local row at all (fresh install / new device / reinstall)
              // was previously skipped entirely, leaving that month editable forever on this
              // device even though it's closed everywhere else (data-persistence audit fix,
              // 2026-09-17). Insert a closed snapshot placeholder; its financial totals are
              // zeroed here deliberately — they are never read from this placeholder row (the
              // UI recomputes actuals from entries/accounts), only `status`/`closedAt` matter
              // for gating further edits to this month.
              if (status == 'closed') {
                await db.into(db.monthSnapshotsTable).insert(
                      MonthSnapshotsTableCompanion.insert(
                        id: _uuid.v4(),
                        householdId: householdId,
                        yearMonth: ym,
                        status: const Value('closed'),
                        closedAt: Value(changedAt ?? DateTime.now()),
                      ),
                    );
              }
              continue;
            }

            if (status == 'closed' && local.status != 'closed') {
              await (db.update(db.monthSnapshotsTable)..where((t) => t.id.equals(local.id))).write(
                MonthSnapshotsTableCompanion(status: const Value('closed'), closedAt: Value(changedAt ?? DateTime.now())),
              );
            } else if (status == 'open' && local.status == 'closed') {
              if (changedAt != null) {
                // Reopened on the server after this device's close was delivered.
                await (db.update(db.monthSnapshotsTable)..where((t) => t.id.equals(local.id))).write(
                  const MonthSnapshotsTableCompanion(status: Value('open'), closedAt: Value(null)),
                );
              } else {
                // The server never recorded this close (older app version or a lost notification).
                unsentCloses.add(ym);
              }
            }
          }
        }

        // Recalculate account balances after all entries are restored
        await db.accountDao.recalculateAllAccountBalances(householdId: householdId);
      });

      for (final ym in unsentCloses) {
        await db.syncQueueDao.enqueueMonthStatus(householdId: householdId, yearMonth: ym, closed: true);
      }
      if (unsentCloses.isNotEmpty) {
        await _replayMonthStatusOps(db, serverUrl, token, householdId);
      }

      debugPrint('Successfully pulled and synchronized all household data from server.');
      return true;
    } catch (e) {
      debugPrint('Failed to pull data from server: $e');
      return false;
    }
  }

  /// Notify backend of month close (fire-and-forget).
  Future<void> notifyMonthClosed(
    String yearMonth, {
    required int openingBalance,
    required int lastMonthReserves,
    required int income,
    required int adjustments,
    required int spending,
    required int protection,
    required int saving,
    required int reserves,
    required int totalAvailable,
  }) async {
    final serverUrl = _ref.read(serverUrlProvider);
    final authState = _ref.read(authStateProvider).valueOrNull;
    final queueId = await _queueMonthStatus(authState?.householdId, yearMonth, closed: true);
    if (serverUrl.isEmpty || authState == null || authState.authMode != AuthMode.authenticated) return;
    final token = authState.token;
    if (token == null) return;

    try {
      await _dio.post(
        '$serverUrl/months/close?yearMonth=$yearMonth',
        data: {
          'openingBalance': openingBalance,
          'lastMonthReserves': lastMonthReserves,
          'income': income,
          'adjustments': adjustments,
          'spending': spending,
          'protection': protection,
          'saving': saving,
          'reserves': reserves,
          'totalAvailable': totalAvailable,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (queueId != null) await _ref.read(appDatabaseProvider).syncQueueDao.markSynced(queueId);
    } catch (e) {
      debugPrint('Failed to notify backend of month close (queued for retry): $e');
    }
  }

  /// Notify backend of month reopen (fire-and-forget).
  Future<void> notifyMonthReopened(String yearMonth) async {
    final serverUrl = _ref.read(serverUrlProvider);
    final authState = _ref.read(authStateProvider).valueOrNull;
    final queueId = await _queueMonthStatus(authState?.householdId, yearMonth, closed: false);
    if (serverUrl.isEmpty || authState == null || authState.authMode != AuthMode.authenticated) return;
    final token = authState.token;
    if (token == null) return;

    try {
      await _dio.post(
        '$serverUrl/months/reopen?yearMonth=$yearMonth',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (queueId != null) await _ref.read(appDatabaseProvider).syncQueueDao.markSynced(queueId);
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404 && queueId != null) {
        // The server never had this month closed — nothing to reopen.
        await _ref.read(appDatabaseProvider).syncQueueDao.markSynced(queueId);
        return;
      }
      debugPrint('Failed to notify backend of month reopen (queued for retry): $e');
    }
  }

  /// Queues a local month close/reopen; returns the queue id, or null when there is no household yet.
  Future<String?> _queueMonthStatus(String? householdId, String yearMonth, {required bool closed}) async {
    if (householdId == null || householdId.isEmpty || householdId == 'local') return null;
    try {
      await _ref.read(appDatabaseProvider).syncQueueDao
          .enqueueMonthStatus(householdId: householdId, yearMonth: yearMonth, closed: closed);
      return 'month_status:$householdId:$yearMonth';
    } catch (e) {
      debugPrint('Failed to queue month status change: $e');
      return null;
    }
  }

  /// Sends queued month closes/reopens for this household to the server.
  Future<void> _replayMonthStatusOps(
    AppDatabase db,
    String serverUrl,
    String token,
    String householdId, {
    CancelToken? cancelToken,
  }) async {
    final ops = (await db.syncQueueDao.getPending())
        .where((op) => op.entity == 'month_status' && op.id == 'month_status:$householdId:${op.entityId}')
        .toList();
    for (final op in ops) {
      if (cancelToken?.isCancelled ?? false) return;
      if (op.attempts >= SyncQueueDao.maxAttempts) continue;
      final path = op.op == 'close' ? 'close' : 'reopen';
      try {
        await _dio.post(
          '$serverUrl/months/$path?yearMonth=${op.entityId}',
          cancelToken: cancelToken,
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
        await db.syncQueueDao.markSynced(op.id);
      } catch (e) {
        if (cancelToken?.isCancelled ?? false) return;
        if (e is DioException && e.response?.statusCode == 404 && op.op == 'reopen') {
          await db.syncQueueDao.markSynced(op.id);
        } else {
          await db.syncQueueDao.incrementAttempts(op.id);
        }
      }
    }
  }
}
