import { ForbiddenException } from '@nestjs/common';
import { SyncService } from './sync.service';
import { EntriesService } from '../entries/entries.service';

describe('SyncService — Non-Entries Entity Sync Paths (Categories, Cards, Bills, Budgets, etc.)', () => {
  let syncService: SyncService;
  let entriesServiceMock: any;
  let prismaMock: any;
  let mockTx: any;

  const householdId = 'household-100';
  const otherHouseholdId = 'household-200';
  const userId = 'user-test-1';

  beforeEach(() => {
    mockTx = {
      category: {
        upsert: jest.fn().mockResolvedValue({}),
        updateMany: jest.fn().mockResolvedValue({ count: 1 }),
      },
      account: {
        upsert: jest.fn().mockResolvedValue({}),
      },
      creditCard: {
        create: jest.fn().mockResolvedValue({}),
        upsert: jest.fn().mockResolvedValue({}),
      },
      cardTransaction: {
        upsert: jest.fn().mockResolvedValue({}),
        deleteMany: jest.fn().mockResolvedValue({ count: 1 }),
      },
      plannedBill: {
        upsert: jest.fn().mockResolvedValue({}),
        deleteMany: jest.fn().mockResolvedValue({ count: 1 }),
      },
      receivable: {
        upsert: jest.fn().mockResolvedValue({}),
        deleteMany: jest.fn().mockResolvedValue({ count: 1 }),
      },
      savingGoal: {
        upsert: jest.fn().mockResolvedValue({}),
        deleteMany: jest.fn().mockResolvedValue({ count: 1 }),
      },
      goalContribution: {
        upsert: jest.fn().mockResolvedValue({}),
        deleteMany: jest.fn().mockResolvedValue({ count: 1 }),
      },
      sinkingFund: {
        upsert: jest.fn().mockResolvedValue({}),
        deleteMany: jest.fn().mockResolvedValue({ count: 1 }),
      },
      fundMovement: {
        upsert: jest.fn().mockResolvedValue({}),
        deleteMany: jest.fn().mockResolvedValue({ count: 1 }),
      },
      budget: {
        upsert: jest.fn().mockResolvedValue({}),
        update: jest.fn().mockResolvedValue({}),
        deleteMany: jest.fn().mockResolvedValue({ count: 1 }),
      },
      reserveLine: {
        upsert: jest.fn().mockResolvedValue({}),
        deleteMany: jest.fn().mockResolvedValue({ count: 1 }),
      },
      annual_targets: {
        upsert: jest.fn().mockResolvedValue({}),
        deleteMany: jest.fn().mockResolvedValue({ count: 1 }),
      },
      syncTombstone: {
        upsert: jest.fn().mockResolvedValue({}),
      },
    };

    prismaMock = {
      category: {
        findUnique: jest.fn().mockResolvedValue(null),
        findMany: jest.fn().mockResolvedValue([]),
      },
      account: {
        findUnique: jest.fn().mockResolvedValue(null),
        findFirst: jest.fn().mockResolvedValue(null),
        findMany: jest.fn().mockResolvedValue([]),
      },
      creditCard: {
        findUnique: jest.fn().mockResolvedValue(null),
        findMany: jest.fn().mockResolvedValue([]),
      },
      cardTransaction: {
        findUnique: jest.fn().mockResolvedValue(null),
        findMany: jest.fn().mockResolvedValue([]),
      },
      plannedBill: {
        findUnique: jest.fn().mockResolvedValue(null),
        findMany: jest.fn().mockResolvedValue([]),
      },
      receivable: {
        findUnique: jest.fn().mockResolvedValue(null),
        findMany: jest.fn().mockResolvedValue([]),
      },
      savingGoal: {
        findUnique: jest.fn().mockResolvedValue(null),
        findMany: jest.fn().mockResolvedValue([]),
      },
      goalContribution: {
        findUnique: jest.fn().mockResolvedValue(null),
        findMany: jest.fn().mockResolvedValue([]),
      },
      sinkingFund: {
        findUnique: jest.fn().mockResolvedValue(null),
        findMany: jest.fn().mockResolvedValue([]),
      },
      fundMovement: {
        findUnique: jest.fn().mockResolvedValue(null),
        findMany: jest.fn().mockResolvedValue([]),
      },
      budget: {
        findUnique: jest.fn().mockResolvedValue(null),
        findFirst: jest.fn().mockResolvedValue(null),
        findMany: jest.fn().mockResolvedValue([]),
      },
      reserveLine: {
        findUnique: jest.fn().mockResolvedValue(null),
        findMany: jest.fn().mockResolvedValue([]),
      },
      annual_targets: {
        findUnique: jest.fn().mockResolvedValue(null),
        findMany: jest.fn().mockResolvedValue([]),
      },
      syncTombstone: {
        findMany: jest.fn().mockResolvedValue([]),
      },
      entry: {
        findUnique: jest.fn().mockResolvedValue(null),
        findMany: jest.fn().mockResolvedValue([]),
      },
      monthSnapshot: {
        findMany: jest.fn().mockResolvedValue([]),
      },
      $transaction: jest.fn(async (cb) => cb(mockTx)),
    };

    entriesServiceMock = {
      validateBatch: jest.fn().mockResolvedValue({
        validWrites: [],
        neededCategories: [],
        syncedCount: 0,
        failedCount: 0,
      }),
      upsertBatch: jest.fn().mockResolvedValue({ synced: 0, failed: 0 }),
    };

    syncService = new SyncService(entriesServiceMock as unknown as EntriesService, prismaMock);
  });

  // ─── 1. CATEGORIES ──────────────────────────────────────────────────────────

  describe('Categories Sync', () => {
    it('successfully upserts custom category', async () => {
      const dto = {
        categories: [
          {
            id: 'cat-custom-1',
            name: 'Freelance',
            kind: 'income',
            groupCode: 'inc',
            needOrWant: 'want',
            isDeduction: false,
            isSystem: false,
            sortOrder: 5,
          },
        ],
      };

      const result = await syncService.syncBatch(householdId, dto, userId);

      expect(result.categories).toBe(1);
      expect(mockTx.category.upsert).toHaveBeenCalledWith({
        where: { id: 'cat-custom-1' },
        create: {
          id: 'cat-custom-1',
          householdId,
          kind: 'income',
          groupCode: 'inc',
          name: 'Freelance',
          needOrWant: 'want',
          isDeduction: false,
          isSystem: false,
          sortOrder: 5,
        },
        update: {
          kind: 'income',
          groupCode: 'inc',
          name: 'Freelance',
          needOrWant: 'want',
          isDeduction: false,
          isSystem: false,
          sortOrder: 5,
        },
      });
    });

    it('skips client-side system category IDs (e.g. lend-system-cat-{householdId})', async () => {
      const dto = {
        categories: [
          {
            id: `lend-system-cat-${householdId}`,
            name: 'Lend System',
            kind: 'adjustment',
          },
          {
            id: 'cat-valid-1',
            name: 'Valid Custom Category',
            kind: 'spending',
          },
        ],
      };

      const result = await syncService.syncBatch(householdId, dto, userId);

      expect(result.categories).toBe(1);
      expect(mockTx.category.upsert).toHaveBeenCalledTimes(1);
      expect(mockTx.category.upsert).toHaveBeenCalledWith(
        expect.objectContaining({ where: { id: 'cat-valid-1' } }),
      );
    });

    it('skips category if an active tombstone exists', async () => {
      prismaMock.syncTombstone.findMany.mockResolvedValue([
        { entity: 'category', entityId: 'cat-deleted-1' },
      ]);

      const dto = {
        categories: [
          { id: 'cat-deleted-1', name: 'Deleted Cat', kind: 'spending' },
          { id: 'cat-active-1', name: 'Active Cat', kind: 'spending' },
        ],
      };

      const result = await syncService.syncBatch(householdId, dto, userId);

      expect(result.categories).toBe(1);
      expect(mockTx.category.upsert).toHaveBeenCalledTimes(1);
      expect(mockTx.category.upsert).toHaveBeenCalledWith(
        expect.objectContaining({ where: { id: 'cat-active-1' } }),
      );
    });

    it('rejects batch with ForbiddenException if category belongs to a different household', async () => {
      prismaMock.category.findUnique.mockResolvedValue({
        id: 'cat-other-1',
        householdId: otherHouseholdId,
      });

      const dto = {
        categories: [{ id: 'cat-other-1', name: 'Other Cat', kind: 'spending' }],
      };

      await expect(syncService.syncBatch(householdId, dto, userId)).rejects.toThrow(
        new ForbiddenException(`Category cat-other-1 belongs to a different household.`),
      );

      expect(mockTx.category.upsert).not.toHaveBeenCalled();
    });
  });

  // ─── 2. ACCOUNTS ────────────────────────────────────────────────────────────

  describe('Accounts Sync', () => {
    it('upserts new account and rounds currentBalancePaise', async () => {
      const dto = {
        accounts: [
          {
            id: 'acc-new-1',
            name: 'HDFC Savings',
            type: 'bank',
            currentBalancePaise: 125000.4,
            sortOrder: 1,
          },
        ],
      };

      const result = await syncService.syncBatch(householdId, dto, userId);

      expect(result.accounts).toBe(1);
      expect(mockTx.account.upsert).toHaveBeenCalledWith({
        where: { id: 'acc-new-1' },
        create: {
          id: 'acc-new-1',
          householdId,
          name: 'HDFC Savings',
          type: 'bank',
          currentBalancePaise: 125000,
          isActive: true,
          sortOrder: 1,
        },
        update: {
          name: 'HDFC Savings',
          type: 'bank',
          currentBalancePaise: 125000,
          isActive: true,
          sortOrder: 1,
        },
      });
    });

    it('deduplicates account by matching case-insensitive name in the same household', async () => {
      prismaMock.account.findFirst.mockResolvedValue({
        id: 'acc-existing-db-id',
        householdId,
        name: 'HDFC Savings',
      });

      const dto = {
        accounts: [
          {
            id: 'acc-device-temp-id',
            name: 'hdfc savings',
            type: 'bank',
            currentBalancePaise: 200000,
          },
        ],
      };

      const result = await syncService.syncBatch(householdId, dto, userId);

      expect(result.accounts).toBe(1);
      expect(mockTx.account.upsert).toHaveBeenCalledWith({
        where: { id: 'acc-existing-db-id' },
        create: expect.objectContaining({ id: 'acc-device-temp-id', name: 'hdfc savings' }),
        update: expect.objectContaining({ name: 'hdfc savings', currentBalancePaise: 200000 }),
      });
    });

    it('rejects batch with ForbiddenException if account ID belongs to a different household', async () => {
      prismaMock.account.findUnique.mockResolvedValue({
        id: 'acc-stolen-id',
        householdId: otherHouseholdId,
      });

      const dto = {
        accounts: [{ id: 'acc-stolen-id', name: 'Victim Account', type: 'bank' as const, currentBalancePaise: 10000 }],
      };

      await expect(syncService.syncBatch(householdId, dto, userId)).rejects.toThrow(
        new ForbiddenException(`Account acc-stolen-id belongs to a different household.`),
      );

      expect(mockTx.account.upsert).not.toHaveBeenCalled();
    });
  });

  // ─── 3. CREDIT CARDS & CARD TRANSACTIONS ────────────────────────────────────

  describe('Credit Cards & Transactions Sync', () => {
    it('upserts credit card and transaction, auto-creating parent card stub if missing', async () => {
      const dto = {
        creditCards: [
          {
            id: 'card-1',
            name: 'Axis Bank',
            previousOutstandingPaise: 50000.4,
          },
        ],
        cardTransactions: [
          {
            id: 'txn-1',
            cardId: 'card-1',
            txnDate: '2026-09-20T10:00:00Z',
            description: 'Lunch',
            amountPaise: 25000.4,
            sNo: 1,
          },
          {
            id: 'txn-missing-card',
            cardId: 'card-unseen-id',
            txnDate: '2026-09-20T11:00:00Z',
            description: 'Fuel',
            amountPaise: 15000,
          },
        ],
      };

      const result = await syncService.syncBatch(householdId, dto, userId);

      expect(result.creditCards).toBe(1);
      expect(result.cardTransactions).toBe(2);

      // Card 1 upsert
      expect(mockTx.creditCard.upsert).toHaveBeenCalledWith({
        where: { id: 'card-1' },
        create: {
          id: 'card-1',
          householdId,
          name: 'Axis Bank',
          previousOutstandingPaise: 50000,
          isActive: true,
        },
        update: {
          name: 'Axis Bank',
          previousOutstandingPaise: 50000,
          isActive: true,
        },
      });

      // Auto-creates stub for card-unseen-id
      expect(mockTx.creditCard.create).toHaveBeenCalledWith({
        data: {
          id: 'card-unseen-id',
          householdId,
          name: 'Credit Card',
          previousOutstandingPaise: 0,
          isActive: true,
        },
      });

      // Transaction 1 upsert
      expect(mockTx.cardTransaction.upsert).toHaveBeenCalledWith({
        where: { id: 'txn-1' },
        create: {
          id: 'txn-1',
          cardId: 'card-1',
          txnDate: new Date('2026-09-20T10:00:00Z'),
          description: 'Lunch',
          amountPaise: 25000,
          sNo: 1,
        },
        update: {
          txnDate: new Date('2026-09-20T10:00:00Z'),
          description: 'Lunch',
          amountPaise: 25000,
          sNo: 1,
        },
      });
    });

    it('rejects batch if parent credit card belongs to a different household', async () => {
      prismaMock.creditCard.findUnique.mockResolvedValue({
        id: 'card-other',
        householdId: otherHouseholdId,
      });

      const dto = {
        cardTransactions: [
          {
            id: 'txn-bad-parent',
            cardId: 'card-other',
            txnDate: '2026-09-20T10:00:00Z',
            description: 'Hacked',
            amountPaise: 1000,
          },
        ],
      };

      await expect(syncService.syncBatch(householdId, dto, userId)).rejects.toThrow(
        new ForbiddenException(`Card card-other belongs to a different household.`),
      );

      expect(mockTx.cardTransaction.upsert).not.toHaveBeenCalled();
    });

    it('rejects batch if existing card transaction belongs to a card of a different household', async () => {
      prismaMock.cardTransaction.findUnique.mockResolvedValue({
        id: 'txn-existing-other',
        card: { householdId: otherHouseholdId },
      });

      const dto = {
        cardTransactions: [
          {
            id: 'txn-existing-other',
            cardId: 'card-valid',
            txnDate: '2026-09-20T10:00:00Z',
            description: 'Hacked txn',
            amountPaise: 1000,
          },
        ],
      };

      await expect(syncService.syncBatch(householdId, dto, userId)).rejects.toThrow(
        new ForbiddenException(
          `Card transaction txn-existing-other belongs to a different household.`,
        ),
      );

      expect(mockTx.cardTransaction.upsert).not.toHaveBeenCalled();
    });
  });

  // ─── 4. PLANNED BILLS & RECEIVABLES ─────────────────────────────────────────

  describe('Planned Bills & Receivables Sync', () => {
    it('successfully upserts planned bill and receivable with rounded paise and parsed dueDate', async () => {
      const dto = {
        plannedBills: [
          {
            id: 'bill-1',
            name: 'Broadband',
            amountPaise: 120000.4,
            dueDate: '2026-10-01T00:00:00Z',
            isPaid: true,
            entryId: 'entry-bill-1',
          },
        ],
        receivables: [
          {
            id: 'rec-1',
            personName: 'Rohan',
            amountPaise: 350000.8,
            dueDate: '2026-10-15T00:00:00Z',
            status: 'open',
            entryId: 'entry-rec-1',
          },
        ],
      };

      const result = await syncService.syncBatch(householdId, dto, userId);

      expect(result.plannedBills).toBe(1);
      expect(result.receivables).toBe(1);

      expect(mockTx.plannedBill.upsert).toHaveBeenCalledWith({
        where: { id: 'bill-1' },
        create: {
          id: 'bill-1',
          householdId,
          name: 'Broadband',
          amountPaise: 120000,
          dueDate: new Date('2026-10-01T00:00:00Z'),
          isPaid: true,
          entry_id: 'entry-bill-1',
        },
        update: {
          name: 'Broadband',
          amountPaise: 120000,
          dueDate: new Date('2026-10-01T00:00:00Z'),
          isPaid: true,
          entry_id: 'entry-bill-1',
        },
      });

      expect(mockTx.receivable.upsert).toHaveBeenCalledWith({
        where: { id: 'rec-1' },
        create: {
          id: 'rec-1',
          householdId,
          personName: 'Rohan',
          amountPaise: 350001,
          status: 'open',
          dueDate: new Date('2026-10-15T00:00:00Z'),
          entry_id: 'entry-rec-1',
        },
        update: {
          personName: 'Rohan',
          amountPaise: 350001,
          status: 'open',
          dueDate: new Date('2026-10-15T00:00:00Z'),
          entry_id: 'entry-rec-1',
        },
      });
    });

    it('rejects batch if linked entryId in planned bill belongs to another household', async () => {
      prismaMock.entry.findUnique.mockResolvedValue({
        id: 'entry-other',
        householdId: otherHouseholdId,
      });

      const dto = {
        plannedBills: [
          {
            id: 'bill-bad-entry',
            name: 'Electric',
            amountPaise: 50000,
            entryId: 'entry-other',
          },
        ],
      };

      await expect(syncService.syncBatch(householdId, dto, userId)).rejects.toThrow(
        new ForbiddenException(`Linked entry entry-other belongs to a different household.`),
      );

      expect(mockTx.plannedBill.upsert).not.toHaveBeenCalled();
    });

    it('rejects batch if linked entryId in receivable belongs to another household', async () => {
      prismaMock.entry.findUnique.mockResolvedValue({
        id: 'entry-other-rec',
        householdId: otherHouseholdId,
      });

      const dto = {
        receivables: [
          {
            id: 'rec-bad-entry',
            personName: 'Friend',
            amountPaise: 50000,
            entryId: 'entry-other-rec',
          },
        ],
      };

      await expect(syncService.syncBatch(householdId, dto, userId)).rejects.toThrow(
        new ForbiddenException(`Linked entry entry-other-rec belongs to a different household.`),
      );

      expect(mockTx.receivable.upsert).not.toHaveBeenCalled();
    });
  });

  // ─── 5. SAVING GOALS & CONTRIBUTIONS ────────────────────────────────────────

  describe('Saving Goals & Contributions Sync', () => {
    it('successfully upserts goal and contribution when parent goal is in batch', async () => {
      const dto = {
        savingGoals: [
          {
            id: 'goal-batch-1',
            bucket: 'wealth',
            name: 'Index Fund',
            targetPaise: 5000000,
            monthlyBudgetPaise: 1000000,
          },
        ],
        goalContributions: [
          {
            id: 'gc-1',
            goalId: 'goal-batch-1',
            amountPaise: 1000000,
            contributionDate: '2026-09-01T00:00:00Z',
            note: 'Monthly investment',
          },
        ],
      };

      const result = await syncService.syncBatch(householdId, dto, userId);

      expect(result.savingGoals).toBe(1);

      expect(mockTx.savingGoal.upsert).toHaveBeenCalledWith({
        where: { id: 'goal-batch-1' },
        create: {
          id: 'goal-batch-1',
          householdId,
          bucket: 'wealth',
          name: 'Index Fund',
          targetPaise: 5000000,
          monthlyBudgetPaise: 1000000,
          archivedAt: null,
        },
        update: {
          bucket: 'wealth',
          name: 'Index Fund',
          targetPaise: 5000000,
          monthlyBudgetPaise: 1000000,
          archivedAt: null,
        },
      });

      expect(mockTx.goalContribution.upsert).toHaveBeenCalledWith({
        where: { id: 'gc-1' },
        create: {
          id: 'gc-1',
          goalId: 'goal-batch-1',
          amountPaise: 1000000,
          contributionDate: new Date('2026-09-01T00:00:00Z'),
          note: 'Monthly investment',
        },
        update: {
          amountPaise: 1000000,
          contributionDate: new Date('2026-09-01T00:00:00Z'),
          note: 'Monthly investment',
        },
      });
    });

    it('rejects contribution when parent goal is neither in DB nor in batch', async () => {
      prismaMock.savingGoal.findUnique.mockResolvedValue(null);

      const dto = {
        goalContributions: [
          {
            id: 'gc-orphan',
            goalId: 'goal-unknown',
            amountPaise: 50000,
            contributionDate: '2026-09-01T00:00:00Z',
          },
        ],
      };

      await expect(syncService.syncBatch(householdId, dto, userId)).rejects.toThrow(
        new ForbiddenException(`Goal goal-unknown does not belong to this household.`),
      );

      expect(mockTx.goalContribution.upsert).not.toHaveBeenCalled();
    });

    it('rejects contribution when parent goal belongs to another household', async () => {
      prismaMock.savingGoal.findUnique.mockResolvedValue({
        id: 'goal-other',
        householdId: otherHouseholdId,
      });

      const dto = {
        goalContributions: [
          {
            id: 'gc-cross',
            goalId: 'goal-other',
            amountPaise: 50000,
            contributionDate: '2026-09-01T00:00:00Z',
          },
        ],
      };

      await expect(syncService.syncBatch(householdId, dto, userId)).rejects.toThrow(
        new ForbiddenException(`Goal goal-other does not belong to this household.`),
      );

      expect(mockTx.goalContribution.upsert).not.toHaveBeenCalled();
    });
  });

  // ─── 6. SINKING FUNDS & FUND MOVEMENTS ──────────────────────────────────────

  describe('Sinking Funds & Fund Movements Sync', () => {
    it('successfully upserts sinking fund and movement when parent fund is in batch', async () => {
      const dto = {
        sinkingFunds: [
          {
            id: 'fund-batch-1',
            name: 'Emergency Buffer',
            openingReservePaise: 2000000,
          },
        ],
        fundMovements: [
          {
            id: 'fm-1',
            fundId: 'fund-batch-1',
            type: 'contribution',
            amountPaise: 500000,
            movementDate: '2026-09-05T00:00:00Z',
            note: 'Bonus deposit',
          },
        ],
      };

      const result = await syncService.syncBatch(householdId, dto, userId);

      expect(result.sinkingFunds).toBe(1);

      expect(mockTx.sinkingFund.upsert).toHaveBeenCalledWith({
        where: { id: 'fund-batch-1' },
        create: {
          id: 'fund-batch-1',
          householdId,
          name: 'Emergency Buffer',
          openingReservePaise: 2000000,
          archivedAt: null,
        },
        update: {
          name: 'Emergency Buffer',
          openingReservePaise: 2000000,
          archivedAt: null,
        },
      });

      expect(mockTx.fundMovement.upsert).toHaveBeenCalledWith({
        where: { id: 'fm-1' },
        create: {
          id: 'fm-1',
          fundId: 'fund-batch-1',
          type: 'contribution',
          amountPaise: 500000,
          movementDate: new Date('2026-09-05T00:00:00Z'),
          note: 'Bonus deposit',
        },
        update: {
          type: 'contribution',
          amountPaise: 500000,
          movementDate: new Date('2026-09-05T00:00:00Z'),
          note: 'Bonus deposit',
        },
      });
    });

    it('rejects fund movement when parent fund is neither in DB nor in batch', async () => {
      prismaMock.sinkingFund.findUnique.mockResolvedValue(null);

      const dto = {
        fundMovements: [
          {
            id: 'fm-orphan',
            fundId: 'fund-unknown',
            type: 'withdrawal',
            amountPaise: 20000,
            movementDate: '2026-09-05T00:00:00Z',
          },
        ],
      };

      await expect(syncService.syncBatch(householdId, dto, userId)).rejects.toThrow(
        new ForbiddenException(`Sinking fund fund-unknown does not belong to this household.`),
      );

      expect(mockTx.fundMovement.upsert).not.toHaveBeenCalled();
    });
  });

  // ─── 7. BUDGETS ─────────────────────────────────────────────────────────────

  describe('Budgets Sync', () => {
    it('upserts budget when new, and updates existing budget when matching cell exists', async () => {
      // Cell 1: brand new
      // Cell 2: already exists in same household/category/yearMonth under a different id
      prismaMock.budget.findFirst.mockResolvedValueOnce(null).mockResolvedValueOnce({
        id: 'budget-cell-existing',
        householdId,
        categoryId: 'cat-2',
        yearMonth: '2026-09',
      });

      const dto = {
        budgets: [
          {
            id: 'b-new-1',
            categoryId: 'cat-1',
            yearMonth: '2026-09',
            amountPaise: 500000,
          },
          {
            id: 'b-device-temp-2',
            categoryId: 'cat-2',
            yearMonth: '2026-09',
            amountPaise: 750000,
          },
        ],
      };

      const result = await syncService.syncBatch(householdId, dto, userId);

      expect(result.budgets).toBe(2);

      // b-new-1: upsert mode
      expect(mockTx.budget.upsert).toHaveBeenCalledWith({
        where: { id: 'b-new-1' },
        create: {
          id: 'b-new-1',
          householdId,
          categoryId: 'cat-1',
          yearMonth: '2026-09',
          amountPaise: 500000,
        },
        update: {
          amountPaise: 500000,
        },
      });

      // b-device-temp-2: update mode on existing cell
      expect(mockTx.budget.update).toHaveBeenCalledWith({
        where: { id: 'budget-cell-existing' },
        data: { amountPaise: 750000 },
      });
    });

    it('rejects budget if category belongs to a different household', async () => {
      prismaMock.category.findUnique.mockResolvedValue({
        id: 'cat-other-hh',
        householdId: otherHouseholdId,
      });

      const dto = {
        budgets: [
          {
            id: 'b-bad-cat',
            categoryId: 'cat-other-hh',
            yearMonth: '2026-09',
            amountPaise: 10000,
          },
        ],
      };

      await expect(syncService.syncBatch(householdId, dto, userId)).rejects.toThrow(
        new ForbiddenException(`Category cat-other-hh belongs to a different household.`),
      );

      expect(mockTx.budget.upsert).not.toHaveBeenCalled();
      expect(mockTx.budget.update).not.toHaveBeenCalled();
    });
  });

  // ─── 8. RESERVE LINES & ANNUAL TARGETS ───────────────────────────────────────

  describe('Reserve Lines & Annual Targets Sync', () => {
    it('successfully upserts reserve line and annual target', async () => {
      const dto = {
        reserveLines: [
          {
            id: 'rl-1',
            yearMonth: '2026-09',
            name: 'Festive Buffer',
            amountPaise: 300000,
            source: 'manual',
          },
        ],
        annualTargets: [
          {
            id: 'at-1',
            title: 'Annual Vacation Goal',
            targetPaise: 12000000,
            type: 'saving',
          },
        ],
      };

      const result = await syncService.syncBatch(householdId, dto, userId);

      expect(result.reserveLines).toBe(1);
      expect(result.annualTargets).toBe(1);

      expect(mockTx.reserveLine.upsert).toHaveBeenCalledWith({
        where: { id: 'rl-1' },
        create: {
          id: 'rl-1',
          householdId,
          yearMonth: '2026-09',
          name: 'Festive Buffer',
          amountPaise: 300000,
          source: 'manual',
        },
        update: {
          name: 'Festive Buffer',
          amountPaise: 300000,
          source: 'manual',
        },
      });

      expect(mockTx.annual_targets.upsert).toHaveBeenCalledWith({
        where: { id: 'at-1' },
        create: {
          id: 'at-1',
          household_id: householdId,
          title: 'Annual Vacation Goal',
          target_paise: 12000000,
          type: 'saving',
        },
        update: {
          title: 'Annual Vacation Goal',
          target_paise: 12000000,
          type: 'saving',
        },
      });
    });

    it('rejects reserve line when existing record belongs to another household', async () => {
      prismaMock.reserveLine.findUnique.mockResolvedValue({
        id: 'rl-other',
        householdId: otherHouseholdId,
      });

      const dto = {
        reserveLines: [
          {
            id: 'rl-other',
            yearMonth: '2026-09',
            name: 'Other Reserve',
            amountPaise: 50000,
          },
        ],
      };

      await expect(syncService.syncBatch(householdId, dto, userId)).rejects.toThrow(
        new ForbiddenException(`Reserve line rl-other belongs to a different household.`),
      );

      expect(mockTx.reserveLine.upsert).not.toHaveBeenCalled();
    });

    it('rejects annual target when existing record belongs to another household', async () => {
      prismaMock.annual_targets.findUnique.mockResolvedValue({
        id: 'at-other',
        household_id: otherHouseholdId,
      });

      const dto = {
        annualTargets: [
          {
            id: 'at-other',
            title: 'Stolen Target',
            targetPaise: 50000,
          },
        ],
      };

      await expect(syncService.syncBatch(householdId, dto, userId)).rejects.toThrow(
        new ForbiddenException(`Annual target at-other belongs to a different household.`),
      );

      expect(mockTx.annual_targets.upsert).not.toHaveBeenCalled();
    });
  });

  // ─── 9. DELETIONS & TOMBSTONES ──────────────────────────────────────────────

  describe('Deletions & Tombstones Sync', () => {
    it('applies deletions for multiple entity types, archiving categories and tombstoning deleted items', async () => {
      // Mock ownership checks for deletions
      prismaMock.plannedBill.findUnique.mockResolvedValue({ id: 'bill-del-1', householdId });
      prismaMock.receivable.findUnique.mockResolvedValue({ id: 'rec-del-1', householdId });
      prismaMock.budget.findUnique.mockResolvedValue({ id: 'b-del-1', householdId });
      prismaMock.reserveLine.findUnique.mockResolvedValue({ id: 'rl-del-1', householdId });
      prismaMock.cardTransaction.findUnique.mockResolvedValue({
        id: 'txn-del-1',
        card: { householdId },
      });
      prismaMock.goalContribution.findUnique.mockResolvedValue({
        id: 'gc-del-1',
        goal: { householdId },
      });
      prismaMock.fundMovement.findUnique.mockResolvedValue({
        id: 'fm-del-1',
        fund: { householdId },
      });
      prismaMock.category.findUnique.mockResolvedValue({ id: 'cat-del-1', householdId });

      const dto = {
        deletions: [
          { entity: 'planned_bill', id: 'bill-del-1' },
          { entity: 'receivable', id: 'rec-del-1' },
          { entity: 'budget', id: 'b-del-1' },
          { entity: 'reserve_line', id: 'rl-del-1' },
          { entity: 'card_transaction', id: 'txn-del-1' },
          { entity: 'goal_contribution', id: 'gc-del-1' },
          { entity: 'fund_movement', id: 'fm-del-1' },
          { entity: 'category', id: 'cat-del-1' },
        ],
        // Backward compatibility
        deletedAnnualTargetIds: ['at-legacy-del-1'],
      };

      prismaMock.annual_targets.findUnique.mockResolvedValue({
        id: 'at-legacy-del-1',
        household_id: householdId,
      });

      const result = await syncService.syncBatch(householdId, dto as any, userId);

      expect(result.deletions).toBe(9);

      // Verify each model deletion
      expect(mockTx.plannedBill.deleteMany).toHaveBeenCalledWith({
        where: { id: 'bill-del-1', householdId },
      });
      expect(mockTx.receivable.deleteMany).toHaveBeenCalledWith({
        where: { id: 'rec-del-1', householdId },
      });
      expect(mockTx.budget.deleteMany).toHaveBeenCalledWith({
        where: { id: 'b-del-1', householdId },
      });
      expect(mockTx.reserveLine.deleteMany).toHaveBeenCalledWith({
        where: { id: 'rl-del-1', householdId },
      });
      expect(mockTx.cardTransaction.deleteMany).toHaveBeenCalledWith({
        where: { id: 'txn-del-1', card: { householdId } },
      });
      expect(mockTx.goalContribution.deleteMany).toHaveBeenCalledWith({
        where: { id: 'gc-del-1', goal: { householdId } },
      });
      expect(mockTx.fundMovement.deleteMany).toHaveBeenCalledWith({
        where: { id: 'fm-del-1', fund: { householdId } },
      });
      expect(mockTx.annual_targets.deleteMany).toHaveBeenCalledWith({
        where: { id: 'at-legacy-del-1', household_id: householdId },
      });

      // Categories are archived, never hard-deleted
      expect(mockTx.category.updateMany).toHaveBeenCalledWith({
        where: { id: 'cat-del-1', householdId, isSystem: false },
        data: { archivedAt: expect.any(Date) },
      });

      // All 9 deletions create tombstones
      expect(mockTx.syncTombstone.upsert).toHaveBeenCalledTimes(9);
    });

    it('rejects deletion if the record belongs to another household', async () => {
      prismaMock.plannedBill.findUnique.mockResolvedValue({
        id: 'bill-victim',
        householdId: otherHouseholdId,
      });

      const dto = {
        deletions: [{ entity: 'planned_bill', id: 'bill-victim' }],
      };

      await expect(syncService.syncBatch(householdId, dto as any, userId)).rejects.toThrow(
        new ForbiddenException(
          `Cannot delete planned_bill bill-victim: it belongs to a different household.`,
        ),
      );

      expect(mockTx.plannedBill.deleteMany).not.toHaveBeenCalled();
      expect(mockTx.syncTombstone.upsert).not.toHaveBeenCalled();
    });
  });

  // ─── 10. MID-TRANSACTION ROLLBACK ───────────────────────────────────────────

  describe('Mid-Transaction Failure & Rollback', () => {
    it('rolls back the entire transaction if a write failure occurs during Phase 2', async () => {
      // Setup a batch with multiple valid entities
      const dto = {
        categories: [{ id: 'cat-ok', name: 'Valid Cat', kind: 'income' }],
        budgets: [{ id: 'b-fail', categoryId: 'cat-ok', yearMonth: '2026-09', amountPaise: 50000 }],
      };

      // Simulate a database constraint failure on budget upsert during Phase 2
      mockTx.budget.upsert.mockRejectedValue(new Error('DB Foreign Key constraint violation'));

      await expect(syncService.syncBatch(householdId, dto, userId)).rejects.toThrow(
        'DB Foreign Key constraint violation',
      );

      // Verify Prisma $transaction was called
      expect(prismaMock.$transaction).toHaveBeenCalled();
    });
  });

  // ─── 11. PULL DATA ──────────────────────────────────────────────────────────

  describe('pullData', () => {
    it('retrieves all 13 entity collections with BigInt conversion, ISO string dates, and tombstone dictionary', async () => {
      prismaMock.account.findMany.mockResolvedValue([
        { id: 'acc-1', householdId, name: 'Bank', currentBalancePaise: BigInt(50000), sortOrder: 1 },
      ]);
      prismaMock.creditCard.findMany.mockResolvedValue([
        { id: 'card-1', householdId, name: 'Visa', previousOutstandingPaise: BigInt(25000) },
      ]);
      prismaMock.cardTransaction.findMany.mockResolvedValue([
        {
          id: 'txn-1',
          cardId: 'card-1',
          amountPaise: BigInt(15000),
          txnDate: new Date('2026-09-01T10:00:00Z'),
        },
      ]);
      prismaMock.plannedBill.findMany.mockResolvedValue([
        {
          id: 'bill-1',
          householdId,
          name: 'WiFi',
          entry_id: 'e-1',
          amountPaise: BigInt(100000),
          dueDate: new Date('2026-09-10T00:00:00Z'),
        },
      ]);
      prismaMock.receivable.findMany.mockResolvedValue([
        {
          id: 'rec-1',
          householdId,
          personName: 'Sam',
          entry_id: 'e-2',
          amountPaise: BigInt(200000),
          dueDate: null,
        },
      ]);
      prismaMock.savingGoal.findMany.mockResolvedValue([
        {
          id: 'goal-1',
          householdId,
          name: 'Car',
          targetPaise: BigInt(5000000),
          monthlyBudgetPaise: BigInt(500000),
          archivedAt: new Date('2026-09-15T00:00:00Z'),
        },
      ]);
      prismaMock.goalContribution.findMany.mockResolvedValue([
        {
          id: 'gc-1',
          goalId: 'goal-1',
          amountPaise: BigInt(500000),
          contributionDate: new Date('2026-09-02T00:00:00Z'),
        },
      ]);
      prismaMock.sinkingFund.findMany.mockResolvedValue([
        {
          id: 'fund-1',
          householdId,
          name: 'Home',
          openingReservePaise: BigInt(1000000),
          archivedAt: null,
        },
      ]);
      prismaMock.fundMovement.findMany.mockResolvedValue([
        {
          id: 'fm-1',
          fundId: 'fund-1',
          amountPaise: BigInt(300000),
          movementDate: new Date('2026-09-03T00:00:00Z'),
        },
      ]);
      prismaMock.budget.findMany.mockResolvedValue([
        { id: 'b-1', householdId, categoryId: 'cat-1', amountPaise: BigInt(700000) },
      ]);
      prismaMock.reserveLine.findMany.mockResolvedValue([
        { id: 'rl-1', householdId, name: 'Buffer', amountPaise: BigInt(400000) },
      ]);
      prismaMock.annual_targets.findMany.mockResolvedValue([
        { id: 'at-1', household_id: householdId, title: 'Trip', target_paise: BigInt(10000000), type: 'saving' },
      ]);
      prismaMock.category.findMany.mockResolvedValue([
        { id: 'cat-1', householdId, name: 'Food', archivedAt: null },
      ]);
      prismaMock.entry.findMany
        .mockResolvedValueOnce([
          {
            id: 'e-1',
            householdId,
            amountPaise: BigInt(100000),
            entryDate: new Date('2026-09-01T00:00:00Z'),
            createdAt: new Date('2026-09-01T00:00:00Z'),
            updatedAt: new Date('2026-09-01T00:00:00Z'),
            deletedAt: null,
          },
        ])
        .mockResolvedValueOnce([
          { id: 'e-del-1', deletedAt: new Date('2026-09-02T00:00:00Z') },
        ]);
      prismaMock.syncTombstone.findMany.mockResolvedValue([
        { entity: 'planned_bill', entityId: 'bill-tomb-1' },
        { entity: 'annual_target', entityId: 'at-tomb-1' },
      ]);
      prismaMock.monthSnapshot.findMany.mockResolvedValue([
        { yearMonth: '2026-08', status: 'closed', statusChangedAt: new Date('2026-09-01T00:00:00Z') },
      ]);

      const result = await syncService.pullData(householdId);

      expect(result.householdId).toBe(householdId);
      expect(result.accounts[0].currentBalancePaise).toBe(50000);
      expect(result.creditCards[0].previousOutstandingPaise).toBe(25000);
      expect(result.cardTransactions[0].amountPaise).toBe(15000);
      expect(result.cardTransactions[0].txnDate).toBe('2026-09-01T10:00:00.000Z');
      expect(result.plannedBills[0].entryId).toBe('e-1');
      expect(result.plannedBills[0].amountPaise).toBe(100000);
      expect(result.receivables[0].entryId).toBe('e-2');
      expect(result.savingGoals[0].targetPaise).toBe(5000000);
      expect(result.savingGoals[0].archivedAt).toBe('2026-09-15T00:00:00.000Z');
      expect(result.goalContributions[0].amountPaise).toBe(500000);
      expect(result.sinkingFunds[0].openingReservePaise).toBe(1000000);
      expect(result.sinkingFunds[0].archivedAt).toBeNull();
      expect(result.fundMovements[0].amountPaise).toBe(300000);
      expect(result.budgets[0].amountPaise).toBe(700000);
      expect(result.reserveLines[0].amountPaise).toBe(400000);
      expect(result.annualTargets[0].targetPaise).toBe(10000000);
      expect(result.annualTargets[0].householdId).toBe(householdId);
      expect(result.deletedRecords.plannedBills).toContain('bill-tomb-1');
      expect(result.deletedRecords.annualTargets).toContain('at-tomb-1');
      expect(result.deletedAnnualTargetIds).toContain('at-tomb-1');
      expect(result.monthStatuses[0].yearMonth).toBe('2026-08');
      expect(result.monthStatuses[0].status).toBe('closed');
      expect(result.monthStatuses[0].statusChangedAt).toBe('2026-09-01T00:00:00.000Z');
    });
  });
});
