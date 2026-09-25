import 'package:flutter_test/flutter_test.dart';
import 'package:budget_tracker/data/local/database.dart';
import 'package:budget_tracker/features/budget/presentation/budget_screen.dart';

CategoriesTableData _createCat({
  required String id,
  required String name,
  String? groupCode,
  String kind = 'spending',
  int sortOrder = 0,
}) {
  return CategoriesTableData(
    id: id,
    householdId: 'h-test',
    kind: kind,
    groupCode: groupCode,
    name: name,
    isDeduction: false,
    isSystem: false,
    sortOrder: sortOrder,
  );
}

void main() {
  group('Budget Search & Filter - filterBudgetCategoryGroups', () {
    late Map<String, List<CategoriesTableData>> sampleGroups;

    setUp(() {
      sampleGroups = {
        'Food & Dining': [
          _createCat(id: 'c1', name: 'Groceries', groupCode: 'Food & Dining', kind: 'spending'),
          _createCat(id: 'c2', name: 'Restaurants', groupCode: 'Food & Dining', kind: 'spending'),
          _createCat(id: 'c3', name: 'Coffee Snacks', groupCode: 'Food & Dining', kind: 'spending'),
        ],
        'Housing': [
          _createCat(id: 'c4', name: 'Rent', groupCode: 'Housing', kind: 'spending'),
          _createCat(id: 'c5', name: 'Electricity Bill', groupCode: 'Housing', kind: 'spending'),
          _createCat(id: 'c6', name: 'Water & Gas', groupCode: 'Housing', kind: 'spending'),
        ],
        'Income Streams': [
          _createCat(id: 'c7', name: 'Primary Salary', groupCode: 'Income Streams', kind: 'income'),
          _createCat(id: 'c8', name: 'Freelance Food Blog', groupCode: 'Income Streams', kind: 'income'),
        ],
      };
    });

    test('1. Empty query returns all category groups and subcategories untouched', () {
      final resEmpty = filterBudgetCategoryGroups(grouped: sampleGroups, query: '');
      expect(resEmpty.length, equals(3));
      expect(resEmpty.keys, containsAll(['Food & Dining', 'Housing', 'Income Streams']));

      final resWhitespace = filterBudgetCategoryGroups(grouped: sampleGroups, query: '   ');
      expect(resWhitespace.length, equals(3));
    });

    test('2. Category (group) name search: preserves group and all its subcategories', () {
      final res = filterBudgetCategoryGroups(grouped: sampleGroups, query: 'Housing');
      expect(res.length, equals(1));
      expect(res.containsKey('Housing'), isTrue);
      expect(res['Housing']!.length, equals(3));
      expect(res['Housing']!.map((c) => c.name), containsAll(['Rent', 'Electricity Bill', 'Water & Gas']));
    });

    test('3. Subcategory name search: preserves parent group and filters to matching subcategories', () {
      final res = filterBudgetCategoryGroups(grouped: sampleGroups, query: 'Electricity');
      expect(res.length, equals(1));
      expect(res.containsKey('Housing'), isTrue);
      expect(res['Housing']!.length, equals(1));
      expect(res['Housing']!.first.name, equals('Electricity Bill'));
    });

    test('4. Case-insensitive search: matches lowercase, uppercase, and mixed case queries', () {
      final resLower = filterBudgetCategoryGroups(grouped: sampleGroups, query: 'groceries');
      expect(resLower['Food & Dining']!.any((c) => c.name == 'Groceries'), isTrue);

      final resUpper = filterBudgetCategoryGroups(grouped: sampleGroups, query: 'GROCERIES');
      expect(resUpper['Food & Dining']!.any((c) => c.name == 'Groceries'), isTrue);

      final resMixed = filterBudgetCategoryGroups(grouped: sampleGroups, query: 'gRoCeRiEs');
      expect(resMixed['Food & Dining']!.any((c) => c.name == 'Groceries'), isTrue);
    });

    test('5. Partial text matching: matches prefixes, infixes, and partial words', () {
      // Partial in subcategory 'Coffee Snacks' -> 'snack'
      final res1 = filterBudgetCategoryGroups(grouped: sampleGroups, query: 'snack');
      expect(res1.containsKey('Food & Dining'), isTrue);
      expect(res1['Food & Dining']!.first.name, equals('Coffee Snacks'));

      // Partial in category name 'Housing' -> 'ous'
      final res2 = filterBudgetCategoryGroups(grouped: sampleGroups, query: 'ous');
      expect(res2.containsKey('Housing'), isTrue);
    });

    test('6. Matches across multiple groups when query appears in both (e.g. "Food")', () {
      // 'Food & Dining' group matches parent name -> retains all 3 subcategories
      // 'Income Streams' has subcategory 'Freelance Food Blog' -> retains group with matching subcategory
      final res = filterBudgetCategoryGroups(grouped: sampleGroups, query: 'food');
      expect(res.length, equals(2));
      expect(res.containsKey('Food & Dining'), isTrue);
      expect(res['Food & Dining']!.length, equals(3));

      expect(res.containsKey('Income Streams'), isTrue);
      expect(res['Income Streams']!.length, equals(1));
      expect(res['Income Streams']!.first.name, equals('Freelance Food Blog'));
    });

    test('7. No-result state: returns empty map when neither group nor subcategory matches', () {
      final res = filterBudgetCategoryGroups(grouped: sampleGroups, query: 'xyz123nonexistent');
      expect(res.isEmpty, isTrue);
    });

    test('8. Combined Filter (by kind) + Search (by text) simulation', () {
      // Simulate filtering categories by kind first (e.g. kind == 'income')
      final allCats = sampleGroups.values.expand((list) => list).toList();
      final incomeCats = allCats.where((c) => c.kind == 'income').toList();

      final Map<String, List<CategoriesTableData>> incomeGroups = {
        'Income Streams': incomeCats,
      };

      // Search 'food' on income filter -> only finds 'Freelance Food Blog' under 'Income Streams'
      final resIncomeFood = filterBudgetCategoryGroups(grouped: incomeGroups, query: 'food');
      expect(resIncomeFood.length, equals(1));
      expect(resIncomeFood['Income Streams']!.single.name, equals('Freelance Food Blog'));

      // Search 'rent' on income filter -> empty result (no income relates to rent)
      final resIncomeRent = filterBudgetCategoryGroups(grouped: incomeGroups, query: 'rent');
      expect(resIncomeRent.isEmpty, isTrue);

      // Now clear search, retaining income filter -> returns all income categories
      final resIncomeCleared = filterBudgetCategoryGroups(grouped: incomeGroups, query: '');
      expect(resIncomeCleared['Income Streams']!.length, equals(2));

      // Now switch filter to 'spending' and search 'food'
      final expenseCats = allCats.where((c) => c.kind == 'spending').toList();
      final Map<String, List<CategoriesTableData>> expenseGroups = {
        'Food & Dining': expenseCats.where((c) => c.groupCode == 'Food & Dining').toList(),
        'Housing': expenseCats.where((c) => c.groupCode == 'Housing').toList(),
      };
      final resExpenseFood = filterBudgetCategoryGroups(grouped: expenseGroups, query: 'food');
      expect(resExpenseFood.length, equals(1));
      expect(resExpenseFood.containsKey('Food & Dining'), isTrue);
      expect(resExpenseFood['Food & Dining']!.length, equals(3));
    });
  });
}
