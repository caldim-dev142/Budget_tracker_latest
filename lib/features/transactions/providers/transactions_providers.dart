import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../../data/local/database.dart';
import '../../../data/repositories/entry_repository_impl.dart';
import '../../../domain/usecases/add_entry.dart';
import '../../../domain/entities/entry.dart';
import '../../../core/utils/month.dart';
import '../../../core/utils/result.dart';
import '../../../core/services/sync_service.dart';
import '../../auth/providers/auth_providers.dart';

final entryRepositoryProvider = Provider<EntryRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return EntryRepositoryImpl(db);
});

final monthStatusRepositoryProvider = Provider<MonthStatusRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return MonthStatusRepositoryImpl(db);
});

final addEntryUseCaseProvider = Provider<AddEntryUseCase>((ref) {
  final repo = ref.watch(entryRepositoryProvider);
  final monthRepo = ref.watch(monthStatusRepositoryProvider);
  final auth = ref.watch(authStateProvider).valueOrNull;

  final householdId = auth?.householdId ?? 'local';
  final userId = auth?.userId ?? 'local-user';

  return AddEntryUseCase(
    repo: repo,
    monthRepo: monthRepo,
    householdId: householdId,
    userId: userId,
  );
});

final addEntryControllerProvider = StateNotifierProvider<AddEntryController, AsyncValue<void>>((ref) {
  final useCase = ref.watch(addEntryUseCaseProvider);
  return AddEntryController(useCase, ref);
});

class AddEntryController extends StateNotifier<AsyncValue<void>> {
  final AddEntryUseCase _useCase;
  final Ref _ref;

  AddEntryController(this._useCase, this._ref) : super(const AsyncValue.data(null));

  Future<bool> addEntry(EntryDraft draft) async {
    state = const AsyncValue.loading();
    final res = await _useCase.execute(draft);
    if (res.isSuccess) {
      final entry = res.value;
      state = const AsyncValue.data(null);
      // Trigger sync upload to Supabase DB via NestJS backend
      _ref.read(syncServiceProvider).syncEntry(entry);
      return true;
    } else {
      final fail = res.failure;
      state = AsyncValue.error(fail.message, StackTrace.current);
      return false;
    }
  }

  Future<bool> updateEntry(String entryId, EntryDraft draft) async {
    state = const AsyncValue.loading();
    try {
      final db = _ref.read(appDatabaseProvider);
      await db.entryDao.updateEntry(
        EntriesTableCompanion(
          id: Value(entryId),
          categoryId: Value(draft.categoryId),
          kind: Value(draft.kind.name),
          entryDate: Value(draft.entryDate),
          amountPaise: Value(draft.amount.paise),
          note: Value(draft.note),
          updatedAt: Value(DateTime.now()),
        ),
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final showSearchProvider = StateProvider<bool>((_) => false);
final searchQueryProvider = StateProvider<String>((_) => '');

final entriesStreamProvider = StreamProvider.family<List<EntriesTableData>, (YearMonth, EntryKind?)>((ref, arg) {
  final db = ref.watch(appDatabaseProvider);
  final auth = ref.watch(authStateProvider).valueOrNull;
  final householdId = auth?.householdId ?? 'local';
  final (ym, kind) = arg;
  if (kind == null) {
    return db.entryDao.watchMonth(ym.toString(), householdId: householdId);
  } else {
    // Map from EntryKind enum to database string representation
    final kindStr = kind.name;
    return db.entryDao.watchByKind(ym.toString(), kindStr, householdId: householdId);
  }
});

final activeCategoriesProvider = StreamProvider.family<List<CategoriesTableData>, EntryKind>((ref, kind) {
  final db = ref.watch(appDatabaseProvider);
  final authState = ref.watch(authStateProvider).valueOrNull;
  final householdId = authState?.householdId ?? 'local';

  return db.categoryDao.watchAll(householdId: householdId).map((all) {
    return all.where((c) {
      final dbKind = c.kind.toLowerCase();
      if (kind == EntryKind.spending && dbKind == 'spending') return true;
      if ((kind == EntryKind.income || kind == EntryKind.incomeDeduction) &&
          (dbKind == 'income' || dbKind == 'incomededuction')) return true;
      if (kind == EntryKind.adjustment && dbKind == 'adjustment') return true;
      if (kind == EntryKind.protection && dbKind == 'protection') return true;
      if (kind == EntryKind.saving && dbKind == 'saving') return true;
      return false;
    }).toList();
  });
});

