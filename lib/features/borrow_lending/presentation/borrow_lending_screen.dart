import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;

import '../../../core/utils/money.dart';
import '../../../data/local/database.dart';
import '../../../core/services/sync_service.dart';
import '../../../shared/widgets/money_text.dart';
import '../../../shared/widgets/pressable_scale.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/borrow_lending_providers.dart';

/// Dedicated Borrow & Lending module screen.
/// Tab 1: Lent Out (Receivables — money you are owed)
/// Tab 2: Borrowed  (Planned Bills — money you owe)
/// Tab 3: History   (Settled records)
class BorrowLendingScreen extends ConsumerStatefulWidget {
  const BorrowLendingScreen({super.key});

  @override
  ConsumerState<BorrowLendingScreen> createState() =>
      _BorrowLendingScreenState();
}

class _BorrowLendingScreenState extends ConsumerState<BorrowLendingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _householdId =>
      ref.read(authStateProvider).valueOrNull?.householdId ?? 'local';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final summaryAsync = ref.watch(borrowLendSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Borrow & Lending',
            style: TextStyle(fontWeight: FontWeight.w700)),
        bottom: TabBar(
          controller: _tabController,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          tabs: const [
            Tab(text: 'Lent Out'),
            Tab(text: 'Borrowed'),
            Tab(text: 'History'),
          ],
        ),
      ),
      floatingActionButton: _tabController.index < 2
          ? FloatingActionButton.extended(
              heroTag: 'bl_fab',
              onPressed: () => _showAddDialog(context, isLending: _tabController.index == 0),
              icon: const Icon(Icons.add_rounded),
              label: Text(_tabController.index == 0 ? 'Lent Money' : 'Borrowed Money'),
              backgroundColor: _tabController.index == 0
                  ? const Color(0xFF00897B)
                  : const Color(0xFFEF4444),
            )
          : null,
      body: Column(
        children: [
          // Summary Header Card
          _SummaryHeader(summaryAsync: summaryAsync),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _LentOutTab(householdId: _householdId),
                _BorrowedTab(householdId: _householdId),
                _HistoryTab(householdId: _householdId),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context, {required bool isLending}) {
    if (isLending) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => _AddReceivableSheet(householdId: _householdId),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => _AddPlannedBillSheet(householdId: _householdId),
      );
    }
  }
}

// ─── Summary Header ───────────────────────────────────────────────────────────

class _SummaryHeader extends StatelessWidget {
  final AsyncValue<BorrowLendSummary> summaryAsync;
  const _SummaryHeader({required this.summaryAsync});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return summaryAsync.when(
      loading: () => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: SkeletonLoader(width: double.infinity, height: 90, borderRadius: 20),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (summary) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A237E), Color(0xFF283593)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A237E).withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            ],
          ),
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  label: 'Total Lent',
                  amount: Money(summary.totalLentPaise),
                  color: const Color(0xFF69F0AE),
                  count: summary.openLentCount,
                  countLabel: 'open',
                ),
              ),
              Container(width: 1, height: 50, color: Colors.white.withValues(alpha: 0.2)),
              Expanded(
                child: _SummaryMetric(
                  label: 'Total Borrowed',
                  amount: Money(summary.totalBorrowedPaise),
                  color: const Color(0xFFFF8A80),
                  count: summary.openBorrowedCount,
                  countLabel: 'pending',
                ),
              ),
              Container(width: 1, height: 50, color: Colors.white.withValues(alpha: 0.2)),
              Expanded(
                child: _SummaryMetric(
                  label: 'Net Position',
                  amount: Money(summary.netPositionPaise),
                  color: summary.netPositionPaise >= 0
                      ? const Color(0xFF69F0AE)
                      : const Color(0xFFFF8A80),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final String label;
  final Money amount;
  final Color color;
  final int? count;
  final String? countLabel;

  const _SummaryMetric({
    required this.label,
    required this.amount,
    required this.color,
    this.count,
    this.countLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        MoneyText(amount,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w800, fontSize: 15)),
        if (count != null)
          Text('$count $countLabel',
              style: TextStyle(
                  color: Colors.white38, fontSize: 10)),
      ],
    );
  }
}

// ─── Lent Out Tab ─────────────────────────────────────────────────────────────

