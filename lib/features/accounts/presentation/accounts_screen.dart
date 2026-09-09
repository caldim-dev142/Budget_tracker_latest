import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:go_router/go_router.dart';

import '../../../core/utils/money.dart';
import '../../../shared/widgets/money_text.dart';
import '../../../shared/widgets/pressable_scale.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../data/local/database.dart';
import '../../../core/services/sync_service.dart';
import '../../auth/providers/auth_providers.dart';

const _uuid = Uuid();

/// S12 — Accounts & Institutions (Toshl Connections inspired UI)
/// Real DB-backed. Maintains exact database logic, calculations, and mutations.
class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(_activeAccountsProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts & Institutions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Account',
            onPressed: () => _showAddAccountDialog(context, ref),
          ),
        ],
      ),
      body: accountsAsync.when(
        loading: () => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: const [
              SkeletonLoader(width: double.infinity, height: 110, borderRadius: 18),
              SizedBox(height: 16),
              SkeletonLoader(width: double.infinity, height: 80, borderRadius: 18),
              SizedBox(height: 12),
              SkeletonLoader(width: double.infinity, height: 80, borderRadius: 18),
            ],
          ),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: cs.error),
              const SizedBox(height: 12),
              Text('Error loading accounts: $e', style: TextStyle(color: cs.error)),
            ],
          ),
        ),
        data: (accounts) {
          if (accounts.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.account_balance_outlined,
                        size: 56,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No Accounts Connected',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Track your bank accounts and cash in one place.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 24),
                    PressableScale(
                      onTap: () => _showAddAccountDialog(context, ref),
                      child: FilledButton.icon(
                        onPressed: () => _showAddAccountDialog(context, ref),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add Institution Account'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final total = accounts.fold<Money>(
            Money.zero,
            (s, a) => s + Money(a.currentBalancePaise),
          );

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              // Hero Net Worth / Total Available Card
              Card(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      colors: [
                        cs.primaryContainer.withValues(alpha: 0.7),
                        cs.surfaceContainerHigh,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: cs.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.account_balance_wallet_rounded, size: 18, color: cs.primary),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'TOTAL AVAILABLE',
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                      color: cs.onSurfaceVariant,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                    ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${accounts.length} ${accounts.length == 1 ? 'account' : 'accounts'}',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: cs.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      MoneyText(
                        total,
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Section Title
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 10),
                child: Text(
                  'Connected Institutions & Wallets',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurfaceVariant,
                      ),
                ),
              ),

              // Account cards list with staggered animation
              ...accounts.asMap().entries.map((entry) {
                final index = entry.key;
                final account = entry.value;

                return TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 250 + (index * 60)),
                  curve: Curves.easeOutCubic,
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 16 * (1 - value)),
                      child: Opacity(opacity: value, child: child),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: PressableScale(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => _showAccountTransactionsSheet(context, ref, account),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              // Avatar icon container
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: account.type == 'cash'
                                      ? Colors.amber.shade700.withValues(alpha: 0.15)
                                      : cs.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  account.type == 'cash'
                                      ? Icons.payments_rounded
                                      : Icons.account_balance_rounded,
                                  color: account.type == 'cash'
                                      ? Colors.amber.shade800
                                      : cs.primary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Name & metadata
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      account.name,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                          ),
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            color: Colors.green,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          account.type.toUpperCase(),
                                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                color: cs.onSurfaceVariant,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 11,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Balance & Action menu
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  MoneyText(
                                    Money(account.currentBalancePaise),
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  PopupMenuButton<String>(
                                    icon: Icon(Icons.more_vert_rounded, color: cs.onSurfaceVariant, size: 20),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    onSelected: (v) {
                                      if (v == 'edit') {
                                        _showEditAccountDialog(context, ref, account);
                                      } else if (v == 'delete') {
                                        _deactivateAccount(context, ref, account);
                                      }
                                    },
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit_outlined, size: 18),
                                            SizedBox(width: 8),
                                            Text('Edit Balance'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                                            SizedBox(width: 8),
                                            Text('Remove', style: TextStyle(color: Colors.red)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 24),

              // ─── Return Awaited (Receivables) ──────────────────────────────
              _buildReturnAwaitedSection(context, ref),

              const SizedBox(height: 24),

              // ─── To be Paid (Planned Bills) ────────────────────────────────
              _buildToBePaidSection(context, ref),
            ],
          );
        },
      ),
    );
  }

  void _showAddAccountDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final balanceCtrl = TextEditingController(text: '');
    String type = 'bank';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Add Institution Account'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Account Name *',
                  hintText: 'e.g. HDFC Savings',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(value: 'bank', child: Text('Bank Account')),
                  DropdownMenuItem(value: 'cash', child: Text('Cash Wallet')),
                ],
                onChanged: (v) => setState(() => type = v ?? 'bank'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: balanceCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onTap: () {
                  // Select all so user can immediately type new value
                  balanceCtrl.selection = TextSelection(
                    baseOffset: 0,
                    extentOffset: balanceCtrl.text.length,
                  );
                },
                decoration: const InputDecoration(
                  labelText: 'Opening Balance (₹)',
                  hintText: '0',
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

                final balanceRupees = double.tryParse(balanceCtrl.text) ?? 0;
                final balancePaise = (balanceRupees * 100).round();
                final db = ref.read(appDatabaseProvider);
                final auth = ref.read(authStateProvider).valueOrNull;
                final householdId = auth?.householdId ?? 'local';
                final accountId = _uuid.v4();

                await db.accountDao.upsertAccount(
                  AccountsTableCompanion.insert(
                    id: accountId,
                    householdId: householdId,
                    name: name,
                    type: type,
                    currentBalancePaise: Value(balancePaise),
                    isActive: const Value(true),
                    sortOrder: const Value(0),
                  ),
                );

                // If opening balance > 0, create an opening balance entry so it is never lost
                if (balancePaise > 0) {
                  final incomeCats = await (db.select(db.categoriesTable)
                        ..where((c) => c.householdId.equals(householdId) & c.kind.equals('income'))
                        ..limit(1))
                      .get();
                  final catId = incomeCats.isNotEmpty ? incomeCats.first.id : 'inc-05-$householdId';

                  await db.entryDao.insertEntry(
                    EntriesTableCompanion.insert(
                      id: 'ob-$accountId',
                      householdId: householdId,
                      categoryId: catId,
                      kind: 'income',
                      accountId: Value(accountId),
                      entryDate: DateTime.now(),
                      amountPaise: balancePaise,
                      note: Value('Opening Balance - $name'),
                      createdBy: auth?.userId ?? 'user',
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    ),
                  );
                }

                // Immediately trigger background sync so the account appears in PostgreSQL
                ref.read(syncServiceProvider).triggerSync();

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Account "$name" added successfully!'),
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

  void _showEditAccountDialog(
      BuildContext context, WidgetRef ref, AccountsTableData account) {
    final nameCtrl = TextEditingController(text: account.name);
    final balanceCtrl = TextEditingController(
      text: (account.currentBalancePaise / 100).toStringAsFixed(2),
    );
    String type = account.type;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Edit Account — ${account.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Account Name *',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(value: 'bank', child: Text('Bank Account')),
                  DropdownMenuItem(value: 'cash', child: Text('Cash Wallet')),
                  DropdownMenuItem(value: 'investment', child: Text('Investment')),
                ],
                onChanged: (v) => setState(() => type = v ?? 'bank'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: balanceCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Current Balance (₹)',
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

                final balancePaise =
                    ((double.tryParse(balanceCtrl.text) ?? 0) * 100).round();
                final db = ref.read(appDatabaseProvider);
                await (db.update(db.accountsTable)..where((a) => a.id.equals(account.id)))
                    .write(AccountsTableCompanion(
                      name: Value(name),
                      type: Value(type),
                      currentBalancePaise: Value(balancePaise),
                    ));

                ref.read(syncServiceProvider).triggerSync();

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Account "$name" updated!'),
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

  Future<void> _deactivateAccount(
      BuildContext context, WidgetRef ref, AccountsTableData account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove Account'),
        content: Text('Are you sure you want to remove "${account.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final db = ref.read(appDatabaseProvider);
      await (db.update(db.accountsTable)
            ..where((a) => a.id.equals(account.id)))
          .write(const AccountsTableCompanion(isActive: Value(false)));
      ref.read(syncServiceProvider).triggerSync();
    }
  }

  void _showAccountTransactionsSheet(
    BuildContext context,
    WidgetRef ref,
    AccountsTableData account,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Consumer(
        builder: (ctx, ref, _) {
          final entriesAsync = ref.watch(_accountEntriesProvider(account.id));

          return DraggableScrollableSheet(
            initialChildSize: 0.7,
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
                              account.name,
                              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Balance: ${MoneyFormatter.formatCompact(Money(account.currentBalancePaise))}',
                              style: TextStyle(color: Theme.of(ctx).colorScheme.onSurfaceVariant, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        tooltip: 'Edit Account',
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showEditAccountDialog(context, ref, account);
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(height: 24),
                Expanded(
                  child: entriesAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                    data: (txns) => txns.isEmpty
                        ? const Center(child: Text('No transactions for this account yet'))
                        : ListView.builder(
                            controller: scrollCtrl,
                            itemCount: txns.length,
                            itemBuilder: (_, i) {
                              final t = txns[i];
                              final isIncome = t.kind == 'income';
                              return ListTile(
                                leading: Icon(
                                  isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                  color: isIncome ? Colors.green : Colors.red,
                                ),
                                title: Text(t.note?.isNotEmpty == true ? t.note! : account.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text('${t.entryDate.day}/${t.entryDate.month}/${t.entryDate.year}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      MoneyFormatter.formatCompact(Money(t.amountPaise)),
                                      style: TextStyle(color: isIncome ? Colors.green : Colors.red, fontWeight: FontWeight.w700),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 18),
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        context.push('/transactions/${t.id}/edit');
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                                      onPressed: () async {
                                        final db = ref.read(appDatabaseProvider);
                                        await (db.delete(db.entriesTable)..where((e) => e.id.equals(t.id))).go();
                                        if (ctx.mounted) Navigator.pop(ctx);
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

final _activeAccountsProvider = StreamProvider<List<AccountsTableData>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final auth = ref.watch(authStateProvider).valueOrNull;
  final householdId = auth?.householdId ?? 'local';
  return db.accountDao.watchActiveAccounts(householdId: householdId).map((list) {
    final seen = <String>{};
    final deduped = <AccountsTableData>[];
    // Sort so accounts with positive balance come first
    final sorted = List<AccountsTableData>.from(list)
      ..sort((a, b) {
        if (a.currentBalancePaise != b.currentBalancePaise) {
          return b.currentBalancePaise.compareTo(a.currentBalancePaise);
        }
        return a.sortOrder.compareTo(b.sortOrder);
      });
    for (final a in sorted) {
      final key = a.name.trim().toLowerCase();
      if (seen.add(key)) {
        deduped.add(a);
      }
    }
    return deduped;
  });
});

final _accountEntriesProvider = StreamProvider.family<List<EntriesTableData>, String>((ref, accountId) {
  final db = ref.watch(appDatabaseProvider);
  return (db.select(db.entriesTable)..where((e) => e.accountId.equals(accountId))).watch();
});

final _receivablesProvider = StreamProvider<List<ReceivablesTableData>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final auth = ref.watch(authStateProvider).valueOrNull;
  final householdId = auth?.householdId ?? 'local';
  return (db.select(db.receivablesTable)..where((r) => r.status.equals('open') & r.householdId.equals(householdId))).watch();
});

final _plannedBillsProvider = StreamProvider<List<PlannedBillsTableData>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final auth = ref.watch(authStateProvider).valueOrNull;
  final householdId = auth?.householdId ?? 'local';
  return (db.select(db.plannedBillsTable)..where((b) => b.isPaid.equals(false) & b.householdId.equals(householdId))).watch();
});

extension on AccountsScreen {
  Widget _buildReturnAwaitedSection(BuildContext context, WidgetRef ref) {
    final receivablesAsync = ref.watch(_receivablesProvider);
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.call_made_rounded, color: Colors.orange.shade700, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Return Awaited (Receivables)',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
              onPressed: () => _showAddReceivableDialog(context, ref),
              tooltip: 'Add Receivable',
            ),
          ],
        ),
        const SizedBox(height: 6),
        receivablesAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('Error loading receivables: $e'),
          data: (items) {
            if (items.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('No open receivables', style: TextStyle(color: cs.onSurfaceVariant)),
                      TextButton.icon(
                        onPressed: () => _showAddReceivableDialog(context, ref),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Add Lent Money'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final totalPaise = items.fold<int>(0, (sum, i) => sum + i.amountPaise);

            return Card(
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Total Return Awaited', style: TextStyle(fontWeight: FontWeight.w600)),
                    trailing: MoneyText(
                      Money(totalPaise),
                      style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ),
                  const Divider(height: 1),
                  ...items.map((item) => ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange.shade100,
                          child: Icon(Icons.person_outline_rounded, color: Colors.orange.shade900, size: 20),
                        ),
                        title: Text(item.personName, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: const Text('Status: Open Receivable'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            MoneyText(Money(item.amountPaise), style: const TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(width: 6),
                            IconButton(
                              icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 22),
                              tooltip: 'Mark as Returned',
                              onPressed: () async {
                                final db = ref.read(appDatabaseProvider);
                                await db.borrowLendDao.settleReceivable(item.id);
                                ref.read(syncServiceProvider).triggerSync();
                              },
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildToBePaidSection(BuildContext context, WidgetRef ref) {
    final billsAsync = ref.watch(_plannedBillsProvider);
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.call_received_rounded, color: Colors.red.shade700, size: 20),
                const SizedBox(width: 8),
                Text(
                  'To be Paid (Planned Bills)',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
              onPressed: () => _showAddPlannedBillDialog(context, ref),
              tooltip: 'Add Planned Bill',
            ),
          ],
        ),
        const SizedBox(height: 6),
        billsAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('Error loading planned bills: $e'),
          data: (items) {
            if (items.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('No upcoming planned bills', style: TextStyle(color: cs.onSurfaceVariant)),
                      TextButton.icon(
                        onPressed: () => _showAddPlannedBillDialog(context, ref),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Add Bill'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final totalPaise = items.fold<int>(0, (sum, i) => sum + i.amountPaise);

            return Card(
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Total To be Paid', style: TextStyle(fontWeight: FontWeight.w600)),
                    trailing: MoneyText(
                      Money(totalPaise),
                      style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ),
                  const Divider(height: 1),
                  ...items.map((item) => ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.red.shade100,
                          child: Icon(Icons.receipt_long_rounded, color: Colors.red.shade900, size: 20),
                        ),
                        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: const Text('Status: Pending Payment'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            MoneyText(Money(item.amountPaise), style: const TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(width: 6),
                            IconButton(
                              icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 22),
                              tooltip: 'Mark as Paid',
                              onPressed: () async {
                                final db = ref.read(appDatabaseProvider);
                                await db.borrowLendDao.settlePlannedBill(item.id);
                                ref.read(syncServiceProvider).triggerSync();
                              },
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  void _showAddReceivableDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add Return Awaited (Lent Money)'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Person / Beneficiary Name *',
                hintText: 'e.g. John Doe, Deposit',
              ),
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
              if (name.isEmpty) return;

              final amountPaise = ((double.tryParse(amountCtrl.text) ?? 0) * 100).round();
              if (amountPaise <= 0) return;

              final db = ref.read(appDatabaseProvider);
              final auth = ref.read(authStateProvider).valueOrNull;
              final householdId = auth?.householdId ?? 'local';

              await db.borrowLendDao.upsertReceivable(
                householdId: householdId,
                personName: name,
                amountPaise: amountPaise,
              );
              ref.read(syncServiceProvider).triggerSync();

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Receivable "$name" added!'),
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

  void _showAddPlannedBillDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add Planned Bill (To be Paid)'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Bill Name *',
                hintText: 'e.g. Electric Bill, School Fees',
              ),
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
              if (name.isEmpty) return;

              final amountPaise = ((double.tryParse(amountCtrl.text) ?? 0) * 100).round();
              if (amountPaise <= 0) return;

              final db = ref.read(appDatabaseProvider);
              final auth = ref.read(authStateProvider).valueOrNull;
              final householdId = auth?.householdId ?? 'local';

              await db.borrowLendDao.upsertPlannedBill(
                householdId: householdId,
                name: name,
                amountPaise: amountPaise,
              );
              ref.read(syncServiceProvider).triggerSync();

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Planned Bill "$name" added!'),
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
