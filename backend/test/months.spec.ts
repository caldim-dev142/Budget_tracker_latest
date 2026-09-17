import { NotFoundException } from '@nestjs/common';
import { MonthsService } from '../src/months/months.service';
import { EngineService } from '../src/engine/engine.service';

/**
 * Phase 4 — MonthsService Unit Tests
 *
 * Tests:
 * 1. closeMonth idempotency (already closed returns early)
 * 2. closeMonth calculation & freeze (isDeduction adjustments, net income, sinking funds, waterfall, remaining)
 * 3. closeMonth seeds next month's opening balances correctly
 * 4. reopenMonth (throws if not found, returns existing if open, updates to open if closed)
 * 5. isMonthOpen (true when none, true when open, false when closed)
 */
describe('MonthsService (Phase 4)', () => {
  let service: MonthsService;
  let engine: EngineService;
  let mockPrisma: any;

  const householdId = 'hh-test-1';
  const yearMonth = '2026-03';

  beforeEach(() => {
    engine = new EngineService();

    mockPrisma = {
      monthSnapshot: {
        findUnique: jest.fn(),
        upsert: jest.fn(),
        update: jest.fn(),
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
    };

    service = new MonthsService(mockPrisma, engine);
  });

  describe('isMonthOpen', () => {
    it('returns true if no snapshot exists', async () => {
      mockPrisma.monthSnapshot.findUnique.mockResolvedValue(null);
      const result = await service.isMonthOpen(householdId, yearMonth);
      expect(result).toBe(true);
    });

    it('returns true if snapshot status is open', async () => {
      mockPrisma.monthSnapshot.findUnique.mockResolvedValue({ status: 'open' });
      const result = await service.isMonthOpen(householdId, yearMonth);
      expect(result).toBe(true);
    });

    it('returns false if snapshot status is closed', async () => {
      mockPrisma.monthSnapshot.findUnique.mockResolvedValue({ status: 'closed' });
      const result = await service.isMonthOpen(householdId, yearMonth);
      expect(result).toBe(false);
    });
  });

  describe('reopenMonth', () => {
    it('throws NotFoundException if snapshot does not exist', async () => {
      mockPrisma.monthSnapshot.findUnique.mockResolvedValue(null);
      await expect(service.reopenMonth(householdId, yearMonth)).rejects.toThrow(
        NotFoundException,
      );
    });

    it('returns existing snapshot if already open', async () => {
      const snap = { id: 'snap-1', householdId, yearMonth, status: 'open' };
      mockPrisma.monthSnapshot.findUnique.mockResolvedValue(snap);

      const result = await service.reopenMonth(householdId, yearMonth);
      expect(result).toEqual(snap);
      expect(mockPrisma.monthSnapshot.update).not.toHaveBeenCalled();
    });

    it('updates status to open and clears closedAt if closed', async () => {
      const snap = { id: 'snap-1', householdId, yearMonth, status: 'closed', closedAt: new Date() };
      mockPrisma.monthSnapshot.findUnique.mockResolvedValue(snap);
      mockPrisma.monthSnapshot.update.mockResolvedValue({
        ...snap,
        status: 'open',
        closedAt: null,
      });

      const result = await service.reopenMonth(householdId, yearMonth);
      expect(result.status).toBe('open');
      expect(result.closedAt).toBeNull();
      expect(mockPrisma.monthSnapshot.update).toHaveBeenCalledWith({
        where: { householdId_yearMonth: { householdId, yearMonth } },
        data: { status: 'open', closedAt: null, statusChangedAt: expect.any(Date) },
      });
    });
  });

  describe('closeMonth', () => {
    it('is idempotent: returns existing snapshot if already closed without recalculation', async () => {
      const closedSnap = {
        householdId,
        yearMonth,
        status: 'closed',
        openingBalancePaise: 10000,
        lastMonthReservesPaise: 2000,
        incomePaise: 50000,
        adjustmentsPaise: 0,
        spendingPaise: 20000,
        protectionPaise: 5000,
        savingPaise: 5000,
        reservesPaise: 2000,
        closingBalancePaise: 28000,
        remainingPaise: 10000,
      };
      mockPrisma.monthSnapshot.findUnique.mockResolvedValue(closedSnap);

      const result = await service.closeMonth(householdId, yearMonth, {} as any);
      expect(result.status).toBe('closed');
      expect(mockPrisma.entry.findMany).not.toHaveBeenCalled();
      expect(mockPrisma.monthSnapshot.upsert).not.toHaveBeenCalled();
    });

    it('freezes actuals, applies isDeduction sign, computes waterfall, and seeds next month', async () => {
      // 1. Initial lookup returns null (or open snapshot)
      mockPrisma.monthSnapshot.findUnique
        .mockResolvedValueOnce(null) // existing in closeMonth check
        .mockResolvedValueOnce(null) // priorSnap
        .mockResolvedValueOnce({    // activeSnap
          openingBalancePaise: 10000,
          lastMonthReservesPaise: 5000,
        });

      // Categories: cat-deduct is an outflow adjustment, cat-add is an inflow adjustment
      mockPrisma.category.findMany.mockResolvedValue([
        { id: 'cat-deduct', isDeduction: true },
        { id: 'cat-add', isDeduction: false },
      ]);

      // Entries
      mockPrisma.entry.findMany.mockResolvedValue([
        { kind: 'income', amountPaise: 80000 },
        { kind: 'incomeDeduction', amountPaise: 5000 }, // netIncome = 75000
        { kind: 'adjustment', categoryId: 'cat-deduct', amountPaise: 3000 }, // -3000
        { kind: 'adjustment', categoryId: 'cat-add', amountPaise: 1000 },    // +1000 -> net adjustments = -2000
        { kind: 'spending', amountPaise: 30000 },
        { kind: 'protection', amountPaise: 10000 },
        { kind: 'saving', amountPaise: 10000 },
      ]);

      // Sinking funds
      mockPrisma.sinkingFund.findMany.mockResolvedValue([
        {
          id: 'fund-1',
          openingReservePaise: 4000,
          movements: [
            { type: 'contribution', amountPaise: 2000 },
            { type: 'withdrawal', amountPaise: 1000 },
          ], // fund closing = 4000 + 2000 - 1000 = 5000
        },
      ]);

      // Active accounts
      mockPrisma.account.findMany.mockResolvedValue([
        { currentBalancePaise: 60000, isActive: true },
      ]); // totalAvailable = 60000
      // closingBalance = totalAvailable (60000) - totalReserves (5000) = 55000

      mockPrisma.monthSnapshot.upsert.mockImplementation(({ create }) => {
        return Promise.resolve({ ...create });
      });

      const result = await service.closeMonth(householdId, yearMonth, {} as any);

      // Verify current month upserted
      expect(mockPrisma.monthSnapshot.upsert).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { householdId_yearMonth: { householdId, yearMonth } },
          create: expect.objectContaining({
            householdId,
            yearMonth,
            incomePaise: 75000,
            adjustmentsPaise: -2000,
            spendingPaise: 30000,
            protectionPaise: 10000,
            savingPaise: 10000,
            reservesPaise: 5000,
            closingBalancePaise: 55000,
            status: 'closed',
          }),
        }),
      );

      // Verify next month seeded with openingBalance = 55000, lastMonthReserves = 5000
      expect(mockPrisma.monthSnapshot.upsert).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { householdId_yearMonth: { householdId, yearMonth: '2026-04' } },
          create: expect.objectContaining({
            householdId,
            yearMonth: '2026-04',
            openingBalancePaise: 55000,
            lastMonthReservesPaise: 5000,
            status: 'open',
          }),
          update: expect.objectContaining({
            openingBalancePaise: 55000,
            lastMonthReservesPaise: 5000,
          }),
        }),
      );

      expect(result.status).toBe('closed');
      expect(result.closingBalancePaise).toBe(55000);
    });
  });
});
