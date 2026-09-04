import { Injectable, Inject, BadRequestException, ConflictException } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import { EngineService } from '../engine/engine.service';

@Injectable()
export class MonthsService {
  constructor(
    @Inject('PRISMA') private readonly prisma: PrismaClient,
    private readonly engine: EngineService,
  ) {}

  async getSnapshot(householdId: string, yearMonth: string) {
    const snap = await this.prisma.monthSnapshot.findUnique({
      where: {
        householdId_yearMonth: {
          householdId,
          yearMonth,
        },
      },
    });

    if (!snap) return null;

    return {
      ...snap,
      openingBalancePaise: Number(snap.openingBalancePaise),
      lastMonthReservesPaise: Number(snap.lastMonthReservesPaise),
      incomePaise: Number(snap.incomePaise),
      adjustmentsPaise: Number(snap.adjustmentsPaise),
      spendingPaise: Number(snap.spendingPaise),
      protectionPaise: Number(snap.protectionPaise),
      savingPaise: Number(snap.savingPaise),
      reservesPaise: Number(snap.reservesPaise),
      closingBalancePaise: Number(snap.closingBalancePaise),
      remainingPaise: Number(snap.remainingPaise),
    };
  }

  async isMonthOpen(householdId: string, yearMonth: string): Promise<boolean> {
    const snap = await this.prisma.monthSnapshot.findUnique({
      where: {
        householdId_yearMonth: {
          householdId,
          yearMonth,
        },
      },
    });
    if (!snap) return true; // Open if no snapshot exists yet
    return snap.status === 'open';
  }

  /**
   * Close a month: freeze actuals, compute closing balance, and initialize next month's opening.
   * Idempotent (doc 06 §4).
   */
  async closeMonth(
    householdId: string,
    yearMonth: string,
    actuals: {
      openingBalance: number;
      lastMonthReserves: number;
      income: number;
      adjustments: number;
      spending: number;
      protection: number;
      saving: number;
      reserves: number;
      totalAvailable: number;
    },
  ) {
    const existing = await this.getSnapshot(householdId, yearMonth);
    if (existing && existing.status === 'closed') {
      return existing; // Already closed (idempotent no-op)
    }

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

    let income = 0n;
    let incomeDeduction = 0n;
    let adjustments = 0n;
    let spending = 0n;
    let protection = 0n;
    let saving = 0n;

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

    // 2. Fetch prior snapshot to compute opening and lastMonthReserves
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
      : 0n;

    const lastMonthReserves = activeSnap
      ? activeSnap.lastMonthReservesPaise
      : priorSnap
      ? priorSnap.reservesPaise
      : 0n;

    // 3. Fetch sinking fund reserve total
    const funds = await this.prisma.sinkingFund.findMany({
      where: { householdId, archivedAt: null },
      include: { movements: true },
    });

    let totalReserves = 0n;
    for (const f of funds) {
      const fundOpening = f.openingReservePaise;
      const contributions = f.movements
        .filter((m) => m.type === 'contribution')
        .reduce((sum, m) => sum + m.amountPaise, 0n);
      const withdrawals = f.movements
        .filter((m) => m.type === 'withdrawal')
        .reduce((sum, m) => sum + m.amountPaise, 0n);
      totalReserves += this.engine.closingReserve(fundOpening, contributions, withdrawals);
    }

    // 4. Fetch bank/cash accounts total available balance
    const accounts = await this.prisma.account.findMany({
      where: { householdId, isActive: true },
    });
    const totalAvailable = accounts.reduce((sum, a) => sum + a.currentBalancePaise, 0n);

    const closingBalance = this.engine.closingBalance(totalAvailable, totalReserves);

    const snapshot = await this.prisma.monthSnapshot.upsert({
      where: {
        householdId_yearMonth: {
          householdId,
          yearMonth,
        },
      },
      create: {
        householdId,
        yearMonth,
        openingBalancePaise: openingBalance,
        lastMonthReservesPaise: lastMonthReserves,
        incomePaise: netIncome,
        adjustmentsPaise: adjustments,
        spendingPaise: spending,
        protectionPaise: protection,
        savingPaise: saving,
        reservesPaise: totalReserves,
        closingBalancePaise: closingBalance,
        remainingPaise: this.engine.computeWaterfall({
          openingBalance,
          lastMonthReserves,
          income: netIncome,
          adjustments,
          spending,
          protection,
          saving,
          reservesSetAside: totalReserves,
        }).remaining,
        status: 'closed',
        closedAt: new Date(),
      },
      update: {
        status: 'closed',
        closedAt: new Date(),
      },
    });

    // Seed next month's opening snapshot structure (so next month can carry forward)
    const nextYm = this.getNextYearMonth(yearMonth);
    await this.prisma.monthSnapshot.upsert({
      where: {
        householdId_yearMonth: {
          householdId,
          yearMonth: nextYm,
        },
      },
      create: {
        householdId,
        yearMonth: nextYm,
        openingBalancePaise: closingBalance,
        lastMonthReservesPaise: totalReserves,
        status: 'open',
      },
      update: {
        openingBalancePaise: closingBalance,
        lastMonthReservesPaise: totalReserves,
      },
    });

    return {
      ...snapshot,
      openingBalancePaise: Number(snapshot.openingBalancePaise),
      closingBalancePaise: Number(snapshot.closingBalancePaise),
    };
  }

  private getPriorYearMonth(ym: string): string {
    const [y, m] = ym.split('-').map(Number);
    if (m === 1) return `${y - 1}-12`;
    return `${y}-${(m - 1).toString().padStart(2, '0')}`;
  }

  private getNextYearMonth(ym: string): string {
    const [y, m] = ym.split('-').map(Number);
    if (m === 12) return `${y + 1}-01`;
    return `${y}-${(m + 1).toString().padStart(2, '0')}`;
  }
}
