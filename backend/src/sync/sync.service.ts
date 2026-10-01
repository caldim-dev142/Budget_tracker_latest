import { Injectable, Inject, ForbiddenException } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import { EntriesService, BatchContext, findManyBatch } from '../entries/entries.service';
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
  SyncRecurringRuleDto,
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
  recurring_rule: 'recurringRules',
};

/**
 * Merge two recurring rule processed states (Section 6).
 * processedSet(state) = { every scheduled occurrence date <= processedThrough } ∪ processedDates
 * merge(A, B) must satisfy: processedSet(result) == processedSet(A) ∪ processedSet(B)
 */
export function mergeProcessedState(
  rule: { dayOfMonth: number; startDate: Date | string; endDate?: Date | string | null },
  a: { processedThrough?: Date | string | null; processedDates?: string[] | null },
  b: { processedThrough?: Date | string | null; processedDates?: string[] | null },
): { processedThrough: Date | null; processedDates: string[] } {
  const toMs = (d: Date | string | null | undefined): number =>
    d ? (d instanceof Date ? d.getTime() : new Date(d).getTime()) : 0;

  const aThrough = a.processedThrough ? new Date(a.processedThrough) : null;
  const bThrough = b.processedThrough ? new Date(b.processedThrough) : null;
  // 1. mergedThrough = the later of the two
  let mergedThrough: Date | null = null;
  if (aThrough && bThrough) {
    mergedThrough = toMs(aThrough) >= toMs(bThrough) ? aThrough : bThrough;
  } else {
    mergedThrough = aThrough ?? bThrough;
  }

  // 2. Union of both processedDates
  const mergedDatesSet = new Set<string>([
    ...(a.processedDates ?? []),
    ...(b.processedDates ?? []),
  ]);

  // 3. Remove any date <= mergedThrough
  if (mergedThrough) {
    const throughMs = toMs(mergedThrough);
    for (const d of Array.from(mergedDatesSet)) {
      if (new Date(d).getTime() <= throughMs) mergedDatesSet.delete(d);
    }
  }

  // 4. Compact: advance mergedThrough while next scheduled occurrence is in mergedDatesSet.
  //    SPEC Item 11: when processedThrough is null, the "next occurrence" must be the
  //    FIRST scheduled occurrence on or after startDate (not the one AFTER startDate's month).
  const dayOfMonth = rule.dayOfMonth;
  let currentThrough = mergedThrough ? new Date(mergedThrough) : null;
  let compacted = true;
  let isFirstStep = currentThrough === null;
  while (compacted) {
    compacted = false;
    let nextOccDate: Date;
    if (isFirstStep) {
      // First step: first occurrence on or after startDate
      nextOccDate = firstOccurrenceOnOrAfter(dayOfMonth, new Date(rule.startDate));
      isFirstStep = false;
    } else {
      // Subsequent steps: next occurrence after currentThrough
      nextOccDate = nextScheduledOccurrence(dayOfMonth, currentThrough!);
    }
    const nextStr = nextOccDate.toISOString().substring(0, 10);
    for (const d of Array.from(mergedDatesSet)) {
      if (d.substring(0, 10) === nextStr) {
        currentThrough = nextOccDate;
        mergedDatesSet.delete(d);
        compacted = true;
        break;
      }
    }
  }

  const finalDates = Array.from(mergedDatesSet);
  if (finalDates.length > 400) {
    console.warn(
      `[mergeProcessedState] processedDates has ${finalDates.length} entries ` +
      `(expected <=400). Keeping all to avoid data loss.`,
    );
  }
  finalDates.sort();
  return { processedThrough: currentThrough, processedDates: finalDates };
}

/**
 * Returns the FIRST scheduled occurrence on or after `from` for a given dayOfMonth.
 * Used when processedThrough is null (compaction starts from startDate).
 */
function firstOccurrenceOnOrAfter(dayOfMonth: number, from: Date): Date {
  const fromDate = new Date(from);
  // Try occurrence in from's own month
  const lastDaySameMonth = new Date(
    Date.UTC(fromDate.getUTCFullYear(), fromDate.getUTCMonth() + 1, 0),
  ).getUTCDate();
  const occInSameMonth = new Date(
    Date.UTC(
      fromDate.getUTCFullYear(),
      fromDate.getUTCMonth(),
      Math.min(dayOfMonth, lastDaySameMonth),
      12, 0, 0, 0,
    ),
  );
  if (occInSameMonth >= fromDate) return occInSameMonth;
  // Otherwise: occurrence in next month
  return nextScheduledOccurrence(dayOfMonth, from);
}

