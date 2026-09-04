import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/pressable_scale.dart';
import '../../../shared/widgets/month_switcher.dart';

import '../../../shared/widgets/money_text.dart';
import '../../auth/providers/auth_providers.dart';
import '../../dashboard/providers/dashboard_providers.dart';

/// S14 — Reports & Charts (doc 09 S14, doc 13).
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ym = ref.watch(selectedMonthProvider);
    final authState = ref.watch(authStateProvider).valueOrNull;
    final householdId = authState?.householdId ?? 'local';
    final vmAsync = ref.watch(dashboardProvider((ym, householdId)));
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: MonthSwitcher(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        children: [
          // Month Summary Overview Banner
          vmAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (vm) => Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0E7C7B), Color(0xFF00A887)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0E7C7B).withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'MONTHLY SUMMARY OVERVIEW',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Inflow', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          const SizedBox(height: 2),
                          MoneyText(
                            vm.waterfall.income,
                            style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.w800, fontSize: 18),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Spending', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          const SizedBox(height: 2),
                          MoneyText(
                            vm.waterfall.spending,
                            style: const TextStyle(color: Color(0xFFFF8A80), fontWeight: FontWeight.w800, fontSize: 18),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Net Remaining', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          const SizedBox(height: 2),
                          MoneyText(
                            vm.waterfall.remaining,
                            style: TextStyle(
                              color: vm.waterfall.remaining.isNegative ? const Color(0xFFFF8A80) : Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
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
          const _ReportCard(
            title: 'Monthly Trends',
            subtitle: 'Income & spending trends over time',
            icon: Icons.show_chart_rounded,
            reportId: 'trends',
          ),
          const _ReportCard(
            title: 'Category Breakdown',
            subtitle: 'Where the money goes by category',
            icon: Icons.donut_large_rounded,
            reportId: 'breakdown',
          ),
          const _ReportCard(
            title: 'Cashflow Distribution',
            subtitle: 'Plan vs Actual allocation layer analysis',
            icon: Icons.balance_rounded,
            reportId: 'needs_wants',
          ),
          const _ReportCard(
            title: 'Cash Flow',
            subtitle: 'Total inward vs outward cash flow',
            icon: Icons.swap_vert_rounded,
            reportId: 'cash_flow',
          ),
          const _ReportCard(
            title: 'Goal Progress',
            subtitle: 'Sinking funds & saving goals trajectory',
            icon: Icons.flag_rounded,
            reportId: 'goal_progress',
          ),
          const _ReportCard(
            title: 'Yearly Summary',
            subtitle: 'Annual roll-up of all financial months',
            icon: Icons.calendar_month_rounded,
            reportId: 'yearly',
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String reportId;
  const _ReportCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.reportId,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PressableScale(
        borderRadius: BorderRadius.circular(22),
        onTap: () => context.push('/reports/$reportId'),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFE0F2F1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: const Color(0xFF00897B), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontSize: 12,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
            ],
          ),
        ),
      ),
    );
  }
}
