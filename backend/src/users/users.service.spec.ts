import { NotFoundException } from '@nestjs/common';
import { UsersService } from './users.service';

describe('UsersService', () => {
  let service: UsersService;
  let prismaMock: any;
  let txMock: any;

  const userId = 'user-test-123';
  const otherUserId = 'user-test-456';
  const householdId = 'household-xyz-789';

  beforeEach(() => {
    txMock = {
      monthSnapshot: { deleteMany: jest.fn().mockResolvedValue({ count: 1 }) },
      syncTombstone: { deleteMany: jest.fn().mockResolvedValue({ count: 1 }) },
      entry: { deleteMany: jest.fn().mockResolvedValue({ count: 5 }) },
      budget: { deleteMany: jest.fn().mockResolvedValue({ count: 3 }) },
      category: { deleteMany: jest.fn().mockResolvedValue({ count: 10 }) },
      account: { deleteMany: jest.fn().mockResolvedValue({ count: 2 }) },
      cardTransaction: { deleteMany: jest.fn().mockResolvedValue({ count: 4 }) },
      creditCard: { deleteMany: jest.fn().mockResolvedValue({ count: 1 }) },
      goalContribution: { deleteMany: jest.fn().mockResolvedValue({ count: 2 }) },
      savingGoal: { deleteMany: jest.fn().mockResolvedValue({ count: 1 }) },
      fundMovement: { deleteMany: jest.fn().mockResolvedValue({ count: 1 }) },
      sinkingFund: { deleteMany: jest.fn().mockResolvedValue({ count: 1 }) },
      receivable: { deleteMany: jest.fn().mockResolvedValue({ count: 1 }) },
      plannedBill: { deleteMany: jest.fn().mockResolvedValue({ count: 1 }) },
      reserveLine: { deleteMany: jest.fn().mockResolvedValue({ count: 1 }) },
      annual_targets: { deleteMany: jest.fn().mockResolvedValue({ count: 1 }) },
      household: { delete: jest.fn().mockResolvedValue({ id: householdId }) },
    };

    prismaMock = {
      user: {
        findUnique: jest.fn(),
        findMany: jest.fn(),
        update: jest.fn(),
        delete: jest.fn(),
      },
      household: {
        findUnique: jest.fn(),
        update: jest.fn(),
        delete: jest.fn(),
      },
      $transaction: jest.fn(async (callback) => callback(txMock)),
    };

    service = new UsersService(prismaMock);
  });

  // ─── findOne ─────────────────────────────────────────────────────────────────

  describe('findOne', () => {
    it('returns sanitized user profile when user exists', async () => {
      const mockUser = {
        id: userId,
        email: 'user@example.test',
        displayName: 'Test User',
        createdAt: new Date('2026-01-01T00:00:00Z'),
      };
      prismaMock.user.findUnique.mockResolvedValue(mockUser);

      const result = await service.findOne(userId);

      expect(prismaMock.user.findUnique).toHaveBeenCalledWith({
        where: { id: userId },
        select: {
          id: true,
          email: true,
          displayName: true,
          createdAt: true,
        },
      });
      expect(result).toEqual(mockUser);
    });

    it('throws NotFoundException when user does not exist', async () => {
      prismaMock.user.findUnique.mockResolvedValue(null);

      await expect(service.findOne('non-existent')).rejects.toThrow(
        new NotFoundException('User non-existent not found.'),
      );
    });
  });

  // ─── updateDisplayName ───────────────────────────────────────────────────────

  describe('updateDisplayName', () => {
    it('updates displayName and returns sanitized fields', async () => {
      const updatedUser = {
        id: userId,
        email: 'user@example.test',
        displayName: 'Updated Name',
      };
      prismaMock.user.update.mockResolvedValue(updatedUser);

      const result = await service.updateDisplayName(userId, 'Updated Name');

      expect(prismaMock.user.update).toHaveBeenCalledWith({
        where: { id: userId },
        data: { displayName: 'Updated Name' },
        select: {
          id: true,
          email: true,
          displayName: true,
        },
      });
      expect(result).toEqual(updatedUser);
    });
  });

  // ─── deleteAccount ───────────────────────────────────────────────────────────

  describe('deleteAccount', () => {
    it('throws NotFoundException when user does not exist, verifying no deletions occur', async () => {
      prismaMock.user.findUnique.mockResolvedValue(null);

      await expect(service.deleteAccount('non-existent')).rejects.toThrow(
        new NotFoundException('User not found.'),
      );

      expect(prismaMock.user.delete).not.toHaveBeenCalled();
      expect(prismaMock.household.delete).not.toHaveBeenCalled();
      expect(prismaMock.$transaction).not.toHaveBeenCalled();
    });

    it('deletes user record directly when user has no household', async () => {
      prismaMock.user.findUnique.mockResolvedValue({
        id: userId,
        household_id: null,
      });
      prismaMock.user.delete.mockResolvedValue({ id: userId });

      const result = await service.deleteAccount(userId);

      expect(prismaMock.user.findMany).not.toHaveBeenCalled();
      expect(prismaMock.$transaction).not.toHaveBeenCalled();
      expect(prismaMock.household.delete).not.toHaveBeenCalled();
      expect(prismaMock.user.delete).toHaveBeenCalledWith({ where: { id: userId } });
      expect(result).toEqual({
        success: true,
        message: 'User account and associated data successfully deleted.',
      });
    });

    describe('Sole member scenario', () => {
      it('deletes all child tables using the exact householdId in where clauses, with no unscoped deletes', async () => {
        prismaMock.user.findUnique.mockResolvedValue({
          id: userId,
          household_id: householdId,
        });
        // No other members in the household
        prismaMock.user.findMany.mockResolvedValue([]);
        prismaMock.user.delete.mockResolvedValue({ id: userId });

        const result = await service.deleteAccount(userId);

        expect(prismaMock.user.findMany).toHaveBeenCalledWith({
          where: {
            household_id: householdId,
            id: { not: userId },
          },
          orderBy: { createdAt: 'asc' },
        });

        // Verify interactive transaction executed
        expect(prismaMock.$transaction).toHaveBeenCalledTimes(1);

        // Verify EVERY delete operation strictly scopes to the exact householdId
        expect(txMock.monthSnapshot.deleteMany).toHaveBeenCalledWith({ where: { householdId } });
        expect(txMock.syncTombstone.deleteMany).toHaveBeenCalledWith({ where: { householdId } });
        expect(txMock.entry.deleteMany).toHaveBeenCalledWith({ where: { householdId } });
        expect(txMock.budget.deleteMany).toHaveBeenCalledWith({ where: { householdId } });
        expect(txMock.category.deleteMany).toHaveBeenCalledWith({ where: { householdId } });
        expect(txMock.account.deleteMany).toHaveBeenCalledWith({ where: { householdId } });
        expect(txMock.cardTransaction.deleteMany).toHaveBeenCalledWith({
          where: { card: { householdId } },
        });
        expect(txMock.creditCard.deleteMany).toHaveBeenCalledWith({ where: { householdId } });
        expect(txMock.goalContribution.deleteMany).toHaveBeenCalledWith({
          where: { goal: { householdId } },
        });
        expect(txMock.savingGoal.deleteMany).toHaveBeenCalledWith({ where: { householdId } });
        expect(txMock.fundMovement.deleteMany).toHaveBeenCalledWith({
          where: { fund: { householdId } },
        });
        expect(txMock.sinkingFund.deleteMany).toHaveBeenCalledWith({ where: { householdId } });
        expect(txMock.receivable.deleteMany).toHaveBeenCalledWith({ where: { householdId } });
        expect(txMock.plannedBill.deleteMany).toHaveBeenCalledWith({ where: { householdId } });
        expect(txMock.reserveLine.deleteMany).toHaveBeenCalledWith({ where: { householdId } });
        expect(txMock.annual_targets.deleteMany).toHaveBeenCalledWith({
          where: { household_id: householdId },
        });
        expect(txMock.household.delete).toHaveBeenCalledWith({ where: { id: householdId } });

        // Verify user record deleted
        expect(prismaMock.user.delete).toHaveBeenCalledWith({ where: { id: userId } });
        expect(result).toEqual({
          success: true,
          message: 'User account and associated data successfully deleted.',
        });
      });
    });

    describe('Owner with remaining members scenario', () => {
      it('reassigns household ownership to the oldest remaining member, never deletes the household or its data', async () => {
        prismaMock.user.findUnique.mockResolvedValue({
          id: userId,
          household_id: householdId,
        });

        const otherMembers = [
          { id: otherUserId, createdAt: new Date('2026-01-02T00:00:00Z') },
          { id: 'user-third', createdAt: new Date('2026-02-01T00:00:00Z') },
        ];
        prismaMock.user.findMany.mockResolvedValue(otherMembers);

        // User is the owner of the household
        prismaMock.household.findUnique.mockResolvedValue({
          id: householdId,
          ownerId: userId,
        });
        prismaMock.household.update.mockResolvedValue({
          id: householdId,
          ownerId: otherUserId,
        });
        prismaMock.user.delete.mockResolvedValue({ id: userId });

        const result = await service.deleteAccount(userId);

        // Verified: Reassigned ownership to otherMembers[0].id
        expect(prismaMock.household.findUnique).toHaveBeenCalledWith({ where: { id: householdId } });
        expect(prismaMock.household.update).toHaveBeenCalledWith({
          where: { id: householdId },
          data: { ownerId: otherUserId },
        });

        // CRITICAL: Verify household.delete is NEVER called
        expect(prismaMock.household.delete).not.toHaveBeenCalled();
        expect(txMock.household.delete).not.toHaveBeenCalled();

        // CRITICAL: Verify transaction deleting child data was NOT called
        expect(prismaMock.$transaction).not.toHaveBeenCalled();
        expect(txMock.entry.deleteMany).not.toHaveBeenCalled();
        expect(txMock.account.deleteMany).not.toHaveBeenCalled();

        // Verify user was deleted
        expect(prismaMock.user.delete).toHaveBeenCalledWith({ where: { id: userId } });
        expect(result).toEqual({
          success: true,
          message: 'User account and associated data successfully deleted.',
        });
      });
    });

    describe('Non-owner with remaining members scenario', () => {
      it('deletes user without modifying or deleting the household', async () => {
        prismaMock.user.findUnique.mockResolvedValue({
          id: userId,
          household_id: householdId,
        });

        const otherMembers = [{ id: otherUserId, createdAt: new Date('2026-01-02T00:00:00Z') }];
        prismaMock.user.findMany.mockResolvedValue(otherMembers);

        // Someone else is the owner
        prismaMock.household.findUnique.mockResolvedValue({
          id: householdId,
          ownerId: otherUserId,
        });
        prismaMock.user.delete.mockResolvedValue({ id: userId });

        const result = await service.deleteAccount(userId);

        expect(prismaMock.household.findUnique).toHaveBeenCalledWith({ where: { id: householdId } });
        expect(prismaMock.household.update).not.toHaveBeenCalled();
        expect(prismaMock.household.delete).not.toHaveBeenCalled();
        expect(prismaMock.$transaction).not.toHaveBeenCalled();
        expect(prismaMock.user.delete).toHaveBeenCalledWith({ where: { id: userId } });
        expect(result).toEqual({
          success: true,
          message: 'User account and associated data successfully deleted.',
        });
      });
    });
  });
});
