jest.mock('firebase-admin/app', () => ({
  initializeApp: jest.fn(),
  cert: jest.fn(),
  getApps: jest.fn(() => [{ name: 'DEFAULT' }]),
}));

jest.mock('firebase-admin/auth', () => ({
  getAuth: jest.fn(() => ({
    verifyIdToken: jest.fn(),
  })),
}));

import { Test, TestingModule } from '@nestjs/testing';
import { NotFoundException, ForbiddenException, BadRequestException } from '@nestjs/common';
import { HouseholdsService } from './households.service';
import { AuthService } from '../auth/auth.service';

describe('HouseholdsService', () => {
  let service: HouseholdsService;
  let prismaMock: any;
  let authServiceMock: any;

  beforeEach(async () => {
    prismaMock = {
      user: {
        findUnique: jest.fn(),
        findMany: jest.fn(),
        update: jest.fn(),
        updateMany: jest.fn(),
      },
      household: {
        create: jest.fn(),
        findUnique: jest.fn(),
        update: jest.fn(),
        delete: jest.fn(),
      },
      category: {
        createMany: jest.fn(),
        deleteMany: jest.fn(),
      },
      monthSnapshot: { deleteMany: jest.fn() },
      budget: { deleteMany: jest.fn() },
      entry: { deleteMany: jest.fn() },
      account: { deleteMany: jest.fn() },
      creditCard: { deleteMany: jest.fn() },
      sinkingFund: { deleteMany: jest.fn() },
      savingGoal: { deleteMany: jest.fn() },
      receivable: { deleteMany: jest.fn() },
      plannedBill: { deleteMany: jest.fn() },
      reserveLine: { deleteMany: jest.fn() },
      annual_targets: { deleteMany: jest.fn() },
      $transaction: jest.fn((callback) => callback(prismaMock)),
    };

    authServiceMock = {
      issueTokens: jest.fn().mockResolvedValue({
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
        refreshTokenFamily: 'family-id',
      }),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        HouseholdsService,
        { provide: 'PRISMA', useValue: prismaMock },
        { provide: AuthService, useValue: authServiceMock },
      ],
    }).compile();

    service = module.get<HouseholdsService>(HouseholdsService);
  });

  describe('create', () => {
    it('should generate a new household ID only upon calling create, set owner, and seed categories', async () => {
      const user = { id: 'usr-1', email: 'owner@test.com', displayName: 'Owner' };
      prismaMock.user.findUnique.mockResolvedValue(user);
      prismaMock.household.create.mockImplementation(({ data }) => Promise.resolve({ ...data }));
      prismaMock.user.update.mockResolvedValue({ ...user, household_id: 'new-id' });

      const result = await service.create('usr-1', 'My Custom Family');

      expect(prismaMock.household.create).toHaveBeenCalledTimes(1);
      const createdData = prismaMock.household.create.mock.calls[0][0].data;
      expect(createdData.id).toBeDefined();
      expect(createdData.name).toBe('My Custom Family');
      expect(createdData.ownerId).toBe('usr-1');

      expect(prismaMock.user.update).toHaveBeenCalledWith({
        where: { id: 'usr-1' },
        data: { household_id: createdData.id },
      });
      expect(prismaMock.category.createMany).toHaveBeenCalled();
      expect(result.household.isOwner).toBe(true);
      expect(result.tokens.accessToken).toBe('access-token');
    });
  });

  describe('join', () => {
    it('should throw NotFoundException if household ID is not found', async () => {
      prismaMock.household.findUnique.mockResolvedValue(null);
      await expect(service.join('usr-2', 'non-existent-id')).rejects.toThrow(NotFoundException);
    });

    it('should associate user with household and return members', async () => {
      const household = { id: 'hsh-100', name: 'Existing Household', ownerId: 'usr-1' };
      const user = { id: 'usr-2', email: 'member@test.com', displayName: 'Member' };
      prismaMock.household.findUnique.mockResolvedValue(household);
      prismaMock.user.findUnique.mockResolvedValue(user);
      prismaMock.user.update.mockResolvedValue({ ...user, household_id: 'hsh-100' });
      prismaMock.user.findMany.mockResolvedValue([
        { id: 'usr-1', email: 'owner@test.com', displayName: 'Owner' },
        { id: 'usr-2', email: 'member@test.com', displayName: 'Member' },
      ]);

      const result = await service.join('usr-2', 'hsh-100');

      expect(prismaMock.user.update).toHaveBeenCalledWith({
        where: { id: 'usr-2' },
        data: { household_id: 'hsh-100' },
      });
      expect(result.household.isOwner).toBe(false);
      expect(result.household.members.length).toBe(2);
      expect(result.household.members[0].role).toBe('owner');
      expect(result.household.members[1].role).toBe('member');
    });
  });

  describe('findMe', () => {
    it('should return null if user has no household', async () => {
      prismaMock.user.findUnique.mockResolvedValue({ id: 'usr-1', household_id: null });
      const result = await service.findMe('usr-1');
      expect(result.household).toBeNull();
    });

    it('should list all joined members with their roles', async () => {
      const user = { id: 'usr-1', household_id: 'hsh-1', displayName: 'Owner' };
      const household = { id: 'hsh-1', name: 'My Household', ownerId: 'usr-1' };
      prismaMock.user.findUnique.mockResolvedValue(user);
      prismaMock.household.findUnique.mockResolvedValue(household);
      prismaMock.user.findMany.mockResolvedValue([
        { id: 'usr-1', email: 'owner@test.com', displayName: 'Owner' },
        { id: 'usr-2', email: 'member@test.com', displayName: 'Member' },
      ]);

      const result = await service.findMe('usr-1');
      expect(result.household).not.toBeNull();
      expect(result.household!.isOwner).toBe(true);
      expect(result.household!.members.length).toBe(2);
      expect(result.household!.members.find((m: any) => m.id === 'usr-1')?.role).toBe('owner');
      expect(result.household!.members.find((m: any) => m.id === 'usr-2')?.role).toBe('member');
    });
  });

  describe('updateName', () => {
    it('should throw ForbiddenException if user is not the owner', async () => {
      prismaMock.user.findUnique.mockResolvedValue({ id: 'usr-2', household_id: 'hsh-1' });
      prismaMock.household.findUnique.mockResolvedValue({ id: 'hsh-1', ownerId: 'usr-1' });

      await expect(service.updateName('usr-2', 'New Name')).rejects.toThrow(ForbiddenException);
    });

    it('should allow owner to update household name', async () => {
      prismaMock.user.findUnique.mockResolvedValue({ id: 'usr-1', household_id: 'hsh-1' });
      prismaMock.household.findUnique.mockResolvedValue({ id: 'hsh-1', ownerId: 'usr-1' });
      prismaMock.household.update.mockResolvedValue({ id: 'hsh-1', name: 'New Name', ownerId: 'usr-1' });

      const result = await service.updateName('usr-1', 'New Name');
      expect(result.name).toBe('New Name');
    });
  });

  describe('deleteHousehold', () => {
    it('should throw ForbiddenException if non-owner attempts to delete household', async () => {
      prismaMock.user.findUnique.mockResolvedValue({ id: 'usr-2', household_id: 'hsh-1' });
      prismaMock.household.findUnique.mockResolvedValue({ id: 'hsh-1', ownerId: 'usr-1' });

      await expect(service.deleteHousehold('usr-2')).rejects.toThrow(ForbiddenException);
    });

    it('should allow owner to delete household, disassociating all members and cleaning data', async () => {
      prismaMock.user.findUnique.mockResolvedValue({ id: 'usr-1', household_id: 'hsh-1' });
      prismaMock.household.findUnique.mockResolvedValue({ id: 'hsh-1', ownerId: 'usr-1' });

      const result = await service.deleteHousehold('usr-1');

      expect(prismaMock.user.updateMany).toHaveBeenCalledWith({
        where: { household_id: 'hsh-1' },
        data: { household_id: null },
      });
      expect(prismaMock.household.delete).toHaveBeenCalledWith({
        where: { id: 'hsh-1' },
      });
      expect(result.success).toBe(true);
    });
  });

  describe('removeMember', () => {
    it('should throw ForbiddenException if non-owner attempts to remove member', async () => {
      prismaMock.user.findUnique.mockResolvedValue({ id: 'usr-2', household_id: 'hsh-1' });
      prismaMock.household.findUnique.mockResolvedValue({ id: 'hsh-1', ownerId: 'usr-1' });

      await expect(service.removeMember('usr-2', 'usr-3')).rejects.toThrow(ForbiddenException);
    });

    it('should throw BadRequestException if owner attempts to remove themselves via member removal', async () => {
      prismaMock.user.findUnique.mockResolvedValue({ id: 'usr-1', household_id: 'hsh-1' });
      prismaMock.household.findUnique.mockResolvedValue({ id: 'hsh-1', ownerId: 'usr-1' });

      await expect(service.removeMember('usr-1', 'usr-1')).rejects.toThrow(BadRequestException);
    });

    it('should allow owner to remove member, isolating only that member', async () => {
      prismaMock.user.findUnique.mockImplementation(({ where }) => {
        if (where.id === 'usr-1') return Promise.resolve({ id: 'usr-1', household_id: 'hsh-1' });
        if (where.id === 'usr-2') return Promise.resolve({ id: 'usr-2', household_id: 'hsh-1', displayName: 'Member 2' });
        return null;
      });
      prismaMock.household.findUnique.mockResolvedValue({ id: 'hsh-1', ownerId: 'usr-1' });

      const result = await service.removeMember('usr-1', 'usr-2');

      expect(prismaMock.user.update).toHaveBeenCalledWith({
        where: { id: 'usr-2' },
        data: { household_id: null },
      });
      expect(result.success).toBe(true);
    });
  });
});