class _LentOutTab extends ConsumerWidget {
  final String householdId;
  const _LentOutTab({required this.householdId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final itemsAsync = ref.watch(openReceivablesProvider);

    return itemsAsync.when(
      loading: () => const _ListSkeleton(),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (items) {
        if (items.isEmpty) {
          return _EmptyState(
            icon: Icons.call_made_rounded,
            title: 'No Money Lent',
            subtitle: 'Money you lend to others will appear here.',
            color: const Color(0xFF00897B),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          itemCount: items.length,
          itemBuilder: (_, i) => _ReceivableCard(
            item: items[i],
            householdId: householdId,
          ),
        );
      },
    );
  }
}

// ─── Borrowed Tab ─────────────────────────────────────────────────────────────

class _BorrowedTab extends ConsumerWidget {
  final String householdId;
  const _BorrowedTab({required this.householdId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(unpaidBillsProvider);

    return itemsAsync.when(
      loading: () => const _ListSkeleton(),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (items) {
        if (items.isEmpty) {
          return _EmptyState(
            icon: Icons.call_received_rounded,
            title: 'No Borrowed Money',
            subtitle: 'Money you owe to others will appear here.',
            color: const Color(0xFFEF4444),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          itemCount: items.length,
          itemBuilder: (_, i) => _PlannedBillCard(
            item: items[i],
            householdId: householdId,
          ),
        );
      },
    );
  }
}

// ─── History Tab ──────────────────────────────────────────────────────────────

class _HistoryTab extends ConsumerWidget {
  final String householdId;
  const _HistoryTab({required this.householdId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settledAsync = ref.watch(settledReceivablesProvider);
    final paidAsync = ref.watch(paidBillsProvider);

    final settled = settledAsync.valueOrNull ?? [];
    final paid = paidAsync.valueOrNull ?? [];

    if (settledAsync.isLoading || paidAsync.isLoading) {
      return const _ListSkeleton();
    }

    if (settled.isEmpty && paid.isEmpty) {
      return _EmptyState(
        icon: Icons.history_rounded,
        title: 'No History Yet',
        subtitle: 'Settled loans and paid bills will appear here.',
        color: const Color(0xFF78909C),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      children: [
        if (settled.isNotEmpty) ...[
          _SectionHeader(
            label: 'Returned to You',
            icon: Icons.check_circle_rounded,
            color: const Color(0xFF00897B),
          ),
          ...settled.map((r) => _HistoryReceivableTile(item: r)),
          const SizedBox(height: 12),
        ],
        if (paid.isNotEmpty) ...[
          _SectionHeader(
            label: 'Bills Paid',
            icon: Icons.check_circle_rounded,
            color: const Color(0xFF5C6BC0),
          ),
          ...paid.map((b) => _HistoryBillTile(item: b)),
        ],
      ],
    );
  }
}

// ─── Item Cards ───────────────────────────────────────────────────────────────

class _ReceivableCard extends ConsumerWidget {
  final ReceivablesTableData item;
  final String householdId;
  const _ReceivableCard({required this.item, required this.householdId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: Key(item.id),
        direction: DismissDirection.startToEnd,
        background: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF00897B),
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.only(left: 20),
          alignment: Alignment.centerLeft,
          child: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Text('Mark Returned',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        confirmDismiss: (_) => _confirmSettle(context, isReturn: true),
        onDismissed: (_) async {
          await ref.read(appDatabaseProvider).borrowLendDao.settleReceivable(item.id);
          ref.read(syncServiceProvider).triggerSync();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${item.personName} marked as returned'),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
        },
        child: PressableScale(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _showEditReceivable(context, ref),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00897B).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_outline_rounded,
                      color: Color(0xFF00897B), size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.personName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00897B).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Open',
                                style: TextStyle(
                                    color: Color(0xFF00897B),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11)),
                          ),
                          if (item.dueDate != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              'Due: ${item.dueDate!.day}/${item.dueDate!.month}/${item.dueDate!.year}',
                              style: TextStyle(
                                  color: cs.onSurfaceVariant, fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    MoneyText(Money(item.amountPaise),
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: Color(0xFF00897B))),
                    const SizedBox(height: 4),
                    Text('Lent',
                        style: TextStyle(
                            color: cs.onSurfaceVariant, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmSettle(BuildContext context,
      {required bool isReturn}) async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Mark as Returned?'),
        content: Text(
            'Mark ₹${(item.amountPaise / 100).toStringAsFixed(0)} from ${item.personName} as returned?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirm')),
        ],
      ),
    );
  }

  void _showEditReceivable(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AddReceivableSheet(
        householdId: householdId,
        existing: item,
      ),
    );
  }
}

class _PlannedBillCard extends ConsumerWidget {
  final PlannedBillsTableData item;
  final String householdId;
  const _PlannedBillCard({required this.item, required this.householdId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: Key(item.id),
        direction: DismissDirection.startToEnd,
        background: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF5C6BC0),
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.only(left: 20),
          alignment: Alignment.centerLeft,
          child: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Text('Mark Paid',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        confirmDismiss: (_) => showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Mark as Paid?'),
            content: Text(
                'Mark ₹${(item.amountPaise / 100).toStringAsFixed(0)} for "${item.name}" as paid?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel')),
              FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Confirm')),
            ],
          ),
        ),
        onDismissed: (_) async {
          await ref.read(appDatabaseProvider).borrowLendDao.settlePlannedBill(item.id);
          ref.read(syncServiceProvider).triggerSync();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('"${item.name}" marked as paid'),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
        },
        child: PressableScale(
          borderRadius: BorderRadius.circular(18),
          onTap: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder: (_) =>
                _AddPlannedBillSheet(householdId: householdId, existing: item),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.receipt_long_rounded,
                      color: Color(0xFFEF4444), size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Pending',
                                style: TextStyle(
                                    color: Color(0xFFEF4444),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11)),
                          ),
                          if (item.dueDate != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              'Due: ${item.dueDate!.day}/${item.dueDate!.month}/${item.dueDate!.year}',
                              style: TextStyle(
                                  color: cs.onSurfaceVariant, fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    MoneyText(Money(item.amountPaise),
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: Color(0xFFEF4444))),
                    const SizedBox(height: 4),
                    Text('Owed',
                        style: TextStyle(
                            color: cs.onSurfaceVariant, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── History Tiles ────────────────────────────────────────────────────────────

class _HistoryReceivableTile extends StatelessWidget {
  final ReceivablesTableData item;
  const _HistoryReceivableTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF00897B).withValues(alpha: 0.12),
          child: const Icon(Icons.person_outline_rounded,
              color: Color(0xFF00897B), size: 20),
        ),
        title: Text(item.personName,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: const Text('Returned'),
        trailing: MoneyText(Money(item.amountPaise),
            style: const TextStyle(
                fontWeight: FontWeight.w700, color: Color(0xFF00897B))),
      ),
    );
  }
}

