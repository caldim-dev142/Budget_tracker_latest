import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';

import '../../../data/local/database.dart';
import '../../../core/utils/money.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/engine/waterfall.dart';
import '../../../shared/widgets/money_text.dart';
import '../../../shared/widgets/month_switcher.dart';
import '../../../shared/widgets/budget_bar.dart';
import '../../../shared/widgets/pressable_scale.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/dashboard_providers.dart';

/// S3 — Dashboard (doc 09 S3).
/// The money's monthly journey at a glance:
/// Remaining hero → Waterfall strip → Accounts panel → Layer budgets snapshot.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ym = ref.watch(selectedMonthProvider);
    final authState = ref.watch(authStateProvider).valueOrNull;
    final householdId = authState?.householdId ?? 'local';
    final dashAsync = ref.watch(dashboardProvider((ym, householdId)));
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardProvider((ym, householdId)));
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // App bar with month switcher
            SliverAppBar(
              floating: true,
              pinned: false,
              elevation: 0,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              title: const MonthSwitcher(),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () => context.push('/notifications'),
                  tooltip: 'Notifications',
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => context.push('/settings'),
                  tooltip: 'Settings',
                ),
              ],
            ),

            // Dashboard content
            dashAsync.when(
              loading: () => const SliverFillRemaining(
                child: _DashboardSkeleton(),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline_rounded,
                          size: 48,
                          color: cs.error),
                      const SizedBox(height: 16),
                      Text('Failed to load dashboard', style: TextStyle(color: cs.error)),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: () => ref.invalidate(dashboardProvider((ym, householdId))),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (vm) => SliverList(
                delegate: SliverChildListDelegate([
                  _HeroRemaining(waterfall: vm.waterfall),
                  if (vm.snapshot?.isClosed == true && vm.snapshot!.reconciliationDifference.paise != 0) ...[
                    const SizedBox(height: 16),
                    _ReconciliationInsightBanner(difference: vm.snapshot!.reconciliationDifference),
                  ],
                  const SizedBox(height: 16),
                  _WaterfallCard(result: vm.waterfall),
                  const SizedBox(height: 16),
                  _AccountsPanel(
                    totalAvailable: vm.totalAvailable,
                    ccOutstanding: vm.ccOutstanding,
                    returnAwaited: vm.returnAwaited,
                    toBePaid: vm.toBePaid,
                  ),
                  const SizedBox(height: 16),
                  if (vm.layerBudgets.isNotEmpty)
                    _LayerBudgetsSection(budgets: vm.layerBudgets),
                  const SizedBox(height: 84), // FAB clearance
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Hero: Remaining balance ──────────────────────────────────────────────────

class _HeroRemaining extends StatelessWidget {
  final WaterfallResult waterfall;
  const _HeroRemaining({required this.waterfall});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: PressableScale(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF044D3A), // Dark forest green from Dashboard.png
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF044D3A).withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFF00796B),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 18,
                          color: Color(0xFF80E2D0),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'REMAINING BUDGET',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: Colors.white70,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              MoneyText(
                waterfall.remaining,
                style: TextStyle(
                  color: waterfall.remaining.isNegative ? const Color(0xFFFF8A80) : Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 36,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 20),
              Container(height: 1, color: Colors.white.withValues(alpha: 0.15)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _HeroSubMetric(
                    label: 'Income',
                    amount: waterfall.income,
                    color: const Color(0xFF00E676),
                  ),
                  Container(height: 28, width: 1, color: Colors.white.withValues(alpha: 0.2)),
                  _HeroSubMetric(
                    label: 'Spending',
                    amount: waterfall.spending,
                    color: const Color(0xFFFF6B6B),
                  ),
                  Container(height: 28, width: 1, color: Colors.white.withValues(alpha: 0.2)),
                  _HeroSubMetric(
                    label: 'Saved',
                    amount: waterfall.saving,
                    color: Colors.white,
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

class _HeroSubMetric extends StatelessWidget {
  final String label;
  final Money amount;
  final Color color;

  const _HeroSubMetric({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        MoneyText(
          amount,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}

// ─── Waterfall Strip ──────────────────────────────────────────────────────────

class _WaterfallCard extends StatelessWidget {
  final WaterfallResult result;
  const _WaterfallCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EAF6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.show_chart_rounded,
                    size: 20,
                    color: Color(0xFF3F51B5),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Money Flow Waterfall',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                ),
                const Spacer(),
                // Global info button for the waterfall
                Tooltip(
                  message: 'How is this calculated?',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _showWaterfallOverviewInfo(context, result),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Waterfall steps
            ...result.steps.asMap().entries.map(
              (entry) {
                final index = entry.key;
                final step = entry.value;
                final isLast = index == result.steps.length - 1;

                return TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 180 + (index * 35)),
                  curve: Curves.easeOutCubic,
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 8 * (1 - value)),
                      child: Opacity(opacity: value, child: child),
                    );
                  },
                  child: Column(
                    children: [
                      _WaterfallRow(step: step, result: result),
                      if (!isLast)
                        Divider(
                          height: 12,
                          thickness: 0.6,
                          color: cs.outlineVariant.withValues(alpha: 0.2),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  static void _showWaterfallOverviewInfo(BuildContext context, WaterfallResult r) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        maxChildSize: 0.9,
        minChildSize: 0.35,
        expand: false,
        builder: (_, ctrl) => _WaterfallInfoSheet(result: r, scrollController: ctrl),
      ),
    );
  }
}

class _WaterfallRow extends ConsumerWidget {
  final WaterfallStep step;
  final WaterfallResult result;
  const _WaterfallRow({required this.step, required this.result});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    final Color badgeBg;
    final Color iconColor;
    final IconData iconData;
    final Color textColor;

    if (step.isFinal) {
      badgeBg = const Color(0xFFE0F2F1);
      iconColor = const Color(0xFF00897B);
      iconData = Icons.add_rounded;
      textColor = const Color(0xFF00796B);
    } else if (step.isAddition) {
      badgeBg = const Color(0xFFE0F2F1);
      iconColor = const Color(0xFF00897B);
      iconData = Icons.add_rounded;
      textColor = const Color(0xFF00796B);
    } else {
      badgeBg = const Color(0xFFECEFF1);
      iconColor = const Color(0xFF78909C);
      iconData = Icons.remove_rounded;
      textColor = cs.onSurface;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: badgeBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              iconData,
              size: 16,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              step.label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: step.isFinal ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 15,
                  ),
            ),
          ),
          // ⓘ Info button for each step
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showStepInfo(context, step, result),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Icon(
                Icons.info_outline_rounded,
                size: 15,
                color: cs.onSurfaceVariant.withValues(alpha: 0.45),
              ),
            ),
          ),
          if (step.label == 'Opening')
            IconButton(
              icon: Icon(Icons.edit_outlined, size: 16, color: cs.primary),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Edit Opening Balance',
              onPressed: () {
                _showEditOpeningBalance(context, ref, step.amount);
              },
            ),
          const SizedBox(width: 8),
          MoneyText(
            step.amount,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: textColor,
                  fontWeight: step.isFinal ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 15,
                ),
          ),
        ],
      ),
    );
  }

  void _showStepInfo(BuildContext context, WaterfallStep step, WaterfallResult r) {
    final info = _waterfallStepInfo(step.label, r);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: info['color'] as Color,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(info['icon'] as IconData, size: 22, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(step.label,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      Text(info['subtitle'] as String,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 13)),
                    ],
                  ),
                ),
                MoneyText(step.amount,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 18)),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Formula',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 6),
                  Text(info['formula'] as String,
                      style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(info['description'] as String,
                style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85))),
          ],
        ),
      ),
    );
  }
}

