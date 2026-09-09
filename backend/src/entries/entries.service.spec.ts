import { ForbiddenException } from '@nestjs/common';
import { EntriesService } from './entries.service';

describe('EntriesService - Multi-Household Tenant Isolation', () => {
  let service: EntriesService;
  let mockPrisma: any;

  beforeEach(() => {
    mockPrisma = {
      category: {
        count: jest.fn().mockResolvedValue(10),
        findUnique: jest.fn().mockResolvedValue({ id: 'cat-1' }),
        create: jest.fn(),
      },
      entry: {
        findUnique: jest.fn(),
        create: jest.fn(),
        update: jest.fn(),
        findMany: jest.fn(),
      },
    };

    service = new EntriesService(mockPrisma);
  });

  it('allows user in Household A to create an entry', async () => {
    mockPrisma.entry.findUnique.mockResolvedValue(null);
    mockPrisma.entry.create.mockResolvedValue({
      id: 'entry-101',
      householdId: 'household-A',
      amountPaise: 50000,
    });

    const result = await service.upsertBatch(
      'household-A',
      [
        {
          id: 'entry-101',
          categoryId: 'cat-1',
          kind: 'spending',
          entryDate: new Date().toISOString(),
          amountPaise: 50000,
        },
      ],
      'user-A',
    );

    expect(result.synced).toBe(1);
    expect(result.failed).toBe(0);
    expect(mockPrisma.entry.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          id: 'entry-101',
          householdId: 'household-A',
          amountPaise: 50000,
        }),
      }),
    );
  });

  it('allows user in Household A to update their own existing entry', async () => {
    mockPrisma.entry.findUnique.mockResolvedValue({
      id: 'entry-101',
      householdId: 'household-A',
      amountPaise: 50000,
      version: 1,
    });
    mockPrisma.entry.update.mockResolvedValue({
      id: 'entry-101',
      householdId: 'household-A',
      amountPaise: 60000,
      version: 2,
    });

    const result = await service.upsertBatch(
      'household-A',
      [
        {
          id: 'entry-101',
          categoryId: 'cat-1',
          kind: 'spending',
          entryDate: new Date().toISOString(),
          amountPaise: 60000,
          version: 2,
        },
      ],
      'user-A',
    );

    expect(result.synced).toBe(1);
    expect(result.failed).toBe(0);
    expect(mockPrisma.entry.update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: 'entry-101' },
        data: expect.objectContaining({ amountPaise: 60000 }),
      }),
    );
  });

  it('rejects attempt by user in Household B to update Household A entry ID', async () => {
    mockPrisma.entry.findUnique.mockResolvedValue({
      id: 'entry-101',
      householdId: 'household-A',
      amountPaise: 50000,
      version: 1,
    });

    const result = await service.upsertBatch(
      'household-B', // User B is in Household B
      [
        {
          id: 'entry-101', // Targeting entry from Household A
          categoryId: 'cat-1',
          kind: 'spending',
          entryDate: new Date().toISOString(),
          amountPaise: 999999,
        },
      ],
      'user-B',
    );

    expect(result.synced).toBe(0);
    expect(result.failed).toBe(1);
    expect(mockPrisma.entry.update).not.toHaveBeenCalled();
    expect(mockPrisma.entry.create).not.toHaveBeenCalled();
  });
});