class _HistoryBillTile extends StatelessWidget {
  final PlannedBillsTableData item;
  const _HistoryBillTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF5C6BC0).withValues(alpha: 0.12),
          child: const Icon(Icons.receipt_long_rounded,
              color: Color(0xFF5C6BC0), size: 20),
        ),
        title: Text(item.name,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: const Text('Paid'),
        trailing: MoneyText(Money(item.amountPaise),
            style: const TextStyle(
                fontWeight: FontWeight.w700, color: Color(0xFF5C6BC0))),
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _SectionHeader(
      {required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: color)),
        ],
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  const _EmptyState(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: color),
            ),
            const SizedBox(height: 20),
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SkeletonLoader(width: double.infinity, height: 80, borderRadius: 18),
          const SizedBox(height: 10),
          SkeletonLoader(width: double.infinity, height: 80, borderRadius: 18),
          const SizedBox(height: 10),
          SkeletonLoader(width: double.infinity, height: 80, borderRadius: 18),
        ],
      ),
    );
  }
}

// ─── Add / Edit Bottom Sheets ─────────────────────────────────────────────────

class _AddReceivableSheet extends ConsumerStatefulWidget {
  final String householdId;
  final ReceivablesTableData? existing;
  const _AddReceivableSheet({required this.householdId, this.existing});

  @override
  ConsumerState<_AddReceivableSheet> createState() =>
      _AddReceivableSheetState();
}

