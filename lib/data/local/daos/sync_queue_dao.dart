import 'dart:convert';
import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/tables.dart';

part 'sync_queue_dao.g.dart';

@DriftAccessor(tables: [SyncQueueTable])
class SyncQueueDao extends DatabaseAccessor<AppDatabase> with _$SyncQueueDaoMixin {
  SyncQueueDao(super.db);

  Future<void> enqueue({
    required String id,
    required String op,
    required String entity,
    required String entityId,
    required Map<String, dynamic> payload,
  }) {
    return into(syncQueueTable).insert(
      SyncQueueTableCompanion.insert(
        id: id,
        op: op,
        entity: entity,
        entityId: entityId,
        payload: jsonEncode(payload),
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Entity names accepted by the server's `deletions[]` sync protocol (SyncDeletionDto).
  static const deletableEntities = {
    'planned_bill',
    'receivable',
    'card_transaction',
    'budget',
    'reserve_line',
    'goal_contribution',
    'fund_movement',
    'annual_target',
    'category',
  };

  /// Records a hard deletion so the next push sends it in `deletions[]` (DEF-SYNC-01).
  /// Must be called before (or in the same transaction as) the local delete.
  Future<void> enqueueDeletion({required String entity, required String entityId}) {
    assert(deletableEntities.contains(entity), 'Unsupported deletion entity: $entity');
    return into(syncQueueTable).insert(
      SyncQueueTableCompanion.insert(
        id: 'delete:$entity:$entityId',
        op: 'delete',
        entity: entity,
        entityId: entityId,
        payload: jsonEncode({'id': entityId}),
        createdAt: DateTime.now(),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  /// Queued ops that keep failing are not retried automatically after this many attempts;
  /// they stay in the queue (and in [pendingCount]) so they remain visible.
  static const maxAttempts = 10;

  /// Records the latest local close/reopen of a month until the server has accepted it
  /// (DEF-SYNC-07). One row per month: a newer action replaces an unsent older one.
  Future<void> enqueueMonthStatus({
    required String householdId,
    required String yearMonth,
    required bool closed,
  }) {
    return into(syncQueueTable).insert(
      SyncQueueTableCompanion.insert(
        id: 'month_status:$householdId:$yearMonth',
        op: closed ? 'close' : 'reopen',
        entity: 'month_status',
        entityId: yearMonth,
        payload: jsonEncode({'householdId': householdId, 'yearMonth': yearMonth}),
        createdAt: DateTime.now(),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  /// Get all unsynced ops, ordered by creation time.
  Future<List<SyncQueueTableData>> getPending() {
    return (select(syncQueueTable)
          ..where((s) => s.syncedAt.isNull())
          ..orderBy([(s) => OrderingTerm.asc(s.createdAt)]))
        .get();
  }

  Future<void> markSynced(String id) {
    return (update(syncQueueTable)..where((s) => s.id.equals(id))).write(
      SyncQueueTableCompanion(syncedAt: Value(DateTime.now())),
    );
  }

  Future<void> incrementAttempts(String id) {
    // Value.absent() wrote nothing, so the attempt counter never changed.
    return customUpdate(
      'UPDATE sync_queue SET attempts = attempts + 1 WHERE id = ?',
      variables: [Variable.withString(id)],
      updates: {syncQueueTable},
    );
  }

  Future<int> pendingCount() {
    final count = syncQueueTable.id.count();
    final query = selectOnly(syncQueueTable)
      ..addColumns([count])
      ..where(syncQueueTable.syncedAt.isNull());
    return query.map((row) => row.read(count)!).getSingle();
  }
}
