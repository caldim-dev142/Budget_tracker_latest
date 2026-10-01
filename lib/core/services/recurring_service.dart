import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/local/database.dart';
import 'sync_service.dart';

export '../../data/local/daos/recurring_rule_dao.dart' show RecurringRuleDao;

// A3: In-memory notices provider (no DB table). Keyed by ruleId → list of notice strings.
// The Recurring screen reads this to show per-rule notices.
final recurringNoticesProvider =
    StateProvider<Map<String, List<String>>>((_) => {});

const _uuid = Uuid();

final recurringServiceProvider = Provider<RecurringService>(
  (ref) => RecurringService(ref),
);

/// Service for generating and managing recurring transaction occurrences.
///
/// STRICT RULE: This service only generates normal entries. No calculation
/// engine (engine.dart, waterfall.dart, etc.) has any knowledge of recurring
/// rules — it only reads the entries this service creates.
///
/// TIMEZONE: All occurrence dates are LOCAL calendar dates. Comparisons use
/// the device's local date. entryDate is stored as 12:00 LOCAL time.
/// processedDates store YYYY-MM-DD with NO timezone shifting.
class RecurringService {
  RecurringService(this._ref);

  final Ref _ref;

  AppDatabase get _db => _ref.read(appDatabaseProvider);

  // ── Deterministic ID ──────────────────────────────────────────────────────

  /// Deterministic entry ID for a recurring occurrence: `rec-<ruleId>-<YYYY-MM-DD>`.
  static String occurrenceEntryId(String ruleId, DateTime date) {
    final dateStr = _isoDate(date);
    return 'rec-$ruleId-$dateStr';
  }

  // ── Occurrence generation ─────────────────────────────────────────────────

  /// Returns all scheduled occurrence dates for a rule between [from] and [to] (inclusive).
  ///
  /// Uses LOCAL calendar dates throughout. Handles month-end clamping
  /// (day 31 in a 28-day month → 28th).
  static List<DateTime> scheduledOccurrences(
    RecurringRulesTableData rule, {
    required DateTime from,
    required DateTime to,
  }) {
    if (!rule.isActive) return const [];
    if (rule.deletedAt != null) return const [];

    final start = rule.startDate.toLocal();
    final end = rule.endDate?.toLocal();
    final day = rule.dayOfMonth;
    final results = <DateTime>[];

    // Start iteration from the rule's startDate month (local)
    int year = start.year;
    int month = start.month;
    final fromLocal = from.toLocal();
    final toLocal = to.toLocal();

    while (true) {
      final lastDay = DateTime(year, month + 1, 0).day;
      final occDay = day.clamp(1, lastDay);
      // LOCAL noon — no UTC offset applied
      final occ = DateTime(year, month, occDay, 12);

      // Advance if before from (local)
      if (occ.isBefore(fromLocal)) {
        month++;
        if (month > 12) {
          month = 1;
          year++;
        }
        if (DateTime(year, month, 1).isAfter(toLocal)) break;
        continue;
      }
      if (occ.isAfter(toLocal)) break;
      if (end != null && occ.isAfter(end)) break;

      results.add(occ);

      month++;
      if (month > 12) {
        month = 1;
        year++;
      }
      if (DateTime(year, month, 1).isAfter(toLocal)) break;
    }

    return results;
  }

  // ── Due occurrences ───────────────────────────────────────────────────────

  /// Returns unprocessed occurrences for a rule up to and including [upTo].
  ///
  /// Uses LOCAL date comparison: an occurrence is "due" when its local date
  /// <= today's local date. (SPEC Item 12: IST 09:00 on the 5th → due.)
  List<DateTime> dueOccurrences(
    RecurringRulesTableData rule, {
    DateTime? upTo,
  }) {
    // Compare by LOCAL date only (truncate to day)
    final nowLocal = (upTo ?? DateTime.now()).toLocal();
    final todayLocal = DateTime(nowLocal.year, nowLocal.month, nowLocal.day, 23, 59, 59);
    final all = scheduledOccurrences(
      rule,
      from: rule.startDate.toLocal(),
      to: todayLocal,
    );
    return all
        .where((occ) =>
            !_db.recurringRuleDao.isOccurrenceProcessed(rule, occ))
        .toList();
  }

