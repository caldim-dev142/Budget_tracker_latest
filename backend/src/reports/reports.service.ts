import { Injectable, Inject } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import { EngineService } from '../engine/engine.service';

@Injectable()
export class ReportsService {
  constructor(
    @Inject('PRISMA') private readonly prisma: PrismaClient,
    private readonly engine: EngineService,
  ) {}

  async getDashboard(householdId: string, yearMonth: string) {
    const [year, month] = yearMonth.split('-').map(Number);
    const from = new Date(year, month - 1, 1);
    const to = new Date(year, month, 0, 23, 59, 59);

    // 1. Fetch entries for the month
    const entries = await this.prisma.entry.findMany({
      where: {
        householdId,
        entryDate: { gte: from, lte: to },
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
      ? activeSnap.openingBalancePaise
      : priorSnap
      ? priorSnap.closingBalancePaise
      : 0;

    const lastMonthReserves = activeSnap
      ? activeSnap.lastMonthReservesPaise
      : priorSnap
      ? priorSnap.reservesPaise
      : 0;

    // 3. Compute layer totals (mirrors RollupEngine in Dart)
    let income = 0;
    let incomeDeduction = 0;
    let adjustments = 0;
    let spending = 0;
    let protection = 0;
    let saving = 0;

    for (const e of entries) {
      const amt = e.amountPaise;
      switch (e.kind) {
        case 'income':
          income += amt;
          break;
        case 'incomeDeduction':
          incomeDeduction += amt;
          break;
        case 'adjustment':
          adjustments += amt;
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
      const fundOpening = f.openingReservePaise;
      const contributions = f.movements
        .filter((m) => m.type === 'contribution')
        .reduce((sum, m) => sum + m.amountPaise, 0);
      const withdrawals = f.movements
        .filter((m) => m.type === 'withdrawal')
        .reduce((sum, m) => sum + m.amountPaise, 0);
      totalReserves += this.engine.closingReserve(fundOpening, contributions, withdrawals);
    }

    // 5. Fetch bank/cash accounts total available balance
    const accounts = await this.prisma.account.findMany({
      where: { householdId, isActive: true },
    });
    const totalAvailable = accounts.reduce((sum, a) => sum + a.currentBalancePaise, 0);

    // 6. Fetch credit card outstanding
    const cards = await this.prisma.creditCard.findMany({
      where: { householdId, isActive: true },
      include: { transactions: true },
    });
    const ccOutstanding = cards.reduce((sum, c) => {
      const outstanding = c.transactions.reduce((s, t) => s + t.amountPaise, 0);
      return sum + c.previousOutstandingPaise + outstanding;
    }, 0);

    // 7. Fetch receivables (Return Awaited) and planned bills (To be Paid)
    const receivables = await this.prisma.receivable.findMany({
      where: { householdId, status: 'open' },
    });
    const returnAwaited = receivables.reduce((sum, r) => sum + r.amountPaise, 0);

    const plannedBills = await this.prisma.plannedBill.findMany({
      where: { householdId, isPaid: false },
    });
    const toBePaid = plannedBills.reduce((sum, b) => sum + b.amountPaise, 0);

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
    const [year, month] = yearMonth.split('-').map(Number);
    const from = new Date(year, month - 1, 1);
    const to = new Date(year, month, 0, 23, 59, 59);

    const categories = await this.prisma.category.findMany({
      where: { householdId, archivedAt: null },
    });

    const budgets = await this.prisma.budget.findMany({
      where: { householdId, yearMonth },
    });

    const entries = await this.prisma.entry.findMany({
      where: {
        householdId,
        entryDate: { gte: from, lte: to },
        deletedAt: null,
      },
    });

    return categories.map((cat) => {
      const b = budgets.find((x) => x.categoryId === cat.id);
      const budgetAmount = b ? b.amountPaise : 0;

      const actualAmount = entries
        .filter((e) => e.categoryId === cat.id)
        .reduce((sum, e) => sum + e.amountPaise, 0);

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

  private getPriorYearMonth(ym: string): string {
    const [y, m] = ym.split('-').map(Number);
    if (m === 1) return `${y - 1}-12`;
    return `${y}-${(m - 1).toString().padStart(2, '0')}`;
  }
}