class _AddReceivableSheetState extends ConsumerState<_AddReceivableSheet> {
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  DateTime? _dueDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _nameCtrl.text = widget.existing!.personName;
      _amountCtrl.text =
          (widget.existing!.amountPaise / 100).toStringAsFixed(0);
      _dueDate = widget.existing!.dueDate;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEdit = widget.existing != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFF00897B),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 12),
              Text(isEdit ? 'Edit Lent Money' : 'Add Lent Money',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Person / Beneficiary Name *',
              hintText: 'e.g. John Doe',
              prefixIcon: const Icon(Icons.person_outline_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Amount (₹) *',
              prefixText: '₹ ',
              prefixIcon: const Icon(Icons.currency_rupee_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _dueDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (picked != null) setState(() => _dueDate = picked);
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: cs.outline),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 20, color: cs.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Text(
                    _dueDate != null
                        ? 'Due: ${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                        : 'Due Date (optional)',
                    style: TextStyle(
                        color: _dueDate != null
                            ? cs.onSurface
                            : cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              if (isEdit)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await ref
                          .read(appDatabaseProvider)
                          .borrowLendDao
                          .deleteReceivable(widget.existing!.id);
                      if (context.mounted) Navigator.pop(context);
                    },
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: Colors.red),
                    label: const Text('Delete',
                        style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red)),
                  ),
                ),
              if (isEdit) const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(isEdit ? 'Update' : 'Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final amountPaise =
        ((double.tryParse(_amountCtrl.text) ?? 0) * 100).round();
    if (amountPaise <= 0) return;

    setState(() => _saving = true);
    try {
      await ref.read(appDatabaseProvider).borrowLendDao.upsertReceivable(
            householdId: widget.householdId,
            id: widget.existing?.id,
            personName: name,
            amountPaise: amountPaise,
            dueDate: _dueDate,
            existingEntryId: widget.existing?.entryId,
          );
      ref.read(syncServiceProvider).triggerSync();
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _AddPlannedBillSheet extends ConsumerStatefulWidget {
  final String householdId;
  final PlannedBillsTableData? existing;
  const _AddPlannedBillSheet({required this.householdId, this.existing});

  @override
  ConsumerState<_AddPlannedBillSheet> createState() =>
      _AddPlannedBillSheetState();
}

class _AddPlannedBillSheetState extends ConsumerState<_AddPlannedBillSheet> {
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  DateTime? _dueDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _nameCtrl.text = widget.existing!.name;
      _amountCtrl.text =
          (widget.existing!.amountPaise / 100).toStringAsFixed(0);
      _dueDate = widget.existing!.dueDate;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEdit = widget.existing != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 12),
              Text(isEdit ? 'Edit Borrowed Money' : 'Add Borrowed Money',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Description / Person *',
              hintText: 'e.g. Borrowed from Mom',
              prefixIcon: const Icon(Icons.receipt_long_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Amount (₹) *',
              prefixText: '₹ ',
              prefixIcon: const Icon(Icons.currency_rupee_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _dueDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (picked != null) setState(() => _dueDate = picked);
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: cs.outline),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 20, color: cs.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Text(
                    _dueDate != null
                        ? 'Due: ${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                        : 'Due Date (optional)',
                    style: TextStyle(
                        color: _dueDate != null
                            ? cs.onSurface
                            : cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              if (isEdit)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await ref
                          .read(appDatabaseProvider)
                          .borrowLendDao
                          .deletePlannedBill(widget.existing!.id);
                      if (context.mounted) Navigator.pop(context);
                    },
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: Colors.red),
                    label: const Text('Delete',
                        style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red)),
                  ),
                ),
              if (isEdit) const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(isEdit ? 'Update' : 'Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final amountPaise =
        ((double.tryParse(_amountCtrl.text) ?? 0) * 100).round();
    if (amountPaise <= 0) return;

    setState(() => _saving = true);
    try {
      await ref.read(appDatabaseProvider).borrowLendDao.upsertPlannedBill(
            householdId: widget.householdId,
            id: widget.existing?.id,
            name: name,
            amountPaise: amountPaise,
            dueDate: _dueDate,
            existingEntryId: widget.existing?.entryId,
          );
      ref.read(syncServiceProvider).triggerSync();
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
