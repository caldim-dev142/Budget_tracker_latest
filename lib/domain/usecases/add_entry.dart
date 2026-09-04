import 'package:uuid/uuid.dart';
import '../../core/utils/money.dart';
import '../../core/utils/result.dart';
import '../entities/entry.dart';
import '../entities/category.dart';

const _uuid = Uuid();

/// Validated draft from the UI before creating an Entry.
class EntryDraft {
  final String categoryId;
  final EntryKind kind;
  final String? accountId;
  final String? cardId;
  final DateTime entryDate;
  final Money amount;
  final String? note;
  final String? parentId;

  const EntryDraft({
    required this.categoryId,
    required this.kind,
    required this.entryDate,
    required this.amount,
    this.accountId,
    this.cardId,
    this.note,
    this.parentId,
  });
}

/// Use-case: Add a new entry (income, spending, adjustment, protection, saving).
/// The hot path: validate → create Entry → write to Drift → queue sync (doc 02 WF-1).
class AddEntryUseCase {
  final EntryRepository _repo;
  final MonthStatusRepository _monthRepo;
  final String _householdId;
  final String _userId;

  AddEntryUseCase({
    required EntryRepository repo,
    required MonthStatusRepository monthRepo,
    required String householdId,
    required String userId,
  })  : _repo = repo,
        _monthRepo = monthRepo,
        _householdId = householdId,
        _userId = userId;

  Future<Result<Entry>> execute(EntryDraft draft) async {
    // Validate: amount ≠ 0 (doc 02 §4)
    if (draft.amount.isZero) {
      return const Failure(ValidationFailure('amount', 'Amount must not be zero.'));
    }

    // Validate: negative only for refund/adjustment kinds (doc 02 §4)
    if (draft.amount.isNegative) {
      const allowNegative = {
        EntryKind.adjustment,
        EntryKind.incomeDeduction,
      };
      if (!allowNegative.contains(draft.kind)) {
        return const Failure(
          ValidationFailure('amount', 'Only adjustments and deductions may be negative.'),
        );
      }
    }

    // Validate: date within an open month (doc 02 §4)
    final monthOpen = await _monthRepo.isMonthOpen(
      draft.entryDate.year,
      draft.entryDate.month,
      householdId: _householdId,
    );
    if (!monthOpen) {
      return const Failure(
        ClosedMonthFailure('Cannot add entries to a closed month.'),
      );
    }

    final entry = Entry(
      id: _uuid.v4(),
      householdId: _householdId,
      categoryId: draft.categoryId,
      kind: draft.kind,
      accountId: draft.accountId,
      cardId: draft.cardId,
      entryDate: draft.entryDate,
      amount: draft.amount,
      note: draft.note,
      parentId: draft.parentId,
      createdBy: _userId,
      version: 1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await _repo.insertLocal(entry);
      _repo.enqueueSyncInsert(entry);
      return Success(entry);
    } catch (e) {
      return Failure(UnexpectedFailure('Failed to save entry.', cause: e));
    }
  }
}

/// Abstract interfaces implemented in the data layer.
abstract interface class EntryRepository {
  Future<void> insertLocal(Entry entry);
  void enqueueSyncInsert(Entry entry);
  Future<void> updateLocal(Entry entry);
  Future<void> softDeleteLocal(String entryId);
}

abstract interface class MonthStatusRepository {
  Future<bool> isMonthOpen(int year, int month, {String? householdId});
}
