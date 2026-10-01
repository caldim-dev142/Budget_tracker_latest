import { SyncService, mergeProcessedState } from '../src/sync/sync.service';

describe('Backend Recurring Rules Sync — Fix Pass Verification', () => {
  let syncService: SyncService;
  let mockPrisma: any;

  beforeEach(() => {
    mockPrisma = {
      syncTombstone: {
        findMany: jest.fn().mockResolvedValue([]),
        upsert: jest.fn().mockResolvedValue({}),
      },
      recurringRule: {
        findUnique: jest.fn(),
        findMany: jest.fn().mockResolvedValue([]),
        upsert: jest.fn().mockImplementation((args: any) => args.create || args.update),
        updateMany: jest.fn().mockResolvedValue({ count: 1 }),
      },
      category: {
        findUnique: jest.fn().mockResolvedValue({ id: 'cat-1', householdId: 'hh-1' }),
        count: jest.fn().mockResolvedValue(1),
      },
      $transaction: jest.fn().mockImplementation(async (callback: any) => {
        return callback(mockPrisma);
      }),
    };

    syncService = new SyncService(
      { getEntries: jest.fn(), applyChanges: jest.fn() } as any,
      mockPrisma,
    );
  });

  describe('Item 10 & 11: mergeProcessedState algorithm', () => {
    it('does not truncate processedDates beyond 60 entries', () => {
      const dates: string[] = [];
      for (let i = 1; i <= 80; i++) {
        const day = (i % 28) + 1;
        const month = ((Math.floor(i / 28) + 1) % 12) + 1;
        dates.push(`2026-${String(month).padStart(2, '0')}-${String(day).padStart(2, '0')}`);
      }

      const res = mergeProcessedState(
        { dayOfMonth: 5, startDate: new Date('2026-01-01') },
        { processedThrough: null, processedDates: dates },
        { processedThrough: null, processedDates: [] },
      );

      // Must NOT be truncated to 60
      expect(res.processedDates.length).toBeGreaterThan(60);
    });

    it('unions disjoint processedDates from client and server', () => {
      const res = mergeProcessedState(
        { dayOfMonth: 10, startDate: new Date('2026-01-01') },
        { processedThrough: null, processedDates: ['2026-03-10'] },
        { processedThrough: null, processedDates: ['2026-05-10'] },
      );

      expect(res.processedDates).toContain('2026-03-10');
      expect(res.processedDates).toContain('2026-05-10');
    });

    it('advances processedThrough from rule FIRST occurrence when processedThrough is null', () => {
      // Rule starts on 2026-01-10, dayOfMonth = 10
      // First occurrence is 2026-01-10
      const res = mergeProcessedState(
        { dayOfMonth: 10, startDate: new Date('2026-01-05') },
        { processedThrough: null, processedDates: ['2026-01-10', '2026-02-10'] },
        { processedThrough: null, processedDates: [] },
      );

      // Compaction should advance through 2026-01-10 and 2026-02-10
      expect(res.processedThrough).not.toBeNull();
      const ptIso = new Date(res.processedThrough).toISOString().substring(0, 10);
      expect(ptIso).toBe('2026-02-10');
      expect(res.processedDates).not.toContain('2026-01-10');
      expect(res.processedDates).not.toContain('2026-02-10');
    });
  });

  describe('Item 9 & 7: LWW & Sticky deletedAt in syncBatch Phase 2', () => {
    it('preserves existing deletedAt when incoming record has no deletedAt (sticky deletedAt)', async () => {
      const existingDeletedAt = new Date('2026-09-01T10:00:00Z');
      mockPrisma.recurringRule.findUnique.mockResolvedValue({
        id: 'r1',
        householdId: 'hh-1',
        kind: 'spending',
        categoryId: 'cat-1',
        amountPaise: 50000,
        dayOfMonth: 5,
        startDate: new Date('2026-01-01'),
        mode: 'auto',
        isActive: true,
        processedThrough: null,
        processedDates: '[]',
        updatedAt: new Date('2026-09-01T10:00:00Z'),
        deletedAt: existingDeletedAt,
      });

      // Incoming rule has NEWER updatedAt but null deletedAt (e.g. from an old offline client)
      await (syncService as any).syncBatch('hh-1', {
        categories: [],
        accounts: [],
        creditCards: [],
        cardTransactions: [],
        plannedBills: [],
        receivables: [],
        savingGoals: [],
        goalContributions: [],
        sinkingFunds: [],
        fundMovements: [],
        budgets: [],
        reserveLines: [],
        annualTargets: [],
        recurringRules: [
          {
            id: 'r1',
            householdId: 'hh-1',
            kind: 'spending',
            categoryId: 'cat-1',
            amountPaise: 60000,
            dayOfMonth: 5,
            startDate: '2026-01-01T00:00:00.000Z',
            mode: 'auto',
            isActive: true,
            updatedAt: '2026-09-02T10:00:00.000Z',
            // deletedAt omitted/null
          },
        ],
        entries: [],
        deletions: [],
      }, 'user-1');

      expect(mockPrisma.recurringRule.upsert).toHaveBeenCalled();
      const upsertCall = mockPrisma.recurringRule.upsert.mock.calls[0][0];
      // Sticky deletedAt: update MUST keep existingDeletedAt
      expect(upsertCall.update.deletedAt).toEqual(existingDeletedAt);
    });

    it('rejects overwrite of non-processed fields when incoming updatedAt is older than existing (LWW)', async () => {
      const existingUpdatedAt = new Date('2026-09-10T12:00:00Z');
      mockPrisma.recurringRule.findUnique.mockResolvedValue({
        id: 'r1',
        householdId: 'hh-1',
        kind: 'spending',
        categoryId: 'cat-1',
        amountPaise: 50000, // newer amount
        dayOfMonth: 5,
        startDate: new Date('2026-01-01'),
        mode: 'auto',
        isActive: true,
        processedThrough: null,
        processedDates: '[]',
        updatedAt: existingUpdatedAt,
        deletedAt: null,
      });

      // Incoming has OLDER updatedAt (2026-09-05) and different amountPaise (30000)
      await (syncService as any).syncBatch('hh-1', {
        categories: [],
        accounts: [],
        creditCards: [],
        cardTransactions: [],
        plannedBills: [],
        receivables: [],
        savingGoals: [],
        goalContributions: [],
        sinkingFunds: [],
        fundMovements: [],
        budgets: [],
        reserveLines: [],
        annualTargets: [],
        recurringRules: [
          {
            id: 'r1',
            householdId: 'hh-1',
            kind: 'spending',
            categoryId: 'cat-1',
            amountPaise: 30000,
            dayOfMonth: 5,
            startDate: '2026-01-01T00:00:00.000Z',
            mode: 'auto',
            isActive: true,
            updatedAt: '2026-09-05T12:00:00.000Z',
          },
        ],
        entries: [],
        deletions: [],
      }, 'user-1');

      expect(mockPrisma.recurringRule.upsert).toHaveBeenCalled();
      const upsertCall = mockPrisma.recurringRule.upsert.mock.calls[0][0];
      // LWW: amountPaise is omitted from update so DB value (50000) is NOT overwritten
      expect(upsertCall.update.amountPaise).toBeUndefined();
      expect(upsertCall.update.kind).toBeUndefined();
    });
  });
});
