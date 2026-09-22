import { BadRequestException, ForbiddenException } from '@nestjs/common';
import { SyncService } from '../src/sync/sync.service';
import { EntriesService } from '../src/entries/entries.service';
import { MonthsService } from '../src/months/months.service';
import { EngineService } from '../src/engine/engine.service';

describe('Phase 3 Batch 2 — Transactional Sync Batch & Month Close (D3, D4)', () => {
  const householdId = 'hh-tx-test';
  const userId = 'user-tx-test';

  describe('D3: Sync Batch Transactionality & Partial Sync Reporting', () => {
    let syncService: SyncService;
    let entriesService: EntriesService;
    let mockPrisma: any;
    let mockTx: any;

    beforeEach(() => {
      mockTx = {
        category: {
          count: jest.fn().mockResolvedValue(10),
          findUnique: jest.fn().mockResolvedValue({ id: 'cat-1', householdId }),
          upsert: jest.fn().mockResolvedValue({}),
          updateMany: jest.fn().mockResolvedValue({ count: 1 }),
          createMany: jest.fn().mockResolvedValue({ count: 1 }),
        },
        account: {
          findUnique: jest.fn().mockResolvedValue(null),
          findFirst: jest.fn().mockResolvedValue(null),
          upsert: jest.fn().mockResolvedValue({}),
        },
        creditCard: {
          findUnique: jest.fn().mockResolvedValue(null),
          create: jest.fn().mockResolvedValue({}),
          upsert: jest.fn().mockResolvedValue({}),
        },
        cardTransaction: {
          findUnique: jest.fn().mockResolvedValue(null),
          upsert: jest.fn().mockResolvedValue({}),
          deleteMany: jest.fn().mockResolvedValue({ count: 1 }),
        },
        plannedBill: {
          findUnique: jest.fn().mockResolvedValue(null),
          upsert: jest.fn().mockResolvedValue({}),
          deleteMany: jest.fn().mockResolvedValue({ count: 1 }),
        },
        receivable: {
          findUnique: jest.fn().mockResolvedValue(null),
          upsert: jest.fn().mockResolvedValue({}),
          deleteMany: jest.fn().mockResolvedValue({ count: 1 }),
        },
        savingGoal: {
          findUnique: jest.fn().mockResolvedValue(null),
          upsert: jest.fn().mockResolvedValue({}),
        },
        goalContribution: {
          findUnique: jest.fn().mockResolvedValue(null),
          upsert: jest.fn().mockResolvedValue({}),
          deleteMany: jest.fn().mockResolvedValue({ count: 1 }),
        },
        sinkingFund: {
          findUnique: jest.fn().mockResolvedValue(null),
          upsert: jest.fn().mockResolvedValue({}),
        },
        fundMovement: {
          findUnique: jest.fn().mockResolvedValue(null),
          upsert: jest.fn().mockResolvedValue({}),
          deleteMany: jest.fn().mockResolvedValue({ count: 1 }),
        },
        budget: {
          findUnique: jest.fn().mockResolvedValue(null),
          findFirst: jest.fn().mockResolvedValue(null),
          upsert: jest.fn().mockResolvedValue({}),
          update: jest.fn().mockResolvedValue({}),
          deleteMany: jest.fn().mockResolvedValue({ count: 1 }),
        },
        reserveLine: {
          findUnique: jest.fn().mockResolvedValue(null),
          upsert: jest.fn().mockResolvedValue({}),
          deleteMany: jest.fn().mockResolvedValue({ count: 1 }),
        },
        annual_targets: {
          findUnique: jest.fn().mockResolvedValue(null),
          upsert: jest.fn().mockResolvedValue({}),
          deleteMany: jest.fn().mockResolvedValue({ count: 1 }),
        },
        entry: {
          findUnique: jest.fn().mockResolvedValue(null),
          create: jest.fn().mockResolvedValue({}),
          update: jest.fn().mockResolvedValue({}),
        },
        syncTombstone: {
          upsert: jest.fn().mockResolvedValue({}),
        },
      };

      mockPrisma = {
        ...mockTx,
        category: {
          count: jest.fn().mockResolvedValue(10),
          findUnique: jest.fn().mockResolvedValue({ id: 'cat-1', householdId }),
          upsert: jest.fn().mockResolvedValue({}),
        },
        syncTombstone: {
          findMany: jest.fn().mockResolvedValue([]),
          upsert: jest.fn().mockResolvedValue({}),
        },
        monthSnapshot: {
          findUnique: jest.fn().mockResolvedValue(null),
          findMany: jest.fn().mockResolvedValue([]),
        },
        $transaction: jest.fn(async (cb: any) => cb(mockTx)),
      };

      entriesService = new EntriesService(mockPrisma);
      syncService = new SyncService(entriesService, mockPrisma);
    });

    it('1. Mid-transaction failure: write error inside transaction causes total rollback', async () => {
      // Mock an unexpected DB crash / constraint error during plannedBill.upsert
      mockTx.plannedBill.upsert.mockRejectedValueOnce(
        new Error('Database connection terminated unexpectedly mid-write'),
      );

      const payload = {
        accounts: [
          {
            id: 'acc-1',
            name: 'Savings',
            type: 'savings',
            currentBalancePaise: 100000,
          },
        ],
        plannedBills: [
          {
            id: 'bill-fail',
            name: 'Electricity',
            amountPaise: 250000,
            dueDate: '2026-03-31T00:00:00.000Z',
          },
        ],
        entries: [
          {
            id: 'entry-1',
            categoryId: 'cat-1',
            kind: 'spending',
            amountPaise: 5000,
            entryDate: '2026-03-15T00:00:00.000Z',
          },
        ],
      };

      await expect(
        syncService.syncBatch(householdId, payload, userId),
      ).rejects.toThrow('Database connection terminated unexpectedly mid-write');

      // Verify transaction was invoked with 45s timeout
      expect(mockPrisma.$transaction).toHaveBeenCalledWith(
        expect.any(Function),
        expect.objectContaining({ timeout: 45000, maxWait: 10000 }),
      );

      // Verify that the error aborted the transaction before entry.create was called
      expect(mockTx.entry.create).not.toHaveBeenCalled();
    });

    it('2. Validation-rejection partial sync preserved: closed-month & invalid-kind entries fail while valid items sync', async () => {
      // Mock month 2026-01 as closed, 2026-03 as open
      mockPrisma.monthSnapshot.findUnique.mockImplementation(({ where }: any) => {
        if (where.householdId_yearMonth?.yearMonth === '2026-01') {
          return Promise.resolve({ status: 'closed' });
        }
        return Promise.resolve(null);
      });

      const payload = {
        accounts: [
          {
            id: 'acc-valid',
            name: 'Main Checking',
            type: 'checking',
            currentBalancePaise: 500000,
          },
        ],
        plannedBills: [
          {
            id: 'bill-valid',
            name: 'Internet',
            amountPaise: 100000,
            dueDate: '2026-03-25T00:00:00.000Z',
          },
        ],
        entries: [
          {
            id: 'entry-closed',
            categoryId: 'cat-1',
            kind: 'spending',
            amountPaise: 10000,
            entryDate: '2026-01-15T00:00:00.000Z', // Closed month -> must fail
          },
          {
            id: 'entry-bad-kind',
            categoryId: 'cat-1',
            kind: 'unknown_kind_xyz', // Invalid kind -> must fail
            amountPaise: 20000,
            entryDate: '2026-03-10T00:00:00.000Z',
          },
          {
            id: 'entry-valid-1',
            categoryId: 'cat-1',
            kind: 'spending',
            amountPaise: 3000,
            entryDate: '2026-03-12T00:00:00.000Z', // Valid
          },
          {
            id: 'entry-valid-2',
            categoryId: 'cat-1',
            kind: 'income',
            amountPaise: 80000,
            entryDate: '2026-03-15T00:00:00.000Z', // Valid
          },
        ],
      };

      const result = await syncService.syncBatch(householdId, payload, userId);

      // Verify partial sync reporting: exactly 2 valid synced, 2 invalid failed
      expect(result.accounts).toBe(1);
      expect(result.plannedBills).toBe(1);
      expect(result.entries.synced).toBe(2);
      expect(result.entries.failed).toBe(2);

      // Transaction was executed for valid items
      expect(mockPrisma.$transaction).toHaveBeenCalledTimes(1);
      expect(mockTx.account.upsert).toHaveBeenCalledTimes(1);
      expect(mockTx.plannedBill.upsert).toHaveBeenCalledTimes(1);
      expect(mockTx.entry.create).toHaveBeenCalledTimes(2);

      // Assert that valid entries were created and invalid ones were not
      const createdIds = mockTx.entry.create.mock.calls.map((c: any) => c[0].data.id);
      expect(createdIds).toEqual(['entry-valid-1', 'entry-valid-2']);
      expect(createdIds).not.toContain('entry-closed');
      expect(createdIds).not.toContain('entry-bad-kind');
    });

    it('5. If all items are invalid, it should return synced: 0, failed: N normally, without crashing', async () => {
      // Mock month 2026-01 as closed
      mockPrisma.monthSnapshot.findUnique.mockResolvedValue({ status: 'closed' });

      const payload = {
        entries: [
          {
            id: 'e-inv-1',
            categoryId: 'cat-1',
            kind: 'spending',
            amountPaise: 1000,
            entryDate: '2026-01-05T00:00:00.000Z', // closed
          },
          {
            id: 'e-inv-2',
            categoryId: 'cat-1',
            kind: 'invalid_kind',
            amountPaise: 2000,
            entryDate: '2026-01-10T00:00:00.000Z', // invalid kind
          },
          {
            id: 'e-inv-3',
            categoryId: 'cat-1',
            kind: 'spending',
            amountPaise: -500, // negative spending not allowed
            entryDate: '2026-01-15T00:00:00.000Z',
          },
        ],
      };

      const result = await syncService.syncBatch(householdId, payload, userId);

      expect(result).toBeDefined();
      expect(result.entries.synced).toBe(0);
      expect(result.entries.failed).toBe(3);
      expect(mockTx.entry.create).not.toHaveBeenCalled();
      expect(mockTx.entry.update).not.toHaveBeenCalled();
    });
  });

  describe('D4: Month Close / Rollover Transactionality', () => {
    let monthsService: MonthsService;
    let engine: EngineService;
    let mockPrisma: any;
    let mockTx: any;

    const yearMonth = '2026-03';

    beforeEach(() => {
      engine = new EngineService();

      mockTx = {
        monthSnapshot: {
          findUnique: jest.fn().mockResolvedValue(null),
          upsert: jest.fn().mockImplementation(({ create }) => Promise.resolve({ ...create })),
          update: jest.fn(),
        },
      };

      mockPrisma = {
        monthSnapshot: {
          findUnique: jest.fn(),
          upsert: jest.fn(),
          update: jest.fn(),
        },
        entry: {
          findMany: jest.fn().mockResolvedValue([
            { kind: 'income', amountPaise: 100000 },
            { kind: 'spending', amountPaise: 40000 },
          ]),
        },
        category: {
          findMany: jest.fn().mockResolvedValue([]),
        },
        sinkingFund: {
          findMany: jest.fn().mockResolvedValue([]),
        },
        account: {
          findMany: jest.fn().mockResolvedValue([
            { currentBalancePaise: 60000, isActive: true },
          ]),
        },
        $transaction: jest.fn(async (cb: any) => cb(mockTx)),
      };

      monthsService = new MonthsService(mockPrisma, engine);
    });

    it('3. Month close (D4): failure during next-month seed causes total rollback (month stays open)', async () => {
      // 1. Initial lookup: current month is not closed
      mockPrisma.monthSnapshot.findUnique
        .mockResolvedValueOnce(null) // existing in closeMonth check
        .mockResolvedValueOnce(null) // priorSnap
        .mockResolvedValueOnce({ openingBalancePaise: 0, lastMonthReservesPaise: 0 }); // activeSnap

      // Inside transaction:
      // Current month upsert succeeds
      mockTx.monthSnapshot.upsert.mockResolvedValueOnce({
        householdId,
        yearMonth,
        status: 'closed',
      });
      // Next month lookup returns null
      mockTx.monthSnapshot.findUnique.mockResolvedValueOnce(null);
      // Next month upsert FAILS (simulating constraint violation or connection drop)
      mockTx.monthSnapshot.upsert.mockRejectedValueOnce(
        new Error('Constraint violation on next-month opening balance seed'),
      );

      await expect(
        monthsService.closeMonth(householdId, yearMonth, {} as any),
      ).rejects.toThrow('Constraint violation on next-month opening balance seed');

      // Assert transaction was invoked with timeout 30s
      expect(mockPrisma.$transaction).toHaveBeenCalledWith(
        expect.any(Function),
        expect.objectContaining({ timeout: 30000, maxWait: 10000 }),
      );

      // Verify that both operations were attempted inside tx, but failure propagated
      expect(mockTx.monthSnapshot.upsert).toHaveBeenCalledTimes(2);
    });

    it('4. Month close (D4): successful atomic close and next-month opening balance seed', async () => {
      // 1. Initial lookup: current month is not closed
      mockPrisma.monthSnapshot.findUnique
        .mockResolvedValueOnce(null) // existing in closeMonth check
        .mockResolvedValueOnce(null) // priorSnap
        .mockResolvedValueOnce({ openingBalancePaise: 10000, lastMonthReservesPaise: 5000 }); // activeSnap

      const result = await monthsService.closeMonth(householdId, yearMonth, {} as any);

      expect(result.status).toBe('closed');
      expect(mockPrisma.$transaction).toHaveBeenCalledWith(
        expect.any(Function),
        expect.objectContaining({ timeout: 30000, maxWait: 10000 }),
      );

      // Current month was closed inside tx
      expect(mockTx.monthSnapshot.upsert).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { householdId_yearMonth: { householdId, yearMonth: '2026-03' } },
          create: expect.objectContaining({ status: 'closed' }),
        }),
      );

      // Next month was seeded inside tx
      expect(mockTx.monthSnapshot.upsert).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { householdId_yearMonth: { householdId, yearMonth: '2026-04' } },
          create: expect.objectContaining({ status: 'open' }),
        }),
      );
    });
  });
});
