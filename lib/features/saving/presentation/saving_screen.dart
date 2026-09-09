import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' hide Column;

import '../../../core/utils/money.dart';
import '../../../shared/widgets/money_text.dart';
import '../../../shared/widgets/pressable_scale.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../data/local/database.dart';
import '../../auth/providers/auth_providers.dart';
import '../../../core/services/sync_service.dart';

const _uuid = Uuid();

// ─── Providers ───────────────────────────────────────────────────────────────

final _activeGoalsProvider = StreamProvider<List<SavingGoalsTableData>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final authState = ref.watch(authStateProvider).valueOrNull;
  final householdId = authState?.householdId ?? 'local';
  return db.goalDao.watchActiveGoals(householdId: householdId);
});

final _goalContributionsProvider =
    StreamProvider.family<List<GoalContributionsTableData>, String>((ref, goalId) {
  final db = ref.watch(appDatabaseProvider);
  return db.goalDao.watchContributionsForGoal(goalId);
});

/// S10 — Saving Goals (doc 09 S10, doc 01 §5) — real DB-backed.
class SavingScreen extends ConsumerWidget {
  const SavingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(_activeGoalsProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saving Goals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddGoalDialog(context, ref),
            tooltip: 'Add Goal',
          ),
        ],
      ),
      body: goalsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: SkeletonLoader(width: double.infinity, height: 120, borderRadius: 18),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (goals) {
          if (goals.isEmpty) {
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
                        Icons.savings_outlined,
                        size: 56,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No Saving Goals Yet',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Build your wealth by tracking retirement, vacation, or custom goals.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 24),
                    PressableScale(
                      onTap: () => _showAddGoalDialog(context, ref),
                      child: FilledButton.icon(
                        onPressed: () => _showAddGoalDialog(context, ref),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add Saving Goal'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Group goals by bucket
          final Map<String, List<SavingGoalsTableData>> grouped = {};
          for (final g in goals) {
            grouped.putIfAbsent(g.bucket, () => []).add(g);
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            children: grouped.entries.expand((entry) {
              return [
                _SectionHeader(_bucketLabel(entry.key)),
                ...entry.value.map((g) => _GoalCard(goal: g)),
              ];
            }).toList(),
          );
        },
      ),
    );
  }

  String _bucketLabel(String bucket) {
    return switch (bucket) {
      'retirement' => 'For Retirement',
      'children' => 'For Children',
      _ => 'Other Goals',
    };
  }

  void _showAddGoalDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    final monthlyCtrl = TextEditingController(text: '0');
    String bucket = 'other_goals';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Add Saving Goal'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Goal Name *',
                    hintText: 'e.g. Dream Home Fund',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: bucket,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: const [
                    DropdownMenuItem(value: 'retirement', child: Text('Retirement')),
                    DropdownMenuItem(value: 'children', child: Text('Children')),
                    DropdownMenuItem(value: 'other_goals', child: Text('Other Goals')),
                  ],
                  onChanged: (v) => setState(() => bucket = v ?? 'other_goals'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: targetCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Target Amount (₹, optional)',
                    prefixText: '₹ ',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: monthlyCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Monthly Budget (₹)',
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

                final targetPaise = targetCtrl.text.isEmpty
                    ? null
                    : ((double.tryParse(targetCtrl.text) ?? 0) * 100).round();
                final monthlyPaise =
                    ((double.tryParse(monthlyCtrl.text) ?? 0) * 100).round();

                final db = ref.read(appDatabaseProvider);
                final auth = ref.read(authStateProvider).valueOrNull;
                final householdId = auth?.householdId ?? 'local-household';

                await db.goalDao.upsertGoal(
                  SavingGoalsTableCompanion.insert(
                    id: _uuid.v4(),
                    householdId: householdId,
                    bucket: bucket,
                    name: name,
                    targetPaise: targetPaise == null
                        ? const Value.absent()
                        : Value(targetPaise),
                    monthlyBudgetPaise: Value(monthlyPaise),
                  ),
                );

                // Auto-create matching saving category for Add Entry (+) picker
                final existingCats = await db.categoryDao.getAllActive();
                if (!existingCats.any((c) => c.name.toLowerCase() == name.toLowerCase())) {
                  await db.categoryDao.upsertAll([
                    CategoriesTableCompanion.insert(
                      id: _uuid.v4(),
                      householdId: householdId,
                      kind: 'saving',
                      groupCode: Value(bucket),
                      name: name,
                      isDeduction: const Value(false),
                      isSystem: const Value(false),
                      sortOrder: const Value(150),
                    ),
                  ]);
                }

                ref.read(syncServiceProvider).triggerSync();

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Goal "$name" created!'),
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

  void _showEditGoalDialog(BuildContext context, WidgetRef ref, SavingGoalsTableData goal) {
    final nameCtrl = TextEditingController(text: goal.name);
    final targetCtrl = TextEditingController(
      text: goal.targetPaise != null ? (goal.targetPaise! / 100).toStringAsFixed(0) : '',
    );
    final monthlyCtrl = TextEditingController(
      text: (goal.monthlyBudgetPaise / 100).toStringAsFixed(0),
    );
    String bucket = goal.bucket;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Edit Goal — ${goal.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Goal Name *',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: bucket,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: const [
                    DropdownMenuItem(value: 'retirement', child: Text('Retirement')),
                    DropdownMenuItem(value: 'children', child: Text('Children')),
                    DropdownMenuItem(value: 'other_goals', child: Text('Other Goals')),
                  ],
                  onChanged: (v) => setState(() => bucket = v ?? 'other_goals'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: targetCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Target Amount (₹, optional)',
                    prefixText: '₹ ',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: monthlyCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Monthly Budget (₹)',
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

                final targetPaise = targetCtrl.text.isEmpty
                    ? null
                    : ((double.tryParse(targetCtrl.text) ?? 0) * 100).round();
                final monthlyPaise =
                    ((double.tryParse(monthlyCtrl.text) ?? 0) * 100).round();

                final db = ref.read(appDatabaseProvider);

                await (db.update(db.savingGoalsTable)..where((g) => g.id.equals(goal.id)))
                    .write(SavingGoalsTableCompanion(
                      name: Value(name),
                      bucket: Value(bucket),
                      targetPaise: targetPaise == null
                          ? const Value.absent()
                          : Value(targetPaise),
                      monthlyBudgetPaise: Value(monthlyPaise),
                    ));

                ref.read(syncServiceProvider).triggerSync();

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Goal "$name" updated!'),
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
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 10),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

// ─── Goal Card ────────────────────────────────────────────────────────────────

class _GoalCard extends ConsumerWidget {
  final SavingGoalsTableData goal;
  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contribsAsync = ref.watch(_goalContributionsProvider(goal.id));
    final cs = Theme.of(context).colorScheme;

    return contribsAsync.when(
      loading: () => const Card(child: Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator())),
      error: (e, _) => Card(child: Text('Error: $e')),
      data: (contribs) {
        final lifetimePaise = contribs.fold<int>(0, (s, c) => s + c.amountPaise);
        final lifetime = Money(lifetimePaise);
        final target = goal.targetPaise == null ? null : Money(goal.targetPaise!);
        final monthly = Money(goal.monthlyBudgetPaise);

        double? progress;
        if (target != null && !target.isZero) {
          progress = (lifetimePaise / target.paise).clamp(0.0, 1.0);
        }

        return PressableScale(
          borderRadius: BorderRadius.circular(18),
          child: Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.flag_rounded, size: 20, color: cs.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          goal.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      MoneyText(
                        monthly,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Text(
                        '/mo',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (v) {
                          if (v == 'history') {
                            _showGoalHistorySheet(context, ref, goal, contribs);
                          } else if (v == 'edit') {
                            const SavingScreen()._showEditGoalDialog(context, ref, goal);
                          } else if (v == 'delete') {
                            _deleteGoal(context, ref, goal);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'history',
                            child: Row(
                              children: [
                                Icon(Icons.history_rounded, size: 18),
                                SizedBox(width: 8),
                                Text('History'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 18),
                                SizedBox(width: 8),
                                Text('Edit Goal'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete Goal', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (target != null) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: cs.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${MoneyFormatter.formatCompact(lifetime)} of ${MoneyFormatter.formatCompact(target)} · ${((progress ?? 0) * 100).toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ] else ...[
                    const SizedBox(height: 6),
                    Text(
                      'Contributed: ${MoneyFormatter.formatCompact(lifetime)}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showAddContributionDialog(context, ref, goal),
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: const Text('Add Contribution'),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.archive_outlined),
                        tooltip: 'Archive Goal',
                        onPressed: () => _archiveGoal(context, ref, goal),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAddContributionDialog(
    BuildContext context,
    WidgetRef ref,
    SavingGoalsTableData goal,
  ) {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Add Contribution — ${goal.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount (₹) *',
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
              final db = ref.read(appDatabaseProvider);

              await db.goalDao.insertContribution(
                GoalContributionsTableCompanion.insert(
                  id: _uuid.v4(),
                  goalId: goal.id,
                  amountPaise: (amount * 100).round(),
                  contributionDate: DateTime.now(),
                  note: noteCtrl.text.isEmpty
                      ? const Value.absent()
                      : Value(noteCtrl.text),
                ),
              );

              ref.read(syncServiceProvider).triggerSync();

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('₹$amount contributed to ${goal.name}!'),
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

  Future<void> _archiveGoal(
      BuildContext context, WidgetRef ref, SavingGoalsTableData goal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Archive Goal'),
        content: Text('Archive "${goal.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final db = ref.read(appDatabaseProvider);
      await (db.update(db.savingGoalsTable)
            ..where((g) => g.id.equals(goal.id)))
          .write(SavingGoalsTableCompanion(archivedAt: Value(DateTime.now())));
      ref.read(syncServiceProvider).triggerSync();
    }
  }

  Future<void> _deleteGoal(
      BuildContext context, WidgetRef ref, SavingGoalsTableData goal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Saving Goal?'),
        content: Text('Remove goal "${goal.name}"?'),
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

    if (confirmed == true) {
      final db = ref.read(appDatabaseProvider);
      await (db.update(db.savingGoalsTable)..where((g) => g.id.equals(goal.id)))
          .write(SavingGoalsTableCompanion(archivedAt: Value(DateTime.now())));
      ref.read(syncServiceProvider).triggerSync();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Goal "${goal.name}" deleted.'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _showGoalHistorySheet(
      BuildContext context, WidgetRef ref, SavingGoalsTableData goal, List<GoalContributionsTableData> contribs) {
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
            Text('${goal.name} Contribution History', style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Expanded(
              child: contribs.isEmpty
                  ? const Center(child: Text('No contributions recorded yet'))
                  : ListView.builder(
                      controller: scrollCtrl,
                      itemCount: contribs.length,
                      itemBuilder: (_, i) {
                        final c = contribs[i];
                        return ListTile(
                          leading: const Icon(Icons.savings_rounded, color: Colors.blue),
                          title: const Text('Contribution', style: TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('${c.contributionDate.day}/${c.contributionDate.month}/${c.contributionDate.year}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              MoneyText(Money(c.amountPaise), style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w700)),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                onPressed: () => _showEditContributionDialog(context, ref, c),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                                onPressed: () async {
                                  final db = ref.read(appDatabaseProvider);
                                  await (db.delete(db.goalContributionsTable)..where((gc) => gc.id.equals(c.id))).go();
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

  void _showEditContributionDialog(BuildContext context, WidgetRef ref, GoalContributionsTableData c) {
    final amountCtrl = TextEditingController(text: (c.amountPaise / 100).toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Contribution'),
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
              await (db.update(db.goalContributionsTable)..where((gc) => gc.id.equals(c.id)))
                  .write(GoalContributionsTableCompanion(
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
