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

    // Authorisation first: a batch that references another household's records is rejected
    // before anything is written, so a rejected batch never leaves partial writes behind.
    await this.assertBatchOwnership(householdId, dto);

    // Deletions (tombstones) are applied before upserts; tombstoned ids are never re-created
    // by a device that still holds a stale copy.
    const tombstones = await this.loadTombstones(householdId);
    const deletionsApplied = await this.applyDeletions(householdId, dto, tombstones);

    // 0. Categories (Sync first so entries satisfy foreign key constraints)
    if (dto.categories && dto.categories.length > 0) {
      const validCats = dto.categories.filter(
        (c) => !tombstones.has(tombKey('category', c.id)) && !isClientSystemCategoryId(c.id, householdId),
      );

      if (validCats.length > 0) {
        const existingCats = await this.prisma.category.findMany({
          where: { id: { in: validCats.map((c) => c.id) } },
          select: { id: true, householdId: true },
        });
        const existingMap = new Map(existingCats.map((c) => [c.id, c.householdId]));

        for (const c of existingCats) {
          if (c.householdId !== householdId) {
            throw new ForbiddenException(`Category ${c.id} belongs to a different household.`);
          }
        }

        const toCreate = validCats.filter((c) => !existingMap.has(c.id));
        if (toCreate.length > 0) {
          await this.prisma.category.createMany({
            data: toCreate.map((cat) => ({
              id: cat.id,
              householdId,
              kind: cat.kind,
              groupCode: cat.groupCode ?? null,
              name: cat.name,
              needOrWant: cat.needOrWant ?? null,
              isDeduction: cat.isDeduction ?? false,
              isSystem: cat.isSystem ?? false,
              sortOrder: cat.sortOrder ?? 0,
            })),
            skipDuplicates: true,
          });
        }
        categoriesSynced = validCats.length;
      }
    }

    // 1. Accounts
    if (dto.accounts && dto.accounts.length > 0) {
      for (const a of dto.accounts) {
        try {
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
          // Guard: verify existing card belongs to the authenticated household
          const existingCard = await this.prisma.creditCard.findUnique({ where: { id: c.id } });
          if (existingCard && existingCard.householdId !== householdId) {
            throw new ForbiddenException(`Credit card ${c.id} belongs to a different household.`);
          }

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
        if (tombstones.has(tombKey('card_transaction', t.id))) continue;
        try {
          // Guard: verify parent card belongs to authenticated household
          const parentCard = await this.prisma.creditCard.findUnique({ where: { id: t.cardId } });
          if (parentCard && parentCard.householdId !== householdId) {
            throw new ForbiddenException(`Card ${t.cardId} belongs to a different household.`);
          }

          // Guard: verify if transaction exists, it belongs to this household
          const existingTxn = await this.prisma.cardTransaction.findUnique({
            where: { id: t.id },
            include: { card: true },
          });
          if (existingTxn && existingTxn.card.householdId !== householdId) {
            throw new ForbiddenException(`Card transaction ${t.id} belongs to a different household.`);
          }

          if (!parentCard) {
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
          if (e instanceof ForbiddenException) throw e;
        }
      }
    }

    // 4. Planned Bills (Payables)
    if (dto.plannedBills && dto.plannedBills.length > 0) {
      for (const b of dto.plannedBills) {
        if (tombstones.has(tombKey('planned_bill', b.id))) continue;
        try {
          // Guard: verify existing bill belongs to the authenticated household
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
          if (e instanceof ForbiddenException) throw e;
        }
      }
    }

    // 5. Receivables
    if (dto.receivables && dto.receivables.length > 0) {
      for (const r of dto.receivables) {
        if (tombstones.has(tombKey('receivable', r.id))) continue;
        try {
          // Guard: verify existing receivable belongs to the authenticated household
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
          if (e instanceof ForbiddenException) throw e;
        }
      }
    }

    // 6. Saving Goals
    if (dto.savingGoals && dto.savingGoals.length > 0) {
      for (const g of dto.savingGoals) {
        try {
          // Guard: verify existing goal belongs to the authenticated household
          const existingGoal = await this.prisma.savingGoal.findUnique({ where: { id: g.id } });
          if (existingGoal && existingGoal.householdId !== householdId) {
            throw new ForbiddenException(`Saving goal ${g.id} belongs to a different household.`);
          }

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
          // Guard: verify existing fund belongs to the authenticated household
          const existingFund = await this.prisma.sinkingFund.findUnique({ where: { id: f.id } });
          if (existingFund && existingFund.householdId !== householdId) {
            throw new ForbiddenException(`Sinking fund ${f.id} belongs to a different household.`);
          }

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
        if (tombstones.has(tombKey('goal_contribution', gc.id))) continue;
        try {
          // Guard: verify parent goal belongs to the authenticated household
          const parentGoal = await this.prisma.savingGoal.findUnique({ where: { id: gc.goalId } });
          if (!parentGoal || parentGoal.householdId !== householdId) {
            throw new ForbiddenException(`Goal ${gc.goalId} does not belong to this household.`);
          }

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
          if (e instanceof ForbiddenException) throw e;
        }
      }
    }

    // 9. Fund Movements
    if (dto.fundMovements && dto.fundMovements.length > 0) {
      for (const fm of dto.fundMovements) {
        if (tombstones.has(tombKey('fund_movement', fm.id))) continue;
        try {
          // Guard: verify parent fund belongs to the authenticated household
          const parentFund = await this.prisma.sinkingFund.findUnique({ where: { id: fm.fundId } });
          if (!parentFund || parentFund.householdId !== householdId) {
            throw new ForbiddenException(`Sinking fund ${fm.fundId} does not belong to this household.`);
          }

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
          if (e instanceof ForbiddenException) throw e;
        }
      }
    }

    // 10. Budgets
    let budgetsSynced = 0;
    if (dto.budgets && dto.budgets.length > 0) {
      for (const b of dto.budgets) {
        if (tombstones.has(tombKey('budget', b.id))) continue;
        try {
          // Guard 1: verify existing budget belongs to authenticated household
          const existingBudget = await this.prisma.budget.findUnique({ where: { id: b.id } });
          if (existingBudget && existingBudget.householdId !== householdId) {
            throw new ForbiddenException(`Budget ${b.id} belongs to a different household.`);
          }

          // Guard 2: verify referenced category belongs to authenticated household
          const cat = await this.prisma.category.findUnique({ where: { id: b.categoryId } });
          if (cat && cat.householdId !== householdId) {
            throw new ForbiddenException(`Category ${b.categoryId} belongs to a different household.`);
          }

          if (!existingBudget) {
            // Another device may already have created the budget for this category/month under a
            // different id (unique category_id + year_month). Apply the change to that row instead
            // of failing silently.
            const sameCell = await this.prisma.budget.findFirst({
              where: { householdId, categoryId: b.categoryId, yearMonth: b.yearMonth },
            });
            if (sameCell) {
              await this.prisma.budget.update({
                where: { id: sameCell.id },
                data: { amountPaise: Math.round(Number(b.amountPaise || 0)) },
              });
              budgetsSynced++;
              continue;
            }
          }

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
          if (e instanceof ForbiddenException) throw e;
        }
      }
    }

    // 11. Reserve Lines
    let reserveLinesSynced = 0;
    if (dto.reserveLines && dto.reserveLines.length > 0) {
      for (const rl of dto.reserveLines) {
        if (tombstones.has(tombKey('reserve_line', rl.id))) continue;
        try {
          const existing = await this.prisma.reserveLine.findUnique({ where: { id: rl.id } });
          if (existing && existing.householdId !== householdId) {
            throw new ForbiddenException(`Reserve line ${rl.id} belongs to a different household.`);
          }

          await this.prisma.reserveLine.upsert({
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
          reserveLinesSynced++;
        } catch (e) {
          console.error(`Failed to sync reserve line ${rl.id}:`, e);
          if (e instanceof ForbiddenException) throw e;
        }
      }
    }

    // 12. Annual Targets
    let annualTargetsSynced = 0;
    if (dto.annualTargets && dto.annualTargets.length > 0) {
      for (const at of dto.annualTargets) {
        if (tombstones.has(tombKey('annual_target', at.id))) continue;
        try {
          const existing = await this.prisma.annual_targets.findUnique({ where: { id: at.id } });
          if (existing && existing.household_id !== householdId) {
            throw new ForbiddenException(`Annual target ${at.id} belongs to a different household.`);
          }

          await this.prisma.annual_targets.upsert({
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
          annualTargetsSynced++;
        } catch (e) {
          console.error(`Failed to sync annual target ${at.id}:`, e);
          if (e instanceof ForbiddenException) throw e;
        }
      }
    }

    // 14. Entries
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
      reserveLines: reserveLinesSynced,
      annualTargets: annualTargetsSynced,
      entries: entriesResult,
      deletions: deletionsApplied,
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
      reserveLines,
      annualTargets,
      categories,
      entries,
      deletedEntries,
      tombstones,
      monthSnapshots,
    ] = await Promise.all([
      // NOTE: intentionally NOT filtering by isActive/archivedAt here. A device that already
      // has a local copy of an account/card/goal/fund/category needs to learn when another
      // device deactivates or archives it; excluding those rows meant the deactivation never
      // reached other devices and the stale local copy stayed "active" forever (data-persistence
      // audit finding, 2026-09-17). The client already applies isActive/archivedAt correctly on
      // upsert — it only needed the row to actually be included in the response.
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

  private async applyDeletions(householdId: string, dto: SyncBatchDto, tombstones: Set<string>): Promise<number> {
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

    let applied = 0;
    for (const del of requested) {
      const key = tombKey(del.entity, del.id);
      if (owners.get(key) === householdId) {
        const entity = del.entity as SyncDeletableEntity;
        const id = del.id;
        switch (entity) {
          case 'planned_bill': await this.prisma.plannedBill.deleteMany({ where: { id, householdId } }); break;
          case 'receivable': await this.prisma.receivable.deleteMany({ where: { id, householdId } }); break;
          case 'budget': await this.prisma.budget.deleteMany({ where: { id, householdId } }); break;
          case 'reserve_line': await this.prisma.reserveLine.deleteMany({ where: { id, householdId } }); break;
          case 'annual_target': await this.prisma.annual_targets.deleteMany({ where: { id, household_id: householdId } }); break;
          case 'card_transaction': await this.prisma.cardTransaction.deleteMany({ where: { id, card: { householdId } } }); break;
          case 'goal_contribution': await this.prisma.goalContribution.deleteMany({ where: { id, goal: { householdId } } }); break;
          case 'fund_movement': await this.prisma.fundMovement.deleteMany({ where: { id, fund: { householdId } } }); break;
          case 'category':
            // Categories are referenced by historical entries (FK RESTRICT): archive, never hard-delete.
            await this.prisma.category.updateMany({ where: { id, householdId, isSystem: false }, data: { archivedAt: new Date() } });
            break;
        }
      }
      // Only records that existed in this household get a tombstone; unknown ids (never synced) need none,
      // and must not reserve the global (entity, entityId) key for another tenant's future record.
      if (owners.get(key) === householdId && !tombstones.has(key)) {
        await this.prisma.syncTombstone.upsert({
          where: { entity_entityId: { entity: del.entity, entityId: del.id } },
          create: { householdId, entity: del.entity, entityId: del.id },
          update: {},
        });
        tombstones.add(key);
      }
      applied++;
    }
    return applied;
  }
}
