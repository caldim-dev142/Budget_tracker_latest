import '../../core/utils/money.dart';
import '../../core/utils/month.dart';
import '../entities/entry.dart';
import '../entities/category.dart';

/// Roll-up calculations that mirror the Excel matrix formulas (doc 01 §1).
///
/// All functions are PURE — no side effects, no I/O.
/// The same logic runs on the Dart client and the TypeScript server (doc 03 §1).
class RollupEngine {
  RollupEngine._();

  /// Item month total: SUM(all entries for this category in year/month).
  /// Excel: =SUM(E8:AI8) for one item row (doc 01 §1 Dart abstraction).
  static Money itemMonthTotal(
    String categoryId,
    YearMonth ym,
    List<Entry> entries,
  ) {
    return entries
        .where((e) =>
            e.categoryId == categoryId &&
            e.yearMonth == ym &&
            e.deletedAt == null)
        .fold(Money.zero, (s, e) => s + e.amount);
  }

  /// Group month total: sum of all item entries in a group.
  /// Excel: =SUM(AJ8:AJ20) for a group column total.
  static Money groupMonthTotal(
    String groupCode,
    List<String> categoryIds,
    YearMonth ym,
    List<Entry> entries,
  ) {
    return entries
        .where((e) =>
            categoryIds.contains(e.categoryId) &&
            e.yearMonth == ym &&
            e.deletedAt == null)
        .fold(Money.zero, (s, e) => s + e.amount);
  }

  /// Layer month total: sum of all entries of a given kind.
  /// Excel: SUM of group subtotals across the sheet.
  static Money layerMonthTotal(
    EntryKind kind,
    YearMonth ym,
    List<Entry> entries,
  ) {
    return entries
        .where((e) => e.kind == kind && e.yearMonth == ym && e.deletedAt == null)
        .fold(Money.zero, (s, e) => s + e.amount);
  }

  /// Day total for a layer (used in daily view).
  /// Excel: =E7+E22+E41+E59+E83+E91 (sum of group day-totals).
  static Money dayTotal(
    EntryKind kind,
    DateTime day,
    List<Entry> entries,
  ) {
    return entries
        .where((e) =>
            e.kind == kind &&
            e.entryDate.year == day.year &&
            e.entryDate.month == day.month &&
            e.entryDate.day == day.day &&
            e.deletedAt == null)
        .fold(Money.zero, (s, e) => s + e.amount);
  }

  /// Net income = inflows − deductions (doc 01 §2.1).
  /// Excel: =SUM(D6:D17) - SUM(D18:D19)
  static Money netIncome(YearMonth ym, List<Entry> entries) {
    final inflows = entries
        .where((e) =>
            e.kind == EntryKind.income &&
            e.yearMonth == ym &&
            e.deletedAt == null)
        .fold(Money.zero, (s, e) => s + e.amount);
    final deductions = entries
        .where((e) =>
            e.kind == EntryKind.incomeDeduction &&
            e.yearMonth == ym &&
            e.deletedAt == null)
        .fold(Money.zero, (s, e) => s + e.amount);
    return inflows - deductions;
  }

  /// Net adjustments = inflows − outflows (doc 01 §2.2).
  /// Signed: returns negative if outflows > inflows (e.g. lending more than borrowing).
  ///
  /// Inflow adjustment categories (add): Credit Card Borrow/Payment, Borrow/Return, Temporary In/Out, Other Inflows
  /// Outflow adjustment categories (subtract when isDeduction is true): Lending/Return(-), Other Outflows
  static Money netAdjustments(
    YearMonth ym,
    List<Entry> entries, {
    Map<String, Category>? categoryMap,
    bool Function(String categoryId)? isDeductionLookup,
    Set<String>? deductionCategoryIds,
  }) {
    return entries
        .where((e) =>
            e.kind == EntryKind.adjustment &&
            e.yearMonth == ym &&
            e.deletedAt == null)
        .fold(Money.zero, (s, e) {
          final isDeduction = isDeductionLookup != null
              ? isDeductionLookup(e.categoryId)
              : (deductionCategoryIds != null
                  ? deductionCategoryIds.contains(e.categoryId)
                  : (categoryMap != null
                      ? (categoryMap[e.categoryId]?.isDeduction ?? false)
                      : false));
          return isDeduction ? s - e.amount : s + e.amount;
        });
  }

  /// Total spending = sum of all 7 spending groups (doc 01 §3).
  static Money totalSpending(YearMonth ym, List<Entry> entries) =>
      layerMonthTotal(EntryKind.spending, ym, entries);

  /// Total protection = sum of all 8 protection groups (doc 01 §4).
  static Money totalProtection(YearMonth ym, List<Entry> entries) =>
      layerMonthTotal(EntryKind.protection, ym, entries);

  /// Total saving = sum of all 3 saving groups (doc 01 §5).
  static Money totalSaving(YearMonth ym, List<Entry> entries) =>
      layerMonthTotal(EntryKind.saving, ym, entries);

  /// Entries for a specific category, year-month, excluding deleted.
  static List<Entry> forCategory(
    String categoryId,
    YearMonth ym,
    List<Entry> entries,
  ) {
    return entries
        .where((e) =>
            e.categoryId == categoryId &&
            e.yearMonth == ym &&
            e.deletedAt == null)
        .toList();
  }

  /// All entries for a year-month, sorted by date desc, excluding deleted.
  static List<Entry> forMonth(YearMonth ym, List<Entry> entries) {
    final list = entries
        .where((e) => e.yearMonth == ym && e.deletedAt == null)
        .toList()
      ..sort((a, b) => b.entryDate.compareTo(a.entryDate));
    return list;
  }
}