/// Returns display metadata for each waterfall step.
Map<String, dynamic> _waterfallStepInfo(String label, WaterfallResult r) {
  switch (label) {
    case 'Opening':
      return {
        'subtitle': 'Starting balance this month',
        'formula': 'Opening Balance + Last Month Reserves',
        'description':
            'This is the cumulative starting point: your account opening balance for the month, plus any reserves carried forward from last month.',
        'icon': Icons.account_balance_wallet_outlined,
        'color': const Color(0xFF5C6BC0),
      };
    case 'Income':
      return {
        'subtitle': 'Net earnings this month',
        'formula': 'Gross Income − Income Deductions',
        'description':
            'All income entries (salary, freelance, dividends, etc.) minus any income deductions (TDS, PF, insurance premiums deducted at source). Only "income" and "incomeDeduction" kind entries count here.',
        'icon': Icons.trending_up_rounded,
        'color': const Color(0xFF00897B),
      };
    case 'Adjustments':
      return {
        'subtitle': 'Signed corrections & one-offs',
        'formula': 'Σ Adjustment entries (signed)',
        'description':
            'One-time corrections that don\'t fit standard buckets — refunds, cash-backs, corrections, or manual overrides. Positive adjustments add to your budget, negative ones reduce it.',
        'icon': Icons.tune_rounded,
        'color': const Color(0xFFF59E0B),
      };
    case 'Spending':
      return {
        'subtitle': 'Day-to-day expenses',
        'formula': 'Σ all "spending" entries',
        'description':
            'All regular expenditure: groceries, utilities, transport, dining, entertainment, etc. These reduce your available balance dollar-for-dollar.',
        'icon': Icons.shopping_cart_outlined,
        'color': const Color(0xFFEF4444),
      };
    case 'Protection':
      return {
        'subtitle': 'Insurance & buffers',
        'formula': 'Σ all "protection" entries',
        'description':
            'Premiums, emergency fund contributions, and financial safety net payments. These are intentional outflows that protect your future financial stability.',
        'icon': Icons.shield_outlined,
        'color': const Color(0xFF3B82F6),
      };
    case 'Saving':
      return {
        'subtitle': 'Goals & investments',
        'formula': 'Σ all "saving" entries',
        'description':
            'Contributions to savings goals, mutual funds, SIPs, or long-term wealth accumulation. This money is set aside — not spent but not freely available either.',
        'icon': Icons.savings_outlined,
        'color': const Color(0xFF8B5CF6),
      };
    case 'Reserves':
      return {
        'subtitle': 'Sinking funds & CC buffer',
        'formula': 'Sinking Fund Reserves + CC Outstanding − Return Awaited',
        'description':
            'Reserves set aside for sinking funds (emergency buffer, planned big expenses) plus credit card outstanding balance, minus money others owe you. This protects you from future cash-flow gaps.',
        'icon': Icons.account_balance_outlined,
        'color': const Color(0xFF78909C),
      };
    case 'Remaining':
      return {
        'subtitle': 'What\'s left after all allocations',
        'formula': 'Opening + Income + Adj − Spending − Protection − Saving − Reserves',
        'description':
            'Your final discretionary budget remaining for the month. A positive number means you\'re on track. A negative number means you\'ve over-allocated — review your spending or adjust reserves.',
        'icon': Icons.check_circle_outline_rounded,
        'color': const Color(0xFF00897B),
      };
    default:
      return {
        'subtitle': '',
        'formula': label,
        'description': 'This step represents the $label allocation in your budget waterfall.',
        'icon': Icons.info_outline_rounded,
        'color': const Color(0xFF78909C),
      };
  }
}

