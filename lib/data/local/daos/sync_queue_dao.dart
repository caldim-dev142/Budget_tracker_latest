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
    return (update(syncQueueTable)..where((s) => s.id.equals(id))).write(
      const SyncQueueTableCompanion(attempts: Value.absent()),
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
