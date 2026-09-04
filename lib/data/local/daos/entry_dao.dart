import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/tables.dart';
import '../../../core/utils/month.dart';

part 'entry_dao.g.dart';

@DriftAccessor(tables: [EntriesTable])
class EntryDao extends DatabaseAccessor<AppDatabase> with _$EntryDaoMixin {
  EntryDao(super.db);

  /// Watch all non-deleted entries for a year-month (reactive stream).
  /// Used by Riverpod providers to reactively drive the dashboard engine.
  Stream<List<EntriesTableData>> watchMonth(String yearMonth, {String? householdId}) {
    final ym = YearMonth.parse(yearMonth);
    return (select(entriesTable)
          ..where((e) {
            final cond = e.entryDate.isBiggerOrEqual(Variable(ym.firstDay)) &
                e.entryDate.isSmallerThan(Variable(ym.next.firstDay)) &
                e.deletedAt.isNull();
            if (householdId != null && householdId.isNotEmpty) {
              return cond & e.householdId.equals(householdId);
            }
            return cond;
          })
          ..orderBy([
            (e) => OrderingTerm.desc(e.entryDate),
            (e) => OrderingTerm.desc(e.createdAt),
          ]))
        .watch();
  }

  Stream<List<EntriesTableData>> watchByKind(String yearMonth, String kind, {String? householdId}) {
    final ym = YearMonth.parse(yearMonth);
    return (select(entriesTable)
          ..where((e) {
            final isDateInMonth = e.entryDate.isBiggerOrEqual(Variable(ym.firstDay)) &
                e.entryDate.isSmallerThan(Variable(ym.next.firstDay)) &
                e.deletedAt.isNull();

            var kindCond = isDateInMonth & e.kind.equals(kind);
            if (kind == 'income') {
              kindCond = isDateInMonth & (e.kind.equals('income') | e.kind.equals('incomeDeduction'));
            } else if (kind == 'saving') {
              kindCond = isDateInMonth & e.kind.equals('saving');
            }

            if (householdId != null && householdId.isNotEmpty) {
              return kindCond & e.householdId.equals(householdId);
            }
            return kindCond;
          })
          ..orderBy([
            (e) => OrderingTerm.desc(e.entryDate),
            (e) => OrderingTerm.desc(e.createdAt),
          ]))
        .watch();
  }

  Stream<List<EntriesTableData>> watchByCategory(String categoryId, String yearMonth, {String? householdId}) {
    final ym = YearMonth.parse(yearMonth);
    return (select(entriesTable)
          ..where((e) {
            final cond = e.categoryId.equals(categoryId) &
                e.entryDate.isBiggerOrEqual(Variable(ym.firstDay)) &
                e.entryDate.isSmallerThan(Variable(ym.next.firstDay)) &
                e.deletedAt.isNull();
            if (householdId != null && householdId.isNotEmpty) {
              return cond & e.householdId.equals(householdId);
            }
            return cond;
          })
          ..orderBy([
            (e) => OrderingTerm.desc(e.entryDate),
            (e) => OrderingTerm.desc(e.createdAt),
          ]))
        .watch();
  }

  Future<void> insertEntry(EntriesTableCompanion entry) {
    return into(entriesTable).insertOnConflictUpdate(entry);
  }

  Future<void> updateEntry(EntriesTableCompanion entry) {
    return (update(entriesTable)..where((e) => e.id.equals(entry.id.value)))
        .write(entry);
  }

  Future<void> softDelete(String id) {
    return (update(entriesTable)..where((e) => e.id.equals(id)))
        .write(EntriesTableCompanion(deletedAt: Value(DateTime.now())));
  }

  Future<List<EntriesTableData>> getMonth(String yearMonth, {String? householdId}) {
    final ym = YearMonth.parse(yearMonth);
    return (select(entriesTable)
          ..where((e) {
            final cond = e.entryDate.isBiggerOrEqual(Variable(ym.firstDay)) &
                e.entryDate.isSmallerThan(Variable(ym.next.firstDay)) &
                e.deletedAt.isNull();
            if (householdId != null && householdId.isNotEmpty) {
              return cond & e.householdId.equals(householdId);
            }
            return cond;
          })
          ..orderBy([
            (e) => OrderingTerm.desc(e.entryDate),
            (e) => OrderingTerm.desc(e.createdAt),
          ]))
        .get();
  }

  Future<EntriesTableData?> getById(String id) {
    return (select(entriesTable)..where((e) => e.id.equals(id))).getSingleOrNull();
  }
}

// Extension to add yearMonth computed column behaviour
extension EntryX on EntriesTableData {
  String get yearMonth {
    final d = entryDate;
    return '${d.year}-${d.month.toString().padLeft(2, '0')}';
  }
}