/// Full waterfall overview info sheet.
class _WaterfallInfoSheet extends StatelessWidget {
  final WaterfallResult result;
  final ScrollController scrollController;
  const _WaterfallInfoSheet({required this.result, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      children: [
        Center(
          child: Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: cs.outlineVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('How the Waterfall Works',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(
          'Your money flows through 7 sequential steps each month.',
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
        ),
        const SizedBox(height: 20),
        ...result.steps.map((step) {
          final info = _waterfallStepInfo(step.label, result);
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: (info['color'] as Color).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: (info['color'] as Color).withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: info['color'] as Color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(info['icon'] as IconData,
                      size: 18, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(step.label,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 14)),
                          MoneyText(step.amount,
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: info['color'] as Color)),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(info['description'] as String,
                          style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurface.withValues(alpha: 0.7),
                              height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}


// ─── Accounts Panel ───────────────────────────────────────────────────────────

class _AccountsPanel extends StatelessWidget {
  final Money totalAvailable;
  final Money ccOutstanding;
  final Money returnAwaited;
  final Money toBePaid;

  const _AccountsPanel({
    required this.totalAvailable,
    required this.ccOutstanding,
    required this.returnAwaited,
    required this.toBePaid,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.3),
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
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2F1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.account_balance_outlined,
                        size: 20,
                        color: Color(0xFF00796B),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Accounts & Balances',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                    ),
                  ],
                ),
                PressableScale(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => context.push('/more/accounts'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      'View All',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: const Color(0xFF00897B),
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _AccountRow('Total Available', totalAvailable, icon: Icons.account_balance_rounded),
            Divider(height: 12, thickness: 0.6, color: cs.outlineVariant.withValues(alpha: 0.2)),
            _AccountRow('CC Outstanding', ccOutstanding, icon: Icons.credit_card_rounded, isLiability: true),
            Divider(height: 12, thickness: 0.6, color: cs.outlineVariant.withValues(alpha: 0.2)),
            _AccountRow('Return Awaited', returnAwaited, icon: Icons.access_time_rounded),
            Divider(height: 12, thickness: 0.6, color: cs.outlineVariant.withValues(alpha: 0.2)),
            _AccountRow('To Be Paid', toBePaid, icon: Icons.alarm_rounded, isLiability: true),
          ],
        ),
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  final String label;
  final Money amount;
  final IconData icon;
  final bool isLiability;

  const _AccountRow(this.label, this.amount,
      {required this.icon, this.isLiability = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final amountColor = isLiability ? const Color(0xFFFF6B6B) : cs.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon,
              size: 20,
              color: isLiability ? const Color(0xFFFF6B6B) : const Color(0xFF546E7A)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
            ),
          ),
          MoneyText(
            amount,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: amountColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
          ),
        ],
      ),
    );
  }
}

// ─── Layer Budgets ────────────────────────────────────────────────────────────

class _LayerBudgetsSection extends StatelessWidget {
  final List<dynamic> budgets;
  const _LayerBudgetsSection({required this.budgets});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: cs.secondaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.pie_chart_outline_rounded, size: 18, color: cs.secondary),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Budget Snapshot',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Set up layer budgets in the Budget tab for real-time tracking.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Loading skeleton ─────────────────────────────────────────────────────────

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: const [
          SkeletonLoader(height: 100, width: double.infinity, borderRadius: 20),
          SizedBox(height: 16),
          SkeletonLoader(height: 220, width: double.infinity, borderRadius: 20),
          SizedBox(height: 16),
          SkeletonLoader(height: 180, width: double.infinity, borderRadius: 20),
        ],
      ),
    );
  }
}

