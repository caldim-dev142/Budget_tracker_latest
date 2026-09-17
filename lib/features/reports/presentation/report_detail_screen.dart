import 'package:flutter/material.dart';
import 'package:drift/drift.dart' hide Column, Table;
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/local/database.dart';
import '../../../core/utils/month.dart';
import '../../auth/providers/auth_providers.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../providers/report_filters_provider.dart';
import '../providers/plan_distribution_lock_provider.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../core/utils/input_formatters.dart';

class ReportDetailScreen extends ConsumerStatefulWidget {
  final String reportId;

  const ReportDetailScreen({super.key, required this.reportId});

  @override
  ConsumerState<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends ConsumerState<ReportDetailScreen> {
  int _segmentedIndex = 0;

  DateTime _selectedMonth = DateTime(2026, 7);

  // 1. trends data
  late List<double> _trendsIncome;
  late List<double> _trendsSpending;
  late List<String> _trendsMonthLabels;
  late double _avgIncome;
  late double _avgSpending;
  late double _netSavings;

  // 2. breakdown data
  late List<Map<String, dynamic>> _breakdownCategories;
  late double _totalBreakdownSpending;

  // 3. cashflow distribution data
  late double _spendingActualPct;
  late double _savingActualPct;
  late double _protectionActualPct;
  late double _spendingActualAmt;
  late double _savingActualAmt;
  late double _protectionActualAmt;
  double _spendingPlanPct = 45.0;
  double _savingPlanPct = 35.0;
  double _protectionPlanPct = 20.0;
  double _initialSpendingBudgetPct = 45.0;
  double _initialSavingBudgetPct = 35.0;
  double _initialProtectionBudgetPct = 20.0;
  bool _spendingLocked = false;
  bool _savingLocked = false;
  bool _protectionLocked = false;
  bool _planCustomizerExpanded = false;

  // 4. cash_flow data
  late List<double> _cashFlowIn;
  late List<double> _cashFlowOut;
  List<String> _cashFlowMonthLabels = [];
  late double _totalInflow;
  late double _totalOutflow;

  // 5. goal_progress data
  late List<double> _savingsTrajectory;
  late List<Map<String, dynamic>> _goalsList;
  late double _totalGoalTarget;
  late double _totalGoalSaved;

  // 6. yearly data
  late List<Map<String, dynamic>> _yearlyMonths;
  late double _yearlyTotalIncome;
  late double _yearlyTotalSpending;
  late double _yearlyTotalSavings;
  late double _yearlyTotalProtection;
  late double _yearlyTotalAdjustments;
  late double _yearlyTotalReserves;
  List<AnnualTargetsTableData> _annualTargets = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final ym = ref.read(selectedMonthProvider);
    _selectedMonth = DateTime(ym.year, ym.month);
    _loadRealData();
  }

  Future<void> _loadRealData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final db = ref.read(appDatabaseProvider);
      final authState = ref.read(authStateProvider).valueOrNull;
      final householdId = authState?.householdId ?? 'local';
      final filter = ref.read(reportFilterProvider);
      final ymStr = '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}';
      
      // Fetch all entries for this month
      final rawEntries = await db.entryDao.getMonth(ymStr, householdId: householdId);
      
      // Fetch categories
      final categories = await db.categoryDao.getAllActive(householdId: householdId);
      const monthNamesShort = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

      final catMap = <String, CategoriesTableData>{};
      for (final c in categories) {
        catMap[c.id] = c;
      }

      // Filter predicate based on active ReportFilterState
      bool entryMatchesFilter(EntriesTableData e) {
        if (filter.categoryIdFilter != null && e.categoryId != filter.categoryIdFilter) {
          return false;
        }
        final cat = catMap[e.categoryId];
        if (filter.kindFilter != 'all') {
          if (e.kind != filter.kindFilter) return false;
        }
        if (filter.needOrWantFilter != 'all') {
          if (cat == null || cat.needOrWant != filter.needOrWantFilter) return false;
        }
        return true;
      }

      final entries = rawEntries.where(entryMatchesFilter).toList();

      // Build deduction category ID set for correct adjustment sign semantics.
      // Rule (source of truth): isDeduction: true → outflow; false → inflow.
      final deductionCategoryIds = <String>{};
      for (final c in categories) {
        if (c.isDeduction) deductionCategoryIds.add(c.id);
      }

      // 1. Trends: Fetch data for the selected horizon up to _selectedMonth (household-scoped)
      final horizon = filter.timeHorizonMonths;
      _trendsIncome = [];
      _trendsSpending = [];
      _trendsMonthLabels = [];
      int activeMonthsCount = 0;

      for (int i = horizon - 1; i >= 0; i--) {
        final m = DateTime(_selectedMonth.year, _selectedMonth.month - i);
        final ymVal = '${m.year}-${m.month.toString().padLeft(2, '0')}';
        _trendsMonthLabels.add(monthNamesShort[m.month - 1]);

        final rawMEntries = await db.entryDao.getMonth(ymVal, householdId: householdId);
        final mEntries = rawMEntries.where(entryMatchesFilter).toList();
        
        double mIncome = 0;
        double mSpending = 0;
        for (final e in mEntries) {
          final val = e.amountPaise / 100.0;
          if (e.kind == 'income') {
            mIncome += val;
          } else if (e.kind == 'incomeDeduction') {
            mIncome -= val;
          } else if (e.kind == 'spending') {
            mSpending += val;
          } else if (e.kind == 'adjustment') {
            // isDeduction: true → outflow (spending); false → inflow (income)
            if (deductionCategoryIds.contains(e.categoryId)) {
              mSpending += val;
            } else {
              mIncome += val;
            }
          }
        }
        if (mEntries.isNotEmpty) {
          activeMonthsCount++;
        }
        _trendsIncome.add(mIncome);
        _trendsSpending.add(mSpending);
      }

      final sumIncome = _trendsIncome.isEmpty ? 0.0 : _trendsIncome.reduce((a, b) => a + b);
      final sumSpending = _trendsSpending.isEmpty ? 0.0 : _trendsSpending.reduce((a, b) => a + b);
      final divisor = activeMonthsCount > 0 ? activeMonthsCount : horizon;
      _avgIncome = sumIncome / divisor;
      _avgSpending = sumSpending / divisor;
      _netSavings = _avgIncome - _avgSpending;

      // 2. Category Breakdown (strictly for matching entries)
      final categoryTotals = <String, double>{};
      for (final e in entries) {
        final isMatch = filter.kindFilter == 'all'
            ? e.kind == 'spending'
            : e.kind == filter.kindFilter;
        if (isMatch) {
          final catName = catMap[e.categoryId]?.name ?? 'Uncategorized';
          categoryTotals[catName] = (categoryTotals[catName] ?? 0.0) + (e.amountPaise / 100.0);
        }
      }
      
      double tempSum = 0;
      _breakdownCategories = [];
      int colorIdx = 0;
      categoryTotals.forEach((name, val) {
        tempSum += val;
        _breakdownCategories.add({
          'name': name,
          'value': val,
          'color': _getCategoryColor(colorIdx++),
        });
      });
      _totalBreakdownSpending = tempSum;
      _breakdownCategories.sort((a, b) => (b['value'] as double).compareTo(a['value'] as double));

      // 3. Cashflow Distribution (Waterfall Allocation Layers)
      double spendingActual = 0;
      double protectionActual = 0;
      double savingActual = 0;

      for (final e in entries) {
        final val = e.amountPaise / 100.0;
        if (e.kind == 'spending') {
          spendingActual += val;
        } else if (e.kind == 'protection') {
          protectionActual += val;
        } else if (e.kind == 'saving') {
          savingActual += val;
        }
      }

      final totalSpent = spendingActual + protectionActual + savingActual;
      if (totalSpent > 0) {
        _spendingActualPct = (spendingActual / totalSpent) * 100;
        _savingActualPct = (savingActual / totalSpent) * 100;
        _protectionActualPct = (protectionActual / totalSpent) * 100;
      } else {
        _spendingActualPct = 0.0;
        _savingActualPct = 0.0;
        _protectionActualPct = 0.0;
      }

      _spendingActualAmt = spendingActual;
      _savingActualAmt = savingActual;
      _protectionActualAmt = protectionActual;

