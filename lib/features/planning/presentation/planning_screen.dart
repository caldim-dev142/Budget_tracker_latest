import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' hide Column;

import '../../../core/utils/money.dart';
import '../../../shared/widgets/money_text.dart';
import '../../../shared/widgets/pressable_scale.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../data/local/database.dart';
import '../../../core/services/sync_service.dart';
import '../../auth/providers/auth_providers.dart';

const _uuid = Uuid();

// ─── Providers ───────────────────────────────────────────────────────────────

final _plannedBillsProvider = StreamProvider<List<PlannedBillsTableData>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final authState = ref.watch(authStateProvider).valueOrNull;
  final householdId = authState?.householdId ?? 'local';
  return (db.select(db.plannedBillsTable)
        ..where((b) => b.householdId.equals(householdId))
        ..orderBy([(b) => OrderingTerm.desc(b.dueDate)]))
      .watch();
});

final _receivablesProvider = StreamProvider<List<ReceivablesTableData>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final authState = ref.watch(authStateProvider).valueOrNull;
  final householdId = authState?.householdId ?? 'local';
  return (db.select(db.receivablesTable)
        ..where((r) => r.status.equals('open') & r.householdId.equals(householdId))
        ..orderBy([(r) => OrderingTerm.desc(r.dueDate)]))
      .watch();
});

final _reserveLinesProvider = StreamProvider<List<ReserveLinesTableData>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final authState = ref.watch(authStateProvider).valueOrNull;
  final householdId = authState?.householdId ?? 'local';
  return (db.select(db.reserveLinesTable)
        ..where((r) => r.householdId.equals(householdId))
        ..orderBy([(r) => OrderingTerm.desc(r.yearMonth)]))
      .watch();
});

/// S13 — Planning / Annexure (doc 09 S13, doc 01 §8) — real DB-backed.
class PlanningScreen extends ConsumerWidget {
  const PlanningScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Planning Annexure'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Planned Bills'),
              Tab(text: 'Reserves'),
              Tab(text: 'Receivables'),
              Tab(text: 'Annual Plan'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _PlannedBillsTab(),
            _ReserveLinesTab(),
            _ReceivablesTab(),
            _AnnualPlanTab(),
          ],
        ),
      ),
    );
  }
}

// ─── Planned Bills Tab ────────────────────────────────────────────────────────

