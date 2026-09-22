import { Injectable, Inject, NotFoundException } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import { EngineService } from '../engine/engine.service';
import { monthRange } from '../common/month-range';

const SNAPSHOT_PAISE_FIELDS = [
  'openingBalancePaise', 'lastMonthReservesPaise', 'incomePaise', 'adjustmentsPaise', 'spendingPaise',
  'protectionPaise', 'savingPaise', 'reservesPaise', 'closingBalancePaise', 'remainingPaise',
] as const;

/** Month snapshot with paise columns serialised as JSON numbers. */
export function toSnapshotResponse<T extends Record<string, any>>(snap: T): T {
  const out: Record<string, any> = { ...snap };
  for (const f of SNAPSHOT_PAISE_FIELDS) {
    if (out[f] !== undefined && out[f] !== null) out[f] = Number(out[f]);
  }
  return out as T;
}

@Injectable()
export class MonthsService {
  constructor(
    @Inject('PRISMA') private readonly prisma: PrismaClient,
    private readonly engine: EngineService,
  ) {}

  async getSnapshot(householdId: string, yearMonth: string) {
    const snap = await this.prisma.monthSnapshot.findUnique({
      where: { householdId_yearMonth: { householdId, yearMonth } },
    });
    if (!snap) return null;
    return toSnapshotResponse(snap);
  }

  async isMonthOpen(householdId: string, yearMonth: string): Promise<boolean> {
    const snap = await this.prisma.monthSnapshot.findUnique({
      where: { householdId_yearMonth: { householdId, yearMonth } },
    });
    if (!snap) return true;
    return snap.status === 'open';
  }

  /**
   * Close a month: freeze actuals derived from real DB entries, compute closing balance,
   * and initialize next month opening. Idempotent (doc 06 �4).
   * Fix: update branch now freezes ALL actuals (previously only set status + closedAt).
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
      return existing;
    }

    const { from, to } = monthRange(yearMonth);

    const entries = await this.prisma.entry.findMany({
      where: { householdId, entryDate: { gte: from, lt: to }, deletedAt: null },
    });

    let income = 0;
    let incomeDeduction = 0;
    let adjustments = 0;
    let spending = 0;
    let protection = 0;
    let saving = 0;

    const categoryRows = await this.prisma.category.findMany({
      where: { householdId },
      select: { id: true, isDeduction: true },
    });
    const deductionSet = new Set(categoryRows.filter((c) => c.isDeduction).map((c) => c.id));

    for (const e of entries) {
      const amt = Number(e.amountPaise);
      switch (e.kind) {
        case 'income':          income += amt; break;
        case 'incomeDeduction': incomeDeduction += amt; break;
        case 'adjustment':      adjustments += deductionSet.has(e.categoryId) ? -amt : amt; break;
        case 'spending':        spending += amt; break;
        case 'protection':      protection += amt; break;
        case 'saving':          saving += amt; break;
      }
    }
    const netIncome = income - incomeDeduction;

    const priorYm = this.getPriorYearMonth(yearMonth);
    const priorSnap = await this.prisma.monthSnapshot.findUnique({
      where: { householdId_yearMonth: { householdId, yearMonth: priorYm } },
    });
    const activeSnap = await this.prisma.monthSnapshot.findUnique({
      where: { householdId_yearMonth: { householdId, yearMonth } },
    });
    const openingBalance = activeSnap
      ? Number(activeSnap.openingBalancePaise)
      : priorSnap ? Number(priorSnap.closingBalancePaise) : 0;
    const lastMonthReserves = activeSnap
      ? Number(activeSnap.lastMonthReservesPaise)
      : priorSnap ? Number(priorSnap.reservesPaise) : 0;

    const funds = await this.prisma.sinkingFund.findMany({
      where: { householdId, archivedAt: null },
      include: { movements: true },
    });
    let totalReserves = 0;
    for (const f of funds) {
      const contributions = f.movements.filter((m) => m.type === 'contribution').reduce((s, m) => s + Number(m.amountPaise), 0);
      const withdrawals   = f.movements.filter((m) => m.type === 'withdrawal').reduce((s, m) => s + Number(m.amountPaise), 0);
      totalReserves += this.engine.closingReserve(Number(f.openingReservePaise), contributions, withdrawals);
    }

    const accounts = await this.prisma.account.findMany({ where: { householdId, isActive: true } });
    const totalAvailableDb = accounts.reduce((s, a) => s + Number(a.currentBalancePaise), 0);

    const closingBalance = this.engine.closingBalance(totalAvailableDb, totalReserves);
    const remainingPaise = this.engine.computeWaterfall({
      openingBalance,
      lastMonthReserves,
      income: netIncome,
      adjustments,
      spending,
      protection,
      saving,
      reservesSetAside: totalReserves,
    }).remaining;

    const frozenData = {
      openingBalancePaise:    openingBalance,
      lastMonthReservesPaise: lastMonthReserves,
      incomePaise:            netIncome,
      adjustmentsPaise:       adjustments,
      spendingPaise:          spending,
      protectionPaise:        protection,
      savingPaise:            saving,
      reservesPaise:          totalReserves,
      closingBalancePaise:    closingBalance,
      remainingPaise,
      status:                 'closed' as const,
      closedAt:               new Date(),
      statusChangedAt:        new Date(),
    };

    const nextYm = this.getNextYearMonth(yearMonth);

    const runner = this.prisma?.$transaction
      ? (fn: any) => this.prisma.$transaction(fn, { timeout: 30000, maxWait: 10000 })
      : (fn: any) => fn(this.prisma);

    const snapshot = await runner(async (tx: any) => {
      const snap = await tx.monthSnapshot.upsert({
        where:  { householdId_yearMonth: { householdId, yearMonth } },
        create: { householdId, yearMonth, ...frozenData },
        update: frozenData,
      });

      const nextSnap = await tx.monthSnapshot.findUnique({
        where: { householdId_yearMonth: { householdId, yearMonth: nextYm } },
        select: { status: true },
      });
      // Only a missing or open next month is (re)seeded. A closed month is frozen and must never be
      // mutated by re-closing an earlier month; reopen it first if the rollover must be applied again.
      if (!nextSnap || nextSnap.status !== 'closed') {
        await tx.monthSnapshot.upsert({
          where:  { householdId_yearMonth: { householdId, yearMonth: nextYm } },
          create: { householdId, yearMonth: nextYm, openingBalancePaise: closingBalance, lastMonthReservesPaise: totalReserves, status: 'open' },
          update: { openingBalancePaise: closingBalance, lastMonthReservesPaise: totalReserves },
        });
      }

      return snap;
    });

    return toSnapshotResponse(snapshot);
  }

  /**
   * Reopen a closed month: sets status back to 'open', clears closedAt.
   * Next month opening snapshot is NOT modified. Idempotent.
   */
  async reopenMonth(householdId: string, yearMonth: string) {
    const existing = await this.prisma.monthSnapshot.findUnique({
      where: { householdId_yearMonth: { householdId, yearMonth } },
    });
    if (!existing) {
      throw new NotFoundException(`No snapshot found for ${yearMonth}`);
    }
    if (existing.status === 'open') {
      return toSnapshotResponse(existing);
    }
    const reopened = await this.prisma.monthSnapshot.update({
      where: { householdId_yearMonth: { householdId, yearMonth } },
      data: { status: 'open', closedAt: null, statusChangedAt: new Date() },
    });
    return toSnapshotResponse(reopened);
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
