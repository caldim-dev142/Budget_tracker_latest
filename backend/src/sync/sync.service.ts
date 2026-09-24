import { Injectable, Inject, ForbiddenException } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import { EntriesService } from '../entries/entries.service';
import { CreateEntryDto } from '../entries/dto/create-entry.dto';

import {
  SyncBatchDto,
  SyncCategoryDto,
  SyncAccountDto,
  SyncCreditCardDto,
  SyncCardTransactionDto,
  SyncPlannedBillDto,
  SyncReceivableDto,
  SyncSavingGoalDto,
  SyncGoalContributionDto,
  SyncSinkingFundDto,
  SyncFundMovementDto,
  SyncBudgetDto,
  SyncReserveLineDto,
  SyncDeletionDto,
  SyncDeletableEntity,
} from './dto/sync-batch.dto';

/** Tombstone key helper: `${entity}:${id}`. */
const tombKey = (entity: string, id: string) => `${entity}:${id}`;

/** /sync/pull response key for each deletable entity. */
const PULL_KEY_BY_ENTITY: Record<SyncDeletableEntity, string> = {
  planned_bill: 'plannedBills',
  receivable: 'receivables',
  card_transaction: 'cardTransactions',
  budget: 'budgets',
  reserve_line: 'reserveLines',
  goal_contribution: 'goalContributions',
  fund_movement: 'fundMovements',
  annual_target: 'annualTargets',
  category: 'categories',
};

export {
  SyncBatchDto,
  SyncCategoryDto,
  SyncAccountDto,
  SyncCreditCardDto,
  SyncCardTransactionDto,
  SyncPlannedBillDto,
  SyncReceivableDto,
  SyncSavingGoalDto,
  SyncGoalContributionDto,
  SyncSinkingFundDto,
  SyncFundMovementDto,
  SyncBudgetDto,
  SyncReserveLineDto,
};

/** Flutter DAO system category ids: '{suffix}-system-cat-{householdId}'. */
function isClientSystemCategoryId(id: string, householdId: string): boolean {
  return ['lend', 'borrow', 'bill-pay', 'return-received'].some((sfx) => id === `${sfx}-system-cat-${householdId}`);
}

@Injectable()
export class SyncService {
  constructor(
    private readonly entriesService: EntriesService,
    @Inject('PRISMA') private readonly prisma: PrismaClient,
  ) { }

