import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' hide Column;

import '../../../data/local/database.dart';
import '../../../shared/widgets/pressable_scale.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../../auth/providers/auth_providers.dart';

class NotificationAlert {
  final String id;
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final String time;
  final String path;

  const NotificationAlert({
    required this.id,
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    required this.time,
    required this.path,
  });
}

final dismissedNotificationsProvider = StateProvider<Set<String>>((ref) => {});

final dynamicNotificationsProvider = StreamProvider<List<NotificationAlert>>((ref) async* {
  final db = ref.watch(appDatabaseProvider);
  final ym = ref.watch(selectedMonthProvider);
  final ymStr = ym.toString();
  final dismissed = ref.watch(dismissedNotificationsProvider);
  final authState = ref.watch(authStateProvider).valueOrNull;
  final householdId = authState?.householdId ?? 'local';

  // Stream-based reactivity listening to entry updates
  await for (final _ in db.entryDao.watchMonth(ymStr, householdId: householdId)) {
    final alerts = <NotificationAlert>[];

    // 1. Budget & Over-spending Alerts
    final categories = await (db.select(db.categoriesTable)..where((c) => c.householdId.equals(householdId))).get();
    final budgets = await (db.select(db.budgetsTable)..where((b) {
      final cond = b.yearMonth.equals(ymStr) & b.householdId.equals(householdId);
      return cond;
    })).get();
    final entries = await db.entryDao.getMonth(ymStr, householdId: householdId);

    for (final cat in categories) {
      final matchingBudget = budgets.where((b) => b.categoryId == cat.id);
      if (matchingBudget.isEmpty) continue;
      final budgetPaise = matchingBudget.first.amountPaise;
      if (budgetPaise <= 0) continue;

      final catSpentPaise = entries
          .where((e) => e.categoryId == cat.id && e.kind == 'spending')
          .fold<int>(0, (sum, e) => sum + e.amountPaise);

      final pct = (catSpentPaise / budgetPaise) * 100;
      if (pct >= 100) {
        alerts.add(NotificationAlert(
          id: 'overbudget_${cat.id}',
          title: 'Over Budget Alert',
          message: '${cat.name} spending has reached ${pct.toStringAsFixed(0)}% of its ₹${(budgetPaise / 100).toStringAsFixed(0)} monthly limit.',
          icon: Icons.error_outline_rounded,
          color: Colors.redAccent,
          time: 'Active Month',
          path: '/budget',
        ));
      } else if (pct >= 80) {
        alerts.add(NotificationAlert(
          id: 'nearbudget_${cat.id}',
          title: 'Near Budget Limit',
          message: '${cat.name} is at ${pct.toStringAsFixed(0)}% of its ₹${(budgetPaise / 100).toStringAsFixed(0)} monthly budget.',
          icon: Icons.warning_amber_rounded,
          color: Colors.orange,
          time: 'Active Month',
          path: '/budget',
        ));
      }
    }

    // 2. Credit Card Outstanding Alerts
    final cards = await db.cardDao.watchActiveCards(householdId: householdId).first;
    for (final card in cards) {
      final txns = await (db.select(db.cardTransactionsTable)..where((t) => t.cardId.equals(card.id))).get();
      final delta = txns.fold<int>(0, (s, t) => s + t.amountPaise);
      final totalCcPaise = card.previousOutstandingPaise + delta;
      if (totalCcPaise > 0) {
        alerts.add(NotificationAlert(
          id: 'card_${card.id}',
          title: 'Credit Card Outstanding',
          message: '${card.name} has an outstanding balance of ₹${(totalCcPaise / 100).toStringAsFixed(0)}.',
          icon: Icons.payment_rounded,
          color: Colors.blue,
          time: 'Current',
          path: '/more/cards',
        ));
      }
    }

    // 3. Receivables (Return Awaited) Alerts
    final receivables = await (db.select(db.receivablesTable)..where((r) => r.householdId.equals(householdId))).get();
    for (final rec in receivables) {
      if (rec.status == 'open') {
        alerts.add(NotificationAlert(
          id: 'rec_${rec.id}',
          title: 'Pending Receivable',
          message: '${rec.personName} owes a pending return of ₹${(rec.amountPaise / 100).toStringAsFixed(0)}.',
          icon: Icons.account_balance_wallet_outlined,
          color: Colors.teal,
          time: 'Pending',
          path: '/more/receivables',
        ));
      }
    }

    // 4. Planned Bills Alerts
    final bills = await (db.select(db.plannedBillsTable)..where((b) => b.householdId.equals(householdId))).get();
    for (final b in bills) {
      if (!b.isPaid) {
        alerts.add(NotificationAlert(
          id: 'bill_${b.id}',
          title: 'Unpaid Bill Reminder',
          message: '${b.name} payment of ₹${(b.amountPaise / 100).toStringAsFixed(0)} is pending.',
          icon: Icons.receipt_long_rounded,
          color: Colors.indigo,
          time: 'Pending',
          path: '/more',
        ));
      }
    }

    // 5. Month Rollover Status Alert
    final snap = await db.snapshotDao.getForMonth(ymStr, householdId: householdId);
    final isClosed = snap?.status == 'closed';
    if (!isClosed) {
      alerts.add(NotificationAlert(
        id: 'rollover_$ymStr',
        title: 'Month Rollover Pending',
        message: 'Active period $ymStr is currently open. Ensure all cash spending is tallied before closing.',
        icon: Icons.lock_clock_rounded,
        color: Colors.amber,
        time: 'Current Period',
        path: '/more',
      ));
    } else {
      alerts.add(NotificationAlert(
        id: 'rollover_closed_$ymStr',
        title: 'Month Period Closed',
        message: 'Period $ymStr is closed and remaining balance of ₹${((snap?.closingBalancePaise ?? 0) / 100).toStringAsFixed(0)} was carried forward.',
        icon: Icons.check_circle_outline_rounded,
        color: Colors.green,
        time: 'Closed Period',
        path: '/more',
      ));
    }

    // Filter out dismissed alerts
    final filtered = alerts.where((a) => !dismissed.contains(a.id)).toList();
    yield filtered;
  }
});

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(dynamicNotificationsProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          alertsAsync.maybeWhen(
            data: (alerts) => alerts.isNotEmpty
                ? TextButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          title: const Text('Clear All Notifications?'),
                          content: const Text('Are you sure you want to clear all notification alerts?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(backgroundColor: Colors.red),
                              onPressed: () {
                                Navigator.pop(ctx);
                                final ids = alerts.map((a) => a.id).toSet();
                                ref.read(dismissedNotificationsProvider.notifier).update((s) => {...s, ...ids});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('All notifications cleared!'),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                );
                              },
                              child: const Text('Clear All'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.clear_all_rounded, size: 18),
                    label: const Text('Clear All'),
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: alertsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('Error loading notifications: $err'),
        ),
        data: (alerts) {
          if (alerts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.notifications_off_outlined,
                      size: 56,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'All Caught Up!',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No unread alert notifications or budget reminders.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: alerts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final alert = alerts[index];
              return Dismissible(
                key: Key(alert.id),
                direction: DismissDirection.endToStart,
                onDismissed: (_) {
                  ref.read(dismissedNotificationsProvider.notifier).update((s) => {...s, alert.id});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Notification dismissed.'),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade400,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                ),
                child: PressableScale(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => context.go(alert.path),
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: alert.color.withValues(alpha: 0.14),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              alert.icon,
                              color: alert.color,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        alert.title,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                    Text(
                                      alert.time,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: cs.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  alert.message,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: cs.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close_rounded, size: 18, color: cs.onSurfaceVariant),
                            onPressed: () {
                              ref.read(dismissedNotificationsProvider.notifier).update((s) => {...s, alert.id});
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Notification dismissed.'),
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 2),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              );
                            },
                            tooltip: 'Dismiss',
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
}
