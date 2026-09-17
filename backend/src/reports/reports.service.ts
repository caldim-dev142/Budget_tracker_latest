import { Injectable, Inject } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import { EngineService } from '../engine/engine.service';
import { monthRange } from '../common/month-range';

@Injectable()
export class ReportsService {
  constructor(
    @Inject('PRISMA') private readonly prisma: PrismaClient,
    private readonly engine: EngineService,
  ) {}

  async getDashboard(householdId: string, yearMonth: string) {
    const { from, to } = monthRange(yearMonth);

    // 1. Fetch entries for the month
    const entries = await this.prisma.entry.findMany({
      where: {
        householdId,
        entryDate: { gte: from, lt: to },
        deletedAt: null,
      },
    });

    // 2. Fetch opening balance snapshot if closed, or carry-forward from prior month close
    const priorYm = this.getPriorYearMonth(yearMonth);
    const priorSnap = await this.prisma.monthSnapshot.findUnique({
      where: { householdId_yearMonth: { householdId, yearMonth: priorYm } },
    });

    const activeSnap = await this.prisma.monthSnapshot.findUnique({
      where: { householdId_yearMonth: { householdId, yearMonth } },
    });

    const openingBalance = activeSnap
      ? Number(activeSnap.openingBalancePaise)
      : priorSnap
      ? Number(priorSnap.closingBalancePaise)
      : 0;

    const lastMonthReserves = activeSnap
      ? Number(activeSnap.lastMonthReservesPaise)
      : priorSnap
      ? Number(priorSnap.reservesPaise)
      : 0;

    // 3. Compute layer totals (mirrors RollupEngine in Dart)
    // For adjustments: fetch category map so we can apply isDeduction semantics.
    // Rule (source of truth): isDeduction: true means this adjustment REDUCES the total (outflow).
    // This matches rollupAdjustments() in engine.ts and RollupEngine.netAdjustments() in Dart.
    const categoryMap = await this.prisma.category.findMany({
      where: { householdId },
      select: { id: true, isDeduction: true },
    });
    const deductionSet = new Set(categoryMap.filter((c) => c.isDeduction).map((c) => c.id));

    let income = 0;
    let incomeDeduction = 0;
    let adjustments = 0;
    let spending = 0;
    let protection = 0;
    let saving = 0;

    for (const e of entries) {
      const amt = Number(e.amountPaise);
      switch (e.kind) {
        case 'income':
          income += amt;
          break;
        case 'incomeDeduction':
          incomeDeduction += amt;
          break;
        case 'adjustment':
          // Apply isDeduction: outflow categories subtract, inflow categories add
          adjustments += deductionSet.has(e.categoryId) ? -amt : amt;
          break;
        case 'spending':
          spending += amt;
          break;
        case 'protection':
          protection += amt;
          break;
        case 'saving':
          saving += amt;
          break;
      }
    }

    const netIncome = income - incomeDeduction;

    // 4. Fetch sinking fund reserve total
    const funds = await this.prisma.sinkingFund.findMany({
      where: { householdId, archivedAt: null },
      include: { movements: true },
    });

    let totalReserves = 0;
    for (const f of funds) {
      const fundOpening = Number(f.openingReservePaise);
      const contributions = f.movements
        .filter((m) => m.type === 'contribution')
        .reduce((sum, m) => sum + Number(m.amountPaise), 0);
      const withdrawals = f.movements
        .filter((m) => m.type === 'withdrawal')
        .reduce((sum, m) => sum + Number(m.amountPaise), 0);
      totalReserves += this.engine.closingReserve(fundOpening, contributions, withdrawals);
    }

    // 5. Fetch bank/cash accounts total available balance
    const accounts = await this.prisma.account.findMany({
      where: { householdId, isActive: true },
    });
    const totalAvailable = accounts.reduce((sum, a) => sum + Number(a.currentBalancePaise), 0);

    // 6. Fetch credit card outstanding
    const cards = await this.prisma.creditCard.findMany({
      where: { householdId, isActive: true },
      include: { transactions: true },
    });
    const ccOutstanding = cards.reduce((sum, c) => {
      const outstanding = c.transactions.reduce((s, t) => s + Number(t.amountPaise), 0);
      return sum + Number(c.previousOutstandingPaise) + outstanding;
    }, 0);

    // 7. Fetch receivables (Return Awaited) and planned bills (To be Paid)
    const receivables = await this.prisma.receivable.findMany({
      where: { householdId, status: 'open' },
    });
    const returnAwaited = receivables.reduce((sum, r) => sum + Number(r.amountPaise), 0);

    const plannedBills = await this.prisma.plannedBill.findMany({
      where: { householdId, isPaid: false },
    });
    const toBePaid = plannedBills.reduce((sum, b) => sum + Number(b.amountPaise), 0);

    // 8. Run waterfall calculation
    const waterfall = this.engine.computeWaterfall({
      openingBalance,
      lastMonthReserves,
      income: netIncome,
      adjustments,
      spending,
      protection,
      saving,
      reservesSetAside: totalReserves,
    });

    return {
      waterfall: {
        openingBalance,
        lastMonthReserves,
        income: netIncome,
        adjustments,
        spending,
        protection,
        saving,
        reservesSetAside: totalReserves,
        remaining: waterfall.remaining,
      },
      accounts: {
        totalAvailable,
        ccOutstanding,
        returnAwaited,
        toBePaid,
      },
    };
  }

