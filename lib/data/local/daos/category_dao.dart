import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/tables.dart';

part 'category_dao.g.dart';

@DriftAccessor(tables: [CategoriesTable])
class CategoryDao extends DatabaseAccessor<AppDatabase> with _$CategoryDaoMixin {
  CategoryDao(super.db);

  /// All non-archived categories.
  Future<List<CategoriesTableData>> getAllActive({String? householdId}) {
    return (select(categoriesTable)
          ..where((c) {
            final isNotArchived = c.archivedAt.isNull();
            if (householdId != null && householdId.isNotEmpty) {
              return isNotArchived & c.householdId.equals(householdId);
            }
            return isNotArchived;
          })
          ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
        .get();
  }

  Stream<List<CategoriesTableData>> watchAll({String? householdId}) {
    return (select(categoriesTable)
          ..where((c) {
            final isNotArchived = c.archivedAt.isNull();
            if (householdId != null && householdId.isNotEmpty) {
              return isNotArchived & c.householdId.equals(householdId);
            }
            return isNotArchived;
          })
          ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
        .watch();
  }

  Future<List<CategoriesTableData>> getByKind(String kind, {String? householdId}) {
    return (select(categoriesTable)
          ..where((c) {
            final cond = c.kind.equals(kind) & c.archivedAt.isNull();
            if (householdId != null && householdId.isNotEmpty) {
              return cond & c.householdId.equals(householdId);
            }
            return cond;
          })
          ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
        .get();
  }

  Future<void> upsertAll(List<CategoriesTableCompanion> cats) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(categoriesTable, cats);
    });
  }

  Future<void> softArchive(String id) {
    return (update(categoriesTable)..where((c) => c.id.equals(id)))
        .write(CategoriesTableCompanion(archivedAt: Value(DateTime.now())));
  }

  Future<CategoriesTableData?> getById(String id) {
    return (select(categoriesTable)..where((c) => c.id.equals(id))).getSingleOrNull();
  }
}
