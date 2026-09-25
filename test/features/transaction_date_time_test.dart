import 'package:flutter_test/flutter_test.dart';
import 'package:budget_tracker/core/utils/timezone_utils.dart';
import 'package:budget_tracker/core/utils/money.dart';
import 'package:budget_tracker/domain/entities/entry.dart';
import 'package:budget_tracker/domain/usecases/add_entry.dart';

void main() {
  group('Transaction Date & Time - Timezone and Formatting', () {
    test('formatTime formats 11:42 AM correctly in UTC', () {
      final dt = DateTime.utc(2026, 9, 25, 11, 42);
      expect(formatTime(dt, 0), '11:42 AM');
    });

    test('formatTime formats midnight as 12:00 AM', () {
      final dt = DateTime.utc(2026, 9, 25, 0, 0);
      expect(formatTime(dt, 0), '12:00 AM');
    });

    test('formatTime formats noon as 12:00 PM', () {
      final dt = DateTime.utc(2026, 9, 25, 12, 0);
      expect(formatTime(dt, 0), '12:00 PM');
    });

    test('formatTime formats single-digit minutes with leading zero', () {
      final dt = DateTime.utc(2026, 9, 25, 9, 5);
      expect(formatTime(dt, 0), '9:05 AM');
    });

    test('formatTime formats late evening (11:59 PM)', () {
      final dt = DateTime.utc(2026, 9, 25, 23, 59);
      expect(formatTime(dt, 0), '11:59 PM');
    });

    test('formatTime correctly applies timezone offset (IST +5:30)', () {
      // 06:12 UTC + 330 minutes (5h30m) = 11:42 AM IST
      final dt = DateTime.utc(2026, 9, 25, 6, 12);
      expect(formatTime(dt, 330), '11:42 AM');
    });

    test('formatTime correctly handles midnight boundary with timezone offset', () {
      // 18:30 UTC on Sept 24 + 330 min = 00:00 (12:00 AM) on Sept 25
      final dt = DateTime.utc(2026, 9, 24, 18, 30);
      final local = toTimezone(dt, 330);
      expect(local.day, 25);
      expect(local.hour, 0);
      expect(local.minute, 0);
      expect(formatTime(dt, 330), '12:00 AM');
      expect(formatDateShort(dt, 330), '25/9/2026');
    });

    test('formatTime correctly handles negative offset (PST -8:00)', () {
      // 19:42 UTC - 480 min = 11:42 AM PST
      final dt = DateTime.utc(2026, 9, 25, 19, 42);
      expect(formatTime(dt, -480), '11:42 AM');
    });
  });

  group('Transaction Date & Time - Model & Persistence Integrity', () {
    test('Entry preserves full DateTime including hour and minute', () {
      final recordedTimestamp = DateTime(2026, 9, 25, 11, 42, 35);
      final entry = Entry(
        id: 'test-entry-1',
        householdId: 'test-household',
        categoryId: 'cat-groceries',
        kind: EntryKind.spending,
        entryDate: recordedTimestamp,
        amount: Money.fromRupees(2500),
        note: 'Amazon',
        createdBy: 'user-1',
        version: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(entry.entryDate.year, 2026);
      expect(entry.entryDate.month, 9);
      expect(entry.entryDate.day, 25);
      expect(entry.entryDate.hour, 11);
      expect(entry.entryDate.minute, 42);
      expect(entry.entryDate.second, 35);
    });

    test('EntryDraft preserves user-edited timestamp for past transaction', () {
      // User records yesterday at 8:30 PM
      final editedTimestamp = DateTime(2026, 9, 24, 20, 30);
      final draft = EntryDraft(
        categoryId: 'cat-groceries',
        kind: EntryKind.spending,
        entryDate: editedTimestamp,
        amount: Money.fromRupees(500),
        note: 'Late entry',
      );

      expect(draft.entryDate.day, 24);
      expect(draft.entryDate.hour, 20);
      expect(draft.entryDate.minute, 30);
    });

    test('ISO 8601 sync serialization preserves full timestamp with time', () {
      final dt = DateTime.utc(2026, 9, 25, 11, 42, 0);
      final isoStr = dt.toIso8601String();
      expect(isoStr, '2026-09-25T11:42:00.000Z');

      final parsed = DateTime.parse(isoStr);
      expect(parsed.isAtSameMomentAs(dt), isTrue);
      expect(parsed.hour, 11);
      expect(parsed.minute, 42);
    });
  });
}