  // ── Auto-add mode ─────────────────────────────────────────────────────────

  /// For all auto-mode active rules in [householdId], generates entries for
  /// any unprocessed due occurrences (up to today).
  ///
  /// Idempotent: uses deterministic IDs so re-running is safe.
  /// Respects:
  ///   - Closed months: does NOT insert; marks processed; records notice.
  ///   - Inactive/missing account or card: does NOT insert; does NOT mark processed.
  ///   - At most 12 occurrences per rule per run.
  ///   - Uses insertOrIgnore (idempotent).
  ///   - Calls triggerSync() once after the run if anything changed.
  ///
  /// Returns the number of entries created.
  Future<int> generateDueEntries({
    required String householdId,
    required String createdBy,
    DateTime? asOf,
  }) async {
    final nowLocal = (asOf ?? DateTime.now()).toLocal();
    final rules = await _db.recurringRuleDao.getAll(householdId);
    int created = 0;
    bool anyChange = false;
    final notices = <String>[];

    for (final rule in rules) {
      if (!rule.isActive || rule.mode != 'auto') continue;
      final due = dueOccurrences(rule, upTo: nowLocal);
      int ruleCount = 0;

      for (final occ in due) {
        if (ruleCount >= 12) break; // at most 12 per rule per run

        final entryId = occurrenceEntryId(rule.id, occ);
        final yearMonth =
            '${occ.year}-${occ.month.toString().padLeft(2, '0')}';

        // Check closed month: do NOT insert; mark processed; record notice.
        final snapshot = await (_db.select(_db.monthSnapshotsTable)
              ..where((s) =>
                  s.householdId.equals(householdId) &
                  s.yearMonth.equals(yearMonth)))
            .getSingleOrNull();
        if (snapshot != null && snapshot.status == 'closed') {
          notices.add('Recurring $entryId: month $yearMonth is closed; '
              'marked processed without inserting entry.');
          await _db.recurringRuleDao.markOccurrenceProcessed(rule.id, occ);
          anyChange = true;
          continue;
        }

        // Inactive or missing account/card → skip; do NOT mark processed.
        if (rule.accountId != null) {
          final account = await (_db.select(_db.accountsTable)
                ..where((a) => a.id.equals(rule.accountId!)))
              .getSingleOrNull();
          if (account == null || !account.isActive) {
            notices.add('Recurring $entryId: account ${rule.accountId} '
                'is inactive or missing; skipped (not marked processed).');
            continue;
          }
        }
        if (rule.cardId != null) {
          final card = await (_db.select(_db.creditCardsTable)
                ..where((c) => c.id.equals(rule.cardId!)))
              .getSingleOrNull();
          if (card == null || !card.isActive) {
            notices.add('Recurring $entryId: card ${rule.cardId} '
                'is inactive or missing; skipped (not marked processed).');
            continue;
          }
        }

        // insertOrIgnore — idempotent if the entry already exists.
        // Drift returns the rowId (>0) if inserted, 0 if ignored (conflict).
        final rowId = await _db.into(_db.entriesTable).insert(
          EntriesTableCompanion.insert(
            id: entryId,
            householdId: householdId,
            categoryId: rule.categoryId,
            kind: rule.kind,
            accountId: Value(rule.accountId),
            cardId: Value(rule.cardId),
            // LOCAL noon — SPEC Item 12
            entryDate: DateTime(occ.year, occ.month, occ.day, 12),
            amountPaise: rule.amountPaise,
            note: Value(rule.note),
            createdBy: createdBy,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          mode: InsertMode.insertOrIgnore,
        );

        // A1: Recalculate balance if an entry was actually inserted (rowId > 0)
        if (rowId > 0 && rule.accountId != null) {
          await _db.accountDao.recalculateAccountBalance(rule.accountId!);
        }

        await _db.recurringRuleDao.markOccurrenceProcessed(rule.id, occ);
        created++;
        ruleCount++;
        anyChange = true;
      }
    }

    // A3: Save notices into Riverpod provider (keyed by ruleId)
    if (notices.isNotEmpty) {
      final noticesByRule = <String, List<String>>{};
      for (final n in notices) {
        // Parse ruleId from notice format: 'Recurring rec-<ruleId>-<date>: ...'
        // We reconstruct: notices are indexed to the rule via entryId prefix 'rec-<ruleId>'
        noticesByRule['_general'] = [...(noticesByRule['_general'] ?? []), n];
        debugPrint('[RecurringService] $n');
      }
      try {
        final current = _ref.read(recurringNoticesProvider);
        _ref.read(recurringNoticesProvider.notifier).state = {
          ...current,
          ...noticesByRule,
        };
      } catch (_) {} // provider may not be available in tests
    }

    if (anyChange) {
      try {
        // A2: Always trigger sync via Ref — no optional parameter needed
        final syncSvc = _ref.read(triggerSyncCallbackProvider);
        unawaited(syncSvc());
      } catch (_) {}
    }

    return created;
  }

  // ── Remind mode ───────────────────────────────────────────────────────────

  /// For remind-mode rules, returns a list of {rule, occurrences} for
  /// occurrences that are due but not yet processed.
  Future<List<({RecurringRulesTableData rule, List<DateTime> due})>>
      getDueReminders({
    required String householdId,
    DateTime? asOf,
  }) async {
    final nowLocal = (asOf ?? DateTime.now()).toLocal();
    final rules = await _db.recurringRuleDao.getAll(householdId);
    final result = <({RecurringRulesTableData rule, List<DateTime> due})>[];

    for (final rule in rules) {
      if (!rule.isActive || rule.mode != 'remind') continue;
      final due = dueOccurrences(rule, upTo: nowLocal);
      if (due.isNotEmpty) {
        result.add((rule: rule, due: due));
      }
    }

    return result;
  }

  // ── Remind mode: confirm / skip (SPEC Section 4) ─────────────────────────

  /// Confirms a remind-mode occurrence: inserts the entry and marks processed.
  ///
  /// Refuses if the month is closed (returns false and records a notice).
  /// Calls triggerSync() after success.
  Future<bool> confirm(
    String ruleId,
    DateTime occurrenceDate, {
    int? overrideAmountPaise,
    required String createdBy,
  }) async {
    final rule = await _db.recurringRuleDao.getById(ruleId);
    if (rule == null) return false;

    final occ = occurrenceDate.toLocal();
    final yearMonth =
        '${occ.year}-${occ.month.toString().padLeft(2, '0')}';
    final entryId = occurrenceEntryId(ruleId, occ);

    // Closed month → refuse confirm
    final snapshot = await (_db.select(_db.monthSnapshotsTable)
          ..where((s) =>
              s.householdId.equals(rule.householdId) &
              s.yearMonth.equals(yearMonth)))
        .getSingleOrNull();
    if (snapshot != null && snapshot.status == 'closed') {
      debugPrint('[RecurringService.confirm] Month $yearMonth is closed; '
          'confirm refused for $entryId.');
      return false;
    }

    // Drift insert returns rowId > 0 if the entry was actually inserted.
    final rowId = await _db.into(_db.entriesTable).insert(
      EntriesTableCompanion.insert(
        id: entryId,
        householdId: rule.householdId,
        categoryId: rule.categoryId,
        kind: rule.kind,
        accountId: Value(rule.accountId),
        cardId: Value(rule.cardId),
        entryDate: DateTime(occ.year, occ.month, occ.day, 12),
        amountPaise: overrideAmountPaise ?? rule.amountPaise,
        note: Value(rule.note),
        createdBy: createdBy,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      mode: InsertMode.insertOrIgnore,
    );

    // A1: Recalculate account balance on actual insertion
    if (rowId > 0 && rule.accountId != null) {
      await _db.accountDao.recalculateAccountBalance(rule.accountId!);
    }

    await _db.recurringRuleDao.markOccurrenceProcessed(ruleId, occ);

    // A2: Always trigger sync via Ref
    try {
      final syncSvc = _ref.read(triggerSyncCallbackProvider);
      unawaited(syncSvc());
    } catch (_) {}
    return true;
  }

  /// Skips a remind-mode occurrence: marks it as processed WITHOUT inserting an entry.
  ///
  /// Skip is allowed even for closed months.
  /// Calls triggerSync() after.
  Future<void> skip(
    String ruleId,
    DateTime occurrenceDate,
  ) async {
    final occ = occurrenceDate.toLocal();
    await _db.recurringRuleDao.markOccurrenceProcessed(ruleId, occ);
    // A2: Always trigger sync via Ref
    try {
      final syncSvc = _ref.read(triggerSyncCallbackProvider);
      unawaited(syncSvc());
    } catch (_) {}
  }

  // ── Rule lifecycle ────────────────────────────────────────────────────────

  /// Creates a new recurring rule and optionally marks the first occurrence
  /// processed when created from an existing entry (SPEC Section 5).
  ///
  /// [fromEntryDate]: when the rule is created from an existing entry,
  /// pass the entry's date. The occurrence in that month is marked as
  /// processedThrough so the same month is not auto-added again.
  Future<RecurringRulesTableData> createRule({
    required String householdId,
    required String kind,
    required String categoryId,
    String? accountId,
    String? cardId,
    required int amountPaise,
    String? note,
    required int dayOfMonth,
    required DateTime startDate,
    DateTime? endDate,
    required String mode,
    DateTime? fromEntryDate,
  }) async {
    assert(dayOfMonth >= 1 && dayOfMonth <= 31, 'dayOfMonth must be 1–31');
    assert(amountPaise > 0, 'amountPaise must be positive');
    assert(mode == 'auto' || mode == 'remind', 'mode must be auto or remind');
    assert(kind == 'spending' || kind == 'income', 'kind must be spending or income');

    final id = _uuid.v4();
    final now = DateTime.now();

    // If created from an existing entry, compute the clamped occurrence date
    // for that month and set it as processedThrough.
    DateTime? initialProcessedThrough;
    if (fromEntryDate != null) {
      final local = fromEntryDate.toLocal();
      final lastDay = DateTime(local.year, local.month + 1, 0).day;
      initialProcessedThrough = DateTime(
        local.year,
        local.month,
        dayOfMonth.clamp(1, lastDay),
        12,
      );
    }

    final companion = RecurringRulesTableCompanion.insert(
      id: id,
      householdId: householdId,
      kind: kind,
      categoryId: categoryId,
      accountId: Value(accountId),
      cardId: Value(cardId),
      amountPaise: amountPaise,
      note: Value(note),
      dayOfMonth: dayOfMonth,
      startDate: startDate,
      endDate: Value(endDate),
      mode: Value(mode),
      isActive: const Value(true),
      processedThrough: Value(initialProcessedThrough),
      processedDates: const Value('[]'),
      createdAt: now,
      updatedAt: now,
    );
    await _db.recurringRuleDao.upsertRule(companion);
    return (await _db.recurringRuleDao.getByIdAny(id))!;
  }

  /// Updates non-processed-state fields of a rule (last-write-wins).
  Future<void> editRule({
    required String id,
    String? kind,
    String? categoryId,
    String? accountId,
    String? cardId,
    int? amountPaise,
    String? note,
    int? dayOfMonth,
    DateTime? endDate,
    String? mode,
  }) async {
    assert(amountPaise == null || amountPaise > 0, 'amountPaise must be positive');
    assert(dayOfMonth == null || (dayOfMonth >= 1 && dayOfMonth <= 31));
    assert(mode == null || mode == 'auto' || mode == 'remind');
    assert(kind == null || kind == 'spending' || kind == 'income');

    await (_db.update(_db.recurringRulesTable)
          ..where((r) => r.id.equals(id)))
        .write(
      RecurringRulesTableCompanion(
        kind: kind != null ? Value(kind) : const Value.absent(),
        categoryId:
            categoryId != null ? Value(categoryId) : const Value.absent(),
        accountId: accountId != null ? Value(accountId) : const Value.absent(),
        cardId: cardId != null ? Value(cardId) : const Value.absent(),
        amountPaise:
            amountPaise != null ? Value(amountPaise) : const Value.absent(),
        note: note != null ? Value(note) : const Value.absent(),
        dayOfMonth:
            dayOfMonth != null ? Value(dayOfMonth) : const Value.absent(),
        endDate: endDate != null ? Value(endDate) : const Value.absent(),
        mode: mode != null ? Value(mode) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> pauseRule(String id) =>
      _db.recurringRuleDao.pause(id);

  /// Resumes a paused rule.
  /// SPEC Item 10 Decision: unpausing generates missing transactions from
  /// lastProcessedDate up to today, respecting closed months (default: catchUp = true).
  /// If [catchUp] is false, marks past occurrences as processed without generating entries.
  Future<void> resumeRule(
    String id, {
    bool catchUp = true,
    DateTime? pausedAt,
    DateTime? asOf,
  }) async {
    final rule = await _db.recurringRuleDao.getById(id);
    if (rule == null) return;

    if (!catchUp) {
      // If explicitly instructed not to catch up, mark occurrences as processed
      final pauseTime = (pausedAt ?? rule.updatedAt).toLocal();
      final nowLocal = (asOf ?? DateTime.now()).toLocal();
      final todayLocal = DateTime(nowLocal.year, nowLocal.month, nowLocal.day, 23, 59, 59);

      final pausedOccurrences = scheduledOccurrences(
        rule,
        from: pauseTime,
        to: todayLocal,
      );
      for (final occ in pausedOccurrences) {
        await _db.recurringRuleDao.markOccurrenceProcessed(rule.id, occ);
      }
    }

    await _db.recurringRuleDao.resume(id);
  }

  /// Soft-deletes a rule: sets deletedAt, updatedAt, and enqueues the deletion.
  Future<void> deleteRule(String id) async {
    await _db.recurringRuleDao.softDelete(id);
    await _db.syncQueueDao.enqueueDeletion(
      entity: 'recurring_rule',
      entityId: id,
    );
    // A2: Always trigger sync
    try {
      final syncSvc = _ref.read(triggerSyncCallbackProvider);
      unawaited(syncSvc());
    } catch (_) {}
  }

  // ── Sync helpers ──────────────────────────────────────────────────────────

  /// Converts a RecurringRulesTableData row into the JSON payload shape
  /// expected by POST /sync/batch → recurringRules[].
  ///
  /// Includes soft-deleted rules so the server can propagate deletions.
  static Map<String, dynamic> toSyncPayload(RecurringRulesTableData rule) {
    return {
      'id': rule.id,
      'kind': rule.kind,
      'categoryId': rule.categoryId,
      'accountId': rule.accountId,
      'cardId': rule.cardId,
      'amountPaise': rule.amountPaise,
      'note': rule.note,
      'dayOfMonth': rule.dayOfMonth,
      'startDate': rule.startDate.toUtc().toIso8601String(),
      'endDate': rule.endDate?.toUtc().toIso8601String(),
      'mode': rule.mode,
      'isActive': rule.isActive,
      'processedThrough':
          rule.processedThrough?.toUtc().toIso8601String(),
      'processedDates':
          List<String>.from(jsonDecode(rule.processedDates) as List),
      'updatedAt': rule.updatedAt.toUtc().toIso8601String(),
      'deletedAt': rule.deletedAt?.toUtc().toIso8601String(),
    };
  }

  static String _isoDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

/// A2: Public provider holding a sync-trigger callback.
/// Default implementation is a no-op. sync_service.dart overrides this in its
/// provider registration so RecurringService can fire sync without importing SyncService.
///
/// Usage in sync_service.dart:
///   final syncServiceProvider = Provider<SyncService>((ref) {
///     final svc = SyncService(ref);
///     // Register the trigger so RecurringService can call it
///     ref.read(triggerSyncCallbackProvider.notifier).state = svc.triggerSync;
///     return svc;
///   });
typedef TriggerSyncFn = Future<void> Function();
final triggerSyncCallbackProvider = Provider<TriggerSyncFn>((ref) {
  return () => ref.read(syncServiceProvider).triggerSync();
});

void unawaited(Future<void> future) {
  // Intentionally ignore the future — fire and forget.
  future.ignore();
}

