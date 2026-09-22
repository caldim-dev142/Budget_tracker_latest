import { NotFoundException, ForbiddenException } from '@nestjs/common';
import { PlanningService } from './planning.service';

describe('PlanningService', () => {
  let service: PlanningService;
  let prismaMock: any;

  const householdId = 'household-123';
  const otherHouseholdId = 'household-999';
  const receivableId = 'rec-abc';
  const billId = 'bill-xyz';

  beforeEach(() => {
    prismaMock = {
      receivable: {
        findMany: jest.fn(),
        create: jest.fn(),
        findUnique: jest.fn(),
        update: jest.fn(),
      },
      plannedBill: {
        findMany: jest.fn(),
        create: jest.fn(),
        findUnique: jest.fn(),
        update: jest.fn(),
      },
      reserveLine: {
        findMany: jest.fn(),
        upsert: jest.fn(),
      },
      $transaction: jest.fn(async (ops) => ops),
    };

    service = new PlanningService(prismaMock);
  });

  // ─── Receivables ─────────────────────────────────────────────────────────────

  describe('Receivables', () => {
    describe('getReceivables', () => {
      it('scopes query to householdId and converts amountPaise to number', async () => {
        prismaMock.receivable.findMany.mockResolvedValue([
          {
            id: 'rec-1',
            householdId,
            personName: 'Ramesh',
            amountPaise: BigInt(500000), // ₹5,000
            status: 'open',
            dueDate: new Date('2026-10-15T00:00:00Z'),
          },
          {
            id: 'rec-2',
            householdId,
            personName: 'Suresh',
            amountPaise: BigInt(250000), // ₹2,500
            status: 'returned',
            dueDate: null,
          },
        ]);

        const result = await service.getReceivables(householdId);

        expect(prismaMock.receivable.findMany).toHaveBeenCalledTimes(1);
        expect(prismaMock.receivable.findMany).toHaveBeenCalledWith({ where: { householdId } });

        expect(result).toHaveLength(2);
        expect(result[0].amountPaise).toBe(500000);
        expect(typeof result[0].amountPaise).toBe('number');
        expect(result[1].amountPaise).toBe(250000);
        expect(typeof result[1].amountPaise).toBe('number');
      });

      it('returns empty array when no receivables exist for household', async () => {
        prismaMock.receivable.findMany.mockResolvedValue([]);

        const result = await service.getReceivables(householdId);

        expect(prismaMock.receivable.findMany).toHaveBeenCalledWith({ where: { householdId } });
        expect(result).toEqual([]);
      });
    });

    describe('createReceivable', () => {
      it('creates receivable scoped to householdId with rounded amount and parsed dueDate', async () => {
        const createdRecord = {
          id: 'rec-new',
          householdId,
          personName: 'Anil',
          amountPaise: 150000,
          dueDate: new Date('2026-11-01T00:00:00.000Z'),
        };
        prismaMock.receivable.create.mockResolvedValue(createdRecord);

        const result = await service.createReceivable(
          householdId,
          'Anil',
          150000.4,
          '2026-11-01T00:00:00.000Z',
        );

        expect(prismaMock.receivable.create).toHaveBeenCalledWith({
          data: {
            householdId,
            personName: 'Anil',
            amountPaise: 150000, // Math.round(150000.4)
            dueDate: new Date('2026-11-01T00:00:00.000Z'),
          },
        });
        expect(result).toEqual(createdRecord);
      });

      it('creates receivable without dueDate, setting dueDate to null', async () => {
        const createdRecord = {
          id: 'rec-new-2',
          householdId,
          personName: 'Sunil',
          amountPaise: 50000,
          dueDate: null,
        };
        prismaMock.receivable.create.mockResolvedValue(createdRecord);

        const result = await service.createReceivable(householdId, 'Sunil', 50000);

        expect(prismaMock.receivable.create).toHaveBeenCalledWith({
          data: {
            householdId,
            personName: 'Sunil',
            amountPaise: 50000,
            dueDate: null,
          },
        });
        expect(result).toEqual(createdRecord);
      });
    });

    describe('updateReceivableStatus', () => {
      it('updates status when receivable belongs to the caller household', async () => {
        prismaMock.receivable.findUnique.mockResolvedValue({
          id: receivableId,
          householdId,
          personName: 'Ramesh',
          amountPaise: BigInt(500000),
          status: 'open',
        });

        const updatedRecord = {
          id: receivableId,
          householdId,
          personName: 'Ramesh',
          amountPaise: BigInt(500000),
          status: 'returned',
        };
        prismaMock.receivable.update.mockResolvedValue(updatedRecord);

        const result = await service.updateReceivableStatus(householdId, receivableId, 'returned');

        expect(prismaMock.receivable.findUnique).toHaveBeenCalledWith({ where: { id: receivableId } });
        expect(prismaMock.receivable.update).toHaveBeenCalledWith({
          where: { id: receivableId },
          data: { status: 'returned' },
        });
        expect(result).toEqual(updatedRecord);
      });

      it('throws NotFoundException when receivable does not exist', async () => {
        prismaMock.receivable.findUnique.mockResolvedValue(null);

        await expect(
          service.updateReceivableStatus(householdId, 'non-existent', 'returned'),
        ).rejects.toThrow(new NotFoundException('Receivable not found.'));

        expect(prismaMock.receivable.update).not.toHaveBeenCalled();
      });

      it('throws ForbiddenException when receivable belongs to a different household (cross-tenant rejection)', async () => {
        prismaMock.receivable.findUnique.mockResolvedValue({
          id: receivableId,
          householdId: otherHouseholdId,
          personName: 'Victim Person',
          amountPaise: BigInt(999999),
          status: 'open',
        });

        await expect(
          service.updateReceivableStatus(householdId, receivableId, 'returned'),
        ).rejects.toThrow(ForbiddenException);

        expect(prismaMock.receivable.update).not.toHaveBeenCalled();
      });
    });
  });

  // ─── Planned Bills ───────────────────────────────────────────────────────────

  describe('Planned Bills', () => {
    describe('getPlannedBills', () => {
      it('scopes query to householdId and converts amountPaise to number', async () => {
        prismaMock.plannedBill.findMany.mockResolvedValue([
          {
            id: 'bill-1',
            householdId,
            name: 'Internet Fiber',
            amountPaise: BigInt(120000), // ₹1,200
            isPaid: false,
            dueDate: new Date('2026-10-05T00:00:00Z'),
          },
          {
            id: 'bill-2',
            householdId,
            name: 'Gym Membership',
            amountPaise: BigInt(200000), // ₹2,000
            isPaid: true,
            dueDate: null,
          },
        ]);

        const result = await service.getPlannedBills(householdId);

        expect(prismaMock.plannedBill.findMany).toHaveBeenCalledWith({ where: { householdId } });
        expect(result).toHaveLength(2);
        expect(result[0].amountPaise).toBe(120000);
        expect(typeof result[0].amountPaise).toBe('number');
        expect(result[1].amountPaise).toBe(200000);
        expect(typeof result[1].amountPaise).toBe('number');
      });

      it('returns empty array when no planned bills exist for household', async () => {
        prismaMock.plannedBill.findMany.mockResolvedValue([]);

        const result = await service.getPlannedBills(householdId);

        expect(prismaMock.plannedBill.findMany).toHaveBeenCalledWith({ where: { householdId } });
        expect(result).toEqual([]);
      });
    });

    describe('createPlannedBill', () => {
      it('creates planned bill scoped to householdId with rounded amount and parsed dueDate', async () => {
        const createdRecord = {
          id: 'bill-new',
          householdId,
          name: 'Electricity',
          amountPaise: 350000,
          dueDate: new Date('2026-10-20T00:00:00Z'),
        };
        prismaMock.plannedBill.create.mockResolvedValue(createdRecord);

        const result = await service.createPlannedBill(
          householdId,
          'Electricity',
          349999.7,
          '2026-10-20T00:00:00Z',
        );

        expect(prismaMock.plannedBill.create).toHaveBeenCalledWith({
          data: {
            householdId,
            name: 'Electricity',
            amountPaise: 350000, // Math.round(349999.7)
            dueDate: new Date('2026-10-20T00:00:00Z'),
          },
        });
        expect(result).toEqual(createdRecord);
      });

      it('creates planned bill without dueDate, setting dueDate to null', async () => {
        const createdRecord = {
          id: 'bill-new-2',
          householdId,
          name: 'Water Bill',
          amountPaise: 50000,
          dueDate: null,
        };
        prismaMock.plannedBill.create.mockResolvedValue(createdRecord);

        const result = await service.createPlannedBill(householdId, 'Water Bill', 50000);

        expect(prismaMock.plannedBill.create).toHaveBeenCalledWith({
          data: {
            householdId,
            name: 'Water Bill',
            amountPaise: 50000,
            dueDate: null,
          },
        });
        expect(result).toEqual(createdRecord);
      });
    });

    describe('markBillPaid', () => {
      it('updates isPaid when bill belongs to the caller household', async () => {
        prismaMock.plannedBill.findUnique.mockResolvedValue({
          id: billId,
          householdId,
          name: 'Internet',
          isPaid: false,
        });

        const updatedRecord = {
          id: billId,
          householdId,
          name: 'Internet',
          isPaid: true,
        };
        prismaMock.plannedBill.update.mockResolvedValue(updatedRecord);

        const result = await service.markBillPaid(householdId, billId, true);

        expect(prismaMock.plannedBill.findUnique).toHaveBeenCalledWith({ where: { id: billId } });
        expect(prismaMock.plannedBill.update).toHaveBeenCalledWith({
          where: { id: billId },
          data: { isPaid: true },
        });
        expect(result).toEqual(updatedRecord);
      });

      it('throws NotFoundException when bill does not exist', async () => {
        prismaMock.plannedBill.findUnique.mockResolvedValue(null);

        await expect(service.markBillPaid(householdId, 'non-existent', true)).rejects.toThrow(
          new NotFoundException('Bill not found.'),
        );

        expect(prismaMock.plannedBill.update).not.toHaveBeenCalled();
      });

      it('throws ForbiddenException when bill belongs to a different household (cross-tenant rejection)', async () => {
        prismaMock.plannedBill.findUnique.mockResolvedValue({
          id: billId,
          householdId: otherHouseholdId,
          name: 'Victim Bill',
          isPaid: false,
        });

        await expect(service.markBillPaid(householdId, billId, true)).rejects.toThrow(
          ForbiddenException,
        );

        expect(prismaMock.plannedBill.update).not.toHaveBeenCalled();
      });
    });
  });

  // ─── Reserve Lines ───────────────────────────────────────────────────────────

  describe('Reserve Lines', () => {
    describe('getReserveLines', () => {
      it('scopes query to householdId and yearMonth, converting amountPaise to number', async () => {
        prismaMock.reserveLine.findMany.mockResolvedValue([
          {
            id: `${householdId}-2026-10-General`,
            householdId,
            yearMonth: '2026-10',
            name: 'General',
            amountPaise: BigInt(1000000), // ₹10,000
          },
          {
            id: `${householdId}-2026-10-Medical`,
            householdId,
            yearMonth: '2026-10',
            name: 'Medical',
            amountPaise: BigInt(500000), // ₹5,000
          },
        ]);

        const result = await service.getReserveLines(householdId, '2026-10');

        expect(prismaMock.reserveLine.findMany).toHaveBeenCalledWith({
          where: { householdId, yearMonth: '2026-10' },
        });
        expect(result).toHaveLength(2);
        expect(result[0].amountPaise).toBe(1000000);
        expect(typeof result[0].amountPaise).toBe('number');
        expect(result[1].amountPaise).toBe(500000);
      });

      it('returns empty array when no reserve lines exist for the month', async () => {
        prismaMock.reserveLine.findMany.mockResolvedValue([]);

        const result = await service.getReserveLines(householdId, '2026-11');

        expect(prismaMock.reserveLine.findMany).toHaveBeenCalledWith({
          where: { householdId, yearMonth: '2026-11' },
        });
        expect(result).toEqual([]);
      });
    });

    describe('upsertReserveLines', () => {
      it('constructs compound ID upsert operations with rounded amounts and executes in transaction', async () => {
        const lines = [
          { name: 'General Reserve', amountPaise: 1000000.4 },
          { name: 'Travel Buffer', amountPaise: 500000.8 },
        ];

        const dummyUpsertOp1 = { op: 1 };
        const dummyUpsertOp2 = { op: 2 };
        prismaMock.reserveLine.upsert
          .mockReturnValueOnce(dummyUpsertOp1)
          .mockReturnValueOnce(dummyUpsertOp2);

        const result = await service.upsertReserveLines(householdId, '2026-10', lines);

        expect(prismaMock.reserveLine.upsert).toHaveBeenCalledTimes(2);

        // Line 1
        expect(prismaMock.reserveLine.upsert).toHaveBeenNthCalledWith(1, {
          where: { id: `${householdId}-2026-10-General Reserve` },
          create: {
            id: `${householdId}-2026-10-General Reserve`,
            householdId,
            yearMonth: '2026-10',
            name: 'General Reserve',
            amountPaise: 1000000,
          },
          update: {
            amountPaise: 1000000,
          },
        });

        // Line 2
        expect(prismaMock.reserveLine.upsert).toHaveBeenNthCalledWith(2, {
          where: { id: `${householdId}-2026-10-Travel Buffer` },
          create: {
            id: `${householdId}-2026-10-Travel Buffer`,
            householdId,
            yearMonth: '2026-10',
            name: 'Travel Buffer',
            amountPaise: 500001, // Math.round(500000.8)
          },
          update: {
            amountPaise: 500001,
          },
        });

        expect(prismaMock.$transaction).toHaveBeenCalledWith([dummyUpsertOp1, dummyUpsertOp2]);
        expect(result).toEqual({ success: true, count: 2 });
      });

      it('handles empty lines array without error', async () => {
        const result = await service.upsertReserveLines(householdId, '2026-10', []);

        expect(prismaMock.reserveLine.upsert).not.toHaveBeenCalled();
        expect(prismaMock.$transaction).toHaveBeenCalledWith([]);
        expect(result).toEqual({ success: true, count: 0 });
      });
    });
  });
});
