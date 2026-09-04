import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/tables.dart';

part 'snapshot_dao.g.dart';

@DriftAccessor(tables: [MonthSnapshotsTable])
class SnapshotDao extends DatabaseAccessor<AppDatabase> with _$SnapshotDaoMixin {
  SnapshotDao(super.db);

  Future<MonthSnapshotsTableData?> getForMonth(String yearMonth, {String? householdId}) {
    return (select(monthSnapshotsTable)
          ..where((s) {
            final cond = s.yearMonth.equals(yearMonth);
            if (householdId != null && householdId.isNotEmpty) {
              return cond & s.householdId.equals(householdId);
            }
            return cond;
          }))
        .getSingleOrNull();
  }

  Stream<MonthSnapshotsTableData?> watchForMonth(String yearMonth, {String? householdId}) {
    return (select(monthSnapshotsTable)
          ..where((s) {
            final cond = s.yearMonth.equals(yearMonth);
            if (householdId != null && householdId.isNotEmpty) {
              return cond & s.householdId.equals(householdId);
            }
            return cond;
          }))
        .watchSingleOrNull();
  }

  Future<bool> isMonthOpen(String yearMonth, {String? householdId}) async {
    final snap = await getForMonth(yearMonth, householdId: householdId);
    if (snap == null) return true; // Not yet closed
    return snap.status == 'open';
  }

  Future<void> upsertSnapshot(MonthSnapshotsTableCompanion snap, {String? householdId}) async {
    final yearMonth = snap.yearMonth.value;
    final hId = householdId ?? (snap.householdId.present ? snap.householdId.value : null);
    
    final existing = await (select(monthSnapshotsTable)
          ..where((s) {
            final cond = s.yearMonth.equals(yearMonth);
            if (hId != null && hId.isNotEmpty) {
              return cond & s.householdId.equals(hId);
            }
            return cond;
          }))
        .getSingleOrNull();

    if (existing != null) {
      final updated = snap.copyWith(id: Value(existing.id));
      await (update(monthSnapshotsTable)
            ..where((s) => s.id.equals(existing.id)))
          .write(updated);
    } else {
      await into(monthSnapshotsTable)
          .insert(snap, mode: InsertMode.insertOrReplace);
    }
  }

  Future<List<MonthSnapshotsTableData>> getAllSnapshots({String? householdId}) {
    return (select(monthSnapshotsTable)
          ..where((s) {
            if (householdId != null && householdId.isNotEmpty) {
              return s.householdId.equals(householdId);
            }
            return const Constant(true);
          })
          ..orderBy([(s) => OrderingTerm.desc(s.yearMonth)]))
        .get();
  }
}
