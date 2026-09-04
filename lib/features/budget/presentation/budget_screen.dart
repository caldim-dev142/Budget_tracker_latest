import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/month_switcher.dart';
import '../../../shared/widgets/budget_bar.dart';
import '../../../shared/widgets/pressable_scale.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/month.dart';
import '../../../data/local/database.dart';
import '../../auth/providers/auth_providers.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../../transactions/providers/transactions_providers.dart';

const _uuid = Uuid();

// ─── Providers ────────────────────────────────────────────────────────────────

final _allCategoriesProvider = StreamProvider<List<CategoriesTableData>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final authState = ref.watch(authStateProvider).valueOrNull;
  final householdId = authState?.householdId ?? 'local';
  return db.categoryDao.watchAll(householdId: householdId);
});

final _budgetsProvider = StreamProvider.family<List<BudgetsTableData>, YearMonth>(
    (ref, ym) {
  final db = ref.watch(appDatabaseProvider);
  final authState = ref.watch(authStateProvider).valueOrNull;
  final householdId = authState?.householdId ?? 'local';
  
  return (db.select(db.budgetsTable)
        ..where((b) {
          final cond = b.yearMonth.equals(ym.toString());
          if (householdId.isNotEmpty) {
            return cond & b.householdId.equals(householdId);
          }
          return cond;
        }))
      .watch();
});

final _selectedKindFilterProvider = StateProvider<String>((ref) => 'spending');

/// S7/S8 — Budget Planner + Budget vs Actual (doc 09 S7, S8) — real DB-backed.
class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (_, innerBoxIsScrolled) => [
            SliverAppBar(
              title: const MonthSwitcher(),
              floating: true,
              forceElevated: innerBoxIsScrolled,
              actions: [
                IconButton(
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  tooltip: 'Add Category',
                  onPressed: () => _showAddCategoryDialog(context, ref),
                ),
              ],
              bottom: TabBar(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: const Color(0xFF00A887),
                  borderRadius: BorderRadius.circular(20),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Plan Budget'),
                  Tab(text: 'Budget vs Actual'),
                ],
              ),
            ),
          ],
          body: const TabBarView(
            children: [
              _BudgetPlannerTab(),
              _BudgetVsActualTab(),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context, WidgetRef ref, {String? defaultGroup}) {
    final nameCtrl = TextEditingController();
    final groupCtrl = TextEditingController(text: defaultGroup ?? '');
    String kind = ref.read(_selectedKindFilterProvider);
    if (kind == 'all') kind = 'spending';
    String needOrWant = 'need';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                defaultGroup != null && defaultGroup.isNotEmpty
                    ? 'Add Subcategory under "$defaultGroup"'
                    : 'Add Category / Subcategory',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Category Name *',
                        hintText: 'e.g. Groceries',
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: groupCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Group / Subcategory *',
                        hintText: 'e.g. Food & Dining',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: kind,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Category Type'),
                      items: const [
                        DropdownMenuItem(value: 'spending', child: Text('Expense (Spending)')),
                        DropdownMenuItem(value: 'income', child: Text('Income')),
                        DropdownMenuItem(value: 'protection', child: Text('Protection (Insurance/EMI)')),
                        DropdownMenuItem(value: 'saving', child: Text('Saving & Investment')),
                        DropdownMenuItem(value: 'adjustment', child: Text('Adjustment')),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => kind = v);
                      },
                    ),


                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    final group = groupCtrl.text.trim();
                    if (name.isEmpty) return;

                    final db = ref.read(appDatabaseProvider);
                    final auth = ref.read(authStateProvider).valueOrNull;
                    final householdId = auth?.householdId ?? 'local';

                    await db.categoryDao.upsertAll([
                      CategoriesTableCompanion.insert(
                        id: 'cat-${DateTime.now().millisecondsSinceEpoch}',
                        householdId: householdId,
                        kind: kind,
                        groupCode: group.isNotEmpty ? Value(group) : const Value.absent(),
                        name: name,
                        needOrWant: kind == 'spending' ? Value(needOrWant) : const Value.absent(),
                        isDeduction: const Value(false),
                        isSystem: const Value(false),
                        sortOrder: const Value(100),
                      )
                    ]);

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Category "$name" added successfully!'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ─── Budget Planner Tab ───────────────────────────────────────────────────────