      // Dynamic Plan Allocation Targets from Budgets Table
      final budgets = await (db.select(db.budgetsTable)..where((b) => b.yearMonth.equals(ymStr))).get();
      double spendingBudget = 0;
      double protectionBudget = 0;
      double savingBudget = 0;
      for (final b in budgets) {
        final cat = categories.where((c) => c.id == b.categoryId).firstOrNull;
        if (cat != null) {
          final amt = b.amountPaise / 100.0;
          if (cat.kind == 'spending') spendingBudget += amt;
          else if (cat.kind == 'protection') protectionBudget += amt;
          else if (cat.kind == 'saving') savingBudget += amt;
        }
      }
      final totalBudget = spendingBudget + protectionBudget + savingBudget;
      if (totalBudget > 0) {
        _spendingPlanPct = ((spendingBudget / totalBudget) * 100).roundToDouble();
        _savingPlanPct = ((savingBudget / totalBudget) * 100).roundToDouble();
        _protectionPlanPct = (100.0 - _spendingPlanPct - _savingPlanPct).clamp(0.0, 100.0);
      } else {
        // No budget data: show zero allocation (no synthetic defaults)
        _spendingPlanPct = 0.0;
        _savingPlanPct = 0.0;
        _protectionPlanPct = 0.0;
      }
      _initialSpendingBudgetPct = _spendingPlanPct;
      _initialSavingBudgetPct = _savingPlanPct;
      _initialProtectionBudgetPct = _protectionPlanPct;

      // Restore locked percentages from PlanDistributionLockProvider
      final lockState = ref.read(planDistributionLockProvider(householdId));
      _spendingLocked = lockState.spendingLocked;
      _savingLocked = lockState.savingLocked;
      _protectionLocked = lockState.protectionLocked;

      if (_spendingLocked && lockState.lockedSpendingPct != null) {
        _spendingPlanPct = lockState.lockedSpendingPct!;
      }
      if (_savingLocked && lockState.lockedSavingPct != null) {
        _savingPlanPct = lockState.lockedSavingPct!;
      }
      if (_protectionLocked && lockState.lockedProtectionPct != null) {
        _protectionPlanPct = lockState.lockedProtectionPct!;
      }

      // 4. Cash Flow: Inflow vs Outflow for the selected horizon (household-scoped)
      final cfHorizon = filter.timeHorizonMonths.clamp(3, 12);
      _cashFlowIn = [];
      _cashFlowOut = [];
      _cashFlowMonthLabels = [];
      for (int i = cfHorizon - 1; i >= 0; i--) {
        final m = DateTime(_selectedMonth.year, _selectedMonth.month - i);
        final ymVal = '${m.year}-${m.month.toString().padLeft(2, '0')}';
        _cashFlowMonthLabels.add(monthNamesShort[m.month - 1]);
        final rawMEntries = await db.entryDao.getMonth(ymVal, householdId: householdId);
        final mEntries = rawMEntries.where(entryMatchesFilter).toList();
        
        double mIn = 0;
        double mOut = 0;
        for (final e in mEntries) {
          final val = e.amountPaise / 100.0;
          if (e.kind == 'income') {
            mIn += val;
          } else if (e.kind == 'incomeDeduction') {
            mIn -= val;
          } else if (e.kind == 'spending' || e.kind == 'saving' || e.kind == 'protection') {
            mOut += val;
          } else if (e.kind == 'adjustment') {
            // isDeduction: true → outflow; false → inflow
            if (deductionCategoryIds.contains(e.categoryId)) {
              mOut += val;
            } else {
              mIn += val;
            }
          }
        }
        _cashFlowIn.add(mIn);
        _cashFlowOut.add(mOut);
      }
      _totalInflow = _cashFlowIn.isEmpty ? 0.0 : _cashFlowIn.reduce((a, b) => a + b);
      _totalOutflow = _cashFlowOut.isEmpty ? 0.0 : _cashFlowOut.reduce((a, b) => a + b);

      // 5. Goal Progress: use SavingGoals with real targetPaise (not sinking funds)
      final goals = await db.goalDao.getAllActive(householdId: householdId);
      _goalsList = [];
      double totalTarget = 0;
      double totalSaved = 0;
      int goalColorIdx = 0;
      for (final g in goals) {
        // Sum all contributions for this goal from goalContributionsTable
        final contributions = await (db.select(db.goalContributionsTable)
              ..where((c) => c.goalId.equals(g.id)))
            .get();
        final totalContributions = contributions.fold<int>(0, (s, c) => s + c.amountPaise);
        final currentBal = totalContributions / 100.0;

        // Real target from DB; null means no target set yet
        final target = g.targetPaise != null ? g.targetPaise! / 100.0 : 0.0;
        if (target > 0) totalTarget += target;
        totalSaved += currentBal;

        _goalsList.add({
          'name': g.name,
          'target': target,
          'saved': currentBal,
          'progress': target > 0 ? (currentBal / target).clamp(0.0, 1.0) : 0.0,
          'color': _getCategoryColor(goalColorIdx++),
        });
      }
      _totalGoalTarget = totalTarget;
      _totalGoalSaved = totalSaved;

      // Savings trajectory: cumulative saving from closed monthly snapshots (real data only)
      // Uses the last horizon months' savingPaise from monthSnapshot where status = 'closed'.
      final trajectoryMonths = <String>[];
      for (int i = horizon - 1; i >= 0; i--) {
        final m = DateTime(_selectedMonth.year, _selectedMonth.month - i);
        trajectoryMonths.add('${m.year}-${m.month.toString().padLeft(2, '0')}');
      }
      final trajectorySnaps = await (db.select(db.monthSnapshotsTable)
            ..where((s) =>
                s.householdId.equals(householdId) &
                s.status.equals('closed')))
          .get();
      double cumulativeSaving = 0;
      _savingsTrajectory = trajectoryMonths.map((ym) {
        final snap = trajectorySnaps.where((s) => s.yearMonth == ym).firstOrNull;
        if (snap != null) cumulativeSaving += snap.savingPaise / 100.0;
        return cumulativeSaving;
      }).toList();
      // Update trajectory month labels for the chart
      _trendsMonthLabels = trajectoryMonths
          .map((ym) {
            final parts = ym.split('-');
            final mIdx = int.parse(parts[1]) - 1;
            return monthNamesShort[mIdx];
          })
          .toList();

      // 6. Yearly Summary — income, spending, saving, protection, adjustments, reserves
      _yearlyMonths = [];
      double yearlyTotalInc = 0;
      double yearlyTotalExp = 0;
      double yearlyTotalProt = 0;
      double yearlyTotalAdj = 0;
      double yearlyTotalRes = 0;
      const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      for (int i = 0; i < 12; i++) {
        final ymVal = '${_selectedMonth.year}-${(i + 1).toString().padLeft(2, '0')}';
        final mEntries = await db.entryDao.getMonth(ymVal, householdId: householdId);

        // Also check MonthSnapshot for closed months — use snapshot reserves if available
        final snapshot = await (db.select(db.monthSnapshotsTable)
              ..where((s) =>
                  s.householdId.equals(householdId) & s.yearMonth.equals(ymVal)))
            .getSingleOrNull();

        double mInc = 0;
        double mExp = 0;
        double mSav = 0;
        double mProt = 0;
        double mAdj = 0;
        double mRes = 0;

        for (final e in mEntries) {
          final val = e.amountPaise / 100.0;
          switch (e.kind) {
            case 'income':
              mInc += val;
            case 'incomeDeduction':
              mInc -= val;
            case 'spending':
              mExp += val;
            case 'saving':
              mSav += val;
            case 'protection':
              mProt += val;
            case 'adjustment':
              // isDeduction: true → outflow (negative adj); false → inflow (positive adj)
              mAdj += deductionCategoryIds.contains(e.categoryId) ? -val : val;
          }
        }

        // Use snapshot reserves if month is closed (frozen value)
        if (snapshot != null && snapshot.status == 'closed') {
          mRes = snapshot.reservesPaise / 100.0;
        } else if (mEntries.isNotEmpty) {
          // Live: read reserve_lines for this month
          final reserveLines = await (db.select(db.reserveLinesTable)
                ..where((r) =>
                    r.householdId.equals(householdId) & r.yearMonth.equals(ymVal)))
              .get();
          mRes = reserveLines.fold(0.0, (s, r) => s + r.amountPaise / 100.0);
        }

        yearlyTotalInc += mInc;
        yearlyTotalExp += mExp;
        yearlyTotalProt += mProt;
        yearlyTotalAdj += mAdj;
        yearlyTotalRes += mRes;

        _yearlyMonths.add({
          'month': monthNames[i],
          'income': mInc,
          'spending': mExp,
          'savings': mInc - mExp,
          'saving': mSav,
          'protection': mProt,
          'adjustments': mAdj,
          'reserves': mRes,
        });
      }
      _yearlyTotalIncome = yearlyTotalInc;
      _yearlyTotalSpending = yearlyTotalExp;
      _yearlyTotalSavings = yearlyTotalInc - yearlyTotalExp;
      _yearlyTotalProtection = yearlyTotalProt;
      _yearlyTotalAdjustments = yearlyTotalAdj;
      _yearlyTotalReserves = yearlyTotalRes;

