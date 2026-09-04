import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/month_switcher.dart';
import '../../../shared/widgets/pressable_scale.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/widgets/money_text.dart';
import '../../../domain/entities/entry.dart';
import '../../../core/utils/money.dart';
import '../../../data/local/database.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../providers/transactions_providers.dart';

/// S4 — Transactions list (doc 09 S4).
/// MonthSwitcher + segmented filter + grouped-by-day list + search + delete.
class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showSearch = ref.watch(showSearchProvider);
    final cs = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 6,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              title: showSearch
                  ? TextField(
                      controller: _searchCtrl,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Search notes or categories...',
                        border: InputBorder.none,
                      ),
                      onChanged: (val) {
                        ref.read(searchQueryProvider.notifier).state = val;
                      },
                    )
                  : const MonthSwitcher(),
              floating: true,
              forceElevated: innerBoxIsScrolled,
              actions: [
                IconButton(
                  icon: Icon(showSearch ? Icons.close_rounded : Icons.search_rounded),
                  onPressed: () {
                    ref.read(showSearchProvider.notifier).state = !showSearch;
                    if (showSearch) {
                      ref.read(searchQueryProvider.notifier).state = '';
                      _searchCtrl.clear();
                    }
                  },
                  tooltip: 'Search',
                ),
                Builder(
                  builder: (ctx) => IconButton(
                    icon: const Icon(Icons.add_rounded),
                    tooltip: 'Add Entry for Section',
                    onPressed: () {
                      final tabIndex = DefaultTabController.of(ctx).index;
                      final kindParam = switch (tabIndex) {
                        1 => 'income',
                        2 => 'saving',
                        3 => 'protection',
                        4 => 'spending',
                        5 => 'adjustment',
                        _ => 'spending',
                      };
                      context.push('/transactions/add?kind=$kindParam');
                    },
                  ),
                ),
              ],
              bottom: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: const Color(0xFF00A887),
                  borderRadius: BorderRadius.circular(20),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: cs.onSurfaceVariant,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: '  All  '),
                  Tab(text: '  Income  '),
                  Tab(text: '  Savings  '),
                  Tab(text: '  Protection  '),
                  Tab(text: '  Expenses  '),
                  Tab(text: '  Adjust  '),
                ],
              ),
            ),
          ],
          body: const TabBarView(
            children: [
              _EntriesList(filter: null),
              _EntriesList(filter: EntryKind.income),
              _EntriesList(filter: EntryKind.saving),
              _EntriesList(filter: EntryKind.protection),
              _EntriesList(filter: EntryKind.spending),
              _EntriesList(filter: EntryKind.adjustment),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Entries List ─────────────────────────────────────────────────────────────

class _EntriesList extends ConsumerWidget {
  final EntryKind? filter;
  const _EntriesList({this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ym = ref.watch(selectedMonthProvider);
    final search = ref.watch(searchQueryProvider).toLowerCase();
    final entriesAsync = ref.watch(entriesStreamProvider((ym, filter)));
    final catsAsync = ref.watch(_categoriesMapProvider);
    final cs = Theme.of(context).colorScheme;

    return entriesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            SkeletonLoader(width: double.infinity, height: 72, borderRadius: 16),
            SizedBox(height: 10),
            SkeletonLoader(width: double.infinity, height: 72, borderRadius: 16),
            SizedBox(height: 10),
            SkeletonLoader(width: double.infinity, height: 72, borderRadius: 16),
          ],
        ),
      ),
      error: (err, _) => Center(child: Text('Error loading entries: $err')),
      data: (list) {
        final catMap = catsAsync.valueOrNull ?? {};

        final filteredList = list.where((entry) {
          final catName = (catMap[entry.categoryId] ?? entry.categoryId).toLowerCase();
          final noteMatch = entry.note?.toLowerCase().contains(search) ?? false;
          return search.isEmpty || noteMatch || catName.contains(search);
        }).toList()
          ..sort((a, b) {
            final cmp = b.entryDate.compareTo(a.entryDate);
            if (cmp != 0) return cmp;
            return b.createdAt.compareTo(a.createdAt);
          });

        if (filteredList.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHigh.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.receipt_long_outlined,
                      size: 48,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    search.isEmpty
                        ? 'No transactions this month'
                        : 'No matching transactions found',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                  if (search.isEmpty) ...[
                    const SizedBox(height: 16),
                    PressableScale(
                      onTap: () => context.push('/transactions/add'),
                      child: FilledButton.icon(
                        onPressed: () => context.push('/transactions/add'),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add Transaction'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        // ── Build day-grouped list items ─────────────────────────────────────
        // Each item is either a String (date header) or an EntriesTableData (entry row).
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final yesterday = today.subtract(const Duration(days: 1));

        final List<dynamic> items = [];
        String? lastDateKey;

        for (final entry in filteredList) {
          final d = entry.entryDate;
          final dateKey = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
          if (dateKey != lastDateKey) {
            lastDateKey = dateKey;
            final entryDay = DateTime(d.year, d.month, d.day);
            String label;
            if (entryDay == today) {
              label = 'TODAY — ${_fmtDay(d)}';
            } else if (entryDay == yesterday) {
              label = 'YESTERDAY — ${_fmtDay(d)}';
            } else {
              label = _fmtDay(d);
            }
            items.add(label);
          }
          items.add(entry);
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
          itemCount: items.length,
          itemBuilder: (context, idx) {
            final item = items[idx];
            if (item is String) {
              return Padding(
                padding: EdgeInsets.fromLTRB(4, idx == 0 ? 4 : 20, 4, 10),
                child: Text(
                  item,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF78909C),
                    letterSpacing: 0.8,
                  ),
                ),
              );
            }
            final entry = item as EntriesTableData;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _EntryTile(entry: entry, catMap: catMap),
            );
          },
        );
      },
    );
  }
}