class _BudgetPlannerTab extends ConsumerWidget {
  const _BudgetPlannerTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ym = ref.watch(selectedMonthProvider);
    final catsAsync = ref.watch(_allCategoriesProvider);
    final budgetsAsync = ref.watch(_budgetsProvider(ym));
    final kindFilter = ref.watch(_selectedKindFilterProvider);
    final cs = Theme.of(context).colorScheme;

    return catsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: SkeletonLoader(width: double.infinity, height: 90, borderRadius: 18),
      ),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (cats) => budgetsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: SkeletonLoader(width: double.infinity, height: 90, borderRadius: 18),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (budgets) {
          final filteredCats = kindFilter == 'all'
              ? cats
              : cats.where((c) => c.kind == kindFilter).toList();

          final budgetMap = {for (final b in budgets) b.categoryId: b.amountPaise};
          final totalPlannedBudget = filteredCats.fold<int>(
              0, (sum, cat) => sum + (budgetMap[cat.id] ?? 0));

          // Group categories by groupCode and remove duplicates
          final Map<String, List<CategoriesTableData>> grouped = {};
          for (final c in filteredCats) {
            final rawKey = (c.groupCode != null && c.groupCode!.isNotEmpty)
                ? c.groupCode!
                : 'General';
            // Normalise to Title Case for display key
            final key = _toTitleCase(rawKey);
            final list = grouped.putIfAbsent(key, () => []);
            if (!list.any((e) => e.name.toLowerCase() == c.name.toLowerCase())) {
              list.add(c);
            }
          }

          for (final key in grouped.keys) {
            grouped[key]!.sort((a, b) => (b.sortOrder ?? 0).compareTo(a.sortOrder ?? 0));
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            children: [
              // Summary Header Card
              Card(
                color: cs.primaryContainer.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.account_balance_wallet_rounded, color: cs.primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TOTAL PLANNED BUDGET',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: cs.onSurfaceVariant,
                                    letterSpacing: 0.5,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              MoneyFormatter.format(Money(totalPlannedBudget)),
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: cs.primary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip(ref, 'all', 'All'),
                    _filterChip(ref, 'spending', 'Expense'),
                    _filterChip(ref, 'income', 'Income'),
                    _filterChip(ref, 'protection', 'Protection'),
                    _filterChip(ref, 'saving', 'Saving'),
                    _filterChip(ref, 'adjustment', 'Adjustment'),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              if (grouped.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'No categories found for this filter.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                    ),
                  ),
                )
              else
                ...grouped.entries.map((entry) {
                  return _BudgetGroupCard(
                    groupName: entry.key,
                    categories: entry.value,
                    budgetMap: budgetMap,
                    ym: ym,
                  );
                }),
            ],
          );
        },
      ),
    );
  }

  Widget _filterChip(WidgetRef ref, String kind, String label) {
    final current = ref.watch(_selectedKindFilterProvider);
    final selected = current == kind;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (val) {
          if (val) ref.read(_selectedKindFilterProvider.notifier).state = kind;
        },
      ),
    );
  }
}

class _BudgetGroupCard extends ConsumerWidget {
  final String groupName;
  final List<CategoriesTableData> categories;
  final Map<String, int> budgetMap;
  final YearMonth ym;

