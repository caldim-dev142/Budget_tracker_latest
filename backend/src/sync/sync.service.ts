import { Injectable, Inject } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import { EntriesService } from '../entries/entries.service';
import { CreateEntryDto } from '../entries/dto/create-entry.dto';

export interface SyncAccountDto {
  id: string;
  name: string;
  type: string;
  currentBalancePaise: number;
  isActive?: boolean;
  sortOrder?: number;
}

export interface SyncCreditCardDto {
  id: string;
  name: string;
  previousOutstandingPaise?: number;
  isActive?: boolean;
}

export interface SyncCardTransactionDto {
  id: string;
  cardId: string;
  txnDate: string;
  description: string;
  amountPaise: number;
  sNo?: number;
}

export interface SyncPlannedBillDto {
  id: string;
  name: string;
  amountPaise: number;
  dueDate?: string | null;
  isPaid?: boolean;
  entryId?: string | null;
}

export interface SyncReceivableDto {
  id: string;
  personName: string;
  amountPaise: number;
  status?: string;
  dueDate?: string | null;
  entryId?: string | null;
}

export interface SyncSavingGoalDto {
  id: string;
  bucket: string;
  name: string;
  targetPaise?: number | null;
  monthlyBudgetPaise?: number;
  archivedAt?: string | null;
}

export interface SyncGoalContributionDto {
  id: string;
  goalId: string;
  amountPaise: number;
  contributionDate: string;
  note?: string | null;
}

export interface SyncSinkingFundDto {
  id: string;
  name: string;
  openingReservePaise?: number;
  archivedAt?: string | null;
}

export interface SyncFundMovementDto {
  id: string;
  fundId: string;
  type: string;
  amountPaise: number;
  movementDate: string;
  note?: string | null;
}

export interface SyncBudgetDto {
  id: string;
  categoryId: string;
  yearMonth: string;
  amountPaise: number;
}

export interface SyncCategoryDto {
  id: string;
  kind: string;
  groupCode?: string | null;
  name: string;
  needOrWant?: string | null;
  isDeduction?: boolean;
  isSystem?: boolean;
  sortOrder?: number;
}

export interface SyncBatchDto {
  categories?: SyncCategoryDto[];
  accounts?: SyncAccountDto[];
  creditCards?: SyncCreditCardDto[];
  cardTransactions?: SyncCardTransactionDto[];
  plannedBills?: SyncPlannedBillDto[];
  receivables?: SyncReceivableDto[];
  savingGoals?: SyncSavingGoalDto[];
  goalContributions?: SyncGoalContributionDto[];
  sinkingFunds?: SyncSinkingFundDto[];
  fundMovements?: SyncFundMovementDto[];
  budgets?: SyncBudgetDto[];
  entries?: CreateEntryDto[];
}

@Injectable()
export class SyncService {
  constructor(
    private readonly entriesService: EntriesService,
    @Inject('PRISMA') private readonly prisma: PrismaClient,
  ) {}