  async getBudgetVsActual(householdId: string, yearMonth: string) {
    const { from, to } = monthRange(yearMonth);

    const categories = await this.prisma.category.findMany({
      where: { householdId, archivedAt: null },
    });

    const budgets = await this.prisma.budget.findMany({
      where: { householdId, yearMonth },
    });

    const entries = await this.prisma.entry.findMany({
      where: {
        householdId,
        entryDate: { gte: from, lt: to },
        deletedAt: null,
      },
    });

    return categories.map((cat) => {
      const b = budgets.find((x) => x.categoryId === cat.id);
      const budgetAmount = b ? Number(b.amountPaise) : 0;

      const actualAmount = entries
        .filter((e) => e.categoryId === cat.id)
        .reduce((sum, e) => sum + Number(e.amountPaise), 0);

      const computed = this.engine.computeBudgetLine(budgetAmount, actualAmount);

      return {
        categoryId: cat.id,
        categoryName: cat.name,
        kind: cat.kind,
        budget: budgetAmount,
        actual: actualAmount,
        difference: computed.difference,
        pctUsed: computed.pctUsed,
        isOverBudget: computed.isOverBudget,
        isNearBudget: computed.isNearBudget,
      };
    });
  }

  /**
   * Monthly trends: returns the last N months of frozen waterfall actuals
   * from monthSnapshot records. Only closed snapshots are included; open snapshots
   * are excluded to avoid showing partial/incomplete months.
   *
   * All data is household-scoped. No synthetic defaults.
   */
  async getMonthlyTrends(householdId: string, months = 6) {
    // Collect the last `months` yearMonth strings in chronological order
    const ymList: string[] = [];
    const now = new Date();
    for (let i = months - 1; i >= 0; i--) {
      const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
      ymList.push(`${d.getFullYear()}-${(d.getMonth() + 1).toString().padStart(2, '0')}`);
    }

    const snapshots = await this.prisma.monthSnapshot.findMany({
      where: {
        householdId,
        yearMonth: { in: ymList },
        status: 'closed',
      },
      orderBy: { yearMonth: 'asc' },
    });

    return ymList.map((ym) => {
      const snap = snapshots.find((s) => s.yearMonth === ym);
      if (!snap) {
        // No closed snapshot: return month label with nulls (no synthetic values)
        return {
          yearMonth: ym,
          income: null,
          adjustments: null,
          spending: null,
          protection: null,
          saving: null,
          remaining: null,
          isClosed: false,
        };
      }
      return {
        yearMonth:   ym,
        income:      Number(snap.incomePaise),
        adjustments: Number(snap.adjustmentsPaise),
        spending:    Number(snap.spendingPaise),
        protection:  Number(snap.protectionPaise),
        saving:      Number(snap.savingPaise),
        remaining:   Number(snap.remainingPaise),
        isClosed:    true,
      };
    });
  }

  /**
   * Yearly summary: aggregates actuals from closed monthly snapshots for a given year.
   * Only closed months contribute. No synthetic values. Household-scoped.
   */
  async getYearlySummary(householdId: string, year: number) {
    const ymList: string[] = Array.from({ length: 12 }, (_, i) =>
      `${year}-${(i + 1).toString().padStart(2, '0')}`,
    );

    const snapshots = await this.prisma.monthSnapshot.findMany({
      where: {
        householdId,
        yearMonth: { in: ymList },
        status: 'closed',
      },
      orderBy: { yearMonth: 'asc' },
    });

    const totals = {
      income:      0,
      adjustments: 0,
      spending:    0,
      protection:  0,
      saving:      0,
      remaining:   0,
    };
    const months: Array<{
      yearMonth: string;
      income: number;
      adjustments: number;
      spending: number;
      protection: number;
      saving: number;
      remaining: number;
    }> = [];

    for (const snap of snapshots) {
      const row = {
        yearMonth:   snap.yearMonth,
        income:      Number(snap.incomePaise),
        adjustments: Number(snap.adjustmentsPaise),
        spending:    Number(snap.spendingPaise),
        protection:  Number(snap.protectionPaise),
        saving:      Number(snap.savingPaise),
        remaining:   Number(snap.remainingPaise),
      };
      months.push(row);
      totals.income      += row.income;
      totals.adjustments += row.adjustments;
      totals.spending    += row.spending;
      totals.protection  += row.protection;
      totals.saving      += row.saving;
      totals.remaining   += row.remaining;
    }

    return {
      year,
      closedMonthsCount: snapshots.length,
      totals,
      months,
    };
  }

  private getPriorYearMonth(ym: string): string {
    const [y, m] = ym.split('-').map(Number);
    if (m === 1) return `${y - 1}-12`;
    return `${y}-${(m - 1).toString().padStart(2, '0')}`;
  }
}
