import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' hide Column;

import '../../../core/utils/money.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../core/utils/input_formatters.dart';
import '../../../shared/widgets/money_text.dart';
import '../../../shared/widgets/pressable_scale.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../data/local/database.dart';
import '../../../core/services/sync_service.dart';
import '../../auth/providers/auth_providers.dart';

const _uuid = Uuid();

// ─── Providers ───────────────────────────────────────────────────────────────

final _activeCardsProvider = StreamProvider<List<CreditCardsTableData>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final authState = ref.watch(authStateProvider).valueOrNull;
  final householdId = authState?.householdId ?? 'local';
  return db.cardDao.watchActiveCards(householdId: householdId);
});

final _cardTransactionsProvider =
    StreamProvider.family<List<CardTransactionsTableData>, String>((ref, cardId) {
  final db = ref.watch(appDatabaseProvider);
  return db.cardDao.watchTransactionsForCard(cardId);
});

/// S11 — Credit Cards (doc 09 S11, doc 01 §9) — real DB-backed.
class CardsScreen extends ConsumerWidget {
  const CardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsAsync = ref.watch(_activeCardsProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Credit Cards'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Card',
            onPressed: () => _showAddCardDialog(context, ref),
          ),
        ],
      ),
      body: cardsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: SkeletonLoader(width: double.infinity, height: 140, borderRadius: 18),
        ),
        error: (e, _) => Center(child: Text(AppFeedback.formatError(e))),
        data: (cards) {
          if (cards.isEmpty) {
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
                        Icons.credit_card_off_outlined,
                        size: 56,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No Credit Cards Added',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Track card ledgers and outstanding balances in one place.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 24),
                    PressableScale(
                      onTap: () => _showAddCardDialog(context, ref),
                      child: FilledButton.icon(
                        onPressed: () => _showAddCardDialog(context, ref),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add Credit Card'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            itemCount: cards.length,
            itemBuilder: (_, i) => _CreditCardWidget(
              card: cards[i],
              onRecordPayment: () => _showRecordPaymentDialog(context, ref, cards[i]),
              onViewTransactions: () =>
                  _showTransactionsSheet(context, ref, cards[i]),
              onEdit: () => _showEditCardDialog(context, ref, cards[i]),
              onDelete: () => _deleteCard(context, ref, cards[i]),
            ),
          );
        },
      ),
    );
  }

  void _showAddCardDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final outstandingCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add Credit Card'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Card Name *',
                hintText: 'e.g. HDFC Regalia',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: outstandingCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [AppInputFormatters.positiveDecimal()],
              decoration: const InputDecoration(
                labelText: 'Opening / Current Outstanding (₹)',
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
                AppFeedback.showWarning(context, 'Please enter a card name.');
                return;
              }

              try {
                final outstanding =
                    ((double.tryParse(outstandingCtrl.text) ?? 0) * 100).round();
                final db = ref.read(appDatabaseProvider);
                final auth = ref.read(authStateProvider).valueOrNull;
                final householdId = auth?.householdId ?? 'local';

                await db.cardDao.upsertCard(
                  CreditCardsTableCompanion.insert(
                    id: _uuid.v4(),
                    householdId: householdId,
                    name: name,
                    previousOutstandingPaise: Value(outstanding),
                    isActive: const Value(true),
                  ),
                );
                ref.read(syncServiceProvider).triggerSync();

                if (context.mounted) {
                  Navigator.pop(context);
                  AppFeedback.showSuccess(context, 'Card "$name" added!');
                }
              } catch (e) {
                if (context.mounted) {
                  AppFeedback.showError(context, 'Failed to add card', error: e);
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditCardDialog(
      BuildContext context, WidgetRef ref, CreditCardsTableData card) {
    final nameCtrl = TextEditingController(text: card.name);
    final outstandingCtrl = TextEditingController(
      text: (card.previousOutstandingPaise / 100).toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Edit Card — ${card.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Card Name *',
                hintText: 'e.g. HDFC Regalia',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: outstandingCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [AppInputFormatters.positiveDecimal()],
              decoration: const InputDecoration(
                labelText: 'Outstanding Balance (₹)',
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
                AppFeedback.showWarning(context, 'Please enter a card name.');
                return;
              }

              try {
                final outstanding =
                    ((double.tryParse(outstandingCtrl.text) ?? 0) * 100).round();
                final db = ref.read(appDatabaseProvider);

                await (db.update(db.creditCardsTable)..where((c) => c.id.equals(card.id)))
                    .write(CreditCardsTableCompanion(
                      name: Value(name),
                      previousOutstandingPaise: Value(outstanding),
                    ));
                ref.read(syncServiceProvider).triggerSync();

                if (context.mounted) {
                  Navigator.pop(context);
                  AppFeedback.showSuccess(context, 'Card "$name" updated!');
                }
              } catch (e) {
                if (context.mounted) {
                  AppFeedback.showError(context, 'Failed to update card', error: e);
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showRecordPaymentDialog(
      BuildContext context, WidgetRef ref, CreditCardsTableData card) {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Record Payment — ${card.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [AppInputFormatters.positiveDecimal()],
              decoration: const InputDecoration(
                labelText: 'Payment Amount (₹) *',
                hintText: '0.00',
                prefixText: '₹ ',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'e.g. Bank transfer, Bill pay',
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
              if (amount <= 0) {
                AppFeedback.showWarning(context, 'Please enter a payment amount greater than zero.');
                return;
              }

              try {
                final amountPaise = (amount * 100).round();
                final db = ref.read(appDatabaseProvider);
                final cleanNote = noteCtrl.text.trim();

                // Insert transaction (payment is negative, reducing current outstanding)
                await db.cardDao.insertTransaction(
                  CardTransactionsTableCompanion.insert(
                    id: _uuid.v4(),
                    cardId: card.id,
                    txnDate: DateTime.now(),
                    description: cleanNote.isEmpty ? 'Payment' : cleanNote,
                    amountPaise: -amountPaise,
                  ),
                );
                ref.read(syncServiceProvider).triggerSync();

                if (context.mounted) {
                  Navigator.pop(context);
                  AppFeedback.showSuccess(context, 'Payment of ₹${amount.toStringAsFixed(2)} recorded!');
                }
              } catch (e) {
                if (context.mounted) {
                  AppFeedback.showError(context, 'Failed to record payment', error: e);
                }
              }
            },
            child: const Text('Record'),
          ),
        ],
      ),
    );
  }

  void _showTransactionsSheet(
      BuildContext context, WidgetRef ref, CreditCardsTableData card) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _CardTransactionsSheet(card: card),
    );
  }

  Future<void> _deleteCard(
      BuildContext context, WidgetRef ref, CreditCardsTableData card) async {
    final confirmed = await AppFeedback.showConfirmDialog(
      context,
      title: 'Remove Card',
      message: 'Are you sure you want to remove "${card.name}"?',
      confirmLabel: 'Remove',
      isDestructive: true,
    );
    if (confirmed == true) {
      final db = ref.read(appDatabaseProvider);
      await (db.update(db.creditCardsTable)
            ..where((c) => c.id.equals(card.id)))
          .write(const CreditCardsTableCompanion(isActive: Value(false)));
      ref.read(syncServiceProvider).triggerSync();
      if (context.mounted) {
        AppFeedback.showSuccess(context, 'Card "${card.name}" removed.');
      }
    }
  }
}

// ─── Card Widget ──────────────────────────────────────────────────────────────

class _CreditCardWidget extends ConsumerWidget {
  final CreditCardsTableData card;
  final VoidCallback onRecordPayment;
  final VoidCallback onViewTransactions;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CreditCardWidget({
    required this.card,
    required this.onRecordPayment,
    required this.onViewTransactions,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    // `previousOutstandingPaise` is the card's fixed opening balance (every other reader —
    // more_screen.dart, notifications_screen.dart, dashboard_providers.dart, and the backend's
    // reports.service.ts — computes the live outstanding as previousOutstandingPaise + sum of
    // transactions). This screen previously displayed the raw stored field with no transaction
    // sum at all, so it never reflected a recorded payment (data-persistence audit fix,
    // 2026-09-17). Computed the same way as every other consumer for consistency.
    final txnsAsync = ref.watch(_cardTransactionsProvider(card.id));
    final delta = txnsAsync.valueOrNull?.fold<int>(0, (s, t) => s + t.amountPaise) ?? 0;
    final liveOutstanding = (card.previousOutstandingPaise + delta).clamp(0, 999999999);
    return PressableScale(
      borderRadius: BorderRadius.circular(18),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
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
                    child: Icon(Icons.credit_card_rounded, color: cs.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      card.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'edit') {
                        onEdit();
                      } else if (v == 'delete') {
                        onDelete();
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Edit Card'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Remove Card', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Outstanding Balance',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const SizedBox(height: 4),
                      MoneyText(
                        Money(liveOutstanding),
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(color: cs.error, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onRecordPayment,
                      icon: const Icon(Icons.payment_rounded, size: 18),
                      label: const Text('Record Payment'),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: onViewTransactions,
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('History'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Card Transactions Sheet ──────────────────────────────────────────────────

class _CardTransactionsSheet extends ConsumerWidget {
  final CreditCardsTableData card;
  const _CardTransactionsSheet({required this.card});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txnsAsync = ref.watch(_cardTransactionsProvider(card.id));

    return DraggableScrollableSheet(
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
                color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '${card.name} Ledger History',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: txnsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(AppFeedback.formatError(e))),
              data: (txns) {
                if (txns.isEmpty) {
                  return const Center(child: Text('No transactions recorded yet'));
                }
                return ListView.builder(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: txns.length,
                  itemBuilder: (_, i) {
                    final t = txns[i];
                    final isPay = t.amountPaise < 0;
                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (isPay
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.error)
                              .withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isPay ? Icons.payment_rounded : Icons.shopping_cart_outlined,
                          color: isPay
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.error,
                          size: 20,
                        ),
                      ),
                      title: Text(t.description, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        '${t.txnDate.day}/${t.txnDate.month}/${t.txnDate.year}',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          MoneyText(
                            Money(t.amountPaise.abs()),
                            signed: false,
                            style: TextStyle(
                              color: isPay
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.error,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            onPressed: () => _showEditCardTxnDialog(context, ref, card, t),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline_rounded, size: 18, color: Theme.of(context).colorScheme.error),
                            onPressed: () async {
                              final confirm = await AppFeedback.showConfirmDialog(
                                context,
                                title: 'Delete Transaction',
                                message: 'Delete "${t.description}"?',
                                confirmLabel: 'Delete',
                                isDestructive: true,
                              );

                              if (confirm == true) {
                                final db = ref.read(appDatabaseProvider);
                                await db.syncQueueDao.enqueueDeletion(entity: 'card_transaction', entityId: t.id);
                                await (db.delete(db.cardTransactionsTable)..where((ct) => ct.id.equals(t.id))).go();
                                // Do NOT also adjust creditCardsTable.previousOutstandingPaise here:
                                // it's the card's fixed opening balance, and every reader (this
                                // screen, dashboard, more/notifications screens, backend reports)
                                // derives the live outstanding as previousOutstandingPaise + sum of
                                // remaining transactions — which already reflects this deletion since
                                // the row above is gone. Mutating it too double-counted the deleted
                                // transaction everywhere else that reads this card (data-persistence
                                // audit fix, 2026-09-17).
                                ref.read(syncServiceProvider).triggerSync();
                                if (context.mounted) {
                                  AppFeedback.showSuccess(context, 'Transaction deleted.');
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showEditCardTxnDialog(BuildContext context, WidgetRef ref, CreditCardsTableData card, CardTransactionsTableData t) {
    final descCtrl = TextEditingController(text: t.description);
    final amountCtrl = TextEditingController(text: (t.amountPaise.abs() / 100).toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Card Transaction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description *',
                hintText: 'e.g. Grocery shopping',
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
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final desc = descCtrl.text.trim();
              final amt = double.tryParse(amountCtrl.text) ?? 0;
              if (desc.isEmpty) {
                AppFeedback.showWarning(context, 'Please enter a description.');
                return;
              }
              if (amt <= 0) {
                AppFeedback.showWarning(context, 'Please enter an amount greater than zero.');
                return;
              }

              final isPay = t.amountPaise < 0;
              final newPaise = (amt * 100).round() * (isPay ? -1 : 1);

              final db = ref.read(appDatabaseProvider);
              await (db.update(db.cardTransactionsTable)..where((ct) => ct.id.equals(t.id)))
                  .write(CardTransactionsTableCompanion(
                description: Value(desc),
                amountPaise: Value(newPaise),
              ));
              // Do NOT also adjust creditCardsTable.previousOutstandingPaise here: it's the
              // card's fixed opening balance, and every reader (this screen, dashboard,
              // more/notifications screens, backend reports) derives the live outstanding as
              // previousOutstandingPaise + sum of transactions, which already reflects this
              // edited amount via the row above. Mutating it too double-counted the delta
              // everywhere else that reads this card (data-persistence audit fix, 2026-09-17).
              ref.read(syncServiceProvider).triggerSync();

              if (context.mounted) {
                Navigator.pop(context);
                AppFeedback.showSuccess(context, 'Transaction updated!');
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