  /**
   * Idempotent batch synchronization (POST /sync/batch).
   * Upserts all client entities (categories, accounts, cards, txns, bills, receivables, goals, funds, entries).
   */
  async syncBatch(householdId: string, dto: SyncBatchDto, userId: string) {
    let categoriesSynced = 0;
    let accountsSynced = 0;
    let cardsSynced = 0;
    let cardTxnsSynced = 0;
    let billsSynced = 0;
    let receivablesSynced = 0;
    let goalsSynced = 0;
    let fundsSynced = 0;
    let entriesResult = { synced: 0, failed: 0 };

    // 0. Categories (Sync first so entries satisfy foreign key constraints)
    if (dto.categories && dto.categories.length > 0) {
      for (const cat of dto.categories) {
        try {
          await this.prisma.category.upsert({
            where: { id: cat.id },
            create: {
              id: cat.id,
              householdId,
              kind: cat.kind,
              groupCode: cat.groupCode ?? null,
              name: cat.name,
              needOrWant: cat.needOrWant ?? null,
              isDeduction: cat.isDeduction ?? false,
              isSystem: cat.isSystem ?? false,
              sortOrder: cat.sortOrder ?? 0,
            },
            update: {
              kind: cat.kind,
              groupCode: cat.groupCode ?? null,
              name: cat.name,
              needOrWant: cat.needOrWant ?? null,
              isDeduction: cat.isDeduction ?? false,
              isSystem: cat.isSystem ?? false,
              sortOrder: cat.sortOrder ?? 0,
            },
          });
          categoriesSynced++;
        } catch (e) {
          console.error(`Failed to sync category ${cat.id}:`, e);
        }
      }
    }

    // 1. Accounts
    if (dto.accounts && dto.accounts.length > 0) {
      for (const a of dto.accounts) {
        try {
          const existing = await this.prisma.account.findFirst({
            where: {
              householdId,
              name: { equals: a.name.trim(), mode: 'insensitive' },
            },
          });
          const targetId = existing ? existing.id : a.id;

          await this.prisma.account.upsert({
            where: { id: targetId },
            create: {
              id: a.id,
              householdId,
              name: a.name.trim(),
              type: a.type,
              currentBalancePaise: Math.round(Number(a.currentBalancePaise ?? 0)),
              isActive: a.isActive ?? true,
              sortOrder: a.sortOrder ?? 0,
            },
            update: {
              name: a.name.trim(),
              type: a.type,
              currentBalancePaise: Math.round(Number(a.currentBalancePaise ?? 0)),
              isActive: a.isActive ?? true,
              sortOrder: a.sortOrder ?? 0,
            },
          });
          accountsSynced++;
        } catch (e) {
          console.error(`Failed to sync account ${a.id}:`, e);
        }
      }
    }

    // 2. Credit Cards
    if (dto.creditCards && dto.creditCards.length > 0) {
      for (const c of dto.creditCards) {
        try {
          await this.prisma.creditCard.upsert({
            where: { id: c.id },
            create: {
              id: c.id,
              householdId,
              name: c.name,
              previousOutstandingPaise: Math.round(Number(c.previousOutstandingPaise ?? 0)),
              isActive: c.isActive ?? true,
            },
            update: {
              name: c.name,
              previousOutstandingPaise: Math.round(Number(c.previousOutstandingPaise ?? 0)),
              isActive: c.isActive ?? true,
            },
          });
          cardsSynced++;
        } catch (e) {
          console.error(`Failed to sync credit card ${c.id}:`, e);
        }
      }
    }

    // 3. Card Transactions
    if (dto.cardTransactions && dto.cardTransactions.length > 0) {
      for (const t of dto.cardTransactions) {
        try {
          // Ensure parent credit card exists to satisfy foreign key
          const cardExists = await this.prisma.creditCard.findUnique({ where: { id: t.cardId } });
          if (!cardExists) {
            await this.prisma.creditCard.create({
              data: {
                id: t.cardId,
                householdId,
                name: 'Credit Card',
                previousOutstandingPaise: 0,
                isActive: true,
              },
            }).catch(() => {});
          }

          await this.prisma.cardTransaction.upsert({
            where: { id: t.id },
            create: {
              id: t.id,
              cardId: t.cardId,
              txnDate: new Date(t.txnDate),
              description: t.description,
              amountPaise: Math.round(Number(t.amountPaise ?? 0)),
              sNo: t.sNo ?? null,
            },
            update: {
              txnDate: new Date(t.txnDate),
              description: t.description,
              amountPaise: Math.round(Number(t.amountPaise ?? 0)),
              sNo: t.sNo ?? null,
            },
          });
          cardTxnsSynced++;
        } catch (e) {
          console.error(`Failed to sync card transaction ${t.id}:`, e);
        }
      }
    }

    // 4. Planned Bills (Payables)
    if (dto.plannedBills && dto.plannedBills.length > 0) {
      for (const b of dto.plannedBills) {
        try {
          await this.prisma.plannedBill.upsert({
            where: { id: b.id },
            create: {
              id: b.id,
              householdId,
              name: b.name,
              amountPaise: Math.round(Number(b.amountPaise ?? 0)),
              dueDate: b.dueDate ? new Date(b.dueDate) : null,
              isPaid: b.isPaid ?? false,
              entry_id: b.entryId ?? null,
            },
            update: {
              name: b.name,
              amountPaise: Math.round(Number(b.amountPaise ?? 0)),
              dueDate: b.dueDate ? new Date(b.dueDate) : null,
              isPaid: b.isPaid ?? false,
              entry_id: b.entryId ?? null,
            },
          });
          billsSynced++;
        } catch (e) {
          console.error(`Failed to sync planned bill ${b.id}:`, e);
        }
      }
    }

    // 5. Receivables
    if (dto.receivables && dto.receivables.length > 0) {
      for (const r of dto.receivables) {
        try {
          await this.prisma.receivable.upsert({
            where: { id: r.id },
            create: {
              id: r.id,
              householdId,
              personName: r.personName,
              amountPaise: Math.round(Number(r.amountPaise ?? 0)),
              status: r.status ?? 'open',
              dueDate: r.dueDate ? new Date(r.dueDate) : null,
              entry_id: r.entryId ?? null,
            },
            update: {
              personName: r.personName,
              amountPaise: Math.round(Number(r.amountPaise ?? 0)),
              status: r.status ?? 'open',
              dueDate: r.dueDate ? new Date(r.dueDate) : null,
              entry_id: r.entryId ?? null,
            },
          });
          receivablesSynced++;
        } catch (e) {
          console.error(`Failed to sync receivable ${r.id}:`, e);
        }
      }
    }

    // 6. Saving Goals
    if (dto.savingGoals && dto.savingGoals.length > 0) {
      for (const g of dto.savingGoals) {
        try {
          await this.prisma.savingGoal.upsert({
            where: { id: g.id },
            create: {
              id: g.id,
              householdId,
              bucket: g.bucket,
              name: g.name,
              targetPaise: g.targetPaise != null ? Math.round(Number(g.targetPaise)) : null,
              monthlyBudgetPaise: Math.round(Number(g.monthlyBudgetPaise ?? 0)),
              archivedAt: g.archivedAt ? new Date(g.archivedAt) : null,
            },
            update: {
              bucket: g.bucket,
              name: g.name,
              targetPaise: g.targetPaise != null ? Math.round(Number(g.targetPaise)) : null,
              monthlyBudgetPaise: Math.round(Number(g.monthlyBudgetPaise ?? 0)),
              archivedAt: g.archivedAt ? new Date(g.archivedAt) : null,
            },
          });
          goalsSynced++;
        } catch (e) {
          console.error(`Failed to sync saving goal ${g.id}:`, e);
        }
      }
    }

    // 7. Sinking Funds
    if (dto.sinkingFunds && dto.sinkingFunds.length > 0) {
      for (const f of dto.sinkingFunds) {
        try {
          await this.prisma.sinkingFund.upsert({
            where: { id: f.id },
            create: {
              id: f.id,
              householdId,
              name: f.name,
              openingReservePaise: Math.round(Number(f.openingReservePaise ?? 0)),
              archivedAt: f.archivedAt ? new Date(f.archivedAt) : null,
            },
            update: {
              name: f.name,
              openingReservePaise: Math.round(Number(f.openingReservePaise ?? 0)),
              archivedAt: f.archivedAt ? new Date(f.archivedAt) : null,
            },
          });
          fundsSynced++;
        } catch (e) {
          console.error(`Failed to sync sinking fund ${f.id}:`, e);
        }
      }
    }

    // 8. Goal Contributions
    if (dto.goalContributions && dto.goalContributions.length > 0) {
      for (const gc of dto.goalContributions) {
        try {
          await this.prisma.goalContribution.upsert({
            where: { id: gc.id },
            create: {
              id: gc.id,
              goalId: gc.goalId,
              amountPaise: Math.round(Number(gc.amountPaise || 0)),
              contributionDate: new Date(gc.contributionDate),
              note: gc.note ?? null,
            },
            update: {
              amountPaise: Math.round(Number(gc.amountPaise || 0)),
              contributionDate: new Date(gc.contributionDate),
              note: gc.note ?? null,
            },
          });
        } catch (e) {
          console.error(`Failed to sync goal contribution ${gc.id}:`, e);
        }
      }
    }

    // 9. Fund Movements
    if (dto.fundMovements && dto.fundMovements.length > 0) {
      for (const fm of dto.fundMovements) {
        try {
          await this.prisma.fundMovement.upsert({
            where: { id: fm.id },
            create: {
              id: fm.id,
              fundId: fm.fundId,
              type: fm.type || 'contribution',
              amountPaise: Math.round(Number(fm.amountPaise || 0)),
              movementDate: new Date(fm.movementDate),
              note: fm.note ?? null,
            },
            update: {
              type: fm.type || 'contribution',
              amountPaise: Math.round(Number(fm.amountPaise || 0)),
              movementDate: new Date(fm.movementDate),
              note: fm.note ?? null,
            },
          });
        } catch (e) {
          console.error(`Failed to sync fund movement ${fm.id}:`, e);
        }
      }
    }

    // 10. Budgets
    let budgetsSynced = 0;
    if (dto.budgets && dto.budgets.length > 0) {
      for (const b of dto.budgets) {
        try {
          await this.prisma.budget.upsert({
            where: { id: b.id },
            create: {
              id: b.id,
              householdId,
              categoryId: b.categoryId,
              yearMonth: b.yearMonth,
              amountPaise: Math.round(Number(b.amountPaise || 0)),
            },
            update: {
              amountPaise: Math.round(Number(b.amountPaise || 0)),
            },
          });
          budgetsSynced++;
        } catch (e) {
          console.error(`Failed to sync budget ${b.id}:`, e);
        }
      }
    }

    // 11. Entries
    if (dto.entries && dto.entries.length > 0) {
      entriesResult = await this.entriesService.upsertBatch(householdId, dto.entries, userId);
    }

    return {
      categories: categoriesSynced,
      accounts: accountsSynced,
      creditCards: cardsSynced,
      cardTransactions: cardTxnsSynced,
      plannedBills: billsSynced,
      receivables: receivablesSynced,
      savingGoals: goalsSynced,
      sinkingFunds: fundsSynced,
      budgets: budgetsSynced,
      entries: entriesResult,
      syncedAt: new Date(),
    };
  }

