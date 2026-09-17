import { ForbiddenException } from '@nestjs/common';
import { SyncService } from '../src/sync/sync.service';

describe('Phase 2 — Sync Service Multi-Tenant Isolation & Completeness', () => {
  let syncService: SyncService;
  let mockPrisma: any;
  let mockEntriesService: any;

  beforeEach(() => {
    mockEntriesService = {
      upsertBatch: jest.fn().mockResolvedValue({ synced: 1, failed: 0 }),
    };

    mockPrisma = {
      category: {
        findUnique: jest.fn(),
        upsert: jest.fn(),
      },
      account: {
        findUnique: jest.fn(),
        findFirst: jest.fn(),
        upsert: jest.fn(),
      },
      creditCard: {
        findUnique: jest.fn(),
        upsert: jest.fn(),
        create: jest.fn(),
      },
      cardTransaction: {
        findUnique: jest.fn(),
        upsert: jest.fn(),
      },
      plannedBill: {
        findUnique: jest.fn(),
        upsert: jest.fn(),
      },
      receivable: {
        findUnique: jest.fn(),
        upsert: jest.fn(),
      },
      savingGoal: {
        findUnique: jest.fn(),
        upsert: jest.fn(),
      },
      goalContribution: {
        findUnique: jest.fn(),
        upsert: jest.fn(),
      },
      sinkingFund: {
        findUnique: jest.fn(),
        upsert: jest.fn(),
      },
      fundMovement: {
        findUnique: jest.fn(),
        upsert: jest.fn(),
      },
      budget: {
        findUnique: jest.fn(),
        upsert: jest.fn(),
      },
      reserveLine: {
        findUnique: jest.fn(),
        upsert: jest.fn(),
        findMany: jest.fn().mockResolvedValue([]),
      },
      annual_targets: {
        findUnique: jest.fn(),
        upsert: jest.fn(),
        findMany: jest.fn().mockResolvedValue([]),
      },
      entry: {
        findUnique: jest.fn(),
        findMany: jest.fn().mockResolvedValue([]),
      },
      // New models/methods used by tombstone sync (DEF-SYNC-01) and month status pull (DEF-SYNC-07)
      syncTombstone: {
        findMany: jest.fn().mockResolvedValue([]),
        upsert: jest.fn(),
      },
      monthSnapshot: {
        findMany: jest.fn().mockResolvedValue([]),
      },
    };

    syncService = new SyncService(mockEntriesService, mockPrisma);
  });

  describe('Parent-Child Household Isolation Guards', () => {
    it('1. Rejects budget when referenced category belongs to another household', async () => {
      mockPrisma.budget.findUnique.mockResolvedValue(null);
      // Category belongs to household-OTHER
      mockPrisma.category.findUnique.mockResolvedValue({
        id: 'cat-foreign',
        householdId: 'household-OTHER',
      });

      await expect(
        syncService.syncBatch(
          'household-ME',
          {
            budgets: [
              {
                id: 'b-1',
                categoryId: 'cat-foreign',
                yearMonth: '2026-09',
                amountPaise: 50000,
              },
            ],
          },
          'user-1',
        ),
      ).rejects.toThrow(ForbiddenException);
    });

    it('2. Rejects card transaction when parent card belongs to another household', async () => {
      mockPrisma.creditCard.findUnique.mockResolvedValue({
        id: 'card-foreign',
        householdId: 'household-OTHER',
      });

      await expect(
        syncService.syncBatch(
          'household-ME',
          {
            cardTransactions: [
              {
                id: 'txn-1',
                cardId: 'card-foreign',
                txnDate: '2026-09-15T10:00:00.000Z',
                description: 'Test purchase',
                amountPaise: 25000,
              },
            ],
          },
          'user-1',
        ),
      ).rejects.toThrow(ForbiddenException);
    });

    it('3. Rejects goal contribution when parent goal belongs to another household', async () => {
      mockPrisma.savingGoal.findUnique.mockResolvedValue({
        id: 'goal-foreign',
        householdId: 'household-OTHER',
      });

      await expect(
        syncService.syncBatch(
          'household-ME',
          {
            goalContributions: [
              {
                id: 'gc-1',
                goalId: 'goal-foreign',
                amountPaise: 10000,
                contributionDate: '2026-09-15T10:00:00.000Z',
              },
            ],
          },
          'user-1',
        ),
      ).rejects.toThrow(ForbiddenException);
    });

    it('4. Rejects fund movement when parent fund belongs to another household', async () => {
      mockPrisma.sinkingFund.findUnique.mockResolvedValue({
        id: 'fund-foreign',
        householdId: 'household-OTHER',
      });

      await expect(
        syncService.syncBatch(
          'household-ME',
          {
            fundMovements: [
              {
                id: 'fm-1',
                fundId: 'fund-foreign',
                type: 'contribution',
                amountPaise: 15000,
                movementDate: '2026-09-15T10:00:00.000Z',
              },
            ],
          },
          'user-1',
        ),
      ).rejects.toThrow(ForbiddenException);
    });

    it('5. Rejects planned bill when linked entry belongs to another household', async () => {
      mockPrisma.plannedBill.findUnique.mockResolvedValue(null);
      mockPrisma.entry.findUnique.mockResolvedValue({
        id: 'entry-foreign',
        householdId: 'household-OTHER',
      });

      await expect(
        syncService.syncBatch(
          'household-ME',
          {
            plannedBills: [
              {
                id: 'pb-1',
                name: 'Electricity bill',
                amountPaise: 30000,
                entryId: 'entry-foreign',
              },
            ],
          },
          'user-1',
        ),
      ).rejects.toThrow(ForbiddenException);
    });

    it('6. Rejects receivable when linked entry belongs to another household', async () => {
      mockPrisma.receivable.findUnique.mockResolvedValue(null);
      mockPrisma.entry.findUnique.mockResolvedValue({
        id: 'entry-foreign',
        householdId: 'household-OTHER',
      });

      await expect(
        syncService.syncBatch(
          'household-ME',
          {
            receivables: [
              {
                id: 'rec-1',
                personName: 'Alice',
                amountPaise: 50000,
                entryId: 'entry-foreign',
              },
            ],
          },
          'user-1',
        ),
      ).rejects.toThrow(ForbiddenException);
    });

    it('7. Rejects reserve line when existing line belongs to another household', async () => {
      mockPrisma.reserveLine.findUnique.mockResolvedValue({
        id: 'rl-foreign',
        householdId: 'household-OTHER',
      });

      await expect(
        syncService.syncBatch(
          'household-ME',
          {
            reserveLines: [
              {
                id: 'rl-foreign',
                yearMonth: '2026-09',
                name: 'Emergency Buffer',
                amountPaise: 20000,
              },
            ],
          },
          'user-1',
        ),
      ).rejects.toThrow(ForbiddenException);
    });

    it('8. Rejects annual target when existing target belongs to another household', async () => {
      mockPrisma.annual_targets.findUnique.mockResolvedValue({
        id: 'at-foreign',
        household_id: 'household-OTHER',
      });

      await expect(
        syncService.syncBatch(
          'household-ME',
          {
            annualTargets: [
              {
                id: 'at-foreign',
                title: 'Foreign Target',
                targetPaise: 50000,
                type: 'income',
              },
            ],
          },
          'user-1',
        ),
      ).rejects.toThrow(ForbiddenException);
    });
  });

  describe('Sync Completeness & Deletion Propagation (pullData)', () => {
    it('9. Returns reserveLines, annualTargets and tracks deletedEntryIds in pullData', async () => {
      mockPrisma.account.findMany = jest.fn().mockResolvedValue([]);
      mockPrisma.creditCard.findMany = jest.fn().mockResolvedValue([]);
      mockPrisma.cardTransaction.findMany = jest.fn().mockResolvedValue([]);
      mockPrisma.plannedBill.findMany = jest.fn().mockResolvedValue([]);
      mockPrisma.receivable.findMany = jest.fn().mockResolvedValue([]);
      mockPrisma.savingGoal.findMany = jest.fn().mockResolvedValue([]);
      mockPrisma.goalContribution.findMany = jest.fn().mockResolvedValue([]);
      mockPrisma.sinkingFund.findMany = jest.fn().mockResolvedValue([]);
      mockPrisma.fundMovement.findMany = jest.fn().mockResolvedValue([]);
      mockPrisma.budget.findMany = jest.fn().mockResolvedValue([]);
      mockPrisma.category.findMany = jest.fn().mockResolvedValue([]);

      // Annual targets present in DB
      mockPrisma.annual_targets.findMany = jest.fn().mockResolvedValue([
        {
          id: 'at-1',
          household_id: 'household-ME',
          title: 'Annual Savings Target',
          target_paise: 60000000,
          type: 'income',
        },
      ]);

      // Reserve lines present in DB
      mockPrisma.reserveLine.findMany = jest.fn().mockResolvedValue([
        {
          id: 'rl-1',
          householdId: 'household-ME',
          yearMonth: '2026-09',
          name: 'Emergency Fund',
          amountPaise: 500000,
          source: 'manual',
        },
      ]);

      // Active entries
      mockPrisma.entry.findMany = jest.fn().mockImplementation((args) => {
        if (args?.where?.deletedAt === null) {
          return Promise.resolve([
            {
              id: 'entry-active-1',
              householdId: 'household-ME',
              categoryId: 'cat-1',
              kind: 'spending',
              amountPaise: 10000,
              entryDate: new Date('2026-09-15T10:00:00Z'),
              createdAt: new Date('2026-09-15T10:00:00Z'),
              updatedAt: new Date('2026-09-15T10:00:00Z'),
              deletedAt: null,
            },
          ]);
        }
        if (args?.where?.deletedAt?.not !== undefined) {
          // Soft-deleted entries
          return Promise.resolve([
            {
              id: 'entry-deleted-1',
              deletedAt: new Date('2026-09-15T11:00:00Z'),
            },
          ]);
        }
        return Promise.resolve([]);
      });

      const pulled = await syncService.pullData('household-ME');

      expect(pulled.annualTargets).toHaveLength(1);
      expect(pulled.annualTargets[0].title).toBe('Annual Savings Target');
      expect(pulled.reserveLines).toHaveLength(1);
      expect(pulled.reserveLines[0].name).toBe('Emergency Fund');
      expect(pulled.entries).toHaveLength(1);
      expect(pulled.entries[0].id).toBe('entry-active-1');
      expect(pulled.deletedEntryIds).toContain('entry-deleted-1');
      expect(pulled.deletedEntries[0].id).toBe('entry-deleted-1');
    });

    it('10. Deactivated accounts/cards and archived goals/funds/categories are still returned by pullData (data-persistence audit fix, 2026-09-17)', async () => {
      // Regression test for the finding: pullData previously filtered these five queries by
      // isActive:true / archivedAt:null, so a device that already had a local copy never learned
      // the item was deactivated/archived on another device — the stale copy stayed "active"
      // forever on that other device. The fix removes those filters; this test locks in that the
      // where-clauses no longer exclude inactive/archived rows, and that the rows (with their
      // real isActive/archivedAt values) come back in the response.
      mockPrisma.account.findMany = jest.fn().mockResolvedValue([
        { id: 'acc-1', householdId: 'household-ME', name: 'Old Wallet', type: 'cash', currentBalancePaise: 0n, isActive: false, sortOrder: 0 },
      ]);
      mockPrisma.creditCard.findMany = jest.fn().mockResolvedValue([
        { id: 'card-1', householdId: 'household-ME', name: 'Closed Card', previousOutstandingPaise: 0n, isActive: false },
      ]);
      mockPrisma.cardTransaction.findMany = jest.fn().mockResolvedValue([]);
      mockPrisma.plannedBill.findMany = jest.fn().mockResolvedValue([]);
      mockPrisma.receivable.findMany = jest.fn().mockResolvedValue([]);
      mockPrisma.savingGoal.findMany = jest.fn().mockResolvedValue([
        { id: 'goal-1', householdId: 'household-ME', bucket: 'other_goals', name: 'Old Goal', targetPaise: null, monthlyBudgetPaise: 0n, archivedAt: new Date('2026-09-01T00:00:00Z') },
      ]);
      mockPrisma.goalContribution.findMany = jest.fn().mockResolvedValue([]);
      mockPrisma.sinkingFund.findMany = jest.fn().mockResolvedValue([
        { id: 'fund-1', householdId: 'household-ME', name: 'Old Fund', openingReservePaise: 0n, archivedAt: new Date('2026-09-01T00:00:00Z') },
      ]);
      mockPrisma.fundMovement.findMany = jest.fn().mockResolvedValue([]);
      mockPrisma.budget.findMany = jest.fn().mockResolvedValue([]);
      mockPrisma.reserveLine.findMany = jest.fn().mockResolvedValue([]);
      mockPrisma.annual_targets.findMany = jest.fn().mockResolvedValue([]);
      mockPrisma.category.findMany = jest.fn().mockResolvedValue([
        { id: 'cat-1', householdId: 'household-ME', kind: 'spending', groupCode: null, name: 'Old Category', needOrWant: null, isDeduction: false, isSystem: false, sortOrder: 0, archivedAt: new Date('2026-09-01T00:00:00Z') },
      ]);

      const pulled = await syncService.pullData('household-ME');

      // The rows are present (not filtered out) ...
      expect(pulled.accounts).toHaveLength(1);
      expect(pulled.accounts[0].isActive).toBe(false);
      expect(pulled.creditCards).toHaveLength(1);
      expect(pulled.creditCards[0].isActive).toBe(false);
      expect(pulled.savingGoals).toHaveLength(1);
      expect(pulled.savingGoals[0].archivedAt).toBe('2026-09-01T00:00:00.000Z');
      expect(pulled.sinkingFunds).toHaveLength(1);
      expect(pulled.sinkingFunds[0].archivedAt).toBe('2026-09-01T00:00:00.000Z');
      expect(pulled.categories).toHaveLength(1);
      expect(pulled.categories[0].archivedAt).toBe('2026-09-01T00:00:00.000Z');

      // ... and the where-clauses passed to Prisma no longer filter by isActive/archivedAt.
      expect(mockPrisma.account.findMany).toHaveBeenCalledWith(
        expect.objectContaining({ where: { householdId: 'household-ME' } }),
      );
      expect(mockPrisma.creditCard.findMany).toHaveBeenCalledWith(
        expect.objectContaining({ where: { householdId: 'household-ME' } }),
      );
      expect(mockPrisma.savingGoal.findMany).toHaveBeenCalledWith(
        expect.objectContaining({ where: { householdId: 'household-ME' } }),
      );
      expect(mockPrisma.sinkingFund.findMany).toHaveBeenCalledWith(
        expect.objectContaining({ where: { householdId: 'household-ME' } }),
      );
      expect(mockPrisma.category.findMany).toHaveBeenCalledWith(
        expect.objectContaining({ where: { householdId: 'household-ME' } }),
      );
    });
  });
});