class _PlannedBillsTab extends ConsumerWidget {
  const _PlannedBillsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billsAsync = ref.watch(_plannedBillsProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: billsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: SkeletonLoader(width: double.infinity, height: 100, borderRadius: 18),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (bills) {
          if (bills.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.receipt_long_outlined,
                        size: 64,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                    const SizedBox(height: 16),
                    Text(
                      'No planned bills',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 16),
                    PressableScale(
                      onTap: () => _showAddBillDialog(context, ref),
                      child: FilledButton.icon(
                        onPressed: () => _showAddBillDialog(context, ref),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add Bill'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final unpaid = bills.where((b) => !b.isPaid).fold<int>(
                0, (s, b) => s + b.amountPaise);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'UNPAID TOTAL',
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                      color: cs.onSurfaceVariant,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              MoneyText(
                                Money(unpaid),
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      color: cs.error,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    PressableScale(
                      onTap: () => _showAddBillDialog(context, ref),
                      child: FilledButton.tonalIcon(
                        onPressed: () => _showAddBillDialog(context, ref),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add Bill'),
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  itemCount: bills.length,
                  itemBuilder: (_, i) {
                    final bill = bills[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: PressableScale(
                        borderRadius: BorderRadius.circular(18),
                        child: Card(
                          child: ListTile(
                            leading: Icon(
                              bill.isPaid
                                  ? Icons.check_circle_rounded
                                  : Icons.pending_rounded,
                              color: bill.isPaid
                                  ? Colors.green.shade600
                                  : cs.error,
                              size: 24,
                            ),
                            title: Text(
                              bill.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                decoration:
                                    bill.isPaid ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            subtitle: bill.dueDate != null
                                ? Text(
                                    'Due: ${bill.dueDate!.day}/${bill.dueDate!.month}/${bill.dueDate!.year}',
                                    style: TextStyle(color: cs.onSurfaceVariant),
                                  )
                                : null,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                MoneyText(
                                  Money(bill.amountPaise),
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                                if (!bill.isPaid)
                                  IconButton(
                                    icon: const Icon(Icons.check_circle_outline_rounded),
                                    tooltip: 'Mark Paid',
                                    onPressed: () => _markPaid(ref, bill),
                                  ),
                                PopupMenuButton<String>(
                                  onSelected: (v) {
                                    if (v == 'edit') _showEditBillDialog(context, ref, bill);
                                    if (v == 'delete') _deleteBill(context, ref, bill);
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(value: 'edit', child: Text('Edit Bill')),
                                    PopupMenuItem(value: 'delete', child: Text('Delete Bill')),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddBillDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    DateTime? dueDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Add Planned Bill'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Bill Name *',
                  hintText: 'e.g. Electricity Bill',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount (₹) *',
                  prefixText: '₹ ',
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  setState(() => dueDate = picked);
                },
                icon: const Icon(Icons.calendar_today_outlined, size: 16),
                label: Text(
                  dueDate == null
                      ? 'Set Due Date (optional)'
                      : 'Due: ${dueDate!.day}/${dueDate!.month}/${dueDate!.year}',
                ),
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
                final amount = double.tryParse(amountCtrl.text) ?? 0;
                if (name.isEmpty || amount <= 0) return;

                final db = ref.read(appDatabaseProvider);
                final auth = ref.read(authStateProvider).valueOrNull;
                final householdId = auth?.householdId ?? 'local';

                await db.borrowLendDao.upsertPlannedBill(
                  householdId: householdId,
                  name: name,
                  amountPaise: (amount * 100).round(),
                  dueDate: dueDate,
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Bill "$name" added!'),
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

  void _showEditBillDialog(BuildContext context, WidgetRef ref, PlannedBillsTableData bill) {
    final nameCtrl = TextEditingController(text: bill.name);
    final amountCtrl = TextEditingController(text: (bill.amountPaise / 100).toStringAsFixed(2));
    DateTime? dueDate = bill.dueDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Edit Planned Bill'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Bill Name *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount (₹) *',
                  prefixText: '₹ ',
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: dueDate ?? DateTime.now(),
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => dueDate = picked);
                },
                icon: const Icon(Icons.calendar_today_outlined, size: 16),
                label: Text(
                  dueDate == null
                      ? 'Set Due Date'
                      : 'Due: ${dueDate!.day}/${dueDate!.month}/${dueDate!.year}',
                ),
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
                final amount = double.tryParse(amountCtrl.text) ?? 0;
                if (name.isEmpty || amount <= 0) return;

                final db = ref.read(appDatabaseProvider);
                final auth = ref.read(authStateProvider).valueOrNull;
                final householdId = auth?.householdId ?? 'local';

                await db.borrowLendDao.upsertPlannedBill(
                  householdId: householdId,
                  id: bill.id,
                  name: name,
                  amountPaise: (amount * 100).round(),
                  dueDate: dueDate,
                  existingEntryId: bill.entryId,
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Bill "$name" updated!'),
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

  Future<void> _markPaid(WidgetRef ref, PlannedBillsTableData bill) async {
    final db = ref.read(appDatabaseProvider);
    await db.borrowLendDao.settlePlannedBill(bill.id);
  }

  Future<void> _deleteBill(BuildContext context, WidgetRef ref, PlannedBillsTableData bill) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Planned Bill?'),
        content: Text('Remove "${bill.name}" from your planned bills?'),
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
      await db.borrowLendDao.deletePlannedBill(bill.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bill "${bill.name}" deleted.'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }
}

// ─── Reserve Lines Tab ────────────────────────────────────────────────────────

class _ReserveLinesTab extends ConsumerWidget {
  const _ReserveLinesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservesAsync = ref.watch(_reserveLinesProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: reservesAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: SkeletonLoader(width: double.infinity, height: 100, borderRadius: 18),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (reserves) {
          final total = reserves.fold<int>(0, (s, r) => s + r.amountPaise);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TOTAL RESERVES',
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                      color: cs.onSurfaceVariant,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              MoneyText(
                                Money(total),
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    PressableScale(
                      onTap: () => _showAddReserveDialog(context, ref),
                      child: FilledButton.tonalIcon(
                        onPressed: () => _showAddReserveDialog(context, ref),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add'),
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: reserves.isEmpty
                    ? Center(
                        child: Text(
                          'No reserve lines yet',
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                        itemCount: reserves.length,
                        itemBuilder: (_, i) {
                          final r = reserves[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: PressableScale(
                              borderRadius: BorderRadius.circular(18),
                              child: Card(
                                child: ListTile(
                                  title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  subtitle: Text('Source: ${r.source}', style: TextStyle(color: cs.onSurfaceVariant)),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      MoneyText(Money(r.amountPaise), style: const TextStyle(fontWeight: FontWeight.w700)),
                                      PopupMenuButton<String>(
                                        onSelected: (v) {
                                          if (v == 'edit') _showEditReserveDialog(context, ref, r);
                                          if (v == 'delete') _deleteReserve(context, ref, r);
                                        },
                                        itemBuilder: (_) => const [
                                          PopupMenuItem(value: 'edit', child: Text('Edit Line')),
                                          PopupMenuItem(value: 'delete', child: Text('Delete Line')),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddReserveDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add Reserve Line'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Reserve Name *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'Amount (₹) *', prefixText: '₹ '),
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
              final amount = double.tryParse(amountCtrl.text) ?? 0;
              if (name.isEmpty || amount <= 0) return;

              final db = ref.read(appDatabaseProvider);
              final auth = ref.read(authStateProvider).valueOrNull;
              final householdId = auth?.householdId ?? 'local';
              final now = DateTime.now();
              final ym =
                  '${now.year}-${now.month.toString().padLeft(2, '0')}';

              await db.into(db.reserveLinesTable).insert(
                ReserveLinesTableCompanion.insert(
                  id: _uuid.v4(),
                  householdId: householdId,
                  yearMonth: ym,
                  name: name,
                  amountPaise: (amount * 100).round(),
                  source: const Value('manual'),
                ),
              );

              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteReserve(BuildContext context, WidgetRef ref, ReserveLinesTableData line) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Reserve Line?'),
        content: Text('Remove "${line.name}" from your reserves register?'),
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
      await (db.delete(db.reserveLinesTable)..where((r) => r.id.equals(line.id))).go();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reserve line "${line.name}" deleted.'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _showEditReserveDialog(BuildContext context, WidgetRef ref, ReserveLinesTableData line) {
    final nameCtrl = TextEditingController(text: line.name);
    final amountCtrl = TextEditingController(text: (line.amountPaise / 100).toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Reserve Line'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Reserve Name *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount (₹) *',
                prefixText: '₹ ',
              ),
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
              final amount = double.tryParse(amountCtrl.text) ?? 0;
              if (name.isEmpty || amount <= 0) return;

              final db = ref.read(appDatabaseProvider);
              await (db.update(db.reserveLinesTable)..where((r) => r.id.equals(line.id)))
                  .write(ReserveLinesTableCompanion(
                name: Value(name),
                amountPaise: Value((amount * 100).round()),
              ));

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Reserve line "$name" updated!'),
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
}

// ─── Receivables Tab ──────────────────────────────────────────────────────────

class _ReceivablesTab extends ConsumerWidget {
  const _ReceivablesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recAsync = ref.watch(_receivablesProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: recAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: SkeletonLoader(width: double.infinity, height: 100, borderRadius: 18),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (receivables) {
          final total =
              receivables.fold<int>(0, (s, r) => s + r.amountPaise);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'RETURN AWAITED',
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                      color: cs.onSurfaceVariant,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              MoneyText(
                                Money(total),
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      color: cs.primary,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    PressableScale(
                      onTap: () => _showAddReceivableDialog(context, ref),
                      child: FilledButton.tonalIcon(
                        onPressed: () => _showAddReceivableDialog(context, ref),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add'),
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: receivables.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_circle_down_outlined,
                                size: 56,
                                color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                            const SizedBox(height: 16),
                            Text('No open receivables',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    )),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                        itemCount: receivables.length,
                        itemBuilder: (_, i) {
                          final rec = receivables[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: PressableScale(
                              borderRadius: BorderRadius.circular(18),
                              child: Card(
                                child: ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: cs.primaryContainer.withValues(alpha: 0.4),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.person_rounded, color: cs.primary, size: 20),
                                  ),
                                  title: Text(rec.personName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  subtitle: rec.dueDate != null
                                      ? Text(
                                          'Due: ${rec.dueDate!.day}/${rec.dueDate!.month}/${rec.dueDate!.year}',
                                          style: TextStyle(color: cs.onSurfaceVariant),
                                        )
                                      : null,
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      MoneyText(
                                        Money(rec.amountPaise),
                                        style: TextStyle(
                                          color: cs.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.check_circle_outline_rounded),
                                        tooltip: 'Mark Returned',
                                        onPressed: () => _markReturned(ref, rec),
                                      ),
                                      PopupMenuButton<String>(
                                        onSelected: (v) {
                                          if (v == 'edit') _showEditReceivableDialog(context, ref, rec);
                                          if (v == 'delete') _deleteReceivable(context, ref, rec);
                                        },
                                        itemBuilder: (_) => const [
                                          PopupMenuItem(value: 'edit', child: Text('Edit Receivable')),
                                          PopupMenuItem(value: 'delete', child: Text('Delete Receivable')),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddReceivableDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    DateTime? dueDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Add Receivable'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Person Name *',
                  hintText: 'Who owes you money?',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount (₹) *',
                  prefixText: '₹ ',
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  setState(() => dueDate = picked);
                },
                icon: const Icon(Icons.calendar_today_outlined, size: 16),
                label: Text(
                  dueDate == null
                      ? 'Set Due Date (optional)'
                      : 'Due: ${dueDate!.day}/${dueDate!.month}/${dueDate!.year}',
                ),
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
                final amount = double.tryParse(amountCtrl.text) ?? 0;
                if (name.isEmpty || amount <= 0) return;

                final db = ref.read(appDatabaseProvider);
                final auth = ref.read(authStateProvider).valueOrNull;
                final householdId = auth?.householdId ?? 'local';

                await db.borrowLendDao.upsertReceivable(
                  householdId: householdId,
                  personName: name,
                  amountPaise: (amount * 100).round(),
                  dueDate: dueDate,
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Receivable from $name added!'),
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

  void _showEditReceivableDialog(BuildContext context, WidgetRef ref, ReceivablesTableData rec) {
    final nameCtrl = TextEditingController(text: rec.personName);
    final amountCtrl = TextEditingController(text: (rec.amountPaise / 100).toStringAsFixed(2));
    DateTime? dueDate = rec.dueDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Edit Receivable'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Person Name *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount (₹) *',
                  prefixText: '₹ ',
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: dueDate ?? DateTime.now(),
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => dueDate = picked);
                },
                icon: const Icon(Icons.calendar_today_outlined, size: 16),
                label: Text(
                  dueDate == null
                      ? 'Set Due Date'
                      : 'Due: ${dueDate!.day}/${dueDate!.month}/${dueDate!.year}',
                ),
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
                final amount = double.tryParse(amountCtrl.text) ?? 0;
                if (name.isEmpty || amount <= 0) return;

                final db = ref.read(appDatabaseProvider);
                final auth = ref.read(authStateProvider).valueOrNull;
                final householdId = auth?.householdId ?? 'local';

                await db.borrowLendDao.upsertReceivable(
                  householdId: householdId,
                  id: rec.id,
                  personName: name,
                  amountPaise: (amount * 100).round(),
                  dueDate: dueDate,
                  existingEntryId: rec.entryId,
                );
                ref.read(syncServiceProvider).triggerSync();

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Receivable for "$name" updated!'),
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

  Future<void> _markReturned(
      WidgetRef ref, ReceivablesTableData rec) async {
    final db = ref.read(appDatabaseProvider);
    await db.borrowLendDao.settleReceivable(rec.id);
    ref.read(syncServiceProvider).triggerSync();
  }

  Future<void> _deleteReceivable(
      BuildContext context, WidgetRef ref, ReceivablesTableData rec) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Receivable?'),
        content: Text('Remove receivable from "${rec.personName}"?'),
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
      await db.borrowLendDao.deleteReceivable(rec.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Receivable from "${rec.personName}" deleted.'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }
}

// ─── Annual Plan Tab ─────────────────────────────────────────────────────────

final _annualTargetsProvider = StreamProvider<List<AnnualTargetsTableData>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final authState = ref.watch(authStateProvider).valueOrNull;
  final householdId = authState?.householdId ?? 'local';
  return (db.select(db.annualTargetsTable)..where((t) => t.householdId.equals(householdId))).watch();
});

class _AnnualPlanTab extends ConsumerWidget {
  const _AnnualPlanTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(_annualTargetsProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAnnualItemDialog(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Target'),
      ),
      body: itemsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: SkeletonLoader(width: double.infinity, height: 100, borderRadius: 18),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.flag_outlined, size: 56, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text('No annual targets configured yet', style: TextStyle(color: cs.onSurfaceVariant)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final item = items[i];
              final isIncome = item.type == 'income';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: PressableScale(
                  borderRadius: BorderRadius.circular(18),
                  child: Card(
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (isIncome ? Colors.green : cs.primary).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isIncome ? Icons.trending_up_rounded : Icons.account_balance_wallet_outlined,
                          color: isIncome ? Colors.green : cs.primary,
                          size: 20,
                        ),
                      ),
                      title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(isIncome ? 'Income Target' : 'Expense Budget', style: TextStyle(color: cs.onSurfaceVariant)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          MoneyText(
                            Money(item.targetPaise),
                            style: TextStyle(color: isIncome ? Colors.green : cs.primary, fontWeight: FontWeight.w700),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'edit') _showEditAnnualItemDialog(context, ref, item);
                              if (v == 'delete') _deleteAnnualItem(context, ref, item);
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'edit', child: Text('Edit Target')),
                              PopupMenuItem(value: 'delete', child: Text('Delete Target')),
                            ],
                          ),
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
    );
  }

  void _showAddAnnualItemDialog(BuildContext context, WidgetRef ref) {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String type = 'income';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Add Annual Target'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Target Title *')),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Amount (₹) *', prefixText: '₹ '),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(labelText: 'Target Type'),
                items: const [
                  DropdownMenuItem(value: 'income', child: Text('Income Target')),
                  DropdownMenuItem(value: 'expense', child: Text('Expense Budget')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => type = v);
                },
              ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final title = titleCtrl.text.trim();
                final amt = double.tryParse(amountCtrl.text) ?? 0;
                if (title.isEmpty || amt <= 0) return;

                final db = ref.read(appDatabaseProvider);
                final auth = ref.read(authStateProvider).valueOrNull;
                final householdId = auth?.householdId ?? 'local';

                await db.into(db.annualTargetsTable).insert(
                  AnnualTargetsTableCompanion.insert(
                    id: _uuid.v4(),
                    householdId: householdId,
                    title: title,
                    targetPaise: (amt * 100).round(),
                    type: Value(type),
                  ),
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Target "$title" added!'),
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

  void _showEditAnnualItemDialog(BuildContext context, WidgetRef ref, AnnualTargetsTableData item) {
    final titleCtrl = TextEditingController(text: item.title);
    final amountCtrl = TextEditingController(text: (item.targetPaise / 100).toStringAsFixed(2));
    String type = item.type;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Edit Annual Target'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Target Title *')),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Amount (₹) *', prefixText: '₹ '),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(labelText: 'Target Type'),
                items: const [
                  DropdownMenuItem(value: 'income', child: Text('Income Target')),
                  DropdownMenuItem(value: 'expense', child: Text('Expense Budget')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => type = v);
                },
              ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final title = titleCtrl.text.trim();
                final amt = double.tryParse(amountCtrl.text) ?? 0;
                if (title.isEmpty || amt <= 0) return;

                final db = ref.read(appDatabaseProvider);
                await (db.update(db.annualTargetsTable)..where((t) => t.id.equals(item.id)))
                    .write(AnnualTargetsTableCompanion(
                  title: Value(title),
                  targetPaise: Value((amt * 100).round()),
                  type: Value(type),
                ));

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Target "$title" updated!'),
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

  Future<void> _deleteAnnualItem(BuildContext context, WidgetRef ref, AnnualTargetsTableData item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Target?'),
        content: Text('Remove annual target "${item.title}"?'),
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
      await (db.delete(db.annualTargetsTable)..where((t) => t.id.equals(item.id))).go();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Target "${item.title}" deleted.'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }
}

