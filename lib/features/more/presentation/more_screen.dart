import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:uuid/uuid.dart';
import '../../../features/dashboard/providers/dashboard_providers.dart';
import '../../../shared/widgets/pressable_scale.dart';
import '../../../data/local/database.dart';
import '../../../domain/engine/waterfall.dart';
import '../../../domain/engine/rollover.dart';
import '../../../domain/entities/month_snapshot.dart';
import '../../../core/utils/money.dart';
import '../../auth/providers/auth_providers.dart';


class MoreScreen extends ConsumerStatefulWidget {
  const MoreScreen({super.key});

  @override
  ConsumerState<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends ConsumerState<MoreScreen> {
  bool _isClosing = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isClosed = ref.watch(isCurrentMonthClosedProvider).valueOrNull ?? false;

    final sections = [
      _MoreItem(
        title: 'Protection',
        subtitle: 'Sinking funds & buffers',
        icon: Icons.shield_outlined,
        color: Colors.indigo.shade500,
        path: '/more/protection',
      ),
      _MoreItem(
        title: 'Saving Goals',
        subtitle: 'Retirement & education',
        icon: Icons.flag_outlined,
        color: Colors.amber.shade800,
        path: '/more/saving',
      ),
      _MoreItem(
        title: 'Credit Cards',
        subtitle: 'Ledgers & deltas',
        icon: Icons.credit_card_outlined,
        color: Colors.blueGrey.shade600,
        path: '/more/cards',
      ),
      _MoreItem(
        title: 'Accounts',
        subtitle: 'Cash & bank tracking',
        icon: Icons.account_balance_outlined,
        color: Colors.teal.shade600,
        path: '/more/accounts',
      ),
      _MoreItem(
        title: 'Borrow & Lending',
        subtitle: 'Loans, receivables & money owed',
        icon: Icons.handshake_outlined,
        color: Colors.deepOrange.shade400,
        path: '/more/borrow-lending',
      ),
      _MoreItem(
        title: 'Planning',
        subtitle: 'Reserves & annual plan',
        icon: Icons.assignment_outlined,
        color: Colors.deepPurple.shade500,
        path: '/more/planning',
      ),
      _MoreItem(
        title: 'Notifications',
        subtitle: 'Alerts & overspends',
        icon: Icons.notifications_none_outlined,
        color: Colors.redAccent.shade400,
        path: '/notifications',
      ),
      _MoreItem(
        title: 'Settings',
        subtitle: 'Profile, theme, backup',
        icon: Icons.settings_outlined,
        color: cs.primary,
        path: '/settings',
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('More Hub')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Month Close Rollover Section
          PressableScale(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _showMonthCloseDialog(context, isClosed),
            child: Card(
              color: isClosed
                  ? cs.surfaceContainerLowest
                  : cs.primaryContainer.withValues(alpha: 0.25),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isClosed ? cs.outlineVariant : cs.primary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        isClosed ? Icons.lock_outline_rounded : Icons.lock_open_rounded,
                        color: cs.onPrimary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isClosed ? 'Month is Closed' : 'Close Active Month',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: isClosed ? null : cs.primary,
                                ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isClosed
                                ? 'This month is locked and read-only.'
                                : 'Perform rollover & calculate opening balance.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: cs.primary),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Grid items for features
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.15,
            ),
            itemCount: sections.length,
            itemBuilder: (context, index) {
              final item = sections[index];
              return PressableScale(
                borderRadius: BorderRadius.circular(22),
                onTap: () => context.push(item.path),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: item.color.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item.icon,
                          color: item.color,
                          size: 20,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        item.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontSize: 11,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _showMonthCloseDialog(BuildContext context, bool isClosed) {
    if (isClosed) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Month Already Closed'),
          content: const Text(
            'This month has already been finalized and rolled over. You can re-open it to adjust entries.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.orange.shade700),
              onPressed: () async {
                Navigator.pop(ctx);
                final messenger = ScaffoldMessenger.of(context);
                await _reopenMonth();
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: const Text('Month re-opened for edits.'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              },
              child: const Text('Re-open Month'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Close Month & Rollover?'),
          content: const Text(
            'Closing this month will freeze all actual entries. The remaining balance will roll over as next month\'s opening balance.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final messenger = ScaffoldMessenger.of(context);
                final ok = await _closeMonth();
                if (mounted && ok) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: const Text('Month closed & rolled over successfully!'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                  ref.invalidate(isCurrentMonthClosedProvider);
                }
              },
              child: _isClosing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Confirm & Rollover'),
            ),
          ],
        ),
      );
    }
  }

  /// Compute waterfall from DB entries and write a closed MonthSnapshot.
  /// Also seeds the next month's opening snapshot via RolloverEngine.
  Future<bool> _closeMonth() async {
    if (_isClosing) return false;
    setState(() => _isClosing = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final db = ref.read(appDatabaseProvider);
      final ym = ref.read(selectedMonthProvider);
      final ymStr = ym.toString();
      final authState = ref.read(authStateProvider).valueOrNull;
      final householdId = authState?.householdId ?? 'local';
      const uuid = Uuid();

      // ── 1. Fetch entries for the month ──────────────────────────────────
      final entries = await db.entryDao.getMonth(ymStr, householdId: householdId);

      int grossIncomePaise = 0;
      int incomeDeductionPaise = 0;
      int adjustmentsPaise = 0;
      int spendingPaise = 0;
      int protectionPaise = 0;
      int savingPaise = 0;

      final categories = await (db.select(db.categoriesTable)..where((c) => c.householdId.equals(householdId))).get();
      final categoryMap = {for (var c in categories) c.id: c};

      for (final e in entries) {
        final cat = categoryMap[e.categoryId];
        final isDeduction = cat?.isDeduction ?? false;

        switch (e.kind) {
          case 'income':            grossIncomePaise    += e.amountPaise; break;
          case 'incomeDeduction':   incomeDeductionPaise += e.amountPaise; break;
          case 'adjustment':
            if (isDeduction) {
              adjustmentsPaise -= e.amountPaise;
            } else {
              adjustmentsPaise += e.amountPaise;
            }
            break;
          case 'spending':          spendingPaise       += e.amountPaise; break;
          case 'protection':        protectionPaise     += e.amountPaise; break;
          case 'saving':            savingPaise         += e.amountPaise; break;
        }
      }

      final netIncomePaise = grossIncomePaise - incomeDeductionPaise;

      // ── 2. Fetch existing snapshot & prior snapshot for opening balance ──────
      final existingSnap = await db.snapshotDao.getForMonth(ymStr, householdId: householdId);
      final prevSnap = await db.snapshotDao.getForMonth(ym.addMonths(-1).toString(), householdId: householdId);

      final currentOpeningPaise = (existingSnap != null && existingSnap.openingBalancePaise != 0)
          ? existingSnap.openingBalancePaise
          : (prevSnap?.closingBalancePaise ?? 0);

      final currentLastReservesPaise = (existingSnap != null && existingSnap.lastMonthReservesPaise != 0)
          ? existingSnap.lastMonthReservesPaise
          : (prevSnap?.reservesPaise ?? 0);

      // ── 3. Fetch accounts balance (total available) ──────────────────────
      final accounts = await db.accountDao.watchActiveAccounts(householdId: householdId).first;
      int totalAvailablePaise = 0;
      for (final acc in accounts) {
        totalAvailablePaise += acc.currentBalancePaise;
      }

      // ── 4. Reserve composition from Excel Annexure!E18 ─────────────────
      final cards = await db.cardDao.watchActiveCards(householdId: householdId).first;
      int ccOutstandingPaise = 0;
      for (final card in cards) {
        final txns = await (db.select(db.cardTransactionsTable)..where((t) => t.cardId.equals(card.id))).get();
        final delta = txns.fold<int>(0, (s, t) => s + t.amountPaise);
        ccOutstandingPaise += card.previousOutstandingPaise + delta;
      }

      final receivables = await db.select(db.receivablesTable).get();
      int returnAwaitedPaise = 0;
      for (final rec in receivables) {
        if (rec.status == 'open') {
          returnAwaitedPaise += rec.amountPaise;
        }
      }

      final plannedBills = await db.select(db.plannedBillsTable).get();
      int toBePaidPaise = 0;
      for (final bill in plannedBills) {
        if (!bill.isPaid) {
          toBePaidPaise += bill.amountPaise;
        }
      }

      final activeFunds = await db.fundDao.getAllActive(householdId: householdId);
      int activeFundsTotalPaise = 0;
      for (final f in activeFunds) {
        activeFundsTotalPaise += f.openingReservePaise;
      }

      final int reservesSetAsidePaise = activeFundsTotalPaise + ccOutstandingPaise - returnAwaitedPaise;

      // ── 5. Compute waterfall & closing balance ───────────────────────────
      final actuals = MonthActuals(
        yearMonth: ym,
        openingBalance: Money(currentOpeningPaise),
        lastMonthReserves: Money(currentLastReservesPaise),
        income: Money(netIncomePaise),
        adjustments: Money(adjustmentsPaise),
        spending: Money(spendingPaise),
        protection: Money(protectionPaise),
        saving: Money(savingPaise),
        reservesSetAside: Money(reservesSetAsidePaise),
        totalAvailable: Money(totalAvailablePaise),
        ccOutstanding: Money(ccOutstandingPaise),
        returnAwaited: Money(returnAwaitedPaise),
        toBePaid: Money(toBePaidPaise),
      );

      final waterfall = WaterfallEngine.compute(actuals);
      final closingBalance = Money(totalAvailablePaise - reservesSetAsidePaise);

      // ── 6. Write closed MonthSnapshot ───────────────────────────────────
      final snapshotId = existingSnap?.id ?? uuid.v4();
      final now = DateTime.now();

      await db.snapshotDao.upsertSnapshot(
        MonthSnapshotsTableCompanion(
          id: Value(snapshotId),
          householdId: Value(householdId),
          yearMonth: Value(ymStr),
          openingBalancePaise: Value(currentOpeningPaise),
          lastMonthReservesPaise: Value(currentLastReservesPaise),
          incomePaise: Value(netIncomePaise),
          adjustmentsPaise: Value(adjustmentsPaise),
          spendingPaise: Value(spendingPaise),
          protectionPaise: Value(protectionPaise),
          savingPaise: Value(savingPaise),
          reservesPaise: Value(reservesSetAsidePaise),
          closingBalancePaise: Value(closingBalance.paise),
          remainingPaise: Value(waterfall.remaining.paise),
          status: const Value('closed'),
          closedAt: Value(now),
        ),
      );

      // ── 7. Seed/Update next month's opening snapshot ─────────────────────
      final nextYm = ym.next;
      final nextYmStr = nextYm.toString();
      final existingNext = await db.snapshotDao.getForMonth(nextYmStr, householdId: householdId);
      final int nextOpeningBalance = closingBalance.paise;
      final int nextLastMonthReserves = reservesSetAsidePaise;

      if (existingNext != null) {
        await db.snapshotDao.upsertSnapshot(
          MonthSnapshotsTableCompanion(
            id: Value(existingNext.id),
            householdId: Value(householdId),
            yearMonth: Value(nextYmStr),
            openingBalancePaise: Value(nextOpeningBalance),
            lastMonthReservesPaise: Value(nextLastMonthReserves),
            incomePaise: Value(existingNext.incomePaise),
            adjustmentsPaise: Value(existingNext.adjustmentsPaise),
            spendingPaise: Value(existingNext.spendingPaise),
            protectionPaise: Value(existingNext.protectionPaise),
            savingPaise: Value(existingNext.savingPaise),
            reservesPaise: Value(existingNext.reservesPaise),
            closingBalancePaise: Value(existingNext.closingBalancePaise),
            remainingPaise: Value(existingNext.remainingPaise),
            status: Value(existingNext.status),
          ),
        );
      } else {
        await db.snapshotDao.upsertSnapshot(
          MonthSnapshotsTableCompanion(
            id: Value(uuid.v4()),
            householdId: Value(householdId),
            yearMonth: Value(nextYmStr),
            openingBalancePaise: Value(nextOpeningBalance),
            lastMonthReservesPaise: Value(nextLastMonthReserves),
            incomePaise: const Value(0),
            adjustmentsPaise: const Value(0),
            spendingPaise: const Value(0),
            protectionPaise: const Value(0),
            savingPaise: const Value(0),
            reservesPaise: const Value(0),
            closingBalancePaise: Value(nextOpeningBalance),
            remainingPaise: Value(nextOpeningBalance),
            status: const Value('open'),
          ),
        );
      }

      ref.invalidate(isCurrentMonthClosedProvider);
      ref.invalidate(dashboardProvider((ym, householdId)));
      ref.invalidate(dashboardProvider((nextYm, householdId)));

      return true;
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Failed to close month: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _isClosing = false);
    }
  }

  /// Re-open a closed month snapshot.
  Future<void> _reopenMonth() async {
    final db = ref.read(appDatabaseProvider);
    final ym = ref.read(selectedMonthProvider);
    final auth = ref.read(authStateProvider).valueOrNull;
    final householdId = auth?.householdId ?? 'local';
    final snap = await db.snapshotDao.getForMonth(ym.toString(), householdId: householdId);
    if (snap == null) return;
    await db.snapshotDao.upsertSnapshot(
      MonthSnapshotsTableCompanion(
        id: Value(snap.id),
        householdId: Value(snap.householdId),
        yearMonth: Value(snap.yearMonth),
        openingBalancePaise: Value(snap.openingBalancePaise),
        lastMonthReservesPaise: Value(snap.lastMonthReservesPaise),
        incomePaise: Value(snap.incomePaise),
        adjustmentsPaise: Value(snap.adjustmentsPaise),
        spendingPaise: Value(snap.spendingPaise),
        protectionPaise: Value(snap.protectionPaise),
        savingPaise: Value(snap.savingPaise),
        reservesPaise: Value(snap.reservesPaise),
        closingBalancePaise: Value(snap.closingBalancePaise),
        remainingPaise: Value(snap.remainingPaise),
        status: const Value('open'),
        closedAt: const Value(null),
      ),
    );
    ref.invalidate(isCurrentMonthClosedProvider);
    ref.invalidate(dashboardProvider((ym, householdId)));
    ref.invalidate(dashboardProvider((ym.next, householdId)));
  }
}

class _MoreItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String path;

  const _MoreItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.path,
  });
}