/** Returns the next monthly occurrence date AFTER `after` for a given dayOfMonth. */
function nextScheduledOccurrence(dayOfMonth: number, after: Date): Date {
  const next = new Date(after);
  next.setUTCDate(1);
  next.setUTCHours(12, 0, 0, 0);
  // Move to next month
  next.setUTCMonth(next.getUTCMonth() + 1);
  const lastDay = new Date(Date.UTC(next.getUTCFullYear(), next.getUTCMonth() + 1, 0)).getUTCDate();
  next.setUTCDate(Math.min(dayOfMonth, lastDay));
  return next;
}

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

function sameInstant(a: Date | string | null | undefined, b: Date | string | null | undefined): boolean {
  if (!a || !b) return !a && !b;
  const tA = a instanceof Date ? a.getTime() : new Date(a).getTime();
  const tB = b instanceof Date ? b.getTime() : new Date(b).getTime();
  return tA === tB;
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
    const phase1StartTime = Date.now();
    const categoriesToUpsert: SyncCategoryDto[] = [];
    const accountsToUpsert: Array<{ targetId: string; account: SyncAccountDto }> = [];
    const cardsToUpsert: SyncCreditCardDto[] = [];
    const cardTxnsToUpsert: SyncCardTransactionDto[] = [];
    const missingParentCards = new Set<string>();
    const billsToUpsert: SyncPlannedBillDto[] = [];
    const receivablesToUpsert: SyncReceivableDto[] = [];
    const goalsToUpsert: SyncSavingGoalDto[] = [];
    const fundsToUpsert: SyncSinkingFundDto[] = [];
    const goalContributionsToUpsert: SyncGoalContributionDto[] = [];
    const fundMovementsToUpsert: SyncFundMovementDto[] = [];
    type BudgetPlan =
      | { mode: 'update'; id: string; amountPaise: number }
      | { mode: 'upsert'; id: string; categoryId: string; yearMonth: string; amountPaise: number };
    const budgetsToUpsert: BudgetPlan[] = [];
    const reserveLinesToUpsert: SyncReserveLineDto[] = [];
    const annualTargetsToUpsert: any[] = [];
    let entryValidation: any = null;
    let entriesResult: { synced: number; failed: number; rejected: Array<{ id: string; reason: string }> } = {
      synced: 0,
      failed: 0,
      rejected: [],
    };
    let tombstones: Set<string>;
    let deletionsToApply: Array<{ del: SyncDeletionDto; isOwner: boolean; shouldTombstone: boolean }> = [];
    let deletionsApplied = 0;
    const recurringRulesToUpsert: SyncRecurringRuleDto[] = [];

    try {
      // Deletions (tombstones) are loaded and validated
      tombstones = await this.loadTombstones(householdId);
      const deletionRes = await this.validateDeletions(
        householdId,
        dto,
        tombstones,
      );
      deletionsToApply = deletionRes.deletionsToApply;
      deletionsApplied = deletionRes.appliedCount;

      // ─── PHASE 1: VALIDATION (NO WRITES) ─────────────────────────────────────

      // 0. Categories
      if (dto.categories && dto.categories.length > 0) {
        const candidates = dto.categories.filter(
          (cat) => !tombstones.has(tombKey('category', cat.id)) && !isClientSystemCategoryId(cat.id, householdId),
        );
        if (candidates.length > 0) {
          const existingCats = await findManyBatch(this.prisma.category, candidates.map((c) => c.id));
          const existingMap = new Map(existingCats.map((c: any) => [c.id, c]));
          for (const cat of candidates) {
            const existingCat = existingMap.get(cat.id);
            if (existingCat && existingCat.householdId !== householdId) {
              throw new ForbiddenException(`Category ${cat.id} belongs to a different household.`);
            }
            const incomingArchivedAt = cat.archivedAt ? new Date(cat.archivedAt) : null;
            if (
              !existingCat ||
              existingCat.kind !== cat.kind ||
              (existingCat.groupCode ?? null) !== (cat.groupCode ?? null) ||
              existingCat.name !== cat.name ||
              (existingCat.needOrWant ?? null) !== (cat.needOrWant ?? null) ||
              (existingCat.isDeduction ?? false) !== (cat.isDeduction ?? false) ||
              (existingCat.isSystem ?? false) !== (cat.isSystem ?? false) ||
              (existingCat.sortOrder ?? 0) !== (cat.sortOrder ?? 0) ||
              !sameInstant(existingCat.archivedAt, incomingArchivedAt)
            ) {
              categoriesToUpsert.push(cat);
            }
          }
        }
      }

      // 1. Accounts
      const validCreatedAccountIds = new Set<string>();
      if (dto.accounts && dto.accounts.length > 0) {
        const accountIds = dto.accounts.map((a) => a.id);
        const [existingAccountsById, existingHouseholdAccounts] = await Promise.all([
          findManyBatch(this.prisma.account, accountIds),
          typeof this.prisma.account?.findMany === 'function'
            ? this.prisma.account.findMany({ where: { householdId } })
            : Promise.resolve([]),
        ]);
        const accountsByIdMap = new Map(existingAccountsById.map((a: any) => [a.id, a]));

        for (const a of dto.accounts) {
          const existingById = accountsByIdMap.get(a.id);
          if (existingById && existingById.householdId !== householdId) {
            throw new ForbiddenException(`Account ${a.id} belongs to a different household.`);
          }

          const existingByName = (existingHouseholdAccounts as any[]).find(
            (acc: any) => acc.name?.trim().toLowerCase() === a.name.trim().toLowerCase(),
          );

          const targetId = existingByName ? existingByName.id : a.id;
          if (targetId === a.id) {
            validCreatedAccountIds.add(a.id);
          }

          const targetDbRow = existingByName ?? existingById;
          const currentBalance = Math.round(Number(a.currentBalancePaise ?? 0));
          const isActive = a.isActive ?? true;
          const sortOrder = a.sortOrder ?? 0;

          if (
            !targetDbRow ||
            targetDbRow.name?.trim() !== a.name.trim() ||
            targetDbRow.type !== a.type ||
            BigInt(targetDbRow.currentBalancePaise ?? 0) !== BigInt(currentBalance) ||
            (targetDbRow.isActive ?? true) !== isActive ||
            (targetDbRow.sortOrder ?? 0) !== sortOrder
          ) {
            accountsToUpsert.push({ targetId, account: a });
          }
        }
      }

      // 2. Credit Cards
      if (dto.creditCards && dto.creditCards.length > 0) {
        const existingCards = await findManyBatch(this.prisma.creditCard, dto.creditCards.map((c) => c.id));
        const cardsMap = new Map(existingCards.map((c: any) => [c.id, c]));
        for (const c of dto.creditCards) {
          const existingCard = cardsMap.get(c.id);
          if (existingCard && existingCard.householdId !== householdId) {
            throw new ForbiddenException(`Credit card ${c.id} belongs to a different household.`);
          }
          const prevOutstanding = Math.round(Number(c.previousOutstandingPaise ?? 0));
          const isActive = c.isActive ?? true;
          if (
            !existingCard ||
            existingCard.name !== c.name ||
            BigInt(existingCard.previousOutstandingPaise ?? 0) !== BigInt(prevOutstanding) ||
            (existingCard.isActive ?? true) !== isActive
          ) {
            cardsToUpsert.push(c);
          }
        }
      }

      // 3. Card Transactions
      if (dto.cardTransactions && dto.cardTransactions.length > 0) {
        const candidates = dto.cardTransactions.filter((t) => !tombstones.has(tombKey('card_transaction', t.id)));
        if (candidates.length > 0) {
          const cardIds = [...new Set(candidates.map((t) => t.cardId))];
          const txnIds = candidates.map((t) => t.id);

          const [parentCards, existingTxns] = await Promise.all([
            findManyBatch(this.prisma.creditCard, cardIds),
            findManyBatch(this.prisma.cardTransaction, txnIds, undefined, { card: true }),
          ]);

          const cardsMap = new Map(parentCards.map((c: any) => [c.id, c]));
          const txnsMap = new Map(existingTxns.map((t: any) => [t.id, t]));
          const payloadCardIds = new Set((dto.creditCards ?? []).map((c) => c.id));

          for (const t of candidates) {
            const parentCard = cardsMap.get(t.cardId);
            if (parentCard && parentCard.householdId !== householdId) {
              throw new ForbiddenException(`Card ${t.cardId} belongs to a different household.`);
            }

            const existingTxn = txnsMap.get(t.id);
            if (existingTxn && existingTxn.card && existingTxn.card.householdId !== householdId) {
              throw new ForbiddenException(`Card transaction ${t.id} belongs to a different household.`);
            }

            if (!parentCard && !payloadCardIds.has(t.cardId)) {
              missingParentCards.add(t.cardId);
            }

            const amountPaise = Math.round(Number(t.amountPaise ?? 0));
            if (
              !existingTxn ||
              existingTxn.cardId !== t.cardId ||
              !sameInstant(existingTxn.txnDate, t.txnDate) ||
              existingTxn.description !== t.description ||
              BigInt(existingTxn.amountPaise ?? 0) !== BigInt(amountPaise) ||
              (existingTxn.sNo ?? null) !== (t.sNo ?? null)
            ) {
              cardTxnsToUpsert.push(t);
            }
          }
        }
      }

      // 4. Planned Bills
      if (dto.plannedBills && dto.plannedBills.length > 0) {
        const candidates = dto.plannedBills.filter((b) => !tombstones.has(tombKey('planned_bill', b.id)));
        if (candidates.length > 0) {
          const billIds = candidates.map((b) => b.id);
          const linkedEntryIds = candidates.map((b) => b.entryId).filter(Boolean) as string[];

          const [existingBills, linkedEntries] = await Promise.all([
            findManyBatch(this.prisma.plannedBill, billIds),
            findManyBatch(this.prisma.entry, linkedEntryIds),
          ]);

          const billsMap = new Map(existingBills.map((b: any) => [b.id, b]));
          const entriesMap = new Map(linkedEntries.map((e: any) => [e.id, e]));

          for (const b of candidates) {
            const existingBill = billsMap.get(b.id);
            if (existingBill && existingBill.householdId !== householdId) {
              throw new ForbiddenException(`Planned bill ${b.id} belongs to a different household.`);
            }

            if (b.entryId) {
              const linkedEntry = entriesMap.get(b.entryId);
              if (linkedEntry && linkedEntry.householdId !== householdId) {
                throw new ForbiddenException(`Linked entry ${b.entryId} belongs to a different household.`);
              }
            }

            const amountPaise = Math.round(Number(b.amountPaise ?? 0));
            const isPaid = b.isPaid ?? false;
            const entryId = b.entryId ?? null;

            if (
              !existingBill ||
              existingBill.name !== b.name ||
              BigInt(existingBill.amountPaise ?? 0) !== BigInt(amountPaise) ||
              !sameInstant(existingBill.dueDate, b.dueDate) ||
              (existingBill.isPaid ?? false) !== isPaid ||
              (existingBill.entry_id ?? null) !== entryId
            ) {
              billsToUpsert.push(b);
            }
          }
        }
      }

      // 5. Receivables
      if (dto.receivables && dto.receivables.length > 0) {
        const candidates = dto.receivables.filter((r) => !tombstones.has(tombKey('receivable', r.id)));
        if (candidates.length > 0) {
          const recIds = candidates.map((r) => r.id);
          const linkedEntryIds = candidates.map((r) => r.entryId).filter(Boolean) as string[];

          const [existingRecs, linkedEntries] = await Promise.all([
            findManyBatch(this.prisma.receivable, recIds),
            findManyBatch(this.prisma.entry, linkedEntryIds),
          ]);

          const recsMap = new Map(existingRecs.map((r: any) => [r.id, r]));
          const entriesMap = new Map(linkedEntries.map((e: any) => [e.id, e]));

          for (const r of candidates) {
            const existingRec = recsMap.get(r.id);
            if (existingRec && existingRec.householdId !== householdId) {
              throw new ForbiddenException(`Receivable ${r.id} belongs to a different household.`);
            }

            if (r.entryId) {
              const linkedEntry = entriesMap.get(r.entryId);
              if (linkedEntry && linkedEntry.householdId !== householdId) {
                throw new ForbiddenException(`Linked entry ${r.entryId} belongs to a different household.`);
              }
            }

            const amountPaise = Math.round(Number(r.amountPaise ?? 0));
            const status = r.status ?? 'open';
            const entryId = r.entryId ?? null;

            if (
              !existingRec ||
              existingRec.personName !== r.personName ||
              BigInt(existingRec.amountPaise ?? 0) !== BigInt(amountPaise) ||
              (existingRec.status ?? 'open') !== status ||
              !sameInstant(existingRec.dueDate, r.dueDate) ||
              (existingRec.entry_id ?? null) !== entryId
            ) {
              receivablesToUpsert.push(r);
            }
          }
        }
      }

      // 6. Saving Goals
      if (dto.savingGoals && dto.savingGoals.length > 0) {
        const existingGoals = await findManyBatch(this.prisma.savingGoal, dto.savingGoals.map((g) => g.id));
        const goalsMap = new Map(existingGoals.map((g: any) => [g.id, g]));
        for (const g of dto.savingGoals) {
          const existingGoal = goalsMap.get(g.id);
          if (existingGoal && existingGoal.householdId !== householdId) {
            throw new ForbiddenException(`Saving goal ${g.id} belongs to a different household.`);
          }
          const targetPaise = g.targetPaise != null ? Math.round(Number(g.targetPaise)) : null;
          const monthlyBudgetPaise = Math.round(Number(g.monthlyBudgetPaise ?? 0));
          const incomingArchivedAt = g.archivedAt ? new Date(g.archivedAt) : null;

          if (
            !existingGoal ||
            existingGoal.bucket !== g.bucket ||
            existingGoal.name !== g.name ||
            (existingGoal.targetPaise != null ? BigInt(existingGoal.targetPaise) : null) !==
              (targetPaise != null ? BigInt(targetPaise) : null) ||
            BigInt(existingGoal.monthlyBudgetPaise ?? 0) !== BigInt(monthlyBudgetPaise) ||
            !sameInstant(existingGoal.archivedAt, incomingArchivedAt)
          ) {
            goalsToUpsert.push(g);
          }
        }
      }

      // 7. Sinking Funds
      if (dto.sinkingFunds && dto.sinkingFunds.length > 0) {
        const existingFunds = await findManyBatch(this.prisma.sinkingFund, dto.sinkingFunds.map((f) => f.id));
        const fundsMap = new Map(existingFunds.map((f: any) => [f.id, f]));
        for (const f of dto.sinkingFunds) {
          const existingFund = fundsMap.get(f.id);
          if (existingFund && existingFund.householdId !== householdId) {
            throw new ForbiddenException(`Sinking fund ${f.id} belongs to a different household.`);
          }
          const openingReservePaise = Math.round(Number(f.openingReservePaise ?? 0));
          const incomingArchivedAt = f.archivedAt ? new Date(f.archivedAt) : null;

          if (
            !existingFund ||
            existingFund.name !== f.name ||
            BigInt(existingFund.openingReservePaise ?? 0) !== BigInt(openingReservePaise) ||
            !sameInstant(existingFund.archivedAt, incomingArchivedAt)
          ) {
            fundsToUpsert.push(f);
          }
        }
      }

      // 8. Goal Contributions
      const batchGoalIds = new Set((dto.savingGoals ?? []).map((g) => g.id));
      if (dto.goalContributions && dto.goalContributions.length > 0) {
        const candidates = dto.goalContributions.filter((gc) => !tombstones.has(tombKey('goal_contribution', gc.id)));
        if (candidates.length > 0) {
          const goalIds = [...new Set(candidates.map((gc) => gc.goalId))];
          const contribIds = candidates.map((gc) => gc.id);

          const [parentGoals, existingContribs] = await Promise.all([
            findManyBatch(this.prisma.savingGoal, goalIds),
            findManyBatch(this.prisma.goalContribution, contribIds),
          ]);

          const goalsMap = new Map(parentGoals.map((g: any) => [g.id, g]));
          const contribsMap = new Map(existingContribs.map((c: any) => [c.id, c]));

          for (const gc of candidates) {
            const parentGoal = goalsMap.get(gc.goalId);
            if (parentGoal ? parentGoal.householdId !== householdId : !batchGoalIds.has(gc.goalId)) {
              throw new ForbiddenException(`Goal ${gc.goalId} does not belong to this household.`);
            }

            const existingContrib = contribsMap.get(gc.id);
            const amountPaise = Math.round(Number(gc.amountPaise || 0));
            const note = gc.note ?? null;

            if (
              !existingContrib ||
              existingContrib.goalId !== gc.goalId ||
              BigInt(existingContrib.amountPaise ?? 0) !== BigInt(amountPaise) ||
              !sameInstant(existingContrib.contributionDate, gc.contributionDate) ||
              (existingContrib.note ?? null) !== note
            ) {
              goalContributionsToUpsert.push(gc);
            }
          }
        }
      }

      // 9. Fund Movements
      const batchFundIds = new Set((dto.sinkingFunds ?? []).map((f) => f.id));
      if (dto.fundMovements && dto.fundMovements.length > 0) {
        const candidates = dto.fundMovements.filter((fm) => !tombstones.has(tombKey('fund_movement', fm.id)));
        if (candidates.length > 0) {
          const fundIds = [...new Set(candidates.map((fm) => fm.fundId))];
          const movementIds = candidates.map((fm) => fm.id);

          const [parentFunds, existingMovements] = await Promise.all([
            findManyBatch(this.prisma.sinkingFund, fundIds),
            findManyBatch(this.prisma.fundMovement, movementIds),
          ]);

          const fundsMap = new Map(parentFunds.map((f: any) => [f.id, f]));
          const movementsMap = new Map(existingMovements.map((m: any) => [m.id, m]));

          for (const fm of candidates) {
            const parentFund = fundsMap.get(fm.fundId);
            if (parentFund ? parentFund.householdId !== householdId : !batchFundIds.has(fm.fundId)) {
              throw new ForbiddenException(`Sinking fund ${fm.fundId} does not belong to this household.`);
            }

            const existingMovement = movementsMap.get(fm.id);
            const amountPaise = Math.round(Number(fm.amountPaise || 0));
            const type = fm.type || 'contribution';
            const note = fm.note ?? null;

            if (
              !existingMovement ||
              existingMovement.fundId !== fm.fundId ||
              (existingMovement.type || 'contribution') !== type ||
              BigInt(existingMovement.amountPaise ?? 0) !== BigInt(amountPaise) ||
              !sameInstant(existingMovement.movementDate, fm.movementDate) ||
              (existingMovement.note ?? null) !== note
            ) {
              fundMovementsToUpsert.push(fm);
            }
          }
        }
      }

      // 10. Budgets
      if (dto.budgets && dto.budgets.length > 0) {
        const candidates = dto.budgets.filter((b) => !tombstones.has(tombKey('budget', b.id)));
        if (candidates.length > 0) {
          const budgetIds = candidates.map((b) => b.id);
          const categoryIds = [...new Set(candidates.map((b) => b.categoryId))];

          const [existingBudgets, categories] = await Promise.all([
            findManyBatch(this.prisma.budget, budgetIds),
            findManyBatch(this.prisma.category, categoryIds),
          ]);

          const budgetsById = new Map(existingBudgets.map((b: any) => [b.id, b]));
          const catsMap = new Map(categories.map((c: any) => [c.id, c]));

          const candidatesWithoutExisting = candidates.filter((b) => !budgetsById.has(b.id));
          let sameCellBudgets: any[] = [];
          if (candidatesWithoutExisting.length > 0 && typeof this.prisma.budget?.findMany === 'function') {
            sameCellBudgets = await this.prisma.budget.findMany({
              where: {
                householdId,
                OR: candidatesWithoutExisting.map((b) => ({ categoryId: b.categoryId, yearMonth: b.yearMonth })),
              },
            });
          }
          const sameCellMap = new Map(sameCellBudgets.map((b: any) => [`${b.categoryId}:${b.yearMonth}`, b]));

          for (const b of candidates) {
            const existingBudget = budgetsById.get(b.id);
            if (existingBudget && existingBudget.householdId !== householdId) {
              throw new ForbiddenException(`Budget ${b.id} belongs to a different household.`);
            }

            const cat = catsMap.get(b.categoryId);
            if (cat && cat.householdId !== householdId) {
              throw new ForbiddenException(`Category ${b.categoryId} belongs to a different household.`);
            }

            const amountPaise = Math.round(Number(b.amountPaise || 0));

            if (!existingBudget) {
              const sameCell = sameCellMap.get(`${b.categoryId}:${b.yearMonth}`);
              if (sameCell) {
                if (BigInt(sameCell.amountPaise ?? 0) !== BigInt(amountPaise)) {
                  budgetsToUpsert.push({ mode: 'update', id: sameCell.id, amountPaise });
                }
                continue;
              }
            }

            if (
              !existingBudget ||
              existingBudget.categoryId !== b.categoryId ||
              existingBudget.yearMonth !== b.yearMonth ||
              BigInt(existingBudget.amountPaise ?? 0) !== BigInt(amountPaise)
            ) {
              budgetsToUpsert.push({
                mode: 'upsert',
                id: b.id,
                categoryId: b.categoryId,
                yearMonth: b.yearMonth,
                amountPaise,
              });
            }
          }
        }
      }

      // 11. Reserve Lines
      if (dto.reserveLines && dto.reserveLines.length > 0) {
        const candidates = dto.reserveLines.filter((rl) => !tombstones.has(tombKey('reserve_line', rl.id)));
        if (candidates.length > 0) {
          const existingLines = await findManyBatch(this.prisma.reserveLine, candidates.map((rl) => rl.id));
          const rlMap = new Map(existingLines.map((r: any) => [r.id, r]));
          for (const rl of candidates) {
            const existing = rlMap.get(rl.id);
            if (existing && existing.householdId !== householdId) {
              throw new ForbiddenException(`Reserve line ${rl.id} belongs to a different household.`);
            }
            const amountPaise = Math.round(Number(rl.amountPaise || 0));
            const source = rl.source ?? 'manual';
            if (
              !existing ||
              existing.yearMonth !== rl.yearMonth ||
              existing.name !== rl.name ||
              BigInt(existing.amountPaise ?? 0) !== BigInt(amountPaise) ||
              (existing.source ?? 'manual') !== source
            ) {
              reserveLinesToUpsert.push(rl);
            }
          }
        }
      }

      // 12. Annual Targets
      if (dto.annualTargets && dto.annualTargets.length > 0) {
        const candidates = dto.annualTargets.filter((at) => !tombstones.has(tombKey('annual_target', at.id)));
        if (candidates.length > 0) {
          const existingTargets = await findManyBatch(this.prisma.annual_targets, candidates.map((at) => at.id));
          const targetsMap = new Map(existingTargets.map((t: any) => [t.id, t]));
          for (const at of candidates) {
            const existing = targetsMap.get(at.id);
            if (existing && existing.household_id !== householdId) {
              throw new ForbiddenException(`Annual target ${at.id} belongs to a different household.`);
            }
            const targetPaise = Math.round(Number(at.targetPaise || 0));
            const type = at.type || 'income';
            if (
              !existing ||
              existing.title !== at.title ||
              BigInt(existing.target_paise ?? 0) !== BigInt(targetPaise) ||
              (existing.type || 'income') !== type
            ) {
              annualTargetsToUpsert.push(at);
            }
          }
        }
      }

      // 13. Entries Validation
      if (dto.entries && dto.entries.length > 0) {
        if (typeof (this.entriesService as any).validateBatch === 'function') {
          const batchContext: BatchContext = {
            createdAccountIds: validCreatedAccountIds,
            createdCardIds: new Set([...(dto.creditCards ?? []).map((c) => c.id), ...missingParentCards]),
            createdEntryIds: new Set((dto.entries ?? []).map((e) => e.id)),
          };
          entryValidation = await (this.entriesService as any).validateBatch(
            householdId,
            dto.entries,
            userId,
            batchContext,
          );
          entriesResult = {
            synced: entryValidation.syncedCount,
            failed: entryValidation.failedCount,
            rejected: entryValidation.rejected ?? [],
          };
        }
      }

      // 14. Recurring Rules
      if (dto.recurringRules && dto.recurringRules.length > 0) {
        const candidates = dto.recurringRules.filter(
          (r) => !tombstones.has(tombKey('recurring_rule', r.id)),
        );
        if (candidates.length > 0) {
          const existingRules = await findManyBatch(
            (this.prisma as any).recurringRule,
            candidates.map((r) => r.id),
          );
          const existingMap = new Map(existingRules.map((r: any) => [r.id, r]));
          for (const r of candidates) {
            const existing = existingMap.get(r.id);
            if (existing && existing.householdId !== householdId) {
              throw new ForbiddenException(`Recurring rule ${r.id} belongs to a different household.`);
            }
            // Always upsert (merged state may differ even if other fields are equal)
            recurringRulesToUpsert.push(r);
          }
        }
      }

      const phase1DurationMs = Date.now() - phase1StartTime;
      console.log(
        `[SyncService.syncBatch] PHASE 1 completed in ${phase1DurationMs}ms for household ${householdId}. ` +
        `Row counts to upsert: categories=${categoriesToUpsert.length}, accounts=${accountsToUpsert.length}, ` +
        `creditCards=${cardsToUpsert.length}, cardTransactions=${cardTxnsToUpsert.length}, ` +
        `plannedBills=${billsToUpsert.length}, receivables=${receivablesToUpsert.length}, ` +
        `savingGoals=${goalsToUpsert.length}, sinkingFunds=${fundsToUpsert.length}, ` +
        `goalContributions=${goalContributionsToUpsert.length}, fundMovements=${fundMovementsToUpsert.length}, ` +
        `budgets=${budgetsToUpsert.length}, reserveLines=${reserveLinesToUpsert.length}, ` +
        `annualTargets=${annualTargetsToUpsert.length}, recurringRules=${recurringRulesToUpsert.length}, ` +
        `entriesSynced=${entriesResult.synced}, entriesFailed=${entriesResult.failed}`
      );
    } catch (error: any) {
      console.error(
        `[SyncService.syncBatch] Error in PHASE 1 for household ${householdId}: ` +
        `code=${error?.code}, meta=${JSON.stringify(error?.meta)}, message=${error?.message}`
      );
      throw error;
    }

    // ─── PHASE 2: ATOMIC TRANSACTIONAL WRITE ─────────────────────────────────
    // Timeout of 45s accommodates large initial/catch-up syncs (500+ items) over mobile connections
    // while preventing runaway locks.
    try {
      const phase2StartTime = Date.now();
      const runner = this.prisma?.$transaction
        ? (fn: any) => this.prisma.$transaction(fn, { timeout: 45000, maxWait: 10000 })
        : (fn: any) => fn(this.prisma);

      await runner(async (tx: any) => {
        // 1. Apply Deletions
        await this.applyValidatedDeletions(householdId, deletionsToApply, tombstones, tx);

        // 2. Categories
        for (const cat of categoriesToUpsert) {
          const incomingArchivedAt = cat.archivedAt ? new Date(cat.archivedAt) : null;
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
              archivedAt: incomingArchivedAt,
            },
            update: {
              kind: cat.kind,
              groupCode: cat.groupCode ?? null,
              name: cat.name,
              needOrWant: cat.needOrWant ?? null,
              isDeduction: cat.isDeduction ?? false,
              isSystem: cat.isSystem ?? false,
              sortOrder: cat.sortOrder ?? 0,
              archivedAt: incomingArchivedAt,
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

        // 16. Recurring Rules — upsert with LWW on non-processed fields + union-merge on processed state
        for (const r of recurringRulesToUpsert) {
          // Batch-load existing row (already fetched in Phase 1 existingMap — re-use within tx)
          const existing = await tx.recurringRule.findUnique({ where: { id: r.id } });
          const incomingDates: string[] = r.processedDates ?? [];
          const incomingThrough = r.processedThrough ? new Date(r.processedThrough) : null;
          const existingDates: string[] = existing ? JSON.parse(existing.processedDates || '[]') : [];
          const existingThrough = existing?.processedThrough ?? null;

          // Processed state: ALWAYS union-merge regardless of updatedAt
          const ruleShape = { dayOfMonth: r.dayOfMonth, startDate: r.startDate };
          const merged = mergeProcessedState(
            ruleShape,
            { processedThrough: existingThrough, processedDates: existingDates },
            { processedThrough: incomingThrough, processedDates: incomingDates },
          );

          // LWW: apply incoming non-processed fields only if incoming.updatedAt > existing.updatedAt
          const incomingUpdatedAt = r.updatedAt ? new Date(r.updatedAt) : new Date();
          const existingUpdatedAt = existing?.updatedAt ? new Date(existing.updatedAt) : null;
          const shouldApplyLww = !existingUpdatedAt || incomingUpdatedAt > existingUpdatedAt;

          // Sticky deletedAt: once set, incoming null never clears it
          let mergedDeletedAt: Date | null = null;
          if (existing?.deletedAt) {
            mergedDeletedAt = existing.deletedAt; // sticky
          } else if (r.deletedAt) {
            mergedDeletedAt = new Date(r.deletedAt);
          }

          // Build the upsert data
          const createData = {
            id: r.id,
            householdId,
            kind: r.kind,
            categoryId: r.categoryId,
            accountId: r.accountId ?? null,
            cardId: r.cardId ?? null,
            amountPaise: r.amountPaise,
            note: r.note ?? null,
            dayOfMonth: r.dayOfMonth,
            startDate: new Date(r.startDate),
            endDate: r.endDate ? new Date(r.endDate) : null,
            mode: r.mode,
            isActive: r.isActive ?? true,
            processedThrough: merged.processedThrough,
            processedDates: JSON.stringify(merged.processedDates),
            updatedAt: incomingUpdatedAt,
            deletedAt: mergedDeletedAt,
          };

          const updateData = shouldApplyLww
            ? {
                kind: r.kind,
                categoryId: r.categoryId,
                accountId: r.accountId ?? null,
                cardId: r.cardId ?? null,
                amountPaise: r.amountPaise,
                note: r.note ?? null,
                dayOfMonth: r.dayOfMonth,
                startDate: new Date(r.startDate),
                endDate: r.endDate ? new Date(r.endDate) : null,
                mode: r.mode,
                isActive: r.isActive ?? true,
                processedThrough: merged.processedThrough,
                processedDates: JSON.stringify(merged.processedDates),
                updatedAt: incomingUpdatedAt,
                deletedAt: mergedDeletedAt,
              }
            : {
                // Incoming is older: only update processed state
                processedThrough: merged.processedThrough,
                processedDates: JSON.stringify(merged.processedDates),
                deletedAt: mergedDeletedAt,
              };

          await tx.recurringRule.upsert({
            where: { id: r.id },
            create: createData,
            update: updateData,
          });
        }
      });

      const phase2DurationMs = Date.now() - phase2StartTime;
      console.log(`[SyncService.syncBatch] PHASE 2 completed in ${phase2DurationMs}ms for household ${householdId}.`);
    } catch (error: any) {
      console.error(
        `[SyncService.syncBatch] Error in PHASE 2 for household ${householdId}: ` +
        `code=${error?.code}, meta=${JSON.stringify(error?.meta)}, message=${error?.message}`
      );
      throw error;
    }

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
      recurringRules: recurringRulesToUpsert.length,
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
      recurringRules,
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
      (this.prisma as any).recurringRule?.findMany
        ? (this.prisma as any).recurringRule.findMany({
            where: { householdId },
            orderBy: { createdAt: 'asc' },
          })
        : Promise.resolve([]),
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
      recurringRules: recurringRules.map((r: any) => ({
        id: r.id,
        householdId: r.householdId,
        kind: r.kind,
        categoryId: r.categoryId,
        accountId: r.accountId,
        cardId: r.cardId,
        amountPaise: Number(r.amountPaise),
        note: r.note,
        dayOfMonth: r.dayOfMonth,
        startDate: r.startDate.toISOString(),
        endDate: r.endDate ? r.endDate.toISOString() : null,
        mode: r.mode,
        isActive: r.isActive,
        processedThrough: r.processedThrough ? r.processedThrough.toISOString() : null,
        processedDates: JSON.parse(r.processedDates || '[]'),
        updatedAt: r.updatedAt.toISOString(),
        createdAt: r.createdAt.toISOString(),
        deletedAt: r.deletedAt ? r.deletedAt.toISOString() : null,
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
      case 'recurring_rule': return (await (this.prisma as any).recurringRule.findUnique({ where: { id } }))?.householdId ?? null;
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
          case 'recurring_rule':
            // Recurring rules are soft-deleted (deletedAt) so past entries are preserved.
            await tx.recurringRule.updateMany({ where: { id, householdId }, data: { deletedAt: new Date() } });
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
