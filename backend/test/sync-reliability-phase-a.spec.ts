import { SyncService } from '../src/sync/sync.service';
import { EntriesService } from '../src/entries/entries.service';

describe('Sync Reliability Fixes — Phase A (Audit 2026-09-29)', () => {
  const householdId = 'hh-reliability-test';
  const userId = 'user-reliability-test';

  let syncService: SyncService;
  let entriesService: EntriesService;
  let mockPrisma: any;
  let mockTx: any;

  beforeEach(() => {
    mockTx = {
      category: {
        count: jest.fn().mockResolvedValue(10),
        findMany: jest.fn().mockResolvedValue([{ id: 'cat-1', householdId, name: 'Food', kind: 'expense', sortOrder: 0, isSystem: false, archivedAt: null }]),
        findUnique: jest.fn().mockResolvedValue({ id: 'cat-1', householdId }),
        upsert: jest.fn().mockResolvedValue({}),
        updateMany: jest.fn().mockResolvedValue({ count: 1 }),
        createMany: jest.fn().mockResolvedValue({ count: 1 }),
      },
      account: {
        findMany: jest.fn().mockResolvedValue([]),
        findUnique: jest.fn().mockResolvedValue(null),
        findFirst: jest.fn().mockResolvedValue(null),
        upsert: jest.fn().mockResolvedValue({}),
      },
      creditCard: {
        findMany: jest.fn().mockResolvedValue([]),
        findUnique: jest.fn().mockResolvedValue(null),
        create: jest.fn().mockResolvedValue({}),
        upsert: jest.fn().mockResolvedValue({}),
      },
      cardTransaction: {
        findMany: jest.fn().mockResolvedValue([]),
        findUnique: jest.fn().mockResolvedValue(null),
        upsert: jest.fn().mockResolvedValue({}),
        deleteMany: jest.fn().mockResolvedValue({ count: 0 }),
      },
      plannedBill: {
        findMany: jest.fn().mockResolvedValue([]),
        findUnique: jest.fn().mockResolvedValue(null),
        findFirst: jest.fn().mockResolvedValue(null),
        upsert: jest.fn().mockResolvedValue({}),
        deleteMany: jest.fn().mockResolvedValue({ count: 0 }),
      },
      receivable: {
        findMany: jest.fn().mockResolvedValue([]),
        findUnique: jest.fn().mockResolvedValue(null),
        findFirst: jest.fn().mockResolvedValue(null),
        upsert: jest.fn().mockResolvedValue({}),
        deleteMany: jest.fn().mockResolvedValue({ count: 0 }),
      },
      savingGoal: {
        findMany: jest.fn().mockResolvedValue([]),
        findUnique: jest.fn().mockResolvedValue(null),
        upsert: jest.fn().mockResolvedValue({}),
      },
      goalContribution: {
        findMany: jest.fn().mockResolvedValue([]),
        findUnique: jest.fn().mockResolvedValue(null),
        upsert: jest.fn().mockResolvedValue({}),
        deleteMany: jest.fn().mockResolvedValue({ count: 0 }),
      },
      sinkingFund: {
        findMany: jest.fn().mockResolvedValue([]),
        findUnique: jest.fn().mockResolvedValue(null),
        upsert: jest.fn().mockResolvedValue({}),
      },
      fundMovement: {
        findMany: jest.fn().mockResolvedValue([]),
        findUnique: jest.fn().mockResolvedValue(null),
        upsert: jest.fn().mockResolvedValue({}),
        deleteMany: jest.fn().mockResolvedValue({ count: 0 }),
      },
      budget: {
        findMany: jest.fn().mockResolvedValue([]),
        findUnique: jest.fn().mockResolvedValue(null),
        findFirst: jest.fn().mockResolvedValue(null),
        upsert: jest.fn().mockResolvedValue({}),
        update: jest.fn().mockResolvedValue({}),
        deleteMany: jest.fn().mockResolvedValue({ count: 0 }),
      },
      reserveLine: {
        findMany: jest.fn().mockResolvedValue([]),
        findUnique: jest.fn().mockResolvedValue(null),
        upsert: jest.fn().mockResolvedValue({}),
        deleteMany: jest.fn().mockResolvedValue({ count: 0 }),
      },
      annual_targets: {
        findMany: jest.fn().mockResolvedValue([]),
        findUnique: jest.fn().mockResolvedValue(null),
        upsert: jest.fn().mockResolvedValue({}),
        deleteMany: jest.fn().mockResolvedValue({ count: 0 }),
      },
      entry: {
        findMany: jest.fn().mockResolvedValue([]),
        findUnique: jest.fn().mockResolvedValue(null),
        create: jest.fn().mockResolvedValue({}),
        update: jest.fn().mockResolvedValue({}),
        deleteMany: jest.fn().mockResolvedValue({ count: 0 }),
      },
      syncTombstone: {
        findMany: jest.fn().mockResolvedValue([]),
        upsert: jest.fn().mockResolvedValue({}),
      },
      monthSnapshot: {
        findUnique: jest.fn().mockResolvedValue(null),
        findMany: jest.fn().mockResolvedValue([]),
      },
      $queryRaw: jest.fn().mockResolvedValue([]),
    };

    mockPrisma = {
      ...mockTx,
      $transaction: jest.fn(async (cb: any) => cb(mockTx)),
    };

    entriesService = new EntriesService(mockPrisma);
    syncService = new SyncService(entriesService, mockPrisma);
  });

  it('Test 1: Non-existent accountId rejects that entry, but saves other valid entities in batch', async () => {
    // DB has cat-1, but no account missing-acc
    const payload = {
      accounts: [
        { id: 'acc-1', name: 'Primary Account', type: 'checking', currentBalancePaise: 50000 },
      ],
      creditCards: [
        { id: 'card-1', name: 'Platinum Card', limitPaise: 100000, statementDay: 1, dueDay: 15 },
      ],
      plannedBills: [
        { id: 'bill-1', name: 'Electric Bill', amountPaise: 3000, dueDate: '2026-04-10T00:00:00.000Z' },
      ],
      receivables: [
        { id: 'rec-1', personName: 'Alice', amountPaise: 1500, dueDate: '2026-04-12T00:00:00.000Z' },
      ],
      savingGoals: [
        { id: 'goal-1', bucket: 'SAVINGS', name: 'Vacation', targetPaise: 200000 },
      ],
      sinkingFunds: [
        { id: 'fund-1', name: 'Car Maintenance', openingReservePaise: 50000 },
      ],
      budgets: [
        { id: 'b-1', categoryId: 'cat-1', yearMonth: '2026-04', amountPaise: 10000 },
      ],
      entries: [
        {
          id: 'entry-bad',
          accountId: 'missing-acc',
          categoryId: 'cat-1',
          kind: 'spending',
          amountPaise: 500,
          entryDate: '2026-04-01T00:00:00.000Z',
        },
      ],
    };

    const res = await syncService.syncBatch(householdId, payload, userId);

    // Entry should be rejected
    expect(res.entries.synced).toBe(0);
    expect(res.entries.failed).toBe(1);
    expect(res.entries.rejected).toHaveLength(1);
    expect(res.entries.rejected[0].id).toBe('entry-bad');
    expect(res.entries.rejected[0].reason).toContain('missing-acc');

    // All other entities must be saved
    expect(mockTx.account.upsert).toHaveBeenCalledWith(expect.objectContaining({
      where: { id: 'acc-1' },
    }));
    expect(mockTx.creditCard.upsert).toHaveBeenCalledWith(expect.objectContaining({
      where: { id: 'card-1' },
    }));
    expect(mockTx.plannedBill.upsert).toHaveBeenCalledWith(expect.objectContaining({
      where: { id: 'bill-1' },
    }));
    expect(mockTx.receivable.upsert).toHaveBeenCalledWith(expect.objectContaining({
      where: { id: 'rec-1' },
    }));
    expect(mockTx.savingGoal.upsert).toHaveBeenCalledWith(expect.objectContaining({
      where: { id: 'goal-1' },
    }));
    expect(mockTx.sinkingFund.upsert).toHaveBeenCalledWith(expect.objectContaining({
      where: { id: 'fund-1' },
    }));
    expect(mockTx.budget.upsert).toHaveBeenCalledWith(expect.objectContaining({
      where: { id: 'b-1' },
    }));
  });

  it('Test 2: Entry whose account is created in the same batch is saved', async () => {
    const payload = {
      accounts: [
        { id: 'acc-new', name: 'New Savings', type: 'savings', currentBalancePaise: 10000 },
      ],
      entries: [
        {
          id: 'entry-ok',
          accountId: 'acc-new',
          categoryId: 'cat-1',
          kind: 'spending',
          amountPaise: 1200,
          entryDate: '2026-04-02T00:00:00.000Z',
        },
      ],
    };

    const res = await syncService.syncBatch(householdId, payload, userId);

    expect(res.entries.synced).toBe(1);
    expect(res.entries.failed).toBe(0);
    expect(res.entries.rejected).toHaveLength(0);
    expect(mockTx.account.upsert).toHaveBeenCalledWith(expect.objectContaining({
      where: { id: 'acc-new' },
    }));
    expect(mockTx.entry.create).toHaveBeenCalledWith(expect.objectContaining({
      data: expect.objectContaining({
        id: 'entry-ok',
        accountId: 'acc-new',
      }),
    }));
  });

  it('Test 3: Account name-matched to different existing server ID rejects its entry, but saves other items', async () => {
    // Existing DB account with same normalized name but different id
    mockPrisma.account.findMany.mockImplementation(({ where }: any) => {
      if (where?.householdId) {
        return Promise.resolve([
          { id: 'acc-server-existing', householdId, name: 'HDFC Bank', type: 'bank', currentBalancePaise: 1000 },
        ]);
      }
      return Promise.resolve([]);
    });

    const payload = {
      accounts: [
        { id: 'acc-client-local', name: 'HDFC Bank', type: 'bank', currentBalancePaise: 1000 },
      ],
      plannedBills: [
        { id: 'bill-valid', name: 'Internet', amountPaise: 1000, dueDate: '2026-04-05T00:00:00.000Z' },
      ],
      entries: [
        {
          id: 'entry-name-matched',
          accountId: 'acc-client-local',
          categoryId: 'cat-1',
          kind: 'spending',
          amountPaise: 400,
          entryDate: '2026-04-03T00:00:00.000Z',
        },
      ],
    };

    const res = await syncService.syncBatch(householdId, payload, userId);

    // Entry should be rejected because acc-client-local is not created (it name-matches acc-server-existing)
    expect(res.entries.synced).toBe(0);
    expect(res.entries.failed).toBe(1);
    expect(res.entries.rejected).toHaveLength(1);
    expect(res.entries.rejected[0].id).toBe('entry-name-matched');
    expect(res.entries.rejected[0].reason).toContain('acc-client-local');

    // Bill is saved
    expect(mockTx.plannedBill.upsert).toHaveBeenCalledWith(expect.objectContaining({
      where: { id: 'bill-valid' },
    }));
  });

  it('Test 4: Re-sending an identical batch results in zero upserts for unchanged rows', async () => {
    const existingCat = {
      id: 'cat-1',
      householdId,
      name: 'Groceries',
      kind: 'expense',
      groupCode: null,
      needOrWant: null,
      isDeduction: false,
      isSystem: false,
      sortOrder: 1,
      archivedAt: new Date('2026-01-01T00:00:00.000Z'),
    };
    const existingAccount = {
      id: 'acc-1',
      householdId,
      name: 'Salary Account',
      type: 'checking',
      currentBalancePaise: BigInt(50000),
    };
    const existingBudget = {
      id: 'b-1',
      householdId,
      categoryId: 'cat-1',
      yearMonth: '2026-04',
      amountPaise: BigInt(20000),
    };
    const existingBill = {
      id: 'bill-1',
      householdId,
      name: 'Gym',
      amountPaise: BigInt(2500),
      dueDate: new Date('2026-04-10T00:00:00.000Z'),
      isRecurring: true,
      recurrenceInterval: 'monthly',
      recurrenceDay: 10,
      autoMarkDone: false,
      isPaid: false,
      linkedEntryId: null,
    };

    mockPrisma.category.findMany.mockResolvedValue([existingCat]);
    mockPrisma.account.findMany.mockImplementation(({ where }: any) => {
      if (where?.id?.in) return Promise.resolve([existingAccount]);
      if (where?.householdId) return Promise.resolve([existingAccount]);
      return Promise.resolve([]);
    });
    mockPrisma.budget.findMany.mockImplementation(({ where }: any) => {
      if (where?.id?.in) return Promise.resolve([existingBudget]);
      if (where?.OR) return Promise.resolve([existingBudget]);
      return Promise.resolve([]);
    });
    mockPrisma.plannedBill.findMany.mockResolvedValue([existingBill]);

    const payload = {
      categories: [
        {
          id: 'cat-1',
          name: 'Groceries',
          kind: 'expense',
          sortOrder: 1,
          isSystem: false,
          archivedAt: '2026-01-01T00:00:00.000Z',
        },
      ],
      accounts: [
        {
          id: 'acc-1',
          name: 'Salary Account',
          type: 'checking',
          currentBalancePaise: 50000,
        },
      ],
      budgets: [
        {
          id: 'b-1',
          categoryId: 'cat-1',
          yearMonth: '2026-04',
          amountPaise: 20000,
        },
      ],
      plannedBills: [
        {
          id: 'bill-1',
          name: 'Gym',
          amountPaise: 2500,
          dueDate: '2026-04-10T00:00:00.000Z',
          isRecurring: true,
          recurrenceInterval: 'monthly',
          recurrenceDay: 10,
          autoMarkDone: false,
          isPaid: false,
          linkedEntryId: null,
        },
      ],
    };

    await syncService.syncBatch(householdId, payload, userId);

    // Phase 2 should skip all identical rows
    expect(mockTx.category.upsert).not.toHaveBeenCalled();
    expect(mockTx.account.upsert).not.toHaveBeenCalled();
    expect(mockTx.budget.upsert).not.toHaveBeenCalled();
    expect(mockTx.plannedBill.upsert).not.toHaveBeenCalled();
  });

  it('Test 5: Prisma queries in PHASE 1 do NOT grow per row for 50 accounts + 50 budgets + 50 bills, and 200 entries across 6 months -> exactly 1 monthSnapshot query', async () => {
    // Generate 50 accounts, 50 budgets, 50 bills
    const accounts = Array.from({ length: 50 }, (_, i) => ({
      id: `acc-${i}`,
      name: `Account ${i}`,
      type: 'savings',
      currentBalancePaise: 1000 * i,
    }));
    const budgets = Array.from({ length: 50 }, (_, i) => ({
      id: `budget-${i}`,
      categoryId: 'cat-1',
      yearMonth: '2026-04',
      amountPaise: 500 * i,
    }));
    const plannedBills = Array.from({ length: 50 }, (_, i) => ({
      id: `bill-${i}`,
      name: `Bill ${i}`,
      amountPaise: 200 * i,
      dueDate: '2026-04-15T00:00:00.000Z',
    }));

    // 200 entries across 6 months
    const months = ['2026-01', '2026-02', '2026-03', '2026-04', '2026-05', '2026-06'];
    const entries = Array.from({ length: 200 }, (_, i) => ({
      id: `entry-bench-${i}`,
      categoryId: 'cat-1',
      kind: 'spending',
      amountPaise: 100 * (i + 1),
      entryDate: `${months[i % months.length]}-15T12:00:00.000Z`,
    }));

    const payload = { accounts, budgets, plannedBills, entries };

    // Reset spy call counts
    mockPrisma.account.findMany.mockClear();
    mockPrisma.account.findUnique.mockClear();

    mockPrisma.budget.findMany.mockClear();
    mockPrisma.budget.findUnique.mockClear();

    mockPrisma.plannedBill.findMany.mockClear();
    mockPrisma.plannedBill.findUnique.mockClear();

    mockPrisma.monthSnapshot.findMany.mockClear();
    mockPrisma.monthSnapshot.findUnique.mockClear();

    await syncService.syncBatch(householdId, payload, userId);

    // Number of queries in Phase 1:
    // account: 1 findMany for id + 1 findMany for household name-matching = 2 queries total (NOT 50)
    expect(mockPrisma.account.findMany.mock.calls.length).toBeLessThanOrEqual(2);
    expect(mockPrisma.account.findUnique).not.toHaveBeenCalled();

    // budget: 1 findMany for id + 1 findMany for same-cell check = <= 2 queries total (NOT 50)
    expect(mockPrisma.budget.findMany.mock.calls.length).toBeLessThanOrEqual(2);
    expect(mockPrisma.budget.findUnique).not.toHaveBeenCalled();

    // plannedBill: 1 findMany for id (and 0 for linked entries since none) = 1 query total (NOT 50)
    expect(mockPrisma.plannedBill.findMany.mock.calls.length).toBe(1);
    expect(mockPrisma.plannedBill.findUnique).not.toHaveBeenCalled();

    // 200 entries across 6 months -> exactly 1 monthSnapshot query
    expect(mockPrisma.monthSnapshot.findMany).toHaveBeenCalledTimes(1);
    expect(mockPrisma.monthSnapshot.findMany).toHaveBeenCalledWith({
      where: {
        householdId,
        yearMonth: { in: expect.arrayContaining(months) },
        status: 'closed',
      },
      select: { yearMonth: true },
    });
    expect(mockPrisma.monthSnapshot.findUnique).not.toHaveBeenCalled();
  });

  it('Test 6: Category archivedAt round-trips through push and pull, and tombstoned category is not un-archived', async () => {
    const archivedDateStr = '2026-02-14T10:00:00.000Z';
    const payload = {
      categories: [
        {
          id: 'cat-archived',
          name: 'Old Entertainment',
          kind: 'expense',
          archivedAt: archivedDateStr,
        },
      ],
    };

    // 1. Push
    await syncService.syncBatch(householdId, payload, userId);

    expect(mockTx.category.upsert).toHaveBeenCalledWith(expect.objectContaining({
      where: { id: 'cat-archived' },
      create: expect.objectContaining({
        id: 'cat-archived',
        archivedAt: new Date(archivedDateStr),
      }),
      update: expect.objectContaining({
        archivedAt: new Date(archivedDateStr),
      }),
    }));

    // 2. Pull
    mockPrisma.category.findMany.mockResolvedValue([
      {
        id: 'cat-archived',
        householdId,
        name: 'Old Entertainment',
        type: 'expense',
        icon: null,
        color: null,
        sortOrder: 0,
        isSystem: false,
        archivedAt: new Date(archivedDateStr),
        createdAt: new Date(),
        updatedAt: new Date(),
      },
    ]);

    const pullResult = await syncService.pullData(householdId);
    const pulledCat = pullResult.categories.find((c: any) => c.id === 'cat-archived');
    expect(pulledCat).toBeDefined();
    expect(pulledCat.archivedAt).toBe(archivedDateStr);

    // 3. Tombstoned category should be skipped in push (not un-archived or resurrected)
    mockTx.category.upsert.mockClear();
    mockPrisma.syncTombstone.findMany.mockResolvedValue([
      { entity: 'category', entityId: 'cat-archived' },
    ]);

    await syncService.syncBatch(householdId, payload, userId);
    expect(mockTx.category.upsert).not.toHaveBeenCalled();
  });

  it('Test 7 (a): new parent in a closed month + new child in the same batch -> both rejected; accounts, bills and budgets in the same batch are still saved; no transaction error', async () => {
    // Mock 2026-01 as closed, other months open
    mockPrisma.monthSnapshot.findMany.mockImplementation(async ({ where }: any) => {
      const inMonths: string[] = where?.yearMonth?.in || [];
      if (inMonths.includes('2026-01')) {
        return [{ yearMonth: '2026-01', status: 'closed' }];
      }
      return [];
    });

    const payload = {
      accounts: [
        { id: 'acc-valid-7a', name: 'Valid Savings 7a', type: 'savings', currentBalancePaise: 50000 },
      ],
      plannedBills: [
        { id: 'bill-valid-7a', name: 'Internet Bill 7a', amountPaise: 150000, dueDate: '2026-04-10T00:00:00.000Z' },
      ],
      budgets: [
        { id: 'budget-valid-7a', categoryId: 'cat-1', yearMonth: '2026-04', amountPaise: 80000 },
      ],
      entries: [
        {
          id: 'parent-closed-7a',
          categoryId: 'cat-1',
          kind: 'spending',
          amountPaise: 5000,
          entryDate: '2026-01-15T00:00:00.000Z', // Closed month -> rejected in pass 1
        },
        {
          id: 'child-open-7a',
          categoryId: 'cat-1',
          kind: 'spending',
          amountPaise: 2000,
          entryDate: '2026-04-15T00:00:00.000Z', // Open month, but parent rejected -> rejected in pass 2
          parentId: 'parent-closed-7a',
        },
      ],
    };

    const result = await syncService.syncBatch(householdId, payload, userId);

    // Both entries rejected
    expect(result.entries.synced).toBe(0);
    expect(result.entries.failed).toBe(2);
    expect(result.entries.rejected).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          id: 'parent-closed-7a',
          reason: expect.stringContaining('closed month 2026-01'),
        }),
        expect.objectContaining({
          id: 'child-open-7a',
          reason: expect.stringContaining('Referenced parent entry parent-closed-7a does not exist'),
        }),
      ]),
    );

    // Accounts, bills, and budgets in the same batch are still saved
    expect(result.accounts).toBe(1);
    expect(result.plannedBills).toBe(1);
    expect(result.budgets).toBe(1);

    expect(mockTx.account.upsert).toHaveBeenCalledWith(
      expect.objectContaining({ where: { id: 'acc-valid-7a' } }),
    );
    expect(mockTx.plannedBill.upsert).toHaveBeenCalledWith(
      expect.objectContaining({ where: { id: 'bill-valid-7a' } }),
    );
    expect(mockTx.budget.upsert).toHaveBeenCalledWith(
      expect.objectContaining({ where: { id: 'budget-valid-7a' } }),
    );

    // Entries were NOT written, no transaction error thrown
    expect(mockTx.entry.create).not.toHaveBeenCalled();
    expect(mockTx.entry.update).not.toHaveBeenCalled();
  });

  it('Test 8 (b): child listed BEFORE its parent in the payload -> both saved, parents written before children', async () => {
    // Both months open
    mockPrisma.monthSnapshot.findMany.mockResolvedValue([]);

    const payload = {
      entries: [
        {
          id: 'child-8b',
          categoryId: 'cat-1',
          kind: 'spending',
          amountPaise: 2500,
          entryDate: '2026-04-15T00:00:00.000Z',
          parentId: 'parent-8b', // Child listed FIRST
        },
        {
          id: 'parent-8b',
          categoryId: 'cat-1',
          kind: 'spending',
          amountPaise: 10000,
          entryDate: '2026-04-15T00:00:00.000Z', // Parent listed SECOND
        },
      ],
    };

    mockTx.entry.create.mockClear();

    const result = await syncService.syncBatch(householdId, payload, userId);

    expect(result.entries.synced).toBe(2);
    expect(result.entries.failed).toBe(0);

    // Both entries were created
    expect(mockTx.entry.create).toHaveBeenCalledTimes(2);

    // In applyBatch, parents must be written before children (parent-8b before child-8b)
    const call1Id = mockTx.entry.create.mock.calls[0][0].data.id;
    const call2Id = mockTx.entry.create.mock.calls[1][0].data.id;
    expect(call1Id).toBe('parent-8b');
    expect(call2Id).toBe('child-8b');
  });
});
