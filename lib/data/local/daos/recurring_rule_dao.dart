import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import '../database.dart';
import '../tables/tables.dart';

part 'recurring_rule_dao.g.dart';

/// Persisted model for a recurring rule occurrence record.
class RecurringOccurrence {
  final String ruleId;
  final DateTime date; // scheduled occurrence date (local noon)
  final bool isProcessed;

  const RecurringOccurrence({
    required this.ruleId,
    required this.date,
    required this.isProcessed,
  });
}

@DriftAccessor(tables: [RecurringRulesTable])
class RecurringRuleDao extends DatabaseAccessor<AppDatabase>
    with _$RecurringRuleDaoMixin {
  RecurringRuleDao(super.db);

  // ── CRUD ──────────────────────────────────────────────────────────────────

  /// Upsert a rule (insert or update on conflict). Used by sync pull.
  Future<void> upsertRule(RecurringRulesTableCompanion rule) {
    return into(recurringRulesTable).insertOnConflictUpdate(rule);
  }

  /// Insert or update a rule, applying:
  ///   1. Last-write-wins on non-processed fields (uses incoming if incoming.updatedAt > existing.updatedAt).
  ///   2. Union-merge for processed state ALWAYS, regardless of updatedAt.
  ///   3. deletedAt is STICKY: once set, an incoming null never clears it.
  /// Returns the merged rule after writing.
  Future<RecurringRulesTableData> upsertWithMerge(
    RecurringRulesTableCompanion incoming,
  ) async {
    final existing = await getByIdAny(incoming.id.value);
    final now = DateTime.now();

    // 1. Merge processed state (always union, regardless of timestamps)
    final merged = _mergeProcessedState(
      dayOfMonth: incoming.dayOfMonth.value,
      startDate: incoming.startDate.value,
      existingThrough: existing?.processedThrough,
      existingDates: existing != null
          ? List<String>.from(jsonDecode(existing.processedDates) as List)
          : const [],
      incomingThrough: incoming.processedThrough.present
          ? incoming.processedThrough.value
          : null,
      incomingDates: incoming.processedDates.present
          ? List<String>.from(jsonDecode(incoming.processedDates.value) as List)
          : const [],
    );

    // 2. Last-write-wins: apply incoming non-processed fields only if
    //    incoming.updatedAt > existing.updatedAt (or no existing row).
    final incomingUpdatedAt = incoming.updatedAt.present
        ? incoming.updatedAt.value
        : now;
    final shouldApplyLww = existing == null ||
        incomingUpdatedAt.isAfter(existing.updatedAt);

    // 3. deletedAt is sticky: once set, incoming null never clears it.
    DateTime? mergedDeletedAt;
    if (existing?.deletedAt != null) {
      // Sticky: keep existing deletedAt even if incoming is null
      mergedDeletedAt = existing!.deletedAt;
    } else if (incoming.deletedAt.present) {
      mergedDeletedAt = incoming.deletedAt.value;
    }

    RecurringRulesTableCompanion companion;
    if (existing == null) {
      // No existing row — write everything from incoming
      companion = incoming.copyWith(
        processedThrough: Value(merged.processedThrough),
        processedDates: Value(jsonEncode(merged.processedDates)),
        deletedAt: Value(mergedDeletedAt),
      );
    } else if (shouldApplyLww) {
      // Incoming is newer — apply LWW on non-processed fields, union merge on processed
      companion = RecurringRulesTableCompanion(
        id: Value(existing.id),
        householdId: Value(existing.householdId),
        kind: incoming.kind.present ? incoming.kind : Value(existing.kind),
        categoryId: incoming.categoryId.present
            ? incoming.categoryId
            : Value(existing.categoryId),
        accountId: incoming.accountId.present
            ? incoming.accountId
            : Value(existing.accountId),
        cardId: incoming.cardId.present
            ? incoming.cardId
            : Value(existing.cardId),
        amountPaise: incoming.amountPaise.present
            ? incoming.amountPaise
            : Value(existing.amountPaise),
        note: incoming.note.present ? incoming.note : Value(existing.note),
        dayOfMonth: incoming.dayOfMonth.present
            ? incoming.dayOfMonth
            : Value(existing.dayOfMonth),
        startDate: incoming.startDate.present
            ? incoming.startDate
            : Value(existing.startDate),
        endDate: incoming.endDate.present
            ? incoming.endDate
            : Value(existing.endDate),
        mode: incoming.mode.present ? incoming.mode : Value(existing.mode),
        isActive: incoming.isActive.present
            ? incoming.isActive
            : Value(existing.isActive),
        processedThrough: Value(merged.processedThrough),
        processedDates: Value(jsonEncode(merged.processedDates)),
        updatedAt: Value(incomingUpdatedAt),
        createdAt: Value(existing.createdAt),
        deletedAt: Value(mergedDeletedAt),
      );
    } else {
      // Existing is newer — keep non-processed fields, only update processed state
      companion = RecurringRulesTableCompanion(
        id: Value(existing.id),
        householdId: Value(existing.householdId),
        kind: Value(existing.kind),
        categoryId: Value(existing.categoryId),
        accountId: Value(existing.accountId),
        cardId: Value(existing.cardId),
        amountPaise: Value(existing.amountPaise),
        note: Value(existing.note),
        dayOfMonth: Value(existing.dayOfMonth),
        startDate: Value(existing.startDate),
        endDate: Value(existing.endDate),
        mode: Value(existing.mode),
        isActive: Value(existing.isActive),
        processedThrough: Value(merged.processedThrough),
        processedDates: Value(jsonEncode(merged.processedDates)),
        updatedAt: Value(existing.updatedAt),
        createdAt: Value(existing.createdAt),
        deletedAt: Value(mergedDeletedAt),
      );
    }

    await into(recurringRulesTable).insertOnConflictUpdate(companion);
    return (await getByIdAny(incoming.id.value))!;
  }

  /// Soft-delete a rule: sets deletedAt AND updatedAt, then enqueues deletion.
  /// Caller must also call syncQueueDao.enqueueDeletion after this.
  Future<void> softDelete(String id) {
    final now = DateTime.now();
    return (update(recurringRulesTable)..where((r) => r.id.equals(id))).write(
      RecurringRulesTableCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  /// Mark a rule as paused (isActive = false).
  Future<void> pause(String id) {
    return (update(recurringRulesTable)..where((r) => r.id.equals(id))).write(
      RecurringRulesTableCompanion(
        isActive: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Resume a paused rule (isActive = true).
  Future<void> resume(String id) {
    return (update(recurringRulesTable)..where((r) => r.id.equals(id))).write(
      RecurringRulesTableCompanion(
        isActive: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // ── Queries ───────────────────────────────────────────────────────────────

  /// Get a rule by ID, excluding soft-deleted rows (used for normal operations).
  Future<RecurringRulesTableData?> getById(String id) {
    return (select(recurringRulesTable)
          ..where((r) => r.id.equals(id) & r.deletedAt.isNull()))
        .getSingleOrNull();
  }

  /// Get a rule by ID INCLUDING soft-deleted rows (used for merge/resurrection checks).
  Future<RecurringRulesTableData?> getByIdAny(String id) {
    return (select(recurringRulesTable)
          ..where((r) => r.id.equals(id)))
        .getSingleOrNull();
  }

  /// All non-deleted rules for a household, active + inactive.
  Future<List<RecurringRulesTableData>> getAll(String householdId) {
    return (select(recurringRulesTable)
          ..where(
            (r) => r.householdId.equals(householdId) & r.deletedAt.isNull(),
          )
          ..orderBy([(r) => OrderingTerm.asc(r.createdAt)]))
        .get();
  }

  /// All rules for a household including soft-deleted (for sync push).
  Future<List<RecurringRulesTableData>> getAllIncludeDeleted(String householdId) {
    return (select(recurringRulesTable)
          ..where((r) => r.householdId.equals(householdId))
          ..orderBy([(r) => OrderingTerm.asc(r.createdAt)]))
        .get();
  }

  /// Live stream of all non-deleted rules.
  Stream<List<RecurringRulesTableData>> watchAll(String householdId) {
    return (select(recurringRulesTable)
          ..where(
            (r) => r.householdId.equals(householdId) & r.deletedAt.isNull(),
          )
          ..orderBy([(r) => OrderingTerm.asc(r.createdAt)]))
        .watch();
  }

  // ── Processed state helpers ────────────────────────────────────────────────

  /// Mark an occurrence as processed.
  /// Uses the union-merge algorithm so no processed date is ever lost.
  Future<void> markOccurrenceProcessed(String id, DateTime occurrenceDate) async {
    final rule = await getByIdAny(id);
    if (rule == null) return;

    final dateStr = _isoDate(occurrenceDate);
    final existingDates =
        List<String>.from(jsonDecode(rule.processedDates) as List);

    final merged = _mergeProcessedState(
      dayOfMonth: rule.dayOfMonth,
      startDate: rule.startDate,
      existingThrough: rule.processedThrough,
      existingDates: existingDates,
      incomingThrough: null,
      incomingDates: [dateStr],
    );

    await (update(recurringRulesTable)..where((r) => r.id.equals(id))).write(
      RecurringRulesTableCompanion(
        processedThrough: Value(merged.processedThrough),
        processedDates: Value(jsonEncode(merged.processedDates)),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Checks whether a given occurrence date is already processed for this rule.
  bool isOccurrenceProcessed(
    RecurringRulesTableData rule,
    DateTime occurrenceDate,
  ) {
    final dateStr = _isoDate(occurrenceDate);
    // Check processedThrough
    if (rule.processedThrough != null &&
        !occurrenceDate.isAfter(rule.processedThrough!)) {
      return true;
    }
    // Check processedDates
    final dates = List<String>.from(jsonDecode(rule.processedDates) as List);
    return dates.any((d) => d.substring(0, 10) == dateStr);
  }

  // ── Merge algorithm (Section 6) ───────────────────────────────────────────

  /// Merges two processed states so no processed occurrence is lost.
  ///
  /// processedSet(state) = { occurrences <= processedThrough } ∪ processedDates
  /// result satisfies: processedSet(result) = processedSet(A) ∪ processedSet(B)
  ///
  /// NEVER truncates processedDates. If the list exceeds 400, logs a warning but keeps all.
  static ({DateTime? processedThrough, List<String> processedDates})
      _mergeProcessedState({
    required int dayOfMonth,
    required DateTime startDate,
    required DateTime? existingThrough,
    required List<String> existingDates,
    required DateTime? incomingThrough,
    required List<String> incomingDates,
  }) {
    // 1. mergedThrough = later of the two
    DateTime? mergedThrough;
    if (existingThrough != null && incomingThrough != null) {
      mergedThrough = existingThrough.isAfter(incomingThrough)
          ? existingThrough
          : incomingThrough;
    } else {
      mergedThrough = existingThrough ?? incomingThrough;
    }

    // 2. Union of both date sets
    final mergedDates = <String>{...existingDates, ...incomingDates};

    // 3. Remove dates already covered by mergedThrough
    if (mergedThrough != null) {
      mergedDates.removeWhere(
        (d) => !DateTime.parse(d).isAfter(mergedThrough!),
      );
    }

    // 4. Compact: advance mergedThrough if next occurrence is in mergedDates.
    //    SPEC Item 11: when processedThrough is null, the "next occurrence" is
    //    the FIRST scheduled occurrence on or after startDate (not the one in
    //    the month AFTER startDate). _firstOccurrenceOnOrAfter handles this.
    DateTime? current = mergedThrough;
    bool compacted = true;
    while (compacted) {
      compacted = false;
      final DateTime next;
      if (current == null) {
        // First compaction step: find first occurrence on or after startDate
        final first = _firstOccurrenceOnOrAfter(dayOfMonth, startDate);
        if (first == null) break;
        next = first;
      } else {
        // Subsequent steps: next occurrence in following month
        final n = _nextOccurrenceAfter(dayOfMonth, current);
        if (n == null) break;
        next = n;
      }
      final nextStr = _isoDate(next);
      if (mergedDates.any((d) => d.substring(0, 10) == nextStr)) {
        mergedDates.removeWhere((d) => d.substring(0, 10) == nextStr);
        current = next;
        compacted = true;
      }
    }

    // 5. NEVER truncate. Warn if large.
    final finalDates = mergedDates.toList()..sort();
    if (finalDates.length > 400) {
      debugPrint(
        '[RecurringRuleDao] WARNING: processedDates has ${finalDates.length} entries '
        '(expected <= 400). Keeping all to avoid data loss.',
      );
    }

    return (processedThrough: current, processedDates: finalDates);
  }

  /// Returns the FIRST scheduled occurrence on or after [from] for [dayOfMonth].
  /// Used for first-compaction step when processedThrough is null.
  static DateTime? _firstOccurrenceOnOrAfter(int dayOfMonth, DateTime from) {
    // Try the occurrence in from's own month first
    final lastDaySameMonth = DateTime(from.year, from.month + 1, 0).day;
    final occInSameMonth = DateTime(
      from.year,
      from.month,
      dayOfMonth.clamp(1, lastDaySameMonth),
      12, // local noon
    );
    if (!occInSameMonth.isBefore(from)) return occInSameMonth;

    // Otherwise return the occurrence in the next month
    return _nextOccurrenceAfter(dayOfMonth, from);
  }

  /// Returns the next scheduled occurrence AFTER [after] for [dayOfMonth].
  static DateTime? _nextOccurrenceAfter(int dayOfMonth, DateTime after) {
    // Move to next month
    final nextMonth = DateTime(after.year, after.month + 1, 1);
    final lastDay = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
    return DateTime(
      nextMonth.year,
      nextMonth.month,
      dayOfMonth.clamp(1, lastDay),
      12, // local noon
    );
  }

  static String _isoDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