  /**
   * Idempotent batch synchronization (POST /sync/batch).
   * Two-phase execution:
   * 1. Validate all entities and entries without writing.
   * 2. Write only valid items inside a single prisma.$transaction (timeout 45s).
   */
  async syncBatch(householdId: string, dto: SyncBatchDto, userId: string) {
    // Authorisation first: a batch that references another household's records is rejected
    // before anything is written, so a rejected batch never leaves partial writes behind.
    await this.assertBatchOwnership(householdId, dto);

    // Deletions (tombstones) are loaded and validated
    const tombstones = await this.loadTombstones(householdId);
    const { deletionsToApply, appliedCount: deletionsApplied } = await this.validateDeletions(
      householdId,
      dto,
      tombstones,
    );

    // ─── PHASE 1: VALIDATION (NO WRITES) ─────────────────────────────────────

    // 0. Categories
    const categoriesToUpsert: SyncCategoryDto[] = [];
    if (dto.categories && dto.categories.length > 0) {
      const candidates = dto.categories.filter(
        (cat) => !tombstones.has(tombKey('category', cat.id)) && !isClientSystemCategoryId(cat.id, householdId),
      );
      if (candidates.length > 0) {
        const existingCats = await this.prisma.category.findMany({
          where: { id: { in: candidates.map((c) => c.id) } },
          select: {
            id: true,
            householdId: true,
            kind: true,
            groupCode: true,
            name: true,
            needOrWant: true,
            isDeduction: true,
            isSystem: true,
            sortOrder: true,
          },
        });
        const existingMap = new Map(existingCats.map((c) => [c.id, c]));
        for (const cat of candidates) {
          const existingCat = existingMap.get(cat.id);
          if (existingCat && existingCat.householdId !== householdId) {
            throw new ForbiddenException(`Category ${cat.id} belongs to a different household.`);
          }
          if (
            !existingCat ||
            existingCat.kind !== cat.kind ||
            existingCat.groupCode !== (cat.groupCode ?? null) ||
            existingCat.name !== cat.name ||
            existingCat.needOrWant !== (cat.needOrWant ?? null) ||
            existingCat.isDeduction !== (cat.isDeduction ?? false) ||
            existingCat.isSystem !== (cat.isSystem ?? false) ||
            existingCat.sortOrder !== (cat.sortOrder ?? 0)
          ) {
            categoriesToUpsert.push(cat);
          }
        }
      }
    }

    // 1. Accounts
    const accountsToUpsert: Array<{ targetId: string; account: SyncAccountDto }> = [];
    if (dto.accounts && dto.accounts.length > 0) {
      for (const a of dto.accounts) {
        const existingById = await this.prisma.account.findUnique({ where: { id: a.id } });
        if (existingById && existingById.householdId !== householdId) {
          throw new ForbiddenException(`Account ${a.id} belongs to a different household.`);
        }

        const existing = await this.prisma.account.findFirst({
          where: {
            householdId,
            name: { equals: a.name.trim(), mode: 'insensitive' },
          },
        });
        const targetId = existing ? existing.id : a.id;
        accountsToUpsert.push({ targetId, account: a });
      }
    }

    // 2. Credit Cards
    const cardsToUpsert: SyncCreditCardDto[] = [];
    if (dto.creditCards && dto.creditCards.length > 0) {
      for (const c of dto.creditCards) {
        const existingCard = await this.prisma.creditCard.findUnique({ where: { id: c.id } });
        if (existingCard && existingCard.householdId !== householdId) {
          throw new ForbiddenException(`Credit card ${c.id} belongs to a different household.`);
        }
        cardsToUpsert.push(c);
      }
    }

    // 3. Card Transactions
    const cardTxnsToUpsert: SyncCardTransactionDto[] = [];
    const missingParentCards = new Set<string>();
    if (dto.cardTransactions && dto.cardTransactions.length > 0) {
      for (const t of dto.cardTransactions) {
        if (tombstones.has(tombKey('card_transaction', t.id))) continue;

        const parentCard = await this.prisma.creditCard.findUnique({ where: { id: t.cardId } });
        if (parentCard && parentCard.householdId !== householdId) {
          throw new ForbiddenException(`Card ${t.cardId} belongs to a different household.`);
        }

        const existingTxn = await this.prisma.cardTransaction.findUnique({
          where: { id: t.id },
          include: { card: true },
        });
        if (existingTxn && existingTxn.card.householdId !== householdId) {
          throw new ForbiddenException(`Card transaction ${t.id} belongs to a different household.`);
        }

        if (!parentCard && !cardsToUpsert.some((c) => c.id === t.cardId)) {
          missingParentCards.add(t.cardId);
        }

        cardTxnsToUpsert.push(t);
      }
    }

    // 4. Planned Bills
    const billsToUpsert: SyncPlannedBillDto[] = [];
    if (dto.plannedBills && dto.plannedBills.length > 0) {
      for (const b of dto.plannedBills) {
        if (tombstones.has(tombKey('planned_bill', b.id))) continue;

        const existingBill = await this.prisma.plannedBill.findUnique({ where: { id: b.id } });
        if (existingBill && existingBill.householdId !== householdId) {
          throw new ForbiddenException(`Planned bill ${b.id} belongs to a different household.`);
        }

        if (b.entryId) {
          const linkedEntry = await this.prisma.entry.findUnique({ where: { id: b.entryId } });
          if (linkedEntry && linkedEntry.householdId !== householdId) {
            throw new ForbiddenException(`Linked entry ${b.entryId} belongs to a different household.`);
          }
        }

        billsToUpsert.push(b);
      }
    }

    // 5. Receivables
    const receivablesToUpsert: SyncReceivableDto[] = [];
    if (dto.receivables && dto.receivables.length > 0) {
      for (const r of dto.receivables) {
        if (tombstones.has(tombKey('receivable', r.id))) continue;

        const existingRec = await this.prisma.receivable.findUnique({ where: { id: r.id } });
        if (existingRec && existingRec.householdId !== householdId) {
          throw new ForbiddenException(`Receivable ${r.id} belongs to a different household.`);
        }

        if (r.entryId) {
          const linkedEntry = await this.prisma.entry.findUnique({ where: { id: r.entryId } });
          if (linkedEntry && linkedEntry.householdId !== householdId) {
            throw new ForbiddenException(`Linked entry ${r.entryId} belongs to a different household.`);
          }
        }

        receivablesToUpsert.push(r);
      }
    }

    // 6. Saving Goals
    const goalsToUpsert: SyncSavingGoalDto[] = [];
    if (dto.savingGoals && dto.savingGoals.length > 0) {
      for (const g of dto.savingGoals) {
        const existingGoal = await this.prisma.savingGoal.findUnique({ where: { id: g.id } });
        if (existingGoal && existingGoal.householdId !== householdId) {
          throw new ForbiddenException(`Saving goal ${g.id} belongs to a different household.`);
        }
        goalsToUpsert.push(g);
      }
    }

    // 7. Sinking Funds
    const fundsToUpsert: SyncSinkingFundDto[] = [];
    if (dto.sinkingFunds && dto.sinkingFunds.length > 0) {
      for (const f of dto.sinkingFunds) {
        const existingFund = await this.prisma.sinkingFund.findUnique({ where: { id: f.id } });
        if (existingFund && existingFund.householdId !== householdId) {
          throw new ForbiddenException(`Sinking fund ${f.id} belongs to a different household.`);
        }
        fundsToUpsert.push(f);
      }
    }

    // 8. Goal Contributions
    const goalContributionsToUpsert: SyncGoalContributionDto[] = [];
    const batchGoalIds = new Set((dto.savingGoals ?? []).map((g) => g.id));
    if (dto.goalContributions && dto.goalContributions.length > 0) {
      for (const gc of dto.goalContributions) {
        if (tombstones.has(tombKey('goal_contribution', gc.id))) continue;

        const parentGoal = await this.prisma.savingGoal.findUnique({ where: { id: gc.goalId } });
        if (parentGoal ? parentGoal.householdId !== householdId : !batchGoalIds.has(gc.goalId)) {
          throw new ForbiddenException(`Goal ${gc.goalId} does not belong to this household.`);
        }
        goalContributionsToUpsert.push(gc);
      }
    }

    // 9. Fund Movements
    const fundMovementsToUpsert: SyncFundMovementDto[] = [];
    const batchFundIds = new Set((dto.sinkingFunds ?? []).map((f) => f.id));
    if (dto.fundMovements && dto.fundMovements.length > 0) {
      for (const fm of dto.fundMovements) {
        if (tombstones.has(tombKey('fund_movement', fm.id))) continue;

        const parentFund = await this.prisma.sinkingFund.findUnique({ where: { id: fm.fundId } });
        if (parentFund ? parentFund.householdId !== householdId : !batchFundIds.has(fm.fundId)) {
          throw new ForbiddenException(`Sinking fund ${fm.fundId} does not belong to this household.`);
        }
        fundMovementsToUpsert.push(fm);
      }
    }

    // 10. Budgets
    type BudgetPlan =
      | { mode: 'update'; id: string; amountPaise: number }
      | { mode: 'upsert'; id: string; categoryId: string; yearMonth: string; amountPaise: number };
    const budgetsToUpsert: BudgetPlan[] = [];
    if (dto.budgets && dto.budgets.length > 0) {
      for (const b of dto.budgets) {
        if (tombstones.has(tombKey('budget', b.id))) continue;

        const existingBudget = await this.prisma.budget.findUnique({ where: { id: b.id } });
        if (existingBudget && existingBudget.householdId !== householdId) {
          throw new ForbiddenException(`Budget ${b.id} belongs to a different household.`);
        }

        const cat = await this.prisma.category.findUnique({ where: { id: b.categoryId } });
        if (cat && cat.householdId !== householdId) {
          throw new ForbiddenException(`Category ${b.categoryId} belongs to a different household.`);
        }

        const amountPaise = Math.round(Number(b.amountPaise || 0));
        if (!existingBudget) {
          const sameCell = await this.prisma.budget.findFirst({
            where: { householdId, categoryId: b.categoryId, yearMonth: b.yearMonth },
          });
          if (sameCell) {
            budgetsToUpsert.push({ mode: 'update', id: sameCell.id, amountPaise });
            continue;
          }
        }

        budgetsToUpsert.push({
          mode: 'upsert',
          id: b.id,
          categoryId: b.categoryId,
          yearMonth: b.yearMonth,
          amountPaise,
        });
      }
    }

    // 11. Reserve Lines
    const reserveLinesToUpsert: SyncReserveLineDto[] = [];
    if (dto.reserveLines && dto.reserveLines.length > 0) {
      for (const rl of dto.reserveLines) {
        if (tombstones.has(tombKey('reserve_line', rl.id))) continue;

        const existing = await this.prisma.reserveLine.findUnique({ where: { id: rl.id } });
        if (existing && existing.householdId !== householdId) {
          throw new ForbiddenException(`Reserve line ${rl.id} belongs to a different household.`);
        }
        reserveLinesToUpsert.push(rl);
      }
    }

    // 12. Annual Targets
    const annualTargetsToUpsert: any[] = [];
    if (dto.annualTargets && dto.annualTargets.length > 0) {
      for (const at of dto.annualTargets) {
        if (tombstones.has(tombKey('annual_target', at.id))) continue;

        const existing = await this.prisma.annual_targets.findUnique({ where: { id: at.id } });
        if (existing && existing.household_id !== householdId) {
          throw new ForbiddenException(`Annual target ${at.id} belongs to a different household.`);
        }
        annualTargetsToUpsert.push(at);
      }
    }

    // 13. Entries Validation
    let entryValidation: any = null;
    let entriesResult = { synced: 0, failed: 0 };
    if (dto.entries && dto.entries.length > 0) {
      if (typeof (this.entriesService as any).validateBatch === 'function') {
        entryValidation = await (this.entriesService as any).validateBatch(householdId, dto.entries, userId);
        entriesResult = { synced: entryValidation.syncedCount, failed: entryValidation.failedCount };
      }
    }

    // ─── PHASE 2: ATOMIC TRANSACTIONAL WRITE ─────────────────────────────────
    // Timeout of 45s accommodates large initial/catch-up syncs (500+ items) over mobile connections
    // while preventing runaway locks.
    const runner = this.prisma?.$transaction
      ? (fn: any) => this.prisma.$transaction(fn, { timeout: 45000, maxWait: 10000 })
      : (fn: any) => fn(this.prisma);

    await runner(async (tx: any) => {
      // 1. Apply Deletions
      await this.applyValidatedDeletions(householdId, deletionsToApply, tombstones, tx);

      // 2. Categories
      for (const cat of categoriesToUpsert) {
        await tx.category.upsert({
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
      }

      // 3. Accounts
      for (const item of accountsToUpsert) {
        const { targetId, account: a } = item;
        await tx.account.upsert({
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
      }

      // 4. Credit Cards
      for (const c of cardsToUpsert) {
        await tx.creditCard.upsert({
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
      }

      // 5. Card Transactions
      for (const cardId of missingParentCards) {
        await tx.creditCard
          .create({
            data: {
              id: cardId,
              householdId,
              name: 'Credit Card',
              previousOutstandingPaise: 0,
              isActive: true,
            },
          })
          .catch(() => {});
      }
      for (const t of cardTxnsToUpsert) {
        await tx.cardTransaction.upsert({
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
      }

      // 6. Planned Bills
      for (const b of billsToUpsert) {
        await tx.plannedBill.upsert({
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
      }

      // 7. Receivables
      for (const r of receivablesToUpsert) {
        await tx.receivable.upsert({
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
      }

      // 8. Saving Goals
      for (const g of goalsToUpsert) {
        await tx.savingGoal.upsert({
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
      }

      // 9. Sinking Funds
      for (const f of fundsToUpsert) {
        await tx.sinkingFund.upsert({
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
      }

      // 10. Goal Contributions
      for (const gc of goalContributionsToUpsert) {
        await tx.goalContribution.upsert({
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
      }

      // 11. Fund Movements
      for (const fm of fundMovementsToUpsert) {
        await tx.fundMovement.upsert({
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
      }

      // 12. Budgets
      for (const b of budgetsToUpsert) {
        if (b.mode === 'update') {
          await tx.budget.update({
            where: { id: b.id },
            data: { amountPaise: b.amountPaise },
          });
        } else {
          await tx.budget.upsert({
            where: { id: b.id },
            create: {
              id: b.id,
              householdId,
              categoryId: b.categoryId,
              yearMonth: b.yearMonth,
              amountPaise: b.amountPaise,
            },
            update: {
              amountPaise: b.amountPaise,
            },
          });
        }
      }

      // 13. Reserve Lines
      for (const rl of reserveLinesToUpsert) {
        await tx.reserveLine.upsert({
          where: { id: rl.id },
          create: {
            id: rl.id,
            householdId,
            yearMonth: rl.yearMonth,
            name: rl.name,
            amountPaise: Math.round(Number(rl.amountPaise || 0)),
            source: rl.source ?? 'manual',
          },
          update: {
            name: rl.name,
            amountPaise: Math.round(Number(rl.amountPaise || 0)),
            source: rl.source ?? 'manual',
          },
        });
      }

      // 14. Annual Targets
      for (const at of annualTargetsToUpsert) {
        await tx.annual_targets.upsert({
          where: { id: at.id },
          create: {
            id: at.id,
            household_id: householdId,
            title: at.title,
            target_paise: Math.round(Number(at.targetPaise || 0)),
            type: at.type || 'income',
          },
          update: {
            title: at.title,
            target_paise: Math.round(Number(at.targetPaise || 0)),
            type: at.type || 'income',
          },
        });
      }

      // 15. Entries
      if (dto.entries && dto.entries.length > 0) {
        if (entryValidation && typeof (this.entriesService as any).applyBatch === 'function') {
          await (this.entriesService as any).applyBatch(
            householdId,
            entryValidation.validWrites,
            entryValidation.neededCategories,
            userId,
            tx,
          );
        } else {
          entriesResult = await this.entriesService.upsertBatch(householdId, dto.entries, userId, tx);
        }
      }
    });

    return {
      categories: categoriesToUpsert.length,
      accounts: accountsToUpsert.length,
      creditCards: cardsToUpsert.length,
      cardTransactions: cardTxnsToUpsert.length,
      plannedBills: billsToUpsert.length,
      receivables: receivablesToUpsert.length,
      savingGoals: goalsToUpsert.length,
      sinkingFunds: fundsToUpsert.length,
      budgets: budgetsToUpsert.length,
      reserveLines: reserveLinesToUpsert.length,
      annualTargets: annualTargetsToUpsert.length,
      entries: entriesResult,
      deletions: deletionsApplied,
      syncedAt: new Date(),
    };
  }

  /**
   * Pull all household data from PostgreSQL database to synchronize client cache (GET /sync/pull).
   */
  async pullData(householdId: string) {
    // Run in controlled batches (max 6 parallel) to respect database connection limits.
    // NOTE: intentionally NOT filtering by isActive/archivedAt here. A device that already
    // has a local copy of an account/card/goal/fund/category needs to learn when another
    // device deactivates or archives it; excluding those rows meant the deactivation never
    // reached other devices and the stale local copy stayed "active" forever (data-persistence
    // audit finding, 2026-09-17). The client already applies isActive/archivedAt correctly on
    // upsert — it only needed the row to actually be included in the response.
    const [
      accounts,
      creditCards,
      cardTransactions,
      plannedBills,
      receivables,
      savingGoals,
    ] = await Promise.all([
      this.prisma.account.findMany({
        where: { householdId },
        orderBy: { sortOrder: 'asc' },
      }),
      this.prisma.creditCard.findMany({
        where: { householdId },
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
        where: { householdId },
      }),
    ]);

    const [
      goalContributions,
      sinkingFunds,
      fundMovements,
      budgets,
      reserveLines,
      annualTargets,
    ] = await Promise.all([
      this.prisma.goalContribution.findMany({
        where: { goal: { householdId } },
        orderBy: { contributionDate: 'desc' },
      }),
      this.prisma.sinkingFund.findMany({
        where: { householdId },
      }),
      this.prisma.fundMovement.findMany({
        where: { fund: { householdId } },
        orderBy: { movementDate: 'desc' },
      }),
      this.prisma.budget.findMany({
        where: { householdId },
      }),
      this.prisma.reserveLine.findMany({
        where: { householdId },
      }),
      this.prisma.annual_targets.findMany({
        where: { household_id: householdId },
      }),
    ]);

    const [
      categories,
      entries,
      deletedEntries,
      tombstones,
      monthSnapshots,
    ] = await Promise.all([
      this.prisma.category.findMany({
        where: { householdId },
        orderBy: { sortOrder: 'asc' },
      }),
      this.prisma.entry.findMany({
        where: { householdId, deletedAt: null },
        orderBy: { entryDate: 'desc' },
      }),
      this.prisma.entry.findMany({
        where: { householdId, deletedAt: { not: null } },
        select: { id: true, deletedAt: true },
      }),
      this.prisma.syncTombstone.findMany({
        where: { householdId },
        select: { entity: true, entityId: true },
      }),
      this.prisma.monthSnapshot.findMany({
        where: { householdId },
        select: { yearMonth: true, status: true, statusChangedAt: true },
      }),
    ]);

    const deletedRecords: Record<string, string[]> = {};
    for (const key of Object.values(PULL_KEY_BY_ENTITY)) deletedRecords[key] = [];
    for (const t of tombstones) {
      const key = PULL_KEY_BY_ENTITY[t.entity as SyncDeletableEntity];
      if (key) deletedRecords[key].push(t.entityId);
    }

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
      reserveLines: reserveLines.map((rl) => ({
        ...rl,
        amountPaise: Number(rl.amountPaise),
      })),
      annualTargets: annualTargets.map((at) => ({
        id: at.id,
        householdId: at.household_id,
        title: at.title,
        targetPaise: Number(at.target_paise),
        type: at.type,
      })),
      categories: categories.map((c) => ({
        ...c,
        archivedAt: c.archivedAt ? c.archivedAt.toISOString() : null,
      })),
      entries: entries.map((e) => ({
        ...e,
        amountPaise: Number(e.amountPaise),
        entryDate: e.entryDate.toISOString(),
        createdAt: e.createdAt.toISOString(),
        updatedAt: e.updatedAt.toISOString(),
        deletedAt: e.deletedAt ? e.deletedAt.toISOString() : null,
      })),
      deletedEntryIds: deletedEntries.map((e) => e.id),
      deletedEntries: deletedEntries.map((e) => ({
        id: e.id,
        deletedAt: e.deletedAt!.toISOString(),
      })),
      // Tombstones for device hard-deletes, keyed like the collections above.
      deletedRecords,
      deletedAnnualTargetIds: deletedRecords.annualTargets,
      // Month open/closed status only (values are computed per device).
      monthStatuses: monthSnapshots.map((m) => ({
        yearMonth: m.yearMonth,
        status: m.status,
        statusChangedAt: m.statusChangedAt ? m.statusChangedAt.toISOString() : null,
      })),
      pulledAt: new Date(),
    };
  }

  // ─── Authorisation pre-check ───────────────────────────────────────────────

  private async assertBatchOwnership(householdId: string, dto: SyncBatchDto) {
    const forbid = (msg: string) => { throw new ForbiddenException(msg); };
    const batchGoalIds = new Set((dto.savingGoals ?? []).map((g) => g.id));
    const batchFundIds = new Set((dto.sinkingFunds ?? []).map((f) => f.id));

    for (const t of dto.cardTransactions ?? []) {
      const parentCard = await this.prisma.creditCard.findUnique({ where: { id: t.cardId } });
      if (parentCard && parentCard.householdId !== householdId) forbid(`Card ${t.cardId} belongs to a different household.`);
      const existingTxn = await this.prisma.cardTransaction.findUnique({ where: { id: t.id }, include: { card: true } });
      if (existingTxn && existingTxn.card.householdId !== householdId) forbid(`Card transaction ${t.id} belongs to a different household.`);
    }
    for (const b of dto.plannedBills ?? []) {
      const existing = await this.prisma.plannedBill.findUnique({ where: { id: b.id } });
      if (existing && existing.householdId !== householdId) forbid(`Planned bill ${b.id} belongs to a different household.`);
      if (b.entryId) {
        const linked = await this.prisma.entry.findUnique({ where: { id: b.entryId } });
        if (linked && linked.householdId !== householdId) forbid(`Linked entry ${b.entryId} belongs to a different household.`);
      }
    }
    for (const r of dto.receivables ?? []) {
      const existing = await this.prisma.receivable.findUnique({ where: { id: r.id } });
      if (existing && existing.householdId !== householdId) forbid(`Receivable ${r.id} belongs to a different household.`);
      if (r.entryId) {
        const linked = await this.prisma.entry.findUnique({ where: { id: r.entryId } });
        if (linked && linked.householdId !== householdId) forbid(`Linked entry ${r.entryId} belongs to a different household.`);
      }
    }
    for (const gc of dto.goalContributions ?? []) {
      const parent = await this.prisma.savingGoal.findUnique({ where: { id: gc.goalId } });
      if (parent ? parent.householdId !== householdId : !batchGoalIds.has(gc.goalId)) {
        forbid(`Goal ${gc.goalId} does not belong to this household.`);
      }
    }
    for (const fm of dto.fundMovements ?? []) {
      const parent = await this.prisma.sinkingFund.findUnique({ where: { id: fm.fundId } });
      if (parent ? parent.householdId !== householdId : !batchFundIds.has(fm.fundId)) {
        forbid(`Sinking fund ${fm.fundId} does not belong to this household.`);
      }
    }
    for (const b of dto.budgets ?? []) {
      const existing = await this.prisma.budget.findUnique({ where: { id: b.id } });
      if (existing && existing.householdId !== householdId) forbid(`Budget ${b.id} belongs to a different household.`);
      const cat = await this.prisma.category.findUnique({ where: { id: b.categoryId } });
      if (cat && cat.householdId !== householdId) forbid(`Category ${b.categoryId} belongs to a different household.`);
    }
    for (const rl of dto.reserveLines ?? []) {
      const existing = await this.prisma.reserveLine.findUnique({ where: { id: rl.id } });
      if (existing && existing.householdId !== householdId) forbid(`Reserve line ${rl.id} belongs to a different household.`);
    }
    for (const at of dto.annualTargets ?? []) {
      const existing = await this.prisma.annual_targets.findUnique({ where: { id: at.id } });
      if (existing && existing.household_id !== householdId) forbid(`Annual target ${at.id} belongs to a different household.`);
    }
  }

  // ─── Tombstones ────────────────────────────────────────────────────────────

  private async loadTombstones(householdId: string): Promise<Set<string>> {
    const rows = await this.prisma.syncTombstone.findMany({
      where: { householdId },
      select: { entity: true, entityId: true },
    });
    return new Set(rows.map((r) => tombKey(r.entity, r.entityId)));
  }

  /** Returns the household that owns a record, `null` if the record does not exist. */
  private async ownerOf(entity: SyncDeletableEntity, id: string): Promise<string | null> {
    switch (entity) {
      case 'planned_bill': return (await this.prisma.plannedBill.findUnique({ where: { id } }))?.householdId ?? null;
      case 'receivable': return (await this.prisma.receivable.findUnique({ where: { id } }))?.householdId ?? null;
      case 'budget': return (await this.prisma.budget.findUnique({ where: { id } }))?.householdId ?? null;
      case 'reserve_line': return (await this.prisma.reserveLine.findUnique({ where: { id } }))?.householdId ?? null;
      case 'annual_target': return (await this.prisma.annual_targets.findUnique({ where: { id } }))?.household_id ?? null;
      case 'category': return (await this.prisma.category.findUnique({ where: { id } }))?.householdId ?? null;
      case 'card_transaction':
        return (await this.prisma.cardTransaction.findUnique({ where: { id }, include: { card: true } }))?.card.householdId ?? null;
      case 'goal_contribution':
        return (await this.prisma.goalContribution.findUnique({ where: { id }, include: { goal: true } }))?.goal.householdId ?? null;
      case 'fund_movement':
        return (await this.prisma.fundMovement.findUnique({ where: { id }, include: { fund: true } }))?.fund.householdId ?? null;
    }
  }

  private async validateDeletions(
    householdId: string,
    dto: SyncBatchDto,
    tombstones: Set<string>,
  ): Promise<{
    deletionsToApply: Array<{ del: SyncDeletionDto; isOwner: boolean; shouldTombstone: boolean }>;
    appliedCount: number;
  }> {
    const requested: SyncDeletionDto[] = [
      ...(dto.deletions ?? []),
      // Backwards compatibility with clients that only send deletedAnnualTargetIds.
      ...(dto.deletedAnnualTargetIds ?? []).map((id) => ({ entity: 'annual_target', id }) as SyncDeletionDto),
    ];

    // Ownership check for every requested deletion before deleting anything.
    const owners = new Map<string, string | null>();
    for (const del of requested) {
      const owner = await this.ownerOf(del.entity as SyncDeletableEntity, del.id);
      if (owner && owner !== householdId) {
        throw new ForbiddenException(`Cannot delete ${del.entity} ${del.id}: it belongs to a different household.`);
      }
      owners.set(tombKey(del.entity, del.id), owner);
    }

    const deletionsToApply: Array<{ del: SyncDeletionDto; isOwner: boolean; shouldTombstone: boolean }> = [];
    let appliedCount = 0;
    for (const del of requested) {
      const key = tombKey(del.entity, del.id);
      const isOwner = owners.get(key) === householdId;
      const shouldTombstone = isOwner && !tombstones.has(key);
      deletionsToApply.push({ del, isOwner, shouldTombstone });
      appliedCount++;
    }

    return { deletionsToApply, appliedCount };
  }

  private async applyValidatedDeletions(
    householdId: string,
    deletionsToApply: Array<{ del: SyncDeletionDto; isOwner: boolean; shouldTombstone: boolean }>,
    tombstones: Set<string>,
    tx: any,
  ): Promise<void> {
    for (const item of deletionsToApply) {
      const { del, isOwner, shouldTombstone } = item;
      const key = tombKey(del.entity, del.id);
      if (isOwner) {
        const entity = del.entity as SyncDeletableEntity;
        const id = del.id;
        switch (entity) {
          case 'planned_bill': await tx.plannedBill.deleteMany({ where: { id, householdId } }); break;
          case 'receivable': await tx.receivable.deleteMany({ where: { id, householdId } }); break;
          case 'budget': await tx.budget.deleteMany({ where: { id, householdId } }); break;
          case 'reserve_line': await tx.reserveLine.deleteMany({ where: { id, householdId } }); break;
          case 'annual_target': await tx.annual_targets.deleteMany({ where: { id, household_id: householdId } }); break;
          case 'card_transaction': await tx.cardTransaction.deleteMany({ where: { id, card: { householdId } } }); break;
          case 'goal_contribution': await tx.goalContribution.deleteMany({ where: { id, goal: { householdId } } }); break;
          case 'fund_movement': await tx.fundMovement.deleteMany({ where: { id, fund: { householdId } } }); break;
          case 'category':
            // Categories are referenced by historical entries (FK RESTRICT): archive, never hard-delete.
            await tx.category.updateMany({ where: { id, householdId, isSystem: false }, data: { archivedAt: new Date() } });
            break;
        }
      }
      // Only records that existed in this household get a tombstone; unknown ids (never synced) need none,
      // and must not reserve the global (entity, entityId) key for another tenant's future record.
      if (shouldTombstone) {
        await tx.syncTombstone.upsert({
          where: { entity_entityId: { entity: del.entity, entityId: del.id } },
          create: { householdId, entity: del.entity, entityId: del.id },
          update: {},
        });
        tombstones.add(key);
      }
    }
  }
}
