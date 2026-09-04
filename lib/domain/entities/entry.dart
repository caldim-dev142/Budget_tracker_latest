import 'package:equatable/equatable.dart';
import '../../core/utils/money.dart';
import '../../core/utils/month.dart';
import 'category.dart';

/// The fundamental transaction record.
/// Maps to one cell value in the Excel matrix (doc 01 §1 "store entries, not cells").
class Entry extends Equatable {
  /// Client-generated UUID for idempotent sync (doc 05 entries table).
  final String id;
  final String householdId;
  final String categoryId;
  final EntryKind kind;     // derived from category, cached for performance
  final String? accountId;
  final String? cardId;
  final DateTime entryDate; // maps to day column
  final Money amount;       // signed; negative = refund/deduction/return (doc 02 §4)
  final String? note;
  final String? parentId;   // split sub-entry (Sub sum 1, doc 01 §10)
  final String createdBy;
  final int version;        // optimistic concurrency (doc 07 §Conventions)
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt; // soft delete

  const Entry({
    required this.id,
    required this.householdId,
    required this.categoryId,
    required this.kind,
    this.accountId,
    this.cardId,
    required this.entryDate,
    required this.amount,
    this.note,
    this.parentId,
    required this.createdBy,
    this.version = 1,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  YearMonth get yearMonth => YearMonth(entryDate.year, entryDate.month);

  @override
  List<Object?> get props => [id, categoryId, entryDate, amount, version, deletedAt];
}

/// Corresponds to the four transaction sheets in the workbook (doc 01 §1).
enum EntryKind {
  /// Income sheet rows 6–19 (inflows)
  income,
  /// Income sheet rows 18–19 (deductions from income)
  incomeDeduction,
  /// Income sheet rows 23–29 (adjustments block)
  adjustment,
  /// Spending sheet — 7 category groups
  spending,
  /// Protection sheet — 8 sinking-fund groups
  protection,
  /// Saving sheet — 3 goal groups
  saving,
}
