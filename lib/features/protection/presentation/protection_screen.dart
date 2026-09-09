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

final _activeFundsProvider = StreamProvider<List<SinkingFundsTableData>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final authState = ref.watch(authStateProvider).valueOrNull;
  final householdId = authState?.householdId ?? 'local';
  return db.fundDao.watchActiveFunds(householdId: householdId);
});

final _fundMovementsProvider =
    StreamProvider.family<List<FundMovementsTableData>, String>((ref, fundId) {
  final db = ref.watch(appDatabaseProvider);
  return db.fundDao.watchMovementsForFund(fundId, '');
});

/// S9 — Protection / Sinking Funds (doc 09 S9, doc 01 §4) — real DB-backed.
class ProtectionScreen extends ConsumerWidget {
  const ProtectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fundsAsync = ref.watch(_activeFundsProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Protection & Sinking Funds'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddFundDialog(context, ref),
            tooltip: 'Add Fund',
          ),
        ],
      ),
      body: fundsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: SkeletonLoader(width: double.infinity, height: 120, borderRadius: 18),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (funds) {
          if (funds.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.shield_outlined,
                        size: 56,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No Protection Funds Yet',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create sinking funds for annual insurance, medical buffers, or unplanned events.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 24),
                    PressableScale(
                      onTap: () => _showAddFundDialog(context, ref),
                      child: FilledButton.icon(
                        onPressed: () => _showAddFundDialog(context, ref),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add Sinking Fund'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            itemCount: funds.length,
            itemBuilder: (_, i) => _SinkingFundCard(fund: funds[i]),
          );
        },
      ),
    );
  }

  void _showAddFundDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final reserveCtrl = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add Sinking Fund'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Fund Name *',
                hintText: 'e.g. Insurance, Medical Emergency',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reserveCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Opening Reserve (₹)',
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
              if (name.isEmpty) return;

              final reserve =
                  ((double.tryParse(reserveCtrl.text) ?? 0) * 100).round();
              final db = ref.read(appDatabaseProvider);
              final auth = ref.read(authStateProvider).valueOrNull;
              final householdId = auth?.householdId ?? 'local-household';

              await db.fundDao.upsertFund(
                SinkingFundsTableCompanion.insert(
                  id: _uuid.v4(),
                  householdId: householdId,
                  name: name,
                  openingReservePaise: Value(reserve),
                ),
              );

              // B1 Bridge: Auto-create matching protection categories for Add Entry (+) picker
              final toMfName = 'To MF for $name';
              final spendingName = 'Spending for $name';
              final existingCats = await db.categoryDao.getAllActive();
              
              if (!existingCats.any((c) => c.name.toLowerCase() == toMfName.toLowerCase())) {
                await db.categoryDao.upsertAll([
                  CategoriesTableCompanion.insert(
                    id: _uuid.v4(),
                    householdId: householdId,
                    kind: 'protection',
                    groupCode: const Value('protection'),
                    name: toMfName,
                    isDeduction: const Value(false),
                    isSystem: const Value(false),
                    sortOrder: const Value(99),
                  ),
                ]);
              }

              if (!existingCats.any((c) => c.name.toLowerCase() == spendingName.toLowerCase())) {
                await db.categoryDao.upsertAll([
                  CategoriesTableCompanion.insert(
                    id: _uuid.v4(),
                    householdId: householdId,
                    kind: 'protection',
                    groupCode: const Value('protection'),
                    name: spendingName,
                    isDeduction: const Value(false),
                    isSystem: const Value(false),
                    sortOrder: const Value(100),
                  ),
                ]);
              }

              ref.read(syncServiceProvider).triggerSync();

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Fund "$name" created!'),
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

  void _showEditFundDialog(BuildContext context, WidgetRef ref, SinkingFundsTableData fund) {
    final nameCtrl = TextEditingController(text: fund.name);
    final reserveCtrl = TextEditingController(
      text: (fund.openingReservePaise / 100).toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Edit Fund — ${fund.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Fund Name *',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reserveCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Opening Reserve (₹)',
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
              if (name.isEmpty) return;

              final reserve =
                  ((double.tryParse(reserveCtrl.text) ?? 0) * 100).round();
              final db = ref.read(appDatabaseProvider);

              await (db.update(db.sinkingFundsTable)..where((f) => f.id.equals(fund.id)))
                  .write(SinkingFundsTableCompanion(
                    name: Value(name),
                    openingReservePaise: Value(reserve),
                  ));
              ref.read(syncServiceProvider).triggerSync();

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Fund "$name" updated!'),
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

// ─── Sinking Fund Card ────────────────────────────────────────────────────────

class _SinkingFundCard extends ConsumerWidget {
  final SinkingFundsTableData fund;
  const _SinkingFundCard({required this.fund});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movementsAsync = ref.watch(_fundMovementsProvider(fund.id));
    final cs = Theme.of(context).colorScheme;

    return movementsAsync.when(
      loading: () => const Card(child: Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator())),
      error: (e, _) => Card(child: Text('Error: $e')),
      data: (movements) {
        int contributionPaise = 0;
        int withdrawalPaise = 0;
        for (final m in movements) {
          if (m.type == 'contribution') {
            contributionPaise += m.amountPaise;
          } else {
            withdrawalPaise += m.amountPaise;
          }
        }
        final opening = Money(fund.openingReservePaise);
        final contribution = Money(contributionPaise);
        final withdrawal = Money(withdrawalPaise);
        final closing = opening + contribution - withdrawal;

        return PressableScale(
          borderRadius: BorderRadius.circular(18),
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cs.secondaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.shield_rounded,
                    color: cs.secondary, size: 22),
              ),
              title: Text(
                fund.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              subtitle: Text(
                'Closing Reserve: ${MoneyFormatter.formatCompact(closing)}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: closing.isNegative ? cs.error : cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Column(
                    children: [
                      const Divider(),
                      _FundRow('Opening Reserve', opening),
                      _FundRow('+ Contributions', contribution),
                      _FundRow('− Withdrawals', withdrawal),
                      const Divider(),
                      _FundRow('Closing Reserve', closing, bold: true),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _showMovementDialog(context, ref, fund, 'contribution'),
                              icon: const Icon(Icons.add_rounded, size: 16),
                              label: const Text('Contribute'),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _showMovementDialog(context, ref, fund, 'withdrawal'),
                              icon: const Icon(Icons.remove_rounded, size: 16),
                              label: const Text('Withdraw'),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.history_rounded),
                            tooltip: 'History',
                            onPressed: () => _showFundMovementsSheet(context, ref, fund, movements),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            tooltip: 'Edit Fund',
                            onPressed: () =>
                                const ProtectionScreen()._showEditFundDialog(context, ref, fund),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                            tooltip: 'Delete Fund',
                            onPressed: () => _deleteFund(context, ref, fund),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMovementDialog(
    BuildContext context,
    WidgetRef ref,
    SinkingFundsTableData fund,
    String type,
  ) {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final isContrib = type == 'contribution';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('${isContrib ? 'Contribute to' : 'Withdraw from'} ${fund.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: '${isContrib ? 'Contribution' : 'Withdrawal'} Amount (₹) *',
                prefixText: '₹ ',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
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
              final amount = double.tryParse(amountCtrl.text) ?? 0;
              if (amount <= 0) return;
              final amountPaise = (amount * 100).round();
              final db = ref.read(appDatabaseProvider);

              await db.fundDao.insertMovement(
                FundMovementsTableCompanion.insert(
                  id: _uuid.v4(),
                  fundId: fund.id,
                  type: type,
                  amountPaise: amountPaise,
                  movementDate: DateTime.now(),
                  note: noteCtrl.text.isEmpty ? const Value.absent() : Value(noteCtrl.text),
                ),
              );

              // Also create a protection entry in entriesTable so it reflects in Dashboard & More waterfall
              final auth = ref.read(authStateProvider).valueOrNull;
              final householdId = auth?.householdId ?? 'local-household';
              final catName = isContrib ? 'To MF for ${fund.name}' : 'Spending for ${fund.name}';
              final activeCats = await db.categoryDao.getAllActive(householdId: householdId);
              var matchingCat = activeCats.firstWhere(
                (c) => c.name.toLowerCase() == catName.toLowerCase(),
                orElse: () => activeCats.firstWhere(
                  (c) => c.kind == 'protection',
                  orElse: () => CategoriesTableData(
                    id: 'cat-protection-default',
                    householdId: householdId,
                    kind: 'protection',
                    name: catName,
                    sortOrder: 99,
                    isDeduction: false,
                    isSystem: false,
                  ),
                ),
              );

              await db.entryDao.insertEntry(
                EntriesTableCompanion.insert(
                  id: _uuid.v4(),
                  householdId: householdId,
                  categoryId: matchingCat.id,
                  kind: 'protection',
                  entryDate: DateTime.now(),
                  amountPaise: amountPaise,
                  note: Value(noteCtrl.text.isEmpty ? 'Fund ${isContrib ? 'Contribution' : 'Withdrawal'}: ${fund.name}' : noteCtrl.text),
                  createdBy: auth?.userId ?? 'local-user',
                  version: const Value(1),
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ),
              );

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${isContrib ? 'Contribution' : 'Withdrawal'} of ₹$amount recorded!'),
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

  Future<void> _deleteFund(
    BuildContext context,
    WidgetRef ref,
    SinkingFundsTableData fund,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Sinking Fund?'),
        content: Text('Remove fund "${fund.name}"? This action soft-deletes the fund reserve.'),
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
      await (db.update(db.sinkingFundsTable)..where((f) => f.id.equals(fund.id)))
          .write(SinkingFundsTableCompanion(archivedAt: Value(DateTime.now())));
      ref.read(syncServiceProvider).triggerSync();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fund "${fund.name}" deleted.'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _showFundMovementsSheet(
      BuildContext context, WidgetRef ref, SinkingFundsTableData fund, List<FundMovementsTableData> movements) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
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
            Text('${fund.name} Movement History', style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Expanded(
              child: movements.isEmpty
                  ? const Center(child: Text('No movements recorded yet'))
                  : ListView.builder(
                      controller: scrollCtrl,
                      itemCount: movements.length,
                      itemBuilder: (_, i) {
                        final m = movements[i];
                        final isContrib = m.type == 'contribution';
                        return ListTile(
                          leading: Icon(
                            isContrib ? Icons.add_circle_outline_rounded : Icons.remove_circle_outline_rounded,
                            color: isContrib ? Colors.green : Colors.red,
                          ),
                          title: Text(isContrib ? 'Contribution' : 'Withdrawal', style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('${m.movementDate.day}/${m.movementDate.month}/${m.movementDate.year}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              MoneyText(Money(m.amountPaise), style: TextStyle(color: isContrib ? Colors.green : Colors.red, fontWeight: FontWeight.w700)),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                onPressed: () => _showEditMovementDialog(context, ref, m),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                                onPressed: () async {
                                  final db = ref.read(appDatabaseProvider);
                                  await (db.delete(db.fundMovementsTable)..where((fm) => fm.id.equals(m.id))).go();
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

  void _showEditMovementDialog(BuildContext context, WidgetRef ref, FundMovementsTableData m) {
    final amountCtrl = TextEditingController(text: (m.amountPaise / 100).toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Edit ${m.type == 'contribution' ? 'Contribution' : 'Withdrawal'}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Amount (₹) *', prefixText: '₹ '),
            ),
          ],
        ),
      ),
      actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final amt = double.tryParse(amountCtrl.text) ?? 0;
              if (amt <= 0) return;

              final db = ref.read(appDatabaseProvider);
              await (db.update(db.fundMovementsTable)..where((fm) => fm.id.equals(m.id)))
                  .write(FundMovementsTableCompanion(
                amountPaise: Value((amt * 100).round()),
              ));

              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// ─── Fund Row Helper ──────────────────────────────────────────────────────────

class _FundRow extends StatelessWidget {
  final String label;
  final Money amount;
  final bool bold;
  const _FundRow(this.label, this.amount, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                  ),
            ),
          ),
          MoneyText(
            amount,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
