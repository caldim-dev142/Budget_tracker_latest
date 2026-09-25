import 'package:flutter_test/flutter_test.dart';

String csvField(String? value) {
  final v = value ?? '';
  if (v.contains(RegExp(r'[",\r\n]'))) return '"${v.replaceAll('"', '""')}"';
  return v;
}

String buildCsvContent({
  required List<Map<String, dynamic>> entries,
  required Map<String, String> categoryNames,
}) {
  final csvBuffer = StringBuffer();
  csvBuffer.writeln('ID,Date,Category,Type,Amount (Paise),Note');
  for (final e in entries) {
    final catId = e['categoryId'] as String? ?? '';
    final catName = categoryNames[catId] ?? (catId.isNotEmpty ? catId : 'Uncategorized');
    csvBuffer.writeln([
      csvField(e['id'] as String?),
      (e['entryDate'] as DateTime).toIso8601String().split('T').first,
      csvField(catName),
      csvField(e['kind'] as String?),
      e['amountPaise'].toString(),
      csvField(e['note'] as String?),
    ].join(','));
  }
  return csvBuffer.toString();
}

String ensureUtf8Bom(String content) {
  return content.startsWith('\uFEFF') ? content : '\uFEFF$content';
}

void main() {
  group('CSV Export formatting and escaping tests', () {
    test('1. RFC 4180 escaping: commas, quotes, and newlines', () {
      expect(csvField('Simple text'), equals('Simple text'));
      expect(csvField('Food, Drinks'), equals('"Food, Drinks"'));
      expect(csvField('He said "hello"'), equals('"He said ""hello"""'));
      expect(csvField('Line 1\nLine 2'), equals('"Line 1\nLine 2"'));
      expect(csvField(''), equals(''));
      expect(csvField(null), equals(''));
    });

    test('2. Builds properly formatted CSV with headers and rows', () {
      final entries = [
        {
          'id': 'ent-1',
          'entryDate': DateTime(2026, 9, 25),
          'categoryId': 'cat-groceries',
          'kind': 'spending',
          'amountPaise': 45000,
          'note': 'Weekly groceries, fruits & veggies',
        },
        {
          'id': 'ent-2',
          'entryDate': DateTime(2026, 9, 24),
          'categoryId': 'cat-salary',
          'kind': 'income',
          'amountPaise': 2500000,
          'note': 'Salary "September" bonus',
        },
      ];
      final categories = {
        'cat-groceries': 'Groceries',
        'cat-salary': 'Monthly Salary',
      };

      final csv = buildCsvContent(entries: entries, categoryNames: categories);
      final lines = csv.trim().split('\n');

      expect(lines.length, equals(3));
      expect(lines[0].trim(), equals('ID,Date,Category,Type,Amount (Paise),Note'));
      expect(lines[1].trim(), equals('ent-1,2026-09-25,Groceries,spending,45000,"Weekly groceries, fruits & veggies"'));
      expect(lines[2].trim(), equals('ent-2,2026-09-24,Monthly Salary,income,2500000,"Salary ""September"" bonus"'));
    });

    test('3. Handles missing or orphaned category IDs gracefully', () {
      final entries = [
        {
          'id': 'ent-3',
          'entryDate': DateTime(2026, 9, 25),
          'categoryId': 'cat-deleted-123',
          'kind': 'spending',
          'amountPaise': 10000,
          'note': null,
        },
        {
          'id': 'ent-4',
          'entryDate': DateTime(2026, 9, 25),
          'categoryId': '',
          'kind': 'spending',
          'amountPaise': 5000,
          'note': null,
        },
      ];
      final categories = <String, String>{};

      final csv = buildCsvContent(entries: entries, categoryNames: categories);
      final lines = csv.trim().split('\n');

      expect(lines[1].trim(), equals('ent-3,2026-09-25,cat-deleted-123,spending,10000,'));
      expect(lines[2].trim(), equals('ent-4,2026-09-25,Uncategorized,spending,5000,'));
    });

    test('4. UTF-8 BOM is correctly applied', () {
      final plain = 'ID,Date,Category\n1,2026-09-25,₹100';
      final withBom = ensureUtf8Bom(plain);
      expect(withBom.startsWith('\uFEFF'), isTrue);

      // Idempotent: does not add duplicate BOM
      final again = ensureUtf8Bom(withBom);
      expect(again, equals(withBom));
    });
  });
}