// ─── Entry Tile ─────────────────────────────────────────────────────────────

class _EntryTile extends ConsumerWidget {
  final EntriesTableData entry;
  final Map<String, String> catMap;

  const _EntryTile({required this.entry, required this.catMap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isIncome = entry.kind == 'income';
    final isAdjustment = entry.kind == 'adjustment';
    final amount = Money(entry.amountPaise);

    Color badgeBg;
    Color iconColor;
    IconData iconData;
    Color amountColor;

    if (isIncome) {
      badgeBg = const Color(0xFFE0F2F1);
      iconColor = const Color(0xFF00897B);
      iconData = Icons.arrow_upward_rounded;
      amountColor = const Color(0xFF00A887);
    } else if (isAdjustment) {
      badgeBg = const Color(0xFFFFF3E0);
      iconColor = const Color(0xFFFB8C00);
      iconData = Icons.swap_vert_rounded;
      amountColor = const Color(0xFFFB8C00);
    } else if (entry.kind == 'saving') {
      badgeBg = const Color(0xFFF3E5F5);
      iconColor = const Color(0xFF8E24AA);
      iconData = Icons.savings_outlined;
      amountColor = const Color(0xFF8E24AA);
    } else if (entry.kind == 'protection') {
      badgeBg = const Color(0xFFE8EAF6);
      iconColor = const Color(0xFF3F51B5);
      iconData = Icons.shield_outlined;
      amountColor = const Color(0xFF3F51B5);
    } else {
      badgeBg = const Color(0xFFFFEBEE); // Light red background for expense badge
      iconColor = const Color(0xFFC62828); // Dark red icon for expense badge
      iconData = Icons.arrow_downward_rounded;
      amountColor = const Color(0xFFEF4444); // Red color for expense amount
    }

    final catName = (entry.note != null && entry.note!.isNotEmpty)
        ? entry.note!
        : (catMap[entry.categoryId] ?? entry.categoryId);
    final formattedDate = '${entry.entryDate.day}/${entry.entryDate.month}/${entry.entryDate.year}';

    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: cs.errorContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(Icons.delete_outline_rounded, color: cs.onErrorContainer, size: 24),
      ),
      confirmDismiss: (_) async {
        return showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Delete Entry'),
            content: const Text('Delete this entry? This cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) async {
        final db = ref.read(appDatabaseProvider);
        await db.entryDao.softDelete(entry.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Entry deleted'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      },
      child: PressableScale(
        borderRadius: BorderRadius.circular(22),
        onTap: () => context.push('/transactions/${entry.id}/edit'),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: badgeBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      catName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formattedDate,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                    ),
                  ],
                ),
              ),
              MoneyText(
                amount,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: amountColor,
                      fontSize: 16,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Day-group date formatter ─────────────────────────────────────────────────

const _monthShort = [
  '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _fmtDay(DateTime d) =>
    '${d.day} ${_monthShort[d.month]} ${d.year}';

// ─── Category Map Provider ────────────────────────────────────────────────────

final _categoriesMapProvider = StreamProvider<Map<String, String>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.categoryDao.watchAll().map((cats) {
    return {for (final c in cats) c.id: c.name};
  });
});