  const _BudgetGroupCard({
    required this.groupName,
    required this.categories,
    required this.budgetMap,
    required this.ym,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalBudget = categories.fold<int>(
        0, (s, c) => s + (budgetMap[c.id] ?? 0));
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        key: PageStorageKey('group_${ym}_$groupName'),
        initiallyExpanded: false,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: cs.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.folder_open_rounded, color: cs.primary, size: 20),
        ),
        title: Text(
          _toTitleCase(groupName),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
        ),
        subtitle: Text(
          '${categories.length} sub-categories',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  MoneyFormatter.format(Money(totalBudget)),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: totalBudget > 0 ? cs.primary : cs.onSurfaceVariant,
                      ),
                ),
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, size: 20),
              tooltip: 'Group Options',
              onSelected: (v) {
                if (v == 'add_subcat') const BudgetScreen()._showAddCategoryDialog(context, ref, defaultGroup: groupName);
                if (v == 'rename_group') _renameGroup(context, ref, groupName, categories);
                if (v == 'delete_group') _deleteGroup(context, ref, groupName, categories);
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'add_subcat',
                  child: Row(
                    children: [
                      Icon(Icons.add_circle_outline_rounded, size: 16, color: cs.primary),
                      const SizedBox(width: 8),
                      Text('Add Sub-category under "$groupName"'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'rename_group',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 16),
                      SizedBox(width: 8),
                      Text('Rename Group'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete_group',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete or Ungroup Group', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        children: [
          ...categories.map((cat) {
            final catBudget = budgetMap[cat.id] ?? 0;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: PressableScale(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _showSetBudgetDialog(context, ref, cat, catBudget),
                child: ListTile(
                  title: Text(
                    cat.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    cat.kind.toUpperCase(),
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        MoneyFormatter.formatCompact(Money(catBudget)),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: catBudget > 0 ? cs.primary : cs.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(width: 4),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded, size: 18),
                        onSelected: (v) async {
                          if (v == 'set_budget') _showSetBudgetDialog(context, ref, cat, catBudget);
                          if (v == 'edit_cat') _showEditCategoryDialog(context, ref, cat);
                          if (v == 'delete_cat') _deleteCategory(context, ref, cat);
                          if (v == 'mark_need' || v == 'mark_want') {
                            final db = ref.read(appDatabaseProvider);
                            await (db.update(db.categoriesTable)..where((c) => c.id.equals(cat.id)))
                                .write(CategoriesTableCompanion(needOrWant: Value(v == 'mark_need' ? 'need' : 'want')));
                          }
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'set_budget',
                            child: Row(
                              children: const [
                                Icon(Icons.edit_outlined, size: 16),
                                SizedBox(width: 8),
                                Text('Set Monthly Budget'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'edit_cat',
                            child: Row(
                              children: const [
                                Icon(Icons.drive_file_rename_outline_rounded, size: 16),
                                SizedBox(width: 8),
                                Text('Edit Category'),
                              ],
                            ),
                          ),
                          // Need / Want label toggle
                          PopupMenuItem(
                            value: 'mark_need',
                            child: Row(
                              children: [
                                Icon(Icons.check_circle_outline_rounded, size: 16,
                                    color: cat.needOrWant == 'need' ? Colors.blue : null),
                                const SizedBox(width: 8),
                                Text('Mark as Need',
                                    style: TextStyle(
                                        color: cat.needOrWant == 'need' ? Colors.blue : null,
                                        fontWeight: cat.needOrWant == 'need' ? FontWeight.bold : null)),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'mark_want',
                            child: Row(
                              children: [
                                Icon(Icons.favorite_border_rounded, size: 16,
                                    color: cat.needOrWant == 'want' ? Colors.purple : null),
                                const SizedBox(width: 8),
                                Text('Mark as Want',
                                    style: TextStyle(
                                        color: cat.needOrWant == 'want' ? Colors.purple : null,
                                        fontWeight: cat.needOrWant == 'want' ? FontWeight.bold : null)),
                              ],
                            ),
                          ),
                          if (!cat.isSystem)
                            PopupMenuItem(
                              value: 'delete_cat',
                              child: Row(
                                children: const [
                                  Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete Category', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _renameGroup(
    BuildContext context,
    WidgetRef ref,
    String oldGroupName,
    List<CategoriesTableData> categories,
  ) async {
    final controller = TextEditingController(text: oldGroupName);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Rename Group "$oldGroupName"'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'New Group Name *'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != oldGroupName) {
      final db = ref.read(appDatabaseProvider);
      for (final cat in categories) {
        await (db.update(db.categoriesTable)..where((c) => c.id.equals(cat.id)))
            .write(CategoriesTableCompanion(groupCode: Value(newName)));
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Group renamed to "$newName".'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> _deleteGroup(
    BuildContext context,
    WidgetRef ref,
    String groupName,
    List<CategoriesTableData> categories,
  ) async {
    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Group "$groupName"'),
        content: Text(
          'Choose how you want to delete the group "$groupName" (${categories.length} sub-categories):',
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          OutlinedButton.icon(
            icon: const Icon(Icons.folder_off_outlined, size: 18),
            label: const Text('Remove Group Only (Keep Items)'),
            onPressed: () => Navigator.pop(ctx, 'ungroup'),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            icon: const Icon(Icons.delete_forever_rounded, size: 18),
            label: const Text('Delete Group & All Sub-categories'),
            onPressed: () => Navigator.pop(ctx, 'delete_all'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'cancel'),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (action == 'delete_all') {
      final db = ref.read(appDatabaseProvider);
      for (final cat in categories) {
        if (!cat.isSystem) {
          await db.categoryDao.softArchive(cat.id);
        }
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Group "$groupName" and all sub-categories deleted.'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } else if (action == 'ungroup') {
      final db = ref.read(appDatabaseProvider);
      for (final cat in categories) {
        await (db.update(db.categoriesTable)..where((c) => c.id.equals(cat.id)))
            .write(const CategoriesTableCompanion(groupCode: Value.absent()));
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Group "$groupName" removed. Sub-categories kept.'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _showSetBudgetDialog(
    BuildContext context,
    WidgetRef ref,
    CategoriesTableData cat,
    int currentBudgetPaise,
  ) {
    final amountCtrl = TextEditingController(
        text: currentBudgetPaise > 0
            ? (currentBudgetPaise / 100).toStringAsFixed(0)
            : '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Set Monthly Budget — ${cat.name}'),
        content: TextField(
          controller: amountCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Monthly Budget (₹)',
            prefixText: '₹ ',
          ),
          autofocus: true,
        ),
        actions: [
          if (currentBudgetPaise > 0)
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () async {
                final db = ref.read(appDatabaseProvider);
                await (db.delete(db.budgetsTable)
                      ..where((b) =>
                          b.categoryId.equals(cat.id) &
                          b.yearMonth.equals(ym.toString())))
                    .go();
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Clear Budget'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final amount = double.tryParse(amountCtrl.text) ?? 0;
              final amountPaise = (amount * 100).round();
              final db = ref.read(appDatabaseProvider);
              final auth = ref.read(authStateProvider).valueOrNull;
              final householdId = auth?.householdId ?? 'local';

              final existing = await (db.select(db.budgetsTable)
                    ..where((b) =>
                        b.categoryId.equals(cat.id) &
                        b.yearMonth.equals(ym.toString())))
                  .getSingleOrNull();

              if (existing != null) {
                await (db.update(db.budgetsTable)
                      ..where((b) => b.id.equals(existing.id)))
                    .write(BudgetsTableCompanion(amountPaise: Value(amountPaise)));
              } else {
                await db.into(db.budgetsTable).insert(
                  BudgetsTableCompanion.insert(
                    id: _uuid.v4(),
                    householdId: householdId,
                    categoryId: cat.id,
                    yearMonth: ym.toString(),
                    amountPaise: Value(amountPaise),
                  ),
                );
              }

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Budget for ${cat.name} set to ₹$amount!'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditCategoryDialog(BuildContext context, WidgetRef ref, CategoriesTableData cat) {
    final nameCtrl = TextEditingController(text: cat.name);
    final groupCtrl = TextEditingController(text: cat.groupCode ?? '');
    String kind = cat.kind;
    String needOrWant = cat.needOrWant ?? 'need';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Edit Category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Category Name *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: groupCtrl,
                  decoration: const InputDecoration(labelText: 'Group / Subcategory'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: kind,
                  decoration: const InputDecoration(labelText: 'Category Type'),
                  items: const [
                    DropdownMenuItem(value: 'spending', child: Text('Expense (Spending)')),
                    DropdownMenuItem(value: 'income', child: Text('Income')),
                    DropdownMenuItem(value: 'protection', child: Text('Protection')),
                    DropdownMenuItem(value: 'saving', child: Text('Saving')),
                    DropdownMenuItem(value: 'adjustment', child: Text('Adjustment')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => kind = v);
                  },
                ),
                if (kind == 'spending') ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: needOrWant,
                    decoration: const InputDecoration(labelText: 'Classification'),
                    items: const [
                      DropdownMenuItem(value: 'need', child: Text('Need')),
                      DropdownMenuItem(value: 'want', child: Text('Want')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => needOrWant = v);
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final group = groupCtrl.text.trim();
                if (name.isEmpty) return;

                final db = ref.read(appDatabaseProvider);
                await (db.update(db.categoriesTable)..where((c) => c.id.equals(cat.id)))
                    .write(CategoriesTableCompanion(
                  name: Value(name),
                  groupCode: Value(group.isNotEmpty ? group : null),
                  kind: Value(kind),
                  needOrWant: kind == 'spending' ? Value(needOrWant) : const Value.absent(),
                ));

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Category "$name" updated!'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteCategory(BuildContext context, WidgetRef ref, CategoriesTableData cat) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Category?'),
        content: Text('Are you sure you want to delete category "${cat.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final db = ref.read(appDatabaseProvider);
      await db.categoryDao.softArchive(cat.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Category "${cat.name}" deleted.'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }
}

// ─── Budget Vs Actual Tab ─────────────────────────────────────────────────────

class _BudgetVsActualTab extends ConsumerWidget {
  const _BudgetVsActualTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ym = ref.watch(selectedMonthProvider);
    final catsAsync = ref.watch(_allCategoriesProvider);
    final budgetsAsync = ref.watch(_budgetsProvider(ym));
    final entriesAsync = ref.watch(entriesStreamProvider((ym, null)));
    final cs = Theme.of(context).colorScheme;

    return catsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: SkeletonLoader(width: double.infinity, height: 90, borderRadius: 18),
      ),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (cats) => budgetsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: SkeletonLoader(width: double.infinity, height: 90, borderRadius: 18),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (budgets) => entriesAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: SkeletonLoader(width: double.infinity, height: 90, borderRadius: 18),
          ),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (entries) {
            final idToKey = <String, String>{};
            final groupedCats = <String, CategoriesTableData>{};
            final groupedIds = <String, Set<String>>{};
            
            for (final c in cats) {
              final key = '${c.groupCode}_${c.name.toLowerCase()}';
              idToKey[c.id] = key;
              groupedCats.putIfAbsent(key, () => c);
              groupedIds.putIfAbsent(key, () => {}).add(c.id);
            }

            final groupedBudgets = <String, int>{};
            for (final b in budgets) {
              final key = idToKey[b.categoryId];
              if (key != null) {
                groupedBudgets[key] = (groupedBudgets[key] ?? 0) + b.amountPaise;
              }
            }

            final groupedActuals = <String, int>{};
            for (final e in entries) {
              final key = idToKey[e.categoryId];
              if (key != null) {
                groupedActuals[key] = (groupedActuals[key] ?? 0) + e.amountPaise;
              }
            }

            final budgetedKeys = groupedCats.keys.where((k) => (groupedBudgets[k] ?? 0) > 0).toList();

            if (budgetedKeys.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bar_chart_rounded,
                          size: 64,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text(
                        'No category budgets configured',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: cs.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Set category budgets in the Plan Budget tab to track spending progress.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
              itemCount: budgetedKeys.length,
              itemBuilder: (context, idx) {
                final key = budgetedKeys[idx];
                final cat = groupedCats[key]!;
                final budget = Money(groupedBudgets[key] ?? 0);
                final actual = Money(groupedActuals[key] ?? 0);
                final catIds = groupedIds[key]!;

                final catEntries = entries.where((e) => catIds.contains(e.categoryId)).toList();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: PressableScale(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => _showCategoryDrillDownSheet(context, ref, cat, budget, actual, catEntries, ym),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: cs.primaryContainer.withValues(alpha: 0.4),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.label_outline_rounded, size: 16, color: cs.primary),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    cat.name,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                  ),
                                ),
                                Icon(Icons.chevron_right_rounded, size: 20, color: cs.onSurfaceVariant),
                              ],
                            ),
                            const SizedBox(height: 12),
                            BudgetBar(budget: budget, actual: actual),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _showCategoryDrillDownSheet(
    BuildContext context,
    WidgetRef ref,
    CategoriesTableData cat,
    Money budget,
    Money actual,
    List<EntriesTableData> catEntries,
    YearMonth ym,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollCtrl) => Column(
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.outlineVariant.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cat.name,
                          style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Spent ${MoneyFormatter.formatCompact(actual)} of ${MoneyFormatter.formatCompact(budget)}',
                          style: TextStyle(color: Theme.of(ctx).colorScheme.onSurfaceVariant, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _showAddEntryForCategoryDialog(context, ref, cat, ym),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Add Entry'),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 24),
            Expanded(
              child: catEntries.isEmpty
                  ? const Center(child: Text('No expense entries recorded for this category yet.'))
                  : ListView.builder(
                      controller: scrollCtrl,
                      itemCount: catEntries.length,
                      itemBuilder: (_, i) {
                        final entry = catEntries[i];
                        return ListTile(
                          leading: const Icon(Icons.receipt_long_rounded, color: Colors.redAccent),
                          title: Text(
                            entry.note?.isNotEmpty == true ? entry.note! : cat.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text('${entry.entryDate.day}/${entry.entryDate.month}/${entry.entryDate.year}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  MoneyFormatter.formatCompact(Money(entry.amountPaise)),
                                  style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700),
                                ),
                              ),
                              IconButton(
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(),
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  context.push('/transactions/${entry.id}/edit');
                                },
                              ),
                              IconButton(
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(),
                                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                                onPressed: () async {
                                  final db = ref.read(appDatabaseProvider);
                                  await (db.delete(db.entriesTable)..where((e) => e.id.equals(entry.id))).go();
                                  if (ctx.mounted) Navigator.pop(ctx);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddEntryForCategoryDialog(
    BuildContext context,
    WidgetRef ref,
    CategoriesTableData cat,
    YearMonth ym,
  ) {
    final noteCtrl = TextEditingController();
    final amountCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Add Entry — ${cat.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount (₹) *',
                prefixText: '₹ ',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Note / Description (optional)',
                hintText: 'e.g. Weekly grocery shopping',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final amount = double.tryParse(amountCtrl.text) ?? 0;
              if (amount <= 0) return;

              final db = ref.read(appDatabaseProvider);
              final auth = ref.read(authStateProvider).valueOrNull;
              final householdId = auth?.householdId ?? 'local';
              final userId = auth?.userId ?? 'user-local';

              final now = DateTime.now();
              final entryDate = DateTime(ym.year, ym.month, now.day > 28 ? 28 : now.day);

              await db.into(db.entriesTable).insert(
                EntriesTableCompanion.insert(
                  id: _uuid.v4(),
                  householdId: householdId,
                  categoryId: cat.id,
                  kind: 'spending',
                  entryDate: entryDate,
                  amountPaise: (amount * 100).round(),
                  note: Value(noteCtrl.text.trim().isNotEmpty ? noteCtrl.text.trim() : null),
                  createdBy: userId,
                  createdAt: now,
                  updatedAt: now,
                ),
              );

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Expense entry of ₹$amount added under ${cat.name}!'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
            child: const Text('Save Entry'),
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

/// Converts snake_case or lowercase strings to Title Case.
/// e.g. "purchase_misc" → "Purchase Misc", "needs" → "Needs"
String _toTitleCase(String s) {
  return s
      .split(RegExp(r'[_\s]+'))
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join(' ');
}
