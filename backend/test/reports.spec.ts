import { ReportsService } from '../src/reports/reports.service';
import { EngineService } from '../src/engine/engine.service';

/**
 * Phase 4 — ReportsService Unit Tests
 *
 * Tests:
 * 1. getMonthlyTrends — returns closed snapshot actuals, nulls for open/missing months (no synthetic defaults)
 * 2. getMonthlyTrends — properly filters by householdId
 * 3. getYearlySummary — aggregates only closed months for given year
 * 4. getYearlySummary — returns 0 totals when no months are closed
 */
describe('ReportsService (Phase 4)', () => {
  let service: ReportsService;
  let engine: EngineService;
  let mockPrisma: any;

  const householdId = 'hh-report-1';

  beforeEach(() => {
    engine = new EngineService();

    mockPrisma = {
      monthSnapshot: {
        findMany: jest.fn(),
        findUnique: jest.fn(),
      },
      entry: {
        findMany: jest.fn(),
      },
      category: {
        findMany: jest.fn(),
      },
      sinkingFund: {
        findMany: jest.fn(),
      },
      account: {
        findMany: jest.fn(),
      },
      creditCard: {
        findMany: jest.fn(),
      },
      receivable: {
        findMany: jest.fn(),
      },
      plannedBill: {
        findMany: jest.fn(),
      },
      budget: {
        findMany: jest.fn(),
      },
    };

    service = new ReportsService(mockPrisma, engine);
  });

  describe('getMonthlyTrends', () => {
    it('returns closed snapshot data and nulls for open/missing months without synthetic defaults', async () => {
      const now = new Date();
      const currentYm = `${now.getFullYear()}-${(now.getMonth() + 1).toString().padStart(2, '0')}`;

      // Mock only 1 closed snapshot matching currentYm
      mockPrisma.monthSnapshot.findMany.mockResolvedValue([
        {
          yearMonth: currentYm,
          householdId,
          status: 'closed',
          incomePaise: 100000,
          adjustmentsPaise: -5000,
          spendingPaise: 40000,
          protectionPaise: 10000,
          savingPaise: 15000,
          remainingPaise: 30000,
        },
      ]);

      const trends = await service.getMonthlyTrends(householdId, 3);
      expect(trends).toHaveLength(3);

      // Verify Prisma query was household-scoped with status 'closed'
      expect(mockPrisma.monthSnapshot.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.objectContaining({
            householdId,
            status: 'closed',
          }),
        }),
      );

      // The current month is closed and has real data
      const currentTrend = trends.find((t) => t.yearMonth === currentYm);
      expect(currentTrend).toBeDefined();
      expect(currentTrend?.isClosed).toBe(true);
      expect(currentTrend?.income).toBe(100000);
      expect(currentTrend?.spending).toBe(40000);
      expect(currentTrend?.remaining).toBe(30000);

      // Earlier missing months have nulls, NOT synthetic values
      const missingTrend = trends.find((t) => t.yearMonth !== currentYm);
      expect(missingTrend).toBeDefined();
      expect(missingTrend?.isClosed).toBe(false);
      expect(missingTrend?.income).toBeNull();
      expect(missingTrend?.spending).toBeNull();
      expect(missingTrend?.remaining).toBeNull();
    });
  });

  describe('getYearlySummary', () => {
    it('aggregates totals accurately from only closed months for the given year', async () => {
      mockPrisma.monthSnapshot.findMany.mockResolvedValue([
        {
          yearMonth: '2026-01',
          householdId,
          status: 'closed',
          incomePaise: 100000,
          adjustmentsPaise: 0,
          spendingPaise: 50000,
          protectionPaise: 10000,
          savingPaise: 10000,
          remainingPaise: 30000,
        },
        {
          yearMonth: '2026-02',
          householdId,
          status: 'closed',
          incomePaise: 120000,
          adjustmentsPaise: -2000,
          spendingPaise: 60000,
          protectionPaise: 10000,
          savingPaise: 20000,
          remainingPaise: 28000,
        },
      ]);

      const summary = await service.getYearlySummary(householdId, 2026);

      expect(summary.year).toBe(2026);
      expect(summary.closedMonthsCount).toBe(2);
      expect(summary.totals.income).toBe(220000);
      expect(summary.totals.adjustments).toBe(-2000);
      expect(summary.totals.spending).toBe(110000);
      expect(summary.totals.protection).toBe(20000);
      expect(summary.totals.saving).toBe(30000);
      expect(summary.totals.remaining).toBe(58000);
      expect(summary.months).toHaveLength(2);
    });

    it('returns 0 totals when no snapshots are closed in that year', async () => {
      mockPrisma.monthSnapshot.findMany.mockResolvedValue([]);

      const summary = await service.getYearlySummary(householdId, 2026);

      expect(summary.year).toBe(2026);
      expect(summary.closedMonthsCount).toBe(0);
      expect(summary.totals.income).toBe(0);
      expect(summary.totals.spending).toBe(0);
      expect(summary.totals.remaining).toBe(0);
      expect(summary.months).toHaveLength(0);
    });
  });
});
