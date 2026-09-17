import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' hide Column;

import '../../../core/utils/app_feedback.dart';
import '../../../core/utils/input_formatters.dart';
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
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              AppFeedback.formatError(e),
              style: TextStyle(color: cs.error, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ),
        ),
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
                                    onPressed: () => _markPaid(context, ref, bill),
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
                inputFormatters: [AppInputFormatters.positiveDecimal()],
                decoration: const InputDecoration(
                  labelText: 'Amount (₹) *',
                  hintText: '0.00',
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
                if (name.isEmpty) {
                  AppFeedback.showWarning(context, 'Please enter a bill name.');
                  return;
                }
                final amount = double.tryParse(amountCtrl.text) ?? 0;
                if (amount <= 0) {
                  AppFeedback.showWarning(context, 'Please enter an amount greater than ₹0.');
                  return;
                }

                try {
                  final db = ref.read(appDatabaseProvider);
                  final auth = ref.read(authStateProvider).valueOrNull;
                  final householdId = auth?.householdId ?? 'local';

                  await db.borrowLendDao.upsertPlannedBill(
                    householdId: householdId,
                    name: name,
                    amountPaise: (amount * 100).round(),
                    dueDate: dueDate,
                  );
                  ref.read(syncServiceProvider).triggerSync();

                  if (context.mounted) {
                    Navigator.pop(context);
                    AppFeedback.showSuccess(context, 'Bill "$name" added!');
                  }
                } catch (e) {
                  if (context.mounted) {
                    AppFeedback.showError(context, 'Failed to save bill', error: e);
                  }
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
                decoration: const InputDecoration(
                  labelText: 'Bill Name *',
                  hintText: 'e.g. Electricity Bill',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [AppInputFormatters.positiveDecimal()],
                decoration: const InputDecoration(
                  labelText: 'Amount (₹) *',
                  hintText: '0.00',
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
                if (name.isEmpty) {
                  AppFeedback.showWarning(context, 'Please enter a bill name.');
                  return;
                }
                final amount = double.tryParse(amountCtrl.text) ?? 0;
                if (amount <= 0) {
                  AppFeedback.showWarning(context, 'Please enter an amount greater than ₹0.');
                  return;
                }

                try {
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
                  ref.read(syncServiceProvider).triggerSync();

                  if (context.mounted) {
                    Navigator.pop(context);
                    AppFeedback.showSuccess(context, 'Bill "$name" updated!');
                  }
                } catch (e) {
                  if (context.mounted) {
                    AppFeedback.showError(context, 'Failed to update bill', error: e);
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markPaid(BuildContext context, WidgetRef ref, PlannedBillsTableData bill) async {
    final db = ref.read(appDatabaseProvider);
    await db.borrowLendDao.settlePlannedBill(bill.id);
    ref.read(syncServiceProvider).triggerSync();
    if (context.mounted) {
      AppFeedback.showSuccess(context, 'Marked "${bill.name}" as paid.');
    }
  }

  Future<void> _deleteBill(BuildContext context, WidgetRef ref, PlannedBillsTableData bill) async {
    final confirm = await AppFeedback.showConfirmDialog(
      context,
      title: 'Delete Planned Bill',
      message: 'Remove "${bill.name}" from your planned bills?',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (confirm == true) {
      try {
        final db = ref.read(appDatabaseProvider);
        await db.borrowLendDao.deletePlannedBill(bill.id);
        ref.read(syncServiceProvider).triggerSync();
        if (context.mounted) {
          AppFeedback.showSuccess(context, 'Bill "${bill.name}" deleted.');
        }
      } catch (e) {
        if (context.mounted) {
          AppFeedback.showError(context, 'Failed to delete bill', error: e);
        }
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
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              AppFeedback.formatError(e),
              style: TextStyle(color: cs.error, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ),
        ),
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
              decoration: const InputDecoration(
                labelText: 'Reserve Name *',
                hintText: 'e.g. Emergency Buffer, Tax Reserve',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [AppInputFormatters.positiveDecimal()],
              decoration: const InputDecoration(
                labelText: 'Amount (₹) *',
                hintText: '0.00',
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
              if (name.isEmpty) {
                AppFeedback.showWarning(context, 'Please enter a reserve name.');
                return;
              }
              final amount = double.tryParse(amountCtrl.text) ?? 0;
              if (amount <= 0) {
                AppFeedback.showWarning(context, 'Please enter an amount greater than ₹0.');
                return;
              }

              try {
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

                if (context.mounted) {
                  Navigator.pop(context);
                  AppFeedback.showSuccess(context, 'Reserve line "$name" added!');
                }
              } catch (e) {
                if (context.mounted) {
                  AppFeedback.showError(context, 'Failed to add reserve line', error: e);
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteReserve(BuildContext context, WidgetRef ref, ReserveLinesTableData line) async {
    final confirm = await AppFeedback.showConfirmDialog(
      context,
      title: 'Delete Reserve Line?',
      message: 'Remove "${line.name}" from your reserves register?',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (confirm == true) {
      final db = ref.read(appDatabaseProvider);
      await db.syncQueueDao.enqueueDeletion(entity: 'reserve_line', entityId: line.id);
      await (db.delete(db.reserveLinesTable)..where((r) => r.id.equals(line.id))).go();
      ref.read(syncServiceProvider).triggerSync();
      if (context.mounted) {
        AppFeedback.showSuccess(context, 'Reserve line "${line.name}" deleted.');
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
              decoration: const InputDecoration(
                labelText: 'Reserve Name *',
                hintText: 'e.g. Emergency Buffer',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [AppInputFormatters.positiveDecimal()],
              decoration: const InputDecoration(
                labelText: 'Amount (₹) *',
                hintText: '0.00',
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
              if (name.isEmpty) {
                AppFeedback.showWarning(context, 'Please enter a reserve name.');
                return;
              }
              final amount = double.tryParse(amountCtrl.text) ?? 0;
              if (amount <= 0) {
                AppFeedback.showWarning(context, 'Please enter an amount greater than ₹0.');
                return;
              }

              final db = ref.read(appDatabaseProvider);
              await (db.update(db.reserveLinesTable)..where((r) => r.id.equals(line.id)))
                  .write(ReserveLinesTableCompanion(
                name: Value(name),
                amountPaise: Value((amount * 100).round()),
              ));

              if (context.mounted) {
                Navigator.pop(context);
                AppFeedback.showSuccess(context, 'Reserve line "$name" updated!');
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
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              AppFeedback.formatError(e),
              style: TextStyle(color: cs.error, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ),
        ),
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
                                        onPressed: () => _markReturned(context, ref, rec),
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
                inputFormatters: [AppInputFormatters.positiveDecimal()],
                decoration: const InputDecoration(
                  labelText: 'Amount (₹) *',
                  hintText: '0.00',
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
                if (name.isEmpty) {
                  AppFeedback.showWarning(context, 'Please enter a person name.');
                  return;
                }
                final amount = double.tryParse(amountCtrl.text) ?? 0;
                if (amount <= 0) {
                  AppFeedback.showWarning(context, 'Please enter an amount greater than ₹0.');
                  return;
                }

                try {
                  final db = ref.read(appDatabaseProvider);
                  final auth = ref.read(authStateProvider).valueOrNull;
                  final householdId = auth?.householdId ?? 'local';

                  await db.borrowLendDao.upsertReceivable(
                    householdId: householdId,
                    personName: name,
                    amountPaise: (amount * 100).round(),
                    dueDate: dueDate,
                  );
                  ref.read(syncServiceProvider).triggerSync();

                  if (context.mounted) {
                    Navigator.pop(context);
                    AppFeedback.showSuccess(context, 'Receivable from $name added!');
                  }
                } catch (e) {
                  if (context.mounted) {
                    AppFeedback.showError(context, 'Failed to add receivable', error: e);
                  }
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
                decoration: const InputDecoration(
                  labelText: 'Person Name *',
                  hintText: 'Who owes you money?',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [AppInputFormatters.positiveDecimal()],
                decoration: const InputDecoration(
                  labelText: 'Amount (₹) *',
                  hintText: '0.00',
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
                if (name.isEmpty) {
                  AppFeedback.showWarning(context, 'Please enter a person name.');
                  return;
                }
                final amount = double.tryParse(amountCtrl.text) ?? 0;
                if (amount <= 0) {
                  AppFeedback.showWarning(context, 'Please enter an amount greater than ₹0.');
                  return;
                }

                try {
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
                    AppFeedback.showSuccess(context, 'Receivable for "$name" updated!');
                  }
                } catch (e) {
                  if (context.mounted) {
                    AppFeedback.showError(context, 'Failed to update receivable', error: e);
                  }
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
      BuildContext context, WidgetRef ref, ReceivablesTableData rec) async {
    final db = ref.read(appDatabaseProvider);
    await db.borrowLendDao.settleReceivable(rec.id);
    ref.read(syncServiceProvider).triggerSync();
    if (context.mounted) {
      AppFeedback.showSuccess(context, 'Marked receivable from "${rec.personName}" as returned.');
    }
  }

  Future<void> _deleteReceivable(
      BuildContext context, WidgetRef ref, ReceivablesTableData rec) async {
    final confirm = await AppFeedback.showConfirmDialog(
      context,
      title: 'Delete Receivable',
      message: 'Remove receivable from "${rec.personName}"?',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (confirm == true) {
      try {
        final db = ref.read(appDatabaseProvider);
        await db.borrowLendDao.deleteReceivable(rec.id);
        ref.read(syncServiceProvider).triggerSync();
        if (context.mounted) {
          AppFeedback.showSuccess(context, 'Receivable from "${rec.personName}" deleted.');
        }
      } catch (e) {
        if (context.mounted) {
          AppFeedback.showError(context, 'Failed to delete receivable', error: e);
        }
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
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              AppFeedback.formatError(e),
              style: TextStyle(color: cs.error, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.flag_outlined, size: 56, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text('No annual targets configured yet', style: TextStyle(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Text('Tap + Add Target below to set your first goal.',
                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                ],
              ),
            );
          }

          // Compute summary aggregates
          final incomeTargetPaise = items
              .where((i) => i.type == 'income')
              .fold<int>(0, (s, i) => s + i.targetPaise);
          final expenseTargetPaise = items
              .where((i) => i.type == 'expense')
              .fold<int>(0, (s, i) => s + i.targetPaise);
          final netSavingsPaise = incomeTargetPaise - expenseTargetPaise;

          return Column(
            children: [
              // ── Summary Header Card ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ANNUAL PLAN SUMMARY',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _AnnualSummaryTile(
                                label: 'Income Target',
                                amount: Money(incomeTargetPaise),
                                color: const Color(0xFF00A887),
                                icon: Icons.trending_up_rounded,
                              ),
                            ),
                            Expanded(
                              child: _AnnualSummaryTile(
                                label: 'Expense Budget',
                                amount: Money(expenseTargetPaise),
                                color: cs.error,
                                icon: Icons.account_balance_wallet_outlined,
                              ),
                            ),
                            Expanded(
                              child: _AnnualSummaryTile(
                                label: 'Net Savings',
                                amount: Money(netSavingsPaise),
                                color: netSavingsPaise >= 0
                                    ? const Color(0xFF8B5CF6)
                                    : cs.error,
                                icon: Icons.savings_outlined,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // ── Items List ────────────────────────────────────────────────
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
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
                                color: (isIncome ? const Color(0xFF00A887) : cs.primary).withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isIncome ? Icons.trending_up_rounded : Icons.account_balance_wallet_outlined,
                                color: isIncome ? const Color(0xFF00A887) : cs.primary,
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
                                  style: TextStyle(
                                    color: isIncome ? const Color(0xFF00A887) : cs.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
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
                ),
              ),
            ],
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
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Target Title *',
                  hintText: 'e.g. Annual Bonus, Health Insurance, Vacation',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [AppInputFormatters.positiveDecimal()],
                decoration: const InputDecoration(
                  labelText: 'Amount (₹) *',
                  hintText: '0.00',
                  prefixText: '₹ ',
                ),
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
                if (title.isEmpty) {
                  AppFeedback.showWarning(context, 'Please enter a target title.');
                  return;
                }
                final amt = double.tryParse(amountCtrl.text) ?? 0;
                if (amt <= 0) {
                  AppFeedback.showWarning(context, 'Please enter an amount greater than ₹0.');
                  return;
                }

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
                ref.read(syncServiceProvider).triggerSync();

                if (context.mounted) {
                  Navigator.pop(context);
                  AppFeedback.showSuccess(context, 'Target "$title" added!');
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
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Target Title *',
                  hintText: 'e.g. Annual Bonus, Health Insurance, Vacation',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [AppInputFormatters.positiveDecimal()],
                decoration: const InputDecoration(
                  labelText: 'Amount (₹) *',
                  hintText: '0.00',
                  prefixText: '₹ ',
                ),
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
                if (title.isEmpty) {
                  AppFeedback.showWarning(context, 'Please enter a target title.');
                  return;
                }
                final amt = double.tryParse(amountCtrl.text) ?? 0;
                if (amt <= 0) {
                  AppFeedback.showWarning(context, 'Please enter an amount greater than ₹0.');
                  return;
                }

                final db = ref.read(appDatabaseProvider);
                await (db.update(db.annualTargetsTable)..where((t) => t.id.equals(item.id)))
                    .write(AnnualTargetsTableCompanion(
                  title: Value(title),
                  targetPaise: Value((amt * 100).round()),
                  type: Value(type),
                ));
                ref.read(syncServiceProvider).triggerSync();

                if (context.mounted) {
                  Navigator.pop(context);
                  AppFeedback.showSuccess(context, 'Target "$title" updated!');
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
    final confirm = await AppFeedback.showConfirmDialog(
      context,
      title: 'Delete Target',
      message: 'Remove annual target "${item.title}"?',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (confirm == true) {
      try {
        final db = ref.read(appDatabaseProvider);
        // Enqueue delete into syncQueue BEFORE local deletion so backend
        // removes it on next push and it is not resurrected on pull.
        await db.syncQueueDao.enqueueDeletion(entity: 'annual_target', entityId: item.id);
        await (db.delete(db.annualTargetsTable)..where((t) => t.id.equals(item.id))).go();
        ref.read(syncServiceProvider).triggerSync();
        if (context.mounted) {
          AppFeedback.showSuccess(context, 'Target "${item.title}" deleted.');
        }
      } catch (e) {
        if (context.mounted) {
          AppFeedback.showError(context, 'Failed to delete target', error: e);
        }
      }
    }
  }
}

// ─── Annual Summary Tile ──────────────────────────────────────────────────────

class _AnnualSummaryTile extends StatelessWidget {
  final String label;
  final Money amount;
  final Color color;
  final IconData icon;

  const _AnnualSummaryTile({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: cs.onSurfaceVariant,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        MoneyText(
          amount,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

