import { NotFoundException, ForbiddenException } from '@nestjs/common';
import { ProtectionService } from './protection.service';

describe('ProtectionService', () => {
  let service: ProtectionService;
  let prismaMock: any;

  const householdId = 'household-123';
  const otherHouseholdId = 'household-999';
  const fundId = 'fund-xyz';

  beforeEach(() => {
    prismaMock = {
      sinkingFund: {
        findMany: jest.fn(),
        create: jest.fn(),
        findUnique: jest.fn(),
      },
      fundMovement: {
        create: jest.fn(),
      },
    };

    service = new ProtectionService(prismaMock);
  });

  describe('findAll', () => {
    it('scopes query to householdId and archivedAt: null, calculating reserve movements accurately', async () => {
      prismaMock.sinkingFund.findMany.mockResolvedValue([
        {
          id: 'fund-1',
          householdId,
          name: 'Medical Emergency',
          openingReservePaise: BigInt(5000000), // ₹50,000
          archivedAt: null,
          movements: [
            {
              id: 'm-1',
              fundId: 'fund-1',
              type: 'contribution',
              amountPaise: BigInt(2000000), // +₹20,000
              note: 'Annual top-up',
            },
            {
              id: 'm-2',
              fundId: 'fund-1',
              type: 'withdrawal',
              amountPaise: BigInt(1500000), // -₹15,000
              note: 'Dental surgery',
            },
          ],
        },
        {
          id: 'fund-2',
          householdId,
          name: 'Home Appliance Repair',
          openingReservePaise: BigInt(1000000), // ₹10,000
          archivedAt: null,
          movements: [], // No movements yet
        },
      ]);

      const funds = await service.findAll(householdId);

      expect(prismaMock.sinkingFund.findMany).toHaveBeenCalledTimes(1);
      expect(prismaMock.sinkingFund.findMany).toHaveBeenCalledWith({
        where: { householdId, archivedAt: null },
        include: { movements: true },
      });

      expect(funds).toHaveLength(2);

      // Fund 1: opening=5000000, contrib=2000000, withdr=1500000 => closing=5500000
      const f1 = funds[0];
      expect(f1.id).toBe('fund-1');
      expect(f1.name).toBe('Medical Emergency');
      expect(f1.openingReservePaise).toBe(5000000);
      expect(f1.contributionsPaise).toBe(2000000);
      expect(f1.withdrawalsPaise).toBe(1500000);
      expect(f1.closingReservePaise).toBe(5500000);
      expect(f1.movements).toHaveLength(2);
      expect(f1.movements[0].amountPaise).toBe(2000000);
      expect(typeof f1.movements[0].amountPaise).toBe('number');
      expect(f1.movements[1].amountPaise).toBe(1500000);

      // Fund 2: opening=1000000, no movements => contrib=0, withdr=0, closing=1000000
      const f2 = funds[1];
      expect(f2.id).toBe('fund-2');
      expect(f2.name).toBe('Home Appliance Repair');
      expect(f2.openingReservePaise).toBe(1000000);
      expect(f2.contributionsPaise).toBe(0);
      expect(f2.withdrawalsPaise).toBe(0);
      expect(f2.closingReservePaise).toBe(1000000);
      expect(f2.movements).toEqual([]);
    });

    it('returns an empty array when no active sinking funds exist for the household', async () => {
      prismaMock.sinkingFund.findMany.mockResolvedValue([]);

      const funds = await service.findAll(householdId);

      expect(prismaMock.sinkingFund.findMany).toHaveBeenCalledWith({
        where: { householdId, archivedAt: null },
        include: { movements: true },
      });
      expect(funds).toEqual([]);
    });
  });

  describe('createFund', () => {
    it('creates a sinking fund scoped to householdId with rounded opening reserve', async () => {
      const createdRecord = {
        id: 'new-fund-1',
        householdId,
        name: 'Car Maintenance',
        openingReservePaise: 2500000,
      };
      prismaMock.sinkingFund.create.mockResolvedValue(createdRecord);

      const result = await service.createFund(householdId, 'Car Maintenance', 2500000.4);

      expect(prismaMock.sinkingFund.create).toHaveBeenCalledTimes(1);
      expect(prismaMock.sinkingFund.create).toHaveBeenCalledWith({
        data: {
          householdId,
          name: 'Car Maintenance',
          openingReservePaise: 2500000, // Math.round(2500000.4)
        },
      });
      expect(result).toEqual(createdRecord);
    });

    it('creates a sinking fund with 0 opening reserve', async () => {
      const createdRecord = {
        id: 'new-fund-2',
        householdId,
        name: 'Zero Fund',
        openingReservePaise: 0,
      };
      prismaMock.sinkingFund.create.mockResolvedValue(createdRecord);

      const result = await service.createFund(householdId, 'Zero Fund', 0);

      expect(prismaMock.sinkingFund.create).toHaveBeenCalledWith({
        data: {
          householdId,
          name: 'Zero Fund',
          openingReservePaise: 0,
        },
      });
      expect(result).toEqual(createdRecord);
    });
  });

  describe('addMovement', () => {
    it('adds a contribution movement when fund belongs to the household, rounding amountPaise', async () => {
      prismaMock.sinkingFund.findUnique.mockResolvedValue({
        id: fundId,
        householdId,
        name: 'Medical Emergency',
      });

      const createdMovement = {
        id: 'mov-1',
        fundId,
        type: 'contribution' as const,
        amountPaise: 1000000,
        movementDate: new Date(),
        note: 'Quarterly savings addition',
      };
      prismaMock.fundMovement.create.mockResolvedValue(createdMovement);

      const result = await service.addMovement(
        householdId,
        fundId,
        'contribution',
        999999.6,
        'Quarterly savings addition',
      );

      expect(prismaMock.sinkingFund.findUnique).toHaveBeenCalledWith({ where: { id: fundId } });
      expect(prismaMock.fundMovement.create).toHaveBeenCalledWith({
        data: {
          fundId,
          type: 'contribution',
          amountPaise: 1000000, // Math.round(999999.6)
          movementDate: expect.any(Date),
          note: 'Quarterly savings addition',
        },
      });
      expect(result).toEqual(createdMovement);
    });

    it('adds a withdrawal movement when fund belongs to the household', async () => {
      prismaMock.sinkingFund.findUnique.mockResolvedValue({
        id: fundId,
        householdId,
        name: 'Medical Emergency',
      });

      const createdMovement = {
        id: 'mov-2',
        fundId,
        type: 'withdrawal' as const,
        amountPaise: 500000,
        movementDate: new Date(),
        note: 'Doctor consultation',
      };
      prismaMock.fundMovement.create.mockResolvedValue(createdMovement);

      const result = await service.addMovement(
        householdId,
        fundId,
        'withdrawal',
        500000,
        'Doctor consultation',
      );

      expect(prismaMock.fundMovement.create).toHaveBeenCalledWith({
        data: {
          fundId,
          type: 'withdrawal',
          amountPaise: 500000,
          movementDate: expect.any(Date),
          note: 'Doctor consultation',
        },
      });
      expect(result).toEqual(createdMovement);
    });

    it('throws NotFoundException when the sinking fund does not exist', async () => {
      prismaMock.sinkingFund.findUnique.mockResolvedValue(null);

      await expect(
        service.addMovement(householdId, 'non-existent-fund', 'contribution', 100000),
      ).rejects.toThrow(new NotFoundException('Sinking fund not found.'));

      expect(prismaMock.fundMovement.create).not.toHaveBeenCalled();
    });

    it('throws ForbiddenException when fund belongs to a different household (cross-tenant rejection)', async () => {
      prismaMock.sinkingFund.findUnique.mockResolvedValue({
        id: fundId,
        householdId: otherHouseholdId,
        name: 'Other Household Fund',
      });

      await expect(
        service.addMovement(householdId, fundId, 'withdrawal', 100000, 'Unauthorized withdrawal'),
      ).rejects.toThrow(ForbiddenException);

      expect(prismaMock.fundMovement.create).not.toHaveBeenCalled();
    });
  });
});