      // Annual Targets (for the selected year's household)
      _annualTargets = await (db.select(db.annualTargetsTable)
            ..where((t) => t.householdId.equals(householdId)))
          .get();
    } catch (_) {
      _trendsIncome = List.filled(8, 0.0);
      _trendsSpending = List.filled(8, 0.0);
      _trendsMonthLabels = List.filled(8, '');
      _avgIncome = 0.0;
      _avgSpending = 0.0;
      _netSavings = 0.0;
      _breakdownCategories = [];
      _totalBreakdownSpending = 0.0;
      _spendingActualPct = 0.0;
      _savingActualPct = 0.0;
      _protectionActualPct = 0.0;
      _spendingActualAmt = 0.0;
      _savingActualAmt = 0.0;
      _protectionActualAmt = 0.0;
      _cashFlowIn = List.filled(6, 0.0);
      _cashFlowOut = List.filled(6, 0.0);
      _cashFlowMonthLabels = List.filled(6, '');
      _totalInflow = 0.0;
      _totalOutflow = 0.0;
      _goalsList = [];
      _totalGoalTarget = 0.0;
      _totalGoalSaved = 0.0;
      _savingsTrajectory = List.filled(8, 0.0);
      _yearlyMonths = [];
      _yearlyTotalIncome = 0.0;
      _yearlyTotalSpending = 0.0;
      _yearlyTotalSavings = 0.0;
      _yearlyTotalProtection = 0.0;
      _yearlyTotalAdjustments = 0.0;
      _yearlyTotalReserves = 0.0;
      _annualTargets = [];
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  String _formatMonth(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.year}';
  }

  Color _getCategoryColor(int index) {
    const colors = [
      Color(0xFF00A887), // Teal
      Color(0xFF8B5CF6), // Purple
      Color(0xFFF59E0B), // Amber
      Color(0xFFEF4444), // Red
      Color(0xFF3B82F6), // Blue
      Color(0xFFEC4899), // Pink
      Color(0xFF10B981), // Emerald
    ];
    return colors[index % colors.length];
  }

  String _getReportTitle(String id) => switch (id) {
        'trends' => 'Monthly Trends',
        'breakdown' => 'Category Breakdown',
        'needs_wants' => 'Cashflow Distribution',
        'cash_flow' => 'Cash Flow (In/Out)',
        'goal_progress' => 'Goal Progress',
        _ => 'Annual Summary',
      };

  void _showFilterSheet(BuildContext context, ColorScheme cs, String householdId) async {
    final db = ref.read(appDatabaseProvider);
    final categories = await db.categoryDao.getAllActive(householdId: householdId);
    if (!context.mounted) return;

    final currentFilter = ref.read(reportFilterProvider);
    int selectedHorizon = currentFilter.timeHorizonMonths;
    String selectedKind = currentFilter.kindFilter;
    String selectedNeedOrWant = currentFilter.needOrWantFilter;
    String? selectedCategory = currentFilter.categoryIdFilter;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final isFiltered = selectedHorizon != 8 ||
              selectedKind != 'all' ||
              selectedNeedOrWant != 'all' ||
              selectedCategory != null;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.tune_rounded, size: 20, color: cs.primary),
                          const SizedBox(width: 8),
                          const Text(
                            'Report Filters',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      if (isFiltered)
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              selectedHorizon = 8;
                              selectedKind = 'all';
                              selectedNeedOrWant = 'all';
                              selectedCategory = null;
                            });
                          },
                          child: const Text('Reset All'),
                        ),
                    ],
                  ),
                  const Divider(height: 24),

                  // 1. Time Horizon
                  const Text(
                    'Time Horizon',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [3, 6, 8, 12].map((m) {
                      final label = m == 12 ? '1 Year' : '$m Months';
                      final isSelected = selectedHorizon == m;
                      return ChoiceChip(
                        label: Text(label),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) setModalState(() => selectedHorizon = m);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // 2. Category Kind
                  const Text(
                    'Transaction Kind',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ('all', 'All Kinds'),
                      ('spending', 'Spending'),
                      ('saving', 'Saving'),
                      ('protection', 'Protection'),
                    ].map((k) {
                      final isSelected = selectedKind == k.$1;
                      return ChoiceChip(
                        label: Text(k.$2),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) setModalState(() => selectedKind = k.$1);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // 3. Need vs Want
                  const Text(
                    'Need vs Want',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ('all', 'All'),
                      ('need', 'Needs Only'),
                      ('want', 'Wants Only'),
                    ].map((nw) {
                      final isSelected = selectedNeedOrWant == nw.$1;
                      return ChoiceChip(
                        label: Text(nw.$2),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) setModalState(() => selectedNeedOrWant = nw.$1);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // 4. Specific Category
                  const Text(
                    'Category',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHigh.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: selectedCategory,
                        isExpanded: true,
                        hint: const Text('All Categories'),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('All Categories'),
                          ),
                          ...categories.map(
                            (c) => DropdownMenuItem<String?>(
                              value: c.id,
                              child: Text(c.name),
                            ),
                          ),
                        ],
                        onChanged: (val) => setModalState(() => selectedCategory = val),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Apply Button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        ref.read(reportFilterProvider.notifier).applyFilters(
                              timeHorizonMonths: selectedHorizon,
                              kindFilter: selectedKind,
                              needOrWantFilter: selectedNeedOrWant,
                              categoryIdFilter: selectedCategory,
                            );
                        Navigator.pop(ctx);
                        _loadRealData();
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<YearMonth>(selectedMonthProvider, (prev, next) {
      if (prev != next) {
        setState(() {
          _selectedMonth = DateTime(next.year, next.month);
        });
        _loadRealData();
      }
    });

    final cs = Theme.of(context).colorScheme;
    final String title = _getReportTitle(widget.reportId);
    final filterState = ref.watch(reportFilterProvider);
    final householdId =
        ref.watch(authStateProvider).valueOrNull?.householdId ?? 'local';

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              AppFeedback.showInfo(context, 'Sharing $title report summary...');
            },
            tooltip: 'Share',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month Switcher + Filter Button Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHigh.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {
                          final prevM = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
                          ref.read(selectedMonthProvider.notifier).select(YearMonth(prevM.year, prevM.month));
                          setState(() {
                            _selectedMonth = prevM;
                          });
                          _loadRealData();
                        },
                        child: const Icon(Icons.chevron_left_rounded, size: 18),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatMonth(_selectedMonth),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () {
                          final nextM = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
                          ref.read(selectedMonthProvider.notifier).select(YearMonth(nextM.year, nextM.month));
                          setState(() {
                            _selectedMonth = nextM;
                          });
                          _loadRealData();
                        },
                        child: const Icon(Icons.chevron_right_rounded, size: 18),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _showFilterSheet(context, cs, householdId),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: filterState.isFiltered
                          ? cs.primary.withValues(alpha: 0.15)
                          : cs.surfaceContainerHigh.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: filterState.isFiltered
                            ? cs.primary
                            : cs.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          size: 18,
                          color: filterState.isFiltered ? cs.primary : cs.onSurface,
                        ),
                        if (filterState.isFiltered)
                          Positioned(
                            top: -2,
                            right: -2,
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: cs.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 80),
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              // Segmented Control (if applicable)
              if (widget.reportId == 'trends' || widget.reportId == 'breakdown' || widget.reportId == 'needs_wants')
                Container(
                  padding: const EdgeInsets.all(4),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHigh.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _segmentedIndex = 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _segmentedIndex == 0 ? cs.surface : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: _segmentedIndex == 0
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : null,
                            ),
                            child: Text(
                              'Visual Chart',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: _segmentedIndex == 0 ? FontWeight.w700 : FontWeight.w500,
                                color: _segmentedIndex == 0 ? cs.onSurface : cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _segmentedIndex = 1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _segmentedIndex == 1 ? cs.surface : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: _segmentedIndex == 1
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : null,
                            ),
                            child: Text(
                              'Statement Data',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: _segmentedIndex == 1 ? FontWeight.w700 : FontWeight.w500,
                                color: _segmentedIndex == 1 ? cs.onSurface : cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Dynamic Report Chart and Data Layouts
              _buildReportContent(context, cs),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReportContent(BuildContext context, ColorScheme cs) {
    return switch (widget.reportId) {
      'trends' => _buildTrendsReport(context, cs),
      'breakdown' => _buildBreakdownReport(context, cs),
      'needs_wants' => _buildNeedsWantsReport(context, cs),
      'cash_flow' => _buildCashFlowReport(context, cs),
      'goal_progress' => _buildGoalProgressReport(context, cs),
      _ => _buildYearlyReport(context, cs),
    };
  }

  // 1. MONTHLY TRENDS REPORT
  Widget _buildTrendsReport(BuildContext context, ColorScheme cs) {
    if (_segmentedIndex == 1) {
      return _buildTrendsStatementTable(context, cs);
    }

    final maxInc = _trendsIncome.isEmpty ? 0.0 : _trendsIncome.reduce(math.max);
    final maxSpe = _trendsSpending.isEmpty ? 0.0 : _trendsSpending.reduce(math.max);
    final maxVal = math.max(maxInc, maxSpe);
    final chartMaxY = maxVal > 0 ? maxVal * 1.2 : 100.0;
    final chartInterval = chartMaxY / 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              SizedBox(
                height: 220,
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: chartMaxY,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: chartInterval,
                      getDrawingHorizontalLine: (val) => FlLine(
                        color: cs.outlineVariant.withValues(alpha: 0.2),
                        strokeWidth: 1,
                        dashArray: [4, 4],
                      ),
                    ),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          getTitlesWidget: (value, _) {
                            final idx = value.toInt();
                            if (idx >= 0 && idx < _trendsMonthLabels.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  _trendsMonthLabels[idx],
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: cs.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      // Income Line
                      LineChartBarData(
                        spots: List.generate(_trendsIncome.length, (i) => FlSpot(i.toDouble(), _trendsIncome[i])),
                        isCurved: true,
                        color: const Color(0xFF00A887),
                        barWidth: 3.5,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: const Color(0xFF00A887).withValues(alpha: 0.08),
                        ),
                      ),
                      // Spending Line
                      LineChartBarData(
                        spots: List.generate(_trendsSpending.length, (i) => FlSpot(i.toDouble(), _trendsSpending[i])),
                        isCurved: true,
                        color: const Color(0xFF8B5CF6),
                        barWidth: 3.5,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  _DotLegendItem(color: Color(0xFF00A887), label: 'Inflow (Income)'),
                  SizedBox(width: 24),
                  _DotLegendItem(color: Color(0xFF8B5CF6), label: 'Outflow (Spending)'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _StatMetricCard(
                dotColor: const Color(0xFF00A887),
                title: 'Avg Inflow',
                amountStr: '₹${_avgIncome.toStringAsFixed(0)}',
                badgeStr: '+5.4%',
                isPositive: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatMetricCard(
                dotColor: const Color(0xFF8B5CF6),
                title: 'Avg Outflow',
                amountStr: '₹${_avgSpending.toStringAsFixed(0)}',
                badgeStr: '-1.2%',
                isPositive: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Summary Table', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              _SummaryItemRow(label: 'Avg Monthly Income', valueStr: '₹${_avgIncome.toStringAsFixed(0)}'),
              Divider(height: 20, thickness: 0.6, color: cs.outlineVariant.withValues(alpha: 0.2)),
              _SummaryItemRow(label: 'Avg Monthly Spending', valueStr: '₹${_avgSpending.toStringAsFixed(0)}'),
              Divider(height: 20, thickness: 0.6, color: cs.outlineVariant.withValues(alpha: 0.2)),
              _SummaryItemRow(
                label: 'Net Monthly Savings',
                valueStr: '₹${_netSavings.toStringAsFixed(0)}',
                valueColor: const Color(0xFF00A887),
                isBold: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrendsStatementTable(BuildContext context, ColorScheme cs) {
    double totalInc = 0;
    double totalSpe = 0;
    for (int i = 0; i < _trendsIncome.length; i++) {
      totalInc += _trendsIncome[i];
      totalSpe += _trendsSpending[i];
    }
    final totalNet = totalInc - totalSpe;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monthly Trends Statement Data',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh.withValues(alpha: 0.5),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  children: const [
                    Expanded(flex: 2, child: Text('Month', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                    Expanded(flex: 3, child: Text('Income', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF00A887)))),
                    Expanded(flex: 3, child: Text('Outflow', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF8B5CF6)))),
                    Expanded(flex: 3, child: Text('Net', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 0.5),
              for (int i = _trendsIncome.length - 1; i >= 0; i--) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          _trendsMonthLabels[i],
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          '₹${_trendsIncome[i].toStringAsFixed(0)}',
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF00A887)),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          '₹${_trendsSpending[i].toStringAsFixed(0)}',
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF8B5CF6)),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          '₹${(_trendsIncome[i] - _trendsSpending[i]).toStringAsFixed(0)}',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: (_trendsIncome[i] - _trendsSpending[i]) >= 0 ? const Color(0xFF00A887) : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (i > 0) Divider(height: 1, thickness: 0.5, color: cs.outlineVariant.withValues(alpha: 0.2)),
              ],
              const Divider(height: 1, thickness: 1),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.15),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    const Expanded(flex: 2, child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                    Expanded(
                      flex: 3,
                      child: Text(
                        '₹${totalInc.toStringAsFixed(0)}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF00A887)),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        '₹${totalSpe.toStringAsFixed(0)}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF8B5CF6)),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        '₹${totalNet.toStringAsFixed(0)}',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: totalNet >= 0 ? const Color(0xFF00A887) : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 2. CATEGORY BREAKDOWN REPORT (Pie Chart + List)
  Widget _buildBreakdownReport(BuildContext context, ColorScheme cs) {
    if (_segmentedIndex == 1) {
      return _buildBreakdownStatementTable(context, cs);
    }

    if (_breakdownCategories.isEmpty) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          children: [
            Icon(Icons.donut_large_rounded, size: 56, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              'No Expense Data Available',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'No spending transactions were recorded for ${_formatMonth(_selectedMonth)}.',
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 240,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 36,
                    sections: List.generate(_breakdownCategories.length, (i) {
                      final item = _breakdownCategories[i];
                      final pct = _totalBreakdownSpending > 0
                          ? ((item['value'] as double) / _totalBreakdownSpending) * 100
                          : 0.0;
                      return PieChartSectionData(
                        color: item['color'] as Color,
                        value: item['value'] as double,
                        title: pct >= 5 ? '${pct.toStringAsFixed(0)}%' : '',
                        radius: 28,
                        titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 6,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(_breakdownCategories.length, (i) {
                      final item = _breakdownCategories[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(color: item['color'] as Color, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item['name'] as String,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Expenses list', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            children: List.generate(_breakdownCategories.length, (i) {
              final item = _breakdownCategories[i];
              final value = item['value'] as double;
              final pct = value / _totalBreakdownSpending;
              return Padding(
                padding: EdgeInsets.only(bottom: i == _breakdownCategories.length - 1 ? 0 : 16.0),
                child: _CategoryBreakdownRow(
                  title: item['name'] as String,
                  spentStr: '₹${value.toStringAsFixed(0)}',
                  totalStr: '₹${_totalBreakdownSpending.toStringAsFixed(0)}',
                  progress: pct,
                  barColor: item['color'] as Color,
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildBreakdownStatementTable(BuildContext context, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category Breakdown Statement Data',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh.withValues(alpha: 0.5),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  children: const [
                    Expanded(flex: 4, child: Text('Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                    Expanded(flex: 3, child: Text('Amount', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                    Expanded(flex: 2, child: Text('Share', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 0.5),
              if (_breakdownCategories.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('No expense transactions in this month')),
                )
              else
                for (int i = 0; i < _breakdownCategories.length; i++) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: _breakdownCategories[i]['color'] as Color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _breakdownCategories[i]['name'] as String,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            '₹${(_breakdownCategories[i]['value'] as double).toStringAsFixed(0)}',
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '${_totalBreakdownSpending > 0 ? (((_breakdownCategories[i]['value'] as double) / _totalBreakdownSpending) * 100).toStringAsFixed(1) : 0}%',
                            textAlign: TextAlign.right,
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: cs.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i < _breakdownCategories.length - 1) Divider(height: 1, thickness: 0.5, color: cs.outlineVariant.withValues(alpha: 0.2)),
                ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNeedsWantsStatementTable(BuildContext context, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cashflow Distribution Statement Data',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              _SummaryItemRow(label: 'Spending Layer (Needs/Wants)', valueStr: '₹${_spendingActualAmt.toStringAsFixed(0)} (${_spendingActualPct.toStringAsFixed(1)}%)'),
              Divider(height: 20, thickness: 0.6, color: cs.outlineVariant.withValues(alpha: 0.2)),
              _SummaryItemRow(label: 'Saving Layer (Goals & Funds)', valueStr: '₹${_savingActualAmt.toStringAsFixed(0)} (${_savingActualPct.toStringAsFixed(1)}%)'),
              Divider(height: 20, thickness: 0.6, color: cs.outlineVariant.withValues(alpha: 0.2)),
              _SummaryItemRow(label: 'Protection Layer (Reserves)', valueStr: '₹${_protectionActualAmt.toStringAsFixed(0)} (${_protectionActualPct.toStringAsFixed(1)}%)'),
            ],
          ),
        ),
      ],
    );
  }

  // ── Plan Pct adjuster (Strict 100% total, lock-aware, user-friendly) ──────
  void _adjustPlanPct(String layer, double newPct) {
    setState(() {
      final target = newPct.roundToDouble().clamp(0.0, 100.0);

      if (layer == 'spending') {
        if (_spendingLocked) return;
        if (_savingLocked && _protectionLocked) return;

        if (_savingLocked) {
          final maxAllowed = (100.0 - _savingPlanPct).clamp(0.0, 100.0);
          _spendingPlanPct = target.clamp(0.0, maxAllowed);
          _protectionPlanPct = (100.0 - _spendingPlanPct - _savingPlanPct).clamp(0.0, 100.0);
        } else if (_protectionLocked) {
          final maxAllowed = (100.0 - _protectionPlanPct).clamp(0.0, 100.0);
          _spendingPlanPct = target.clamp(0.0, maxAllowed);
          _savingPlanPct = (100.0 - _spendingPlanPct - _protectionPlanPct).clamp(0.0, 100.0);
        } else {
          final oldVal = _spendingPlanPct;
          _spendingPlanPct = target;
          final delta = target - oldVal;

          final othersTotal = _savingPlanPct + _protectionPlanPct;
          if (othersTotal > 0) {
            final saveRatio = _savingPlanPct / othersTotal;
            _savingPlanPct = (_savingPlanPct - (delta * saveRatio)).roundToDouble().clamp(0.0, 100.0 - _spendingPlanPct);
            _protectionPlanPct = (100.0 - _spendingPlanPct - _savingPlanPct).clamp(0.0, 100.0);
            _savingPlanPct = (100.0 - _spendingPlanPct - _protectionPlanPct).clamp(0.0, 100.0);
          } else {
            _savingPlanPct = ((100.0 - _spendingPlanPct) / 2).roundToDouble();
            _protectionPlanPct = (100.0 - _spendingPlanPct - _savingPlanPct).clamp(0.0, 100.0);
          }
        }
      } else if (layer == 'saving') {
        if (_savingLocked) return;
        if (_spendingLocked && _protectionLocked) return;

        if (_spendingLocked) {
          final maxAllowed = (100.0 - _spendingPlanPct).clamp(0.0, 100.0);
          _savingPlanPct = target.clamp(0.0, maxAllowed);
          _protectionPlanPct = (100.0 - _spendingPlanPct - _savingPlanPct).clamp(0.0, 100.0);
        } else if (_protectionLocked) {
          final maxAllowed = (100.0 - _protectionPlanPct).clamp(0.0, 100.0);
          _savingPlanPct = target.clamp(0.0, maxAllowed);
          _spendingPlanPct = (100.0 - _savingPlanPct - _protectionPlanPct).clamp(0.0, 100.0);
        } else {
          final oldVal = _savingPlanPct;
          _savingPlanPct = target;
          final delta = target - oldVal;

          final othersTotal = _spendingPlanPct + _protectionPlanPct;
          if (othersTotal > 0) {
            final spendRatio = _spendingPlanPct / othersTotal;
            _spendingPlanPct = (_spendingPlanPct - (delta * spendRatio)).roundToDouble().clamp(0.0, 100.0 - _savingPlanPct);
            _protectionPlanPct = (100.0 - _spendingPlanPct - _savingPlanPct).clamp(0.0, 100.0);
            _spendingPlanPct = (100.0 - _savingPlanPct - _protectionPlanPct).clamp(0.0, 100.0);
          } else {
            _spendingPlanPct = ((100.0 - _savingPlanPct) / 2).roundToDouble();
            _protectionPlanPct = (100.0 - _spendingPlanPct - _savingPlanPct).clamp(0.0, 100.0);
          }
        }
      } else {
        // protection
        if (_protectionLocked) return;
        if (_spendingLocked && _savingLocked) return;

        if (_spendingLocked) {
          final maxAllowed = (100.0 - _spendingPlanPct).clamp(0.0, 100.0);
          _protectionPlanPct = target.clamp(0.0, maxAllowed);
          _savingPlanPct = (100.0 - _spendingPlanPct - _protectionPlanPct).clamp(0.0, 100.0);
        } else if (_savingLocked) {
          final maxAllowed = (100.0 - _savingPlanPct).clamp(0.0, 100.0);
          _protectionPlanPct = target.clamp(0.0, maxAllowed);
          _spendingPlanPct = (100.0 - _savingPlanPct - _protectionPlanPct).clamp(0.0, 100.0);
        } else {
          final oldVal = _protectionPlanPct;
          _protectionPlanPct = target;
          final delta = target - oldVal;

          final othersTotal = _spendingPlanPct + _savingPlanPct;
          if (othersTotal > 0) {
            final spendRatio = _spendingPlanPct / othersTotal;
            _spendingPlanPct = (_spendingPlanPct - (delta * spendRatio)).roundToDouble().clamp(0.0, 100.0 - _protectionPlanPct);
            _savingPlanPct = (100.0 - _spendingPlanPct - _protectionPlanPct).clamp(0.0, 100.0);
            _spendingPlanPct = (100.0 - _savingPlanPct - _protectionPlanPct).clamp(0.0, 100.0);
          } else {
            _spendingPlanPct = ((100.0 - _protectionPlanPct) / 2).roundToDouble();
            _savingPlanPct = (100.0 - _spendingPlanPct - _protectionPlanPct).clamp(0.0, 100.0);
          }
        }
      }

      final authState = ref.read(authStateProvider).valueOrNull;
      final householdId = authState?.householdId ?? 'local';
      final lockNotifier = ref.read(planDistributionLockProvider(householdId).notifier);
      if (_spendingLocked) lockNotifier.setLockedValue('spending', _spendingPlanPct);
      if (_savingLocked) lockNotifier.setLockedValue('saving', _savingPlanPct);
      if (_protectionLocked) lockNotifier.setLockedValue('protection', _protectionPlanPct);
    });
  }

  void _setPlanPreset(double spend, double save, double protect) {
    final authState = ref.read(authStateProvider).valueOrNull;
    final householdId = authState?.householdId ?? 'local';
    ref.read(planDistributionLockProvider(householdId).notifier).unlockAll();
    setState(() {
      _spendingLocked = false;
      _savingLocked = false;
      _protectionLocked = false;
      _spendingPlanPct = spend;
      _savingPlanPct = save;
      _protectionPlanPct = protect;
    });
  }

  void _promptDirectPct(String layer, String label, double currentVal) {
    final ctrl = TextEditingController(text: currentVal > 0 ? currentVal.toStringAsFixed(0) : '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Set $label Target %'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [AppInputFormatters.positiveDecimal()],
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Target Percentage',
            hintText: 'e.g. 50',
            suffixText: '%',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final val = double.tryParse(ctrl.text.trim());
              if (val == null || val < 0 || val > 100) {
                AppFeedback.showWarning(ctx, 'Please enter a valid percentage between 0 and 100.');
                return;
              }
              _adjustPlanPct(layer, val);
              Navigator.pop(ctx);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  // 3. CASHFLOW DISTRIBUTION REPORT (PLAN VS ACTUAL)
  Widget _buildNeedsWantsReport(BuildContext context, ColorScheme cs) {
    if (_segmentedIndex == 1) {
      return _buildNeedsWantsStatementTable(context, cs);
    }
    final authState = ref.watch(authStateProvider).valueOrNull;
    final householdId = authState?.householdId ?? 'local';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Main dual-pie chart card ─────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          'Plan Distribution',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 140,
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 3,
                              centerSpaceRadius: 24,
                              sections: [
                                PieChartSectionData(
                                  color: const Color(0xFFEF4444),
                                  value: _spendingPlanPct,
                                  title: '${_spendingPlanPct.toStringAsFixed(0)}%',
                                  radius: 30,
                                  titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                PieChartSectionData(
                                  color: const Color(0xFF10B981),
                                  value: _savingPlanPct,
                                  title: '${_savingPlanPct.toStringAsFixed(0)}%',
                                  radius: 30,
                                  titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                PieChartSectionData(
                                  color: const Color(0xFFF59E0B),
                                  value: _protectionPlanPct,
                                  title: '${_protectionPlanPct.toStringAsFixed(0)}%',
                                  radius: 30,
                                  titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 140,
                    width: 0.6,
                    color: cs.outlineVariant.withValues(alpha: 0.3),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          'Actual Distribution',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 140,
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 3,
                              centerSpaceRadius: 24,
                              sections: [
                                PieChartSectionData(
                                  color: const Color(0xFFEF4444),
                                  value: _spendingActualPct,
                                  title: '${_spendingActualPct.toStringAsFixed(0)}%',
                                  radius: 30,
                                  titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                PieChartSectionData(
                                  color: const Color(0xFF10B981),
                                  value: _savingActualPct,
                                  title: '${_savingActualPct.toStringAsFixed(0)}%',
                                  radius: 30,
                                  titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                PieChartSectionData(
                                  color: const Color(0xFFF59E0B),
                                  value: _protectionActualPct,
                                  title: '${_protectionActualPct.toStringAsFixed(0)}%',
                                  radius: 30,
                                  titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _DotLegendItem(color: Color(0xFFEF4444), label: 'Spending'),
                  SizedBox(width: 16),
                  _DotLegendItem(color: Color(0xFF10B981), label: 'Saving'),
                  SizedBox(width: 16),
                  _DotLegendItem(color: Color(0xFFF59E0B), label: 'Protection'),
                ],
              ),
            ],
          ),
        ),

        // ── Customize Plan button ─────────────────────────────────────────────
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => setState(() => _planCustomizerExpanded = !_planCustomizerExpanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.tune_rounded, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Customize Plan Distribution',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.primary,
                    ),
                  ),
                ),
                Icon(
                  _planCustomizerExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  size: 20,
                  color: cs.primary,
                ),
              ],
            ),
          ),
        ),

        // ── Sliders & Presets (expanded) ──────────────────────────────────────
        if (_planCustomizerExpanded) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Target Split (Must total 100%)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF10B981)),
                          const SizedBox(width: 4),
                          Text(
                            'Total: ${(_spendingPlanPct + _savingPlanPct + _protectionPlanPct).round()}%',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF10B981)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Presets
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.flash_on_rounded, size: 14),
                        label: const Text('50/30/20', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _setPlanPreset(50, 30, 20),
                      ),
                      const SizedBox(width: 6),
                      ActionChip(
                        label: const Text('60/20/20', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _setPlanPreset(60, 20, 20),
                      ),
                      const SizedBox(width: 6),
                      ActionChip(
                        label: const Text('70/20/10', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _setPlanPreset(70, 20, 10),
                      ),
                      const SizedBox(width: 6),
                      ActionChip(
                        label: const Text('40/40/20', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _setPlanPreset(40, 40, 20),
                      ),
                      const SizedBox(width: 6),
                      ActionChip(
                        avatar: const Icon(Icons.restart_alt_rounded, size: 14),
                        label: const Text('Reset', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _setPlanPreset(
                          _initialSpendingBudgetPct,
                          _initialSavingBudgetPct,
                          _initialProtectionBudgetPct,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Spending slider
                _PlanSlider(
                  label: 'Spending',
                  color: const Color(0xFFEF4444),
                  value: _spendingPlanPct,
                  isLocked: _spendingLocked,
                  onLockToggle: () {
                    final notifier = ref.read(planDistributionLockProvider(householdId).notifier);
                    notifier.toggleLock('spending', _spendingPlanPct);
                    setState(() => _spendingLocked = !_spendingLocked);
                  },
                  onStep: (delta) => _adjustPlanPct('spending', _spendingPlanPct + delta),
                  onDirectInput: () => _promptDirectPct('spending', 'Spending', _spendingPlanPct),
                  onChanged: (v) => _adjustPlanPct('spending', v),
                ),

                // Saving slider
                _PlanSlider(
                  label: 'Saving',
                  color: const Color(0xFF10B981),
                  value: _savingPlanPct,
                  isLocked: _savingLocked,
                  onLockToggle: () {
                    final notifier = ref.read(planDistributionLockProvider(householdId).notifier);
                    notifier.toggleLock('saving', _savingPlanPct);
                    setState(() => _savingLocked = !_savingLocked);
                  },
                  onStep: (delta) => _adjustPlanPct('saving', _savingPlanPct + delta),
                  onDirectInput: () => _promptDirectPct('saving', 'Saving', _savingPlanPct),
                  onChanged: (v) => _adjustPlanPct('saving', v),
                ),

                // Protection slider
                _PlanSlider(
                  label: 'Protection',
                  color: const Color(0xFFF59E0B),
                  value: _protectionPlanPct,
                  isLocked: _protectionLocked,
                  onLockToggle: () {
                    final notifier = ref.read(planDistributionLockProvider(householdId).notifier);
                    notifier.toggleLock('protection', _protectionPlanPct);
                    setState(() => _protectionLocked = !_protectionLocked);
                  },
                  onStep: (delta) => _adjustPlanPct('protection', _protectionPlanPct + delta),
                  onDirectInput: () => _promptDirectPct('protection', 'Protection', _protectionPlanPct),
                  onChanged: (v) => _adjustPlanPct('protection', v),
                ),

                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 13, color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'Tap 🔒 to lock a target percentage while adjusting other layers.',
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 24),
        Text('Allocation vs Actual Comparison', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              _ComparisonRow(
                title: 'Spending Layer',
                planPct: _spendingPlanPct,
                actualPct: _spendingActualPct,
                diffPct: _spendingActualPct - _spendingPlanPct,
                isOverspent: _spendingActualPct > _spendingPlanPct,
                color: const Color(0xFFEF4444),
              ),
              Divider(height: 24, thickness: 0.6, color: cs.outlineVariant.withValues(alpha: 0.2)),
              _ComparisonRow(
                title: 'Saving Layer',
                planPct: _savingPlanPct,
                actualPct: _savingActualPct,
                diffPct: _savingActualPct - _savingPlanPct,
                isOverspent: _savingActualPct < _savingPlanPct,
                color: const Color(0xFF10B981),
              ),
              Divider(height: 24, thickness: 0.6, color: cs.outlineVariant.withValues(alpha: 0.2)),
              _ComparisonRow(
                title: 'Protection Layer',
                planPct: _protectionPlanPct,
                actualPct: _protectionActualPct,
                diffPct: _protectionActualPct - _protectionPlanPct,
                isOverspent: _protectionActualPct < _protectionPlanPct,
                color: const Color(0xFFF59E0B),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 4. CASH FLOW REPORT (Inflow vs Outflow Bar Chart)
  Widget _buildCashFlowReport(BuildContext context, ColorScheme cs) {
    final maxIn = _cashFlowIn.isEmpty ? 0.0 : _cashFlowIn.reduce(math.max);
    final maxOut = _cashFlowOut.isEmpty ? 0.0 : _cashFlowOut.reduce(math.max);
    final maxVal = math.max(maxIn, maxOut);
    final chartMaxY = maxVal > 0 ? maxVal * 1.2 : 100.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 240,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
          ),
          padding: const EdgeInsets.all(20),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: chartMaxY,
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, _) {
                      final idx = value.toInt();
                      if (idx >= 0 && idx < _cashFlowMonthLabels.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(_cashFlowMonthLabels[idx], style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(6, (index) {
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: _cashFlowIn[index],
                      color: const Color(0xFF10B981), // Emerald Inflow
                      width: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    BarChartRodData(
                      toY: _cashFlowOut[index],
                      color: const Color(0xFFEF4444), // Red Outflow
                      width: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            _DotLegendItem(color: Color(0xFF10B981), label: 'Total Inflow'),
            SizedBox(width: 24),
            _DotLegendItem(color: Color(0xFFEF4444), label: 'Total Outflow'),
          ],
        ),
        const SizedBox(height: 24),
        Text('Inflow / Outflow Summary', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              _SummaryItemRow(
                label: 'Cumulative Cash Inflow',
                valueStr: '₹${_totalInflow.toStringAsFixed(0)}',
                valueColor: const Color(0xFF10B981),
              ),
              Divider(height: 20, thickness: 0.6, color: cs.outlineVariant.withValues(alpha: 0.2)),
              _SummaryItemRow(
                label: 'Cumulative Cash Outflow',
                valueStr: '₹${_totalOutflow.toStringAsFixed(0)}',
                valueColor: const Color(0xFFEF4444),
              ),
              Divider(height: 20, thickness: 0.6, color: cs.outlineVariant.withValues(alpha: 0.2)),
              _SummaryItemRow(
                label: 'Net Balance Flow',
                valueStr: '₹${(_totalInflow - _totalOutflow).toStringAsFixed(0)}',
                valueColor: const Color(0xFF00A887),
                isBold: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 5. GOAL PROGRESS REPORT (Savings growth + Sinking Funds list)
  Widget _buildGoalProgressReport(BuildContext context, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Savings Growth (in Thousands)',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 180,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          getTitlesWidget: (value, _) {
                            // Use the trend month labels which now reflect real months
                            final idx = value.toInt();
                            if (idx >= 0 && idx < _trendsMonthLabels.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(_trendsMonthLabels[idx], style: TextStyle(fontSize: 9, color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: List.generate(_savingsTrajectory.length, (i) => FlSpot(i.toDouble(), _savingsTrajectory[i])),
                        isCurved: true,
                        color: const Color(0xFF00A887),
                        barWidth: 3.5,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: const Color(0xFF00A887).withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Sinking Funds & Savings Goals', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            if (_totalGoalTarget > 0)
              Text(
                'Total: ₹${_totalGoalSaved.toStringAsFixed(0)} / ₹${_totalGoalTarget.toStringAsFixed(0)}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.primary),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Column(
          children: List.generate(_goalsList.length, (i) {
            final item = _goalsList[i];
            final saved = item['saved'] as double;
            final target = item['target'] as double;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item['name'] as String, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      Text(
                        '₹${saved.toStringAsFixed(0)} / ₹${target.toStringAsFixed(0)}',
                        style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurfaceVariant, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: item['progress'] as double,
                      minHeight: 8,
                      backgroundColor: cs.outlineVariant.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(item['color'] as Color),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${((item['progress'] as double) * 100).toStringAsFixed(0)}%',
                        style: TextStyle(fontSize: 11, color: item['color'] as Color, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  // 6. YEARLY SUMMARY REPORT — all waterfall buckets month-wise
  Widget _buildYearlyReport(BuildContext context, ColorScheme cs) {
    final totalIncome = _yearlyTotalIncome;
    final totalSpending = _yearlyTotalSpending;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Annual Targets vs YTD Actuals ──────────────────────────────────
        if (_annualTargets.isNotEmpty) ...[
          Text(
            'Annual Targets vs YTD Actuals',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            '${_selectedMonth.year} • ${_annualTargets.length} target${_annualTargets.length == 1 ? '' : 's'} set',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          ...(_annualTargets.map((t) {
            final isIncome = t.type == 'income';
            final targetAmt = t.targetPaise / 100.0;
            final actualAmt = isIncome ? totalIncome : totalSpending;
            final pct = targetAmt > 0 ? (actualAmt / targetAmt).clamp(0.0, 1.0) : 0.0;
            final targetColor = isIncome ? const Color(0xFF00A887) : const Color(0xFFEF4444);
            final isOnTrack = isIncome
                ? actualAmt >= targetAmt * 0.8
                : actualAmt <= targetAmt;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: targetColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isIncome ? Icons.trending_up_rounded : Icons.account_balance_wallet_outlined,
                            color: targetColor,
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            t.title,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: (isOnTrack ? const Color(0xFF00A887) : cs.error).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isOnTrack ? 'On Track' : 'Under Target',
                            style: TextStyle(
                              color: isOnTrack ? const Color(0xFF00A887) : cs.error,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Actual: ₹${_compactK(actualAmt)}',
                            style: TextStyle(color: targetColor, fontWeight: FontWeight.w700, fontSize: 12)),
                        Text('Target: ₹${_compactK(targetAmt)}',
                            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11)),
                        Text('${(pct * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 6,
                        backgroundColor: cs.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(targetColor),
                      ),
                    ),
                  ],
                ),
              ),
            );
          })).toList(),
          const Divider(height: 32),
        ],
        // ── Summary Metric Grid ────────────────────────────────────────────
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _YearlyMetricChip(label: 'Income', value: totalIncome, color: const Color(0xFF00A887)),
            _YearlyMetricChip(label: 'Spending', value: totalSpending, color: const Color(0xFFEF4444)),
            _YearlyMetricChip(label: 'Saving', value: _yearlyTotalSavings, color: const Color(0xFF8B5CF6)),
            _YearlyMetricChip(label: 'Protection', value: _yearlyTotalProtection, color: const Color(0xFF3B82F6)),
            _YearlyMetricChip(label: 'Adjustments', value: _yearlyTotalAdjustments, color: const Color(0xFFF59E0B), signed: true),
            _YearlyMetricChip(label: 'Reserves', value: _yearlyTotalReserves, color: const Color(0xFF78909C)),
          ],
        ),
        const SizedBox(height: 24),
        Text('Monthly Roll-up Table',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Swipe left/right for all columns',
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
        const SizedBox(height: 12),
        // Horizontally scrollable table with all 6 buckets
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Table(
              border: TableBorder(
                horizontalInside: BorderSide(
                    width: 0.6,
                    color: cs.outlineVariant.withValues(alpha: 0.15)),
              ),
              defaultColumnWidth: const FixedColumnWidth(90),
              columnWidths: const {
                0: FixedColumnWidth(48), // Month
              },
              children: [
                // Header row
                TableRow(
                  decoration: BoxDecoration(
                      color: cs.surfaceContainerHigh.withValues(alpha: 0.4)),
                  children: [
                    _buildTableCell('Mo', isHeader: true, cs: cs),
                    _buildTableCell('Income', isHeader: true, cs: cs),
                    _buildTableCell('Spend', isHeader: true, cs: cs),
                    _buildTableCell('Saving', isHeader: true, cs: cs),
                    _buildTableCell('Protectn', isHeader: true, cs: cs),
                    _buildTableCell('Adj', isHeader: true, cs: cs),
                    _buildTableCell('Reserves', isHeader: true, cs: cs),
                    _buildTableCell('Net', isHeader: true, cs: cs),
                  ],
                ),
                // Monthly data rows
                ...List.generate(_yearlyMonths.length, (i) {
                  final m = _yearlyMonths[i];
                  final net = (m['income'] as double) - (m['spending'] as double);
                  final adj = m['adjustments'] as double;
                  return TableRow(
                    decoration: i % 2 == 0
                        ? null
                        : BoxDecoration(
                            color: cs.surfaceContainerLowest.withValues(alpha: 0.3)),
                    children: [
                      _buildTableCell(m['month'] as String,
                          isHeader: true, cs: cs, fontSize: 11),
                      _buildTableCell(
                          '₹${_compactK(m['income'] as double)}',
                          textColor: const Color(0xFF00A887), cs: cs),
                      _buildTableCell(
                          '₹${_compactK(m['spending'] as double)}',
                          textColor: const Color(0xFFEF4444), cs: cs),
                      _buildTableCell(
                          '₹${_compactK(m['saving'] as double)}',
                          textColor: const Color(0xFF8B5CF6), cs: cs),
                      _buildTableCell(
                          '₹${_compactK(m['protection'] as double)}',
                          textColor: const Color(0xFF3B82F6), cs: cs),
                      _buildTableCell(
                          '${adj >= 0 ? '+' : ''}₹${_compactK(adj.abs())}',
                          textColor: adj >= 0
                              ? const Color(0xFF00A887)
                              : const Color(0xFFEF4444),
                          cs: cs),
                      _buildTableCell(
                          '₹${_compactK(m['reserves'] as double)}',
                          textColor: const Color(0xFF78909C), cs: cs),
                      _buildTableCell(
                          '${net >= 0 ? '+' : ''}₹${_compactK(net.abs())}',
                          textColor: net >= 0
                              ? const Color(0xFF00A887)
                              : const Color(0xFFEF4444),
                          isBold: true,
                          cs: cs),
                    ],
                  );
                }),
                // Totals footer row
                TableRow(
                  decoration: BoxDecoration(
                      color: cs.surfaceContainerHigh.withValues(alpha: 0.4)),
                  children: [
                    _buildTableCell('YR', isHeader: true, cs: cs, fontSize: 11),
                    _buildTableCell('₹${_compactK(totalIncome)}',
                        textColor: const Color(0xFF00A887),
                        isBold: true,
                        cs: cs),
                    _buildTableCell('₹${_compactK(totalSpending)}',
                        textColor: const Color(0xFFEF4444),
                        isBold: true,
                        cs: cs),
                    _buildTableCell('₹${_compactK(_yearlyTotalSavings)}',
                        textColor: const Color(0xFF8B5CF6),
                        isBold: true,
                        cs: cs),
                    _buildTableCell('₹${_compactK(_yearlyTotalProtection)}',
                        textColor: const Color(0xFF3B82F6),
                        isBold: true,
                        cs: cs),
                    _buildTableCell(
                        '${_yearlyTotalAdjustments >= 0 ? '+' : ''}₹${_compactK(_yearlyTotalAdjustments.abs())}',
                        textColor: _yearlyTotalAdjustments >= 0
                            ? const Color(0xFF00A887)
                            : const Color(0xFFEF4444),
                        isBold: true,
                        cs: cs),
                    _buildTableCell('₹${_compactK(_yearlyTotalReserves)}',
                        textColor: const Color(0xFF78909C),
                        isBold: true,
                        cs: cs),
                    _buildTableCell(
                        '${(totalIncome - totalSpending) >= 0 ? '+' : ''}₹${_compactK((totalIncome - totalSpending).abs())}',
                        textColor: (totalIncome - totalSpending) >= 0
                            ? const Color(0xFF00A887)
                            : const Color(0xFFEF4444),
                        isBold: true,
                        cs: cs),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Format number as K shorthand: 125000 → '125K', 5000 → '5K', 500 → '0.5K'
  String _compactK(double value) {
    if (value.abs() < 1000) return value.toStringAsFixed(0);
    return '${(value / 1000).toStringAsFixed(0)}K';
  }

  Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    Color? textColor,
    required ColorScheme cs,
    bool isBold = false,
    double? fontSize,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      child: Text(
        text,
        style: TextStyle(
          fontWeight:
              (isHeader || isBold) ? FontWeight.bold : FontWeight.w600,
          fontSize: fontSize ?? (isHeader ? 11 : 12),
          color: isHeader ? cs.onSurfaceVariant : (textColor ?? cs.onSurface),
        ),
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// Compact metric chip for the yearly report header.
class _YearlyMetricChip extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final bool signed;

  const _YearlyMetricChip({
    required this.label,
    required this.value,
    required this.color,
    this.signed = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final valueStr = signed && value != 0
        ? '${value >= 0 ? '+' : ''}₹${(value.abs() / 1000).toStringAsFixed(0)}K'
        : '₹${(value.abs() / 1000).toStringAsFixed(0)}K';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(valueStr,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: color)),
        ],
      ),
    );
  }
}


class _DotLegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _DotLegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _StatMetricCard extends StatelessWidget {
  final Color dotColor;
  final String title;
  final String amountStr;
  final String badgeStr;
  final bool isPositive;

  const _StatMetricCard({
    required this.dotColor,
    required this.title,
    required this.amountStr,
    required this.badgeStr,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant, fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            amountStr,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isPositive ? const Color(0xFFE0F2F1) : const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              badgeStr,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: isPositive ? const Color(0xFF00A887) : const Color(0xFFFF6B6B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItemRow extends StatelessWidget {
  final String label;
  final String valueStr;
  final Color? valueColor;
  final bool isBold;

  const _SummaryItemRow({
    required this.label,
    required this.valueStr,
    this.valueColor,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
        Text(
          valueStr,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
            color: valueColor ?? Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _CategoryBreakdownRow extends StatelessWidget {
  final String title;
  final String spentStr;
  final String totalStr;
  final double progress;
  final Color barColor;

  const _CategoryBreakdownRow({
    required this.title,
    required this.spentStr,
    required this.totalStr,
    required this.progress,
    required this.barColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: spentStr,
                    style: TextStyle(fontWeight: FontWeight.w700, color: cs.onSurfaceVariant, fontSize: 12),
                  ),
                  TextSpan(
                    text: ' / $totalStr',
                    style: TextStyle(fontWeight: FontWeight.w500, color: cs.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: cs.outlineVariant.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
      ],
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  final String title;
  final double planPct;
  final double actualPct;
  final double diffPct;
  final bool isOverspent;
  final Color color;

  const _ComparisonRow({
    required this.title,
    required this.planPct,
    required this.actualPct,
    required this.diffPct,
    required this.isOverspent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final diffSign = diffPct > 0 ? '+' : '';
    final diffColor = diffPct == 0 
        ? cs.onSurfaceVariant 
        : (title == 'Spending Layer' 
            ? (diffPct > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981))
            : (diffPct < 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Plan Target', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                const SizedBox(height: 2),
                Text('${planPct.toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Actual Spent', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                const SizedBox(height: 2),
                Text('${actualPct.toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Difference', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                const SizedBox(height: 2),
                Text(
                  '$diffSign${diffPct.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: diffColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Plan Distribution Slider ─────────────────────────────────────────────────

class _PlanSlider extends StatelessWidget {
  final String label;
  final Color color;
  final double value;
  final bool isLocked;
  final VoidCallback onLockToggle;
  final ValueChanged<int> onStep;
  final VoidCallback onDirectInput;
  final ValueChanged<double> onChanged;

  const _PlanSlider({
    required this.label,
    required this.color,
    required this.value,
    required this.isLocked,
    required this.onLockToggle,
    required this.onStep,
    required this.onDirectInput,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final intVal = value.round();
    final effectiveColor = isLocked ? color.withValues(alpha: 0.6) : color;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isLocked ? cs.surfaceContainerHighest.withValues(alpha: 0.3) : color.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLocked ? cs.outlineVariant.withValues(alpha: 0.5) : color.withValues(alpha: 0.18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(color: effectiveColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: isLocked ? cs.onSurfaceVariant : cs.onSurface,
                    ),
                  ),
                ),
                // Lock toggle button
                IconButton(
                  tooltip: isLocked ? 'Unlock $label' : 'Lock $label',
                  icon: Icon(
                    isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                    size: 18,
                    color: isLocked ? cs.primary : cs.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: onLockToggle,
                ),
                const SizedBox(width: 4),
                // Decrement button
                IconButton(
                  tooltip: 'Decrease 1%',
                  icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  color: isLocked ? cs.onSurfaceVariant.withValues(alpha: 0.3) : cs.onSurface,
                  onPressed: isLocked ? null : () => onStep(-1),
                ),
                // Tappable percentage chip for direct input
                GestureDetector(
                  onTap: isLocked ? null : onDirectInput,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: effectiveColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: effectiveColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$intVal%',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: effectiveColor,
                          ),
                        ),
                        if (!isLocked) ...[
                          const SizedBox(width: 3),
                          Icon(Icons.edit_rounded, size: 11, color: effectiveColor.withValues(alpha: 0.7)),
                        ],
                      ],
                    ),
                  ),
                ),
                // Increment button
                IconButton(
                  tooltip: 'Increase 1%',
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  color: isLocked ? cs.onSurfaceVariant.withValues(alpha: 0.3) : cs.onSurface,
                  onPressed: isLocked ? null : () => onStep(1),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: effectiveColor,
                inactiveTrackColor: effectiveColor.withValues(alpha: 0.15),
                thumbColor: effectiveColor,
                overlayColor: effectiveColor.withValues(alpha: 0.12),
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              ),
              child: Slider(
                value: value.clamp(0.0, 100.0),
                min: 0.0,
                max: 100.0,
                divisions: 100,
                onChanged: isLocked ? null : onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