Future<void> _showEditOpeningBalance(BuildContext context, WidgetRef ref, Money currentBalance) async {
  final ym = ref.read(selectedMonthProvider);
  final ctrl = TextEditingController(text: (currentBalance.paise / 100).toStringAsFixed(2));

  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Edit Opening Balance ($ym)'),
      content: TextField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(labelText: 'Amount (₹)', prefixText: '₹ '),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(
          onPressed: () async {
            final val = double.tryParse(ctrl.text) ?? 0;
            final paise = (val * 100).round();
            
            final db = ref.read(appDatabaseProvider);
            final auth = ref.read(authStateProvider).valueOrNull;
            final householdId = auth?.householdId ?? 'local';
            final existing = await db.snapshotDao.getForMonth(ym.toString(), householdId: householdId);
            
            if (existing != null) {
              await db.snapshotDao.upsertSnapshot(
                MonthSnapshotsTableCompanion(
                  id: drift.Value(existing.id),
                  householdId: drift.Value(householdId),
                  yearMonth: drift.Value(existing.yearMonth),
                  status: drift.Value(existing.status),
                  openingBalancePaise: drift.Value(paise),
                  lastMonthReservesPaise: drift.Value(existing.lastMonthReservesPaise),
                  closingBalancePaise: drift.Value(existing.closingBalancePaise),
                  reservesPaise: drift.Value(existing.reservesPaise),
                ),
              );
            } else {
              await db.snapshotDao.upsertSnapshot(
                MonthSnapshotsTableCompanion.insert(
                  id: const Uuid().v4(),
                  householdId: householdId,
                  yearMonth: ym.toString(),
                  status: const drift.Value('open'),
                  openingBalancePaise: drift.Value(paise),
                  lastMonthReservesPaise: const drift.Value(0),
                ),
              );
            }

            // Sync account balance for this household
            final accounts = await db.accountDao.watchActiveAccounts(householdId: householdId).first;
            if (accounts.isNotEmpty) {
              final mainAccount = accounts.first;
              await db.accountDao.upsertAccount(
                AccountsTableCompanion(
                  id: drift.Value(mainAccount.id),
                  householdId: drift.Value(householdId),
                  name: drift.Value(mainAccount.name),
                  type: drift.Value(mainAccount.type),
                  currentBalancePaise: drift.Value(paise),
                ),
              );
            }
            
            if (ctx.mounted) Navigator.pop(ctx);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
// ─── Reconciliation Banner ──────────────────────────────────────────────────────

class _ReconciliationInsightBanner extends StatelessWidget {
  final Money difference;
  const _ReconciliationInsightBanner({required this.difference});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.errorContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: cs.error, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reconciliation Difference',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.onErrorContainer,
                        ),
                  ),
                  Text(
                    'Plan vs. actual balance: ${MoneyFormatter.formatSigned(difference)} difference — check for missing entries.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onErrorContainer,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
