import { NotFoundException, ForbiddenException } from '@nestjs/common';
import { SavingService } from './saving.service';

describe('SavingService', () => {
  let service: SavingService;
  let prismaMock: any;

  const householdId = 'household-123';
  const otherHouseholdId = 'household-999';
  const goalId = 'goal-abc';

  beforeEach(() => {
    prismaMock = {
      savingGoal: {
        findMany: jest.fn(),
        create: jest.fn(),
        findUnique: jest.fn(),
      },
      goalContribution: {
        create: jest.fn(),
      },
    };

    service = new SavingService(prismaMock);
  });

  describe('findAll', () => {
    it('scopes query to householdId and archivedAt: null, calculating lifetime and progress fraction accurately', async () => {
      prismaMock.savingGoal.findMany.mockResolvedValue([
        {
          id: 'goal-1',
          householdId,
          bucket: 'emergency',
          name: 'Emergency Fund',
          targetPaise: BigInt(10000000), // ₹1,00,000
          monthlyBudgetPaise: BigInt(1000000), // ₹10,000
          archivedAt: null,
          contributions: [
            { id: 'c-1', goalId: 'goal-1', amountPaise: BigInt(2000000), note: 'Initial deposit' }, // ₹20,000
            { id: 'c-2', goalId: 'goal-1', amountPaise: BigInt(3000000), note: 'Bonus contribution' }, // ₹30,000
          ],
        },
        {
          id: 'goal-2',
          householdId,
          bucket: 'wealth',
          name: 'General Investments',
          targetPaise: null, // No fixed target
          monthlyBudgetPaise: BigInt(500000), // ₹5,000
          archivedAt: null,
          contributions: [
            { id: 'c-3', goalId: 'goal-2', amountPaise: BigInt(500000), note: 'Monthly SIP' },
          ],
        },
        {
          id: 'goal-3',
          householdId,
          bucket: 'vacation',
          name: 'Summer Trip',
          targetPaise: BigInt(5000000), // ₹50,000
          monthlyBudgetPaise: BigInt(500000),
          archivedAt: null,
          contributions: [], // No contributions yet
        },
      ]);

      const goals = await service.findAll(householdId);

      expect(prismaMock.savingGoal.findMany).toHaveBeenCalledTimes(1);
      expect(prismaMock.savingGoal.findMany).toHaveBeenCalledWith({
        where: { householdId, archivedAt: null },
        include: { contributions: true },
      });

      expect(goals).toHaveLength(3);

      // Goal 1: target=10000000, lifetime=5000000 => progressFraction=0.5
      const g1 = goals[0];
      expect(g1.id).toBe('goal-1');
      expect(g1.bucket).toBe('emergency');
      expect(g1.name).toBe('Emergency Fund');
      expect(g1.targetPaise).toBe(10000000);
      expect(g1.monthlyBudgetPaise).toBe(1000000);
      expect(g1.lifetimeContributedPaise).toBe(5000000);
      expect(g1.progressFraction).toBe(0.5);
      expect(g1.contributions).toHaveLength(2);
      expect(g1.contributions[0].amountPaise).toBe(2000000);
      expect(typeof g1.contributions[0].amountPaise).toBe('number');

      // Goal 2: target=null => progressFraction=null
      const g2 = goals[1];
      expect(g2.id).toBe('goal-2');
      expect(g2.targetPaise).toBeNull();
      expect(g2.monthlyBudgetPaise).toBe(500000);
      expect(g2.lifetimeContributedPaise).toBe(500000);
      expect(g2.progressFraction).toBeNull();

      // Goal 3: target=5000000, no contributions => lifetime=0, progressFraction=0
      const g3 = goals[2];
      expect(g3.id).toBe('goal-3');
      expect(g3.targetPaise).toBe(5000000);
      expect(g3.lifetimeContributedPaise).toBe(0);
      expect(g3.progressFraction).toBe(0);
      expect(g3.contributions).toEqual([]);
    });

    it('returns an empty array when no active saving goals exist for the household', async () => {
      prismaMock.savingGoal.findMany.mockResolvedValue([]);

      const goals = await service.findAll(householdId);

      expect(prismaMock.savingGoal.findMany).toHaveBeenCalledWith({
        where: { householdId, archivedAt: null },
        include: { contributions: true },
      });
      expect(goals).toEqual([]);
    });
  });

  describe('createGoal', () => {
    it('creates a goal scoped to householdId with rounded monthly budget and target', async () => {
      const createdRecord = {
        id: 'new-goal-1',
        householdId,
        bucket: 'education',
        name: 'College Fund',
        monthlyBudgetPaise: 2500000,
        targetPaise: 50000000,
      };
      prismaMock.savingGoal.create.mockResolvedValue(createdRecord);

      const result = await service.createGoal(
        householdId,
        'education',
        'College Fund',
        2500000.4,
        49999999.6,
      );

      expect(prismaMock.savingGoal.create).toHaveBeenCalledTimes(1);
      expect(prismaMock.savingGoal.create).toHaveBeenCalledWith({
        data: {
          householdId,
          bucket: 'education',
          name: 'College Fund',
          monthlyBudgetPaise: 2500000, // Math.round(2500000.4)
          targetPaise: 50000000, // Math.round(49999999.6)
        },
      });
      expect(result).toEqual(createdRecord);
    });

    it('creates a goal without a target, setting targetPaise to null', async () => {
      const createdRecord = {
        id: 'new-goal-2',
        householdId,
        bucket: 'wealth',
        name: 'Open Ended Savings',
        monthlyBudgetPaise: 1000000,
        targetPaise: null,
      };
      prismaMock.savingGoal.create.mockResolvedValue(createdRecord);

      const result = await service.createGoal(
        householdId,
        'wealth',
        'Open Ended Savings',
        1000000,
      );

      expect(prismaMock.savingGoal.create).toHaveBeenCalledWith({
        data: {
          householdId,
          bucket: 'wealth',
          name: 'Open Ended Savings',
          monthlyBudgetPaise: 1000000,
          targetPaise: null,
        },
      });
      expect(result).toEqual(createdRecord);
    });
  });

  describe('addContribution', () => {
    it('adds a contribution when goal belongs to the household, rounding amountPaise', async () => {
      prismaMock.savingGoal.findUnique.mockResolvedValue({
        id: goalId,
        householdId,
        name: 'Emergency Fund',
      });

      const createdContribution = {
        id: 'contrib-1',
        goalId,
        amountPaise: 500000,
        contributionDate: new Date(),
        note: 'Monthly deposit',
      };
      prismaMock.goalContribution.create.mockResolvedValue(createdContribution);

      const result = await service.addContribution(
        householdId,
        goalId,
        500000.2,
        'Monthly deposit',
      );

      expect(prismaMock.savingGoal.findUnique).toHaveBeenCalledWith({ where: { id: goalId } });
      expect(prismaMock.goalContribution.create).toHaveBeenCalledWith({
        data: {
          goalId,
          amountPaise: 500000, // Math.round(500000.2)
          contributionDate: expect.any(Date),
          note: 'Monthly deposit',
        },
      });
      expect(result).toEqual(createdContribution);
    });

    it('throws NotFoundException when the saving goal does not exist', async () => {
      prismaMock.savingGoal.findUnique.mockResolvedValue(null);

      await expect(
        service.addContribution(householdId, 'non-existent-goal', 100000),
      ).rejects.toThrow(new NotFoundException('Saving goal not found.'));

      expect(prismaMock.goalContribution.create).not.toHaveBeenCalled();
    });

    it('throws ForbiddenException when goal belongs to a different household (cross-tenant rejection)', async () => {
      prismaMock.savingGoal.findUnique.mockResolvedValue({
        id: goalId,
        householdId: otherHouseholdId,
        name: 'Victim Goal',
      });

      await expect(
        service.addContribution(householdId, goalId, 100000, 'Malicious note'),
      ).rejects.toThrow(ForbiddenException);

      expect(prismaMock.goalContribution.create).not.toHaveBeenCalled();
    });
  });
});
