import { NotFoundException, ForbiddenException } from '@nestjs/common';
import { AccountsService } from './accounts.service';

describe('AccountsService', () => {
  let service: AccountsService;
  let prismaMock: any;

  const householdId = 'household-123';
  const otherHouseholdId = 'household-999';
  const accountId = 'account-abc';

  beforeEach(() => {
    prismaMock = {
      account: {
        findMany: jest.fn(),
        create: jest.fn(),
        findUnique: jest.fn(),
        update: jest.fn(),
      },
    };

    service = new AccountsService(prismaMock);
  });

  describe('findAll', () => {
    it('scopes query to householdId, filters isActive: true, and orders by sortOrder asc', async () => {
      prismaMock.account.findMany.mockResolvedValue([
        {
          id: 'acc-1',
          householdId,
          name: 'Main Checking',
          type: 'bank',
          currentBalancePaise: BigInt(250000),
          isActive: true,
          sortOrder: 1,
        },
        {
          id: 'acc-2',
          householdId,
          name: 'Wallet Cash',
          type: 'cash',
          currentBalancePaise: BigInt(5000),
          isActive: true,
          sortOrder: 2,
        },
      ]);

      const accounts = await service.findAll(householdId);

      expect(prismaMock.account.findMany).toHaveBeenCalledTimes(1);
      expect(prismaMock.account.findMany).toHaveBeenCalledWith({
        where: { householdId, isActive: true },
        orderBy: { sortOrder: 'asc' },
      });

      expect(accounts).toHaveLength(2);
      expect(accounts[0]).toEqual({
        id: 'acc-1',
        householdId,
        name: 'Main Checking',
        type: 'bank',
        currentBalancePaise: 250000,
        isActive: true,
        sortOrder: 1,
      });
      expect(typeof accounts[0].currentBalancePaise).toBe('number');
      expect(accounts[1].currentBalancePaise).toBe(5000);
      expect(typeof accounts[1].currentBalancePaise).toBe('number');
    });

    it('returns an empty array when no active accounts match householdId', async () => {
      prismaMock.account.findMany.mockResolvedValue([]);

      const accounts = await service.findAll(householdId);

      expect(prismaMock.account.findMany).toHaveBeenCalledWith({
        where: { householdId, isActive: true },
        orderBy: { sortOrder: 'asc' },
      });
      expect(accounts).toEqual([]);
    });
  });

  describe('createAccount', () => {
    it('creates an account scoped to householdId with bank type and balance', async () => {
      const createdRecord = {
        id: 'new-acc-1',
        householdId,
        name: 'Savings Account',
        type: 'bank' as const,
        currentBalancePaise: 100000,
        createdAt: new Date(),
        updatedAt: new Date(),
      };
      prismaMock.account.create.mockResolvedValue(createdRecord);

      const result = await service.createAccount(householdId, 'Savings Account', 'bank', 100000);

      expect(prismaMock.account.create).toHaveBeenCalledTimes(1);
      expect(prismaMock.account.create).toHaveBeenCalledWith({
        data: {
          householdId,
          name: 'Savings Account',
          type: 'bank',
          currentBalancePaise: 100000,
        },
      });
      expect(result).toEqual(createdRecord);
    });

    it('creates an account with cash type and zero initial balance', async () => {
      const createdRecord = {
        id: 'new-acc-2',
        householdId,
        name: 'Petty Cash',
        type: 'cash' as const,
        currentBalancePaise: 0,
      };
      prismaMock.account.create.mockResolvedValue(createdRecord);

      const result = await service.createAccount(householdId, 'Petty Cash', 'cash', 0);

      expect(prismaMock.account.create).toHaveBeenCalledWith({
        data: {
          householdId,
          name: 'Petty Cash',
          type: 'cash',
          currentBalancePaise: 0,
        },
      });
      expect(result).toEqual(createdRecord);
    });
  });

  describe('updateBalance', () => {
    it('updates balance when account exists and belongs to the requested household', async () => {
      prismaMock.account.findUnique.mockResolvedValue({
        id: accountId,
        householdId,
        name: 'Main Checking',
        type: 'bank',
        currentBalancePaise: BigInt(250000),
      });

      const updatedRecord = {
        id: accountId,
        householdId,
        name: 'Main Checking',
        type: 'bank',
        currentBalancePaise: 300000,
      };
      prismaMock.account.update.mockResolvedValue(updatedRecord);

      const result = await service.updateBalance(householdId, accountId, 300000);

      expect(prismaMock.account.findUnique).toHaveBeenCalledWith({ where: { id: accountId } });
      expect(prismaMock.account.update).toHaveBeenCalledWith({
        where: { id: accountId },
        data: { currentBalancePaise: 300000 },
      });
      expect(result).toEqual(updatedRecord);
    });

    it('throws NotFoundException when account does not exist', async () => {
      prismaMock.account.findUnique.mockResolvedValue(null);

      await expect(service.updateBalance(householdId, 'non-existent-id', 50000)).rejects.toThrow(
        new NotFoundException('Account not found.'),
      );

      expect(prismaMock.account.update).not.toHaveBeenCalled();
    });

    it('throws ForbiddenException when account belongs to a different household (cross-tenant rejection)', async () => {
      prismaMock.account.findUnique.mockResolvedValue({
        id: accountId,
        householdId: otherHouseholdId,
        name: 'Victim Account',
        type: 'bank',
        currentBalancePaise: BigInt(999999),
      });

      await expect(service.updateBalance(householdId, accountId, 0)).rejects.toThrow(
        ForbiddenException,
      );

      expect(prismaMock.account.update).not.toHaveBeenCalled();
    });
  });
});