  /**
   * Pull all household data from PostgreSQL database to synchronize client cache (GET /sync/pull).
   */
  async pullData(householdId: string) {
    const [
      accounts,
      creditCards,
      cardTransactions,
      plannedBills,
      receivables,
      savingGoals,
      goalContributions,
      sinkingFunds,
      fundMovements,
      budgets,
      categories,
      entries,
    ] = await Promise.all([
      this.prisma.account.findMany({
        where: { householdId, isActive: true },
        orderBy: { sortOrder: 'asc' },
      }),
      this.prisma.creditCard.findMany({
        where: { householdId, isActive: true },
      }),
      this.prisma.cardTransaction.findMany({
        where: { card: { householdId } },
        orderBy: { txnDate: 'desc' },
      }),
      this.prisma.plannedBill.findMany({
        where: { householdId },
        orderBy: { dueDate: 'asc' },
      }),
      this.prisma.receivable.findMany({
        where: { householdId },
        orderBy: { dueDate: 'asc' },
      }),
      this.prisma.savingGoal.findMany({
        where: { householdId, archivedAt: null },
      }),
      this.prisma.goalContribution.findMany({
        where: { goal: { householdId } },
        orderBy: { contributionDate: 'desc' },
      }),
      this.prisma.sinkingFund.findMany({
        where: { householdId, archivedAt: null },
      }),
      this.prisma.fundMovement.findMany({
        where: { fund: { householdId } },
        orderBy: { movementDate: 'desc' },
      }),
      this.prisma.budget.findMany({
        where: { householdId },
      }),
      this.prisma.category.findMany({
        where: { householdId, archivedAt: null },
        orderBy: { sortOrder: 'asc' },
      }),
      this.prisma.entry.findMany({
        where: { householdId, deletedAt: null },
        orderBy: { entryDate: 'desc' },
      }),
    ]);

    return {
      householdId,
      accounts: accounts.map((a) => ({
        ...a,
        currentBalancePaise: Number(a.currentBalancePaise),
      })),
      creditCards: creditCards.map((c) => ({
        ...c,
        previousOutstandingPaise: Number(c.previousOutstandingPaise),
      })),
      cardTransactions: cardTransactions.map((t) => ({
        ...t,
        amountPaise: Number(t.amountPaise),
        txnDate: t.txnDate.toISOString(),
      })),
      plannedBills: plannedBills.map((b) => ({
        ...b,
        entryId: b.entry_id,
        amountPaise: Number(b.amountPaise),
        dueDate: b.dueDate ? b.dueDate.toISOString() : null,
      })),
      receivables: receivables.map((r) => ({
        ...r,
        entryId: r.entry_id,
        amountPaise: Number(r.amountPaise),
        dueDate: r.dueDate ? r.dueDate.toISOString() : null,
      })),
      savingGoals: savingGoals.map((g) => ({
        ...g,
        targetPaise: g.targetPaise != null ? Number(g.targetPaise) : null,
        monthlyBudgetPaise: Number(g.monthlyBudgetPaise),
        archivedAt: g.archivedAt ? g.archivedAt.toISOString() : null,
      })),
      goalContributions: goalContributions.map((gc) => ({
        ...gc,
        amountPaise: Number(gc.amountPaise),
        contributionDate: gc.contributionDate.toISOString(),
      })),
      sinkingFunds: sinkingFunds.map((f) => ({
        ...f,
        openingReservePaise: Number(f.openingReservePaise),
        archivedAt: f.archivedAt ? f.archivedAt.toISOString() : null,
      })),
      fundMovements: fundMovements.map((fm) => ({
        ...fm,
        amountPaise: Number(fm.amountPaise),
        movementDate: fm.movementDate.toISOString(),
      })),
      budgets: budgets.map((b) => ({
        ...b,
        amountPaise: Number(b.amountPaise),
      })),
      categories,
      entries: entries.map((e) => ({
        ...e,
        amountPaise: Number(e.amountPaise),
        entryDate: e.entryDate.toISOString(),
        createdAt: e.createdAt.toISOString(),
        updatedAt: e.updatedAt.toISOString(),
      })),
      pulledAt: new Date(),
    };
  }
}
