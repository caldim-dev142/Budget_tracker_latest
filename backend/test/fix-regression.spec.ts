/**
 * Regression tests for the Master 39-defect fix (2026-09-16).
 * Each describe block names the defect it protects.
 */
import { BadRequestException, ForbiddenException, UnauthorizedException } from '@nestjs/common';

jest.mock('firebase-admin/app', () => ({ initializeApp: jest.fn(), cert: jest.fn(), getApps: jest.fn(() => [{}]) }));
jest.mock('firebase-admin/auth', () => ({ getAuth: jest.fn(() => ({ verifyIdToken: jest.fn() })) }));

import { JwtStrategy } from '../src/auth/strategies/jwt.strategy';
import { HouseholdGuard } from '../src/auth/guards/household.guard';
import { AuthController } from '../src/auth/auth.controller';
import { AuthService, normalizeEmail } from '../src/auth/auth.service';
import { YearMonthPipe } from '../src/common/pipes/year-month.pipe';
import { monthRange } from '../src/common/month-range';
import { EntriesService, normalizeCategoryId } from '../src/entries/entries.service';
import { BudgetsService } from '../src/budgets/budgets.service';
import { SyncService } from '../src/sync/sync.service';
import { seedCategories } from '../src/categories/categories-seed.data';
import { toSnapshotResponse } from '../src/months/months.service';
import '../src/common/bigint-json';

const HH = 'hh-A';
const ctx = (user: any) => ({ switchToHttp: () => ({ getRequest: () => ({ user }) }) }) as any;

describe('DEF-SEC-01/02 — JWT strategy re-validates account and household', () => {
  const config: any = { get: () => 'x'.repeat(40) };
  const make = (user: any) => new JwtStrategy(config, { user: { findUnique: jest.fn().mockResolvedValue(user) } } as any);

  it('rejects a token for a deleted user', async () => {
    await expect(make(null).validate({ sub: 'u1', householdId: HH })).rejects.toBeInstanceOf(UnauthorizedException);
  });
  it('rejects a token whose household no longer matches (removed / left member)', async () => {
    await expect(make({ id: 'u1', household_id: 'hh-B' }).validate({ sub: 'u1', householdId: HH }))
      .rejects.toBeInstanceOf(UnauthorizedException);
    await expect(make({ id: 'u1', household_id: null }).validate({ sub: 'u1', householdId: HH }))
      .rejects.toBeInstanceOf(UnauthorizedException);
  });
  it('rejects a token without subject', async () => {
    await expect(make({ id: 'u1' }).validate({} as any)).rejects.toBeInstanceOf(UnauthorizedException);
  });
  it('normalises an empty household claim to null and accepts when DB agrees', async () => {
    await expect(make({ id: 'u1', household_id: null }).validate({ sub: 'u1', householdId: '' }))
      .resolves.toEqual({ userId: 'u1', householdId: null });
    await expect(make({ id: 'u1', household_id: HH }).validate({ sub: 'u1', householdId: HH }))
      .resolves.toEqual({ userId: 'u1', householdId: HH });
  });
  it('HouseholdGuard fails closed for missing/empty household', () => {
    const g = new HouseholdGuard();
    expect(() => g.canActivate(ctx({ userId: 'u1', householdId: '' }))).toThrow(ForbiddenException);
    expect(() => g.canActivate(ctx({ userId: 'u1', householdId: null }))).toThrow(ForbiddenException);
    expect(() => g.canActivate(ctx(undefined))).toThrow(ForbiddenException);
    expect(g.canActivate(ctx({ userId: 'u1', householdId: HH }))).toBe(true);
  });
});

describe('DEF-AUTH-01/02 — refresh uses the raw token once; logout is scoped to the caller', () => {
  it('controller passes the raw refresh token to the service (no double hashing)', () => {
    const svc: any = { refresh: jest.fn(), logout: jest.fn() };
    new AuthController(svc).refresh({ userId: 'u1', refreshToken: 'RAW', family: 'f1' } as any);
    expect(svc.refresh).toHaveBeenCalledWith('u1', 'RAW', 'f1');
  });
  it('controller logout uses req.user.userId', () => {
    const svc: any = { logout: jest.fn() };
    new AuthController(svc).logout({ user: { userId: 'u1', householdId: HH } }, { family: 'f1' });
    expect(svc.logout).toHaveBeenCalledWith('u1', 'f1');
  });

  const buildAuth = () => {
    const prisma: any = {
      refreshToken: { findUnique: jest.fn(), update: jest.fn(), delete: jest.fn(), deleteMany: jest.fn(), create: jest.fn() },
      user: { findFirst: jest.fn().mockResolvedValue({ id: 'u1', household_id: HH }) },
    };
    const jwt: any = { sign: jest.fn().mockReturnValue('access') };
    const config: any = { get: jest.fn((k: string) => (k.includes('EXPIR') ? '7d' : 'x'.repeat(40))) };
    return { prisma, svc: new AuthService(prisma, jwt, config, {} as any) };
  };

  it('logout without family revokes only the caller\'s tokens', async () => {
    const { prisma, svc } = buildAuth();
    await svc.logout('u1');
    expect(prisma.refreshToken.deleteMany).toHaveBeenCalledWith({ where: { userId: 'u1' } });
    await svc.logout('u1', 'f1');
    expect(prisma.refreshToken.deleteMany).toHaveBeenCalledWith({ where: { userId: 'u1', family: 'f1' } });
  });
  it('reuse of a rotated refresh token revokes the family', async () => {
    const { prisma, svc } = buildAuth();
    prisma.refreshToken.findUnique.mockResolvedValue({ userId: 'u1', family: 'f1', usedAt: new Date(), expiresAt: new Date(Date.now() + 1e6) });
    await expect(svc.refresh('u1', 'RAW', 'f1')).rejects.toBeInstanceOf(UnauthorizedException);
    expect(prisma.refreshToken.deleteMany).toHaveBeenCalledWith({ where: { family: 'f1' } });
  });
  it('refresh with a family that does not match the stored token family is rejected without rotating', async () => {
    const { prisma, svc } = buildAuth();
    prisma.refreshToken.findUnique.mockResolvedValue({ userId: 'u1', family: 'f1', usedAt: null, expiresAt: new Date(Date.now() + 1e6) });
    await expect(svc.refresh('u1', 'RAW', 'other-family')).rejects.toBeInstanceOf(UnauthorizedException);
    expect(prisma.refreshToken.update).not.toHaveBeenCalled();
  });
  it('normalizeEmail trims and lower-cases (DEF-AUTH-04)', () => {
    expect(normalizeEmail('  Alice@Example.COM ')).toBe('alice@example.com');
  });
});

describe('DEF-API-03 — YYYY-MM validation and half-open month range (DEF-FIN-06)', () => {
  const pipe = new YearMonthPipe();
  it.each(['2026-13', '2026-00', '26-01', '2026-1', '', undefined, '2026-01; DROP'])('rejects %p', (v) => {
    expect(() => pipe.transform(v)).toThrow(BadRequestException);
  });
  it('accepts a valid month', () => expect(pipe.transform('2026-12')).toBe('2026-12'));
  it('month range includes the last second of the month', () => {
    const { from, to } = monthRange('2026-01');
    const lastSecond = new Date(2026, 0, 31, 23, 59, 59, 500);
    expect(lastSecond >= from && lastSecond < to).toBe(true);
    expect(to.getTime()).toBe(new Date(2026, 1, 1).getTime());
  });
});

describe('DEF-FIN-02 — lending system category id normalisation (₹7,000 regression)', () => {
  it('maps Flutter and mis-prefixed ids to the canonical system category', () => {
    expect(normalizeCategoryId(`lend-system-cat-${HH}`, HH)).toBe(`${HH}-lend-system-cat`);
    expect(normalizeCategoryId(`${HH}-lend-system-cat-${HH}`, HH)).toBe(`${HH}-lend-system-cat`);
    expect(normalizeCategoryId(`return-received-system-cat-${HH}`, HH)).toBe(`${HH}-return-received-system-cat`);
    expect(normalizeCategoryId('spd-n05', HH)).toBe(`${HH}-spd-n05`);
    expect(normalizeCategoryId('custom-x', HH)).toBe('custom-x');
    expect(normalizeCategoryId('cat-1790170089030', HH)).toBe('cat-1790170089030');
  });

  it('allow-list: prepends householdId only to known seed category prefixes, leaving UUIDs and custom IDs untouched', () => {
    // 1. Known seed prefixes (from category_seed.dart / categories-seed.data.ts)
    expect(normalizeCategoryId('inc-01', HH)).toBe(`${HH}-inc-01`);
    expect(normalizeCategoryId('ded-01', HH)).toBe(`${HH}-ded-01`);
    expect(normalizeCategoryId('adj-05', HH)).toBe(`${HH}-adj-05`);
    expect(normalizeCategoryId('spd-n05', HH)).toBe(`${HH}-spd-n05`);
    expect(normalizeCategoryId('pro-i01', HH)).toBe(`${HH}-pro-i01`);
    expect(normalizeCategoryId('sav-r01', HH)).toBe(`${HH}-sav-r01`);

    // 2. Already-prefixed seed categories (idempotence)
    expect(normalizeCategoryId(`${HH}-spd-n05`, HH)).toBe(`${HH}-spd-n05`);
    expect(normalizeCategoryId(`${HH}-inc-01`, HH)).toBe(`${HH}-inc-01`);

    // 3. Bare UUID categories (produced by saving_screen.dart and protection_screen.dart via _uuid.v4())
    const savingGoalCatUuid = 'c8b411d7-2f3b-4c5a-8e2b-1a2b3c4d5e6f';
    const protectionCatUuid = '7e6a5b4c-3d2e-1f0a-9b8c-7d6e5f4a3b2c';
    expect(normalizeCategoryId(savingGoalCatUuid, HH)).toBe(savingGoalCatUuid);
    expect(normalizeCategoryId(protectionCatUuid, HH)).toBe(protectionCatUuid);

    // 4. Custom categories ('custom-*' and 'cat-*')
    expect(normalizeCategoryId('custom-1790170089030', HH)).toBe('custom-1790170089030');
    expect(normalizeCategoryId('cat-1790170089030', HH)).toBe('cat-1790170089030');

    // 5. Future / arbitrary custom category format
    expect(normalizeCategoryId('future-arbitrary-category-id', HH)).toBe('future-arbitrary-category-id');
  });

  it('a ₹7,000 lend entry (positive amount, as borrow_lend_dao sends it) is stored against the canonical deduction category so net adjustments = -700000', async () => {
    const prisma: any = {
      category: { count: jest.fn().mockResolvedValue(1), findUnique: jest.fn().mockResolvedValue(null), upsert: jest.fn(), create: jest.fn().mockResolvedValue({}) },
      entry: { findUnique: jest.fn().mockResolvedValue(null), create: jest.fn().mockImplementation(({ data }) => data) },
      monthSnapshot: { findUnique: jest.fn().mockResolvedValue(null) },
      account: { findUnique: jest.fn() },
      creditCard: { findUnique: jest.fn() },
    };
    await new EntriesService(prisma).upsertBatch(HH, [{
      id: 'e-lend', kind: 'adjustment', categoryId: `lend-system-cat-${HH}`, amountPaise: 700000,
      entryDate: '2026-09-10T00:00:00.000Z',
    } as any], 'u1');
    const created = prisma.entry.create.mock.calls[0][0].data;
    expect(created.categoryId).toBe(`${HH}-lend-system-cat`);
    expect(created.amountPaise).toBe(700000);
    // Sign comes from the category flag (reports.service: isDeduction ? -amt : amt)
    const catCreate = prisma.category.upsert.mock.calls[0][0].create;
    expect(catCreate.id).toBe(`${HH}-lend-system-cat`);
    expect(catCreate.isDeduction).toBe(true);
  });
});

describe('DEF-FIN-01 — seeded adjustment categories: exactly 4 ADD / 2 SUBTRACT', () => {
  it('adj seed flags', () => {
    const adj = seedCategories.filter((c: any) => c.kind === 'adjustment');
    expect(adj).toHaveLength(6);
    expect(adj.filter((c: any) => !c.isDeduction)).toHaveLength(4);
    expect(adj.filter((c: any) => c.isDeduction).map((c: any) => c.id).sort()).toEqual(['adj-05', 'adj-06']);
  });
});

describe('DEF-FIN-04 / DEF-SYNC-02/03 — entries upsert guards', () => {
  const base = () => ({
    category: { count: jest.fn().mockResolvedValue(1), findUnique: jest.fn().mockResolvedValue({ id: `${HH}-spd-n05`, householdId: HH }), upsert: jest.fn(), create: jest.fn() },
    entry: { findUnique: jest.fn(), create: jest.fn(), update: jest.fn().mockImplementation(({ data }) => data) },
    monthSnapshot: { findUnique: jest.fn().mockResolvedValue(null) },
    account: { findUnique: jest.fn() },
    creditCard: { findUnique: jest.fn() },
  });
  const existing = { id: 'e1', householdId: HH, categoryId: `${HH}-spd-n05`, kind: 'spending', entryDate: new Date('2026-01-15T00:00:00Z'),
    amountPaise: 1000, note: null, parentId: null, accountId: null, cardId: null, deletedAt: null, version: 2 };
  const logSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
  afterAll(() => logSpy.mockRestore());

  it('moving an entry out of a closed month is rejected (date-change bypass)', async () => {
    const prisma: any = base();
    prisma.entry.findUnique.mockResolvedValue(existing);
    prisma.monthSnapshot.findUnique.mockImplementation(({ where }: any) =>
      Promise.resolve(where.householdId_yearMonth.yearMonth === '2026-01' ? { status: 'closed' } : null));
    const res = await new EntriesService(prisma).upsertBatch(HH, [{ ...existing, entryDate: '2026-02-15T00:00:00.000Z', amountPaise: 1000, version: 3, categoryId: 'spd-n05' } as any], 'u1');
    expect(prisma.entry.update).not.toHaveBeenCalled();
    expect(res).toBeDefined();
  });

  it('negative spending is rejected; negative adjustment accepted', async () => {
    const prisma: any = base();
    prisma.entry.findUnique.mockResolvedValue(null);
    prisma.entry.create.mockImplementation(({ data }: any) => data);
    await new EntriesService(prisma).upsertBatch(HH, [
      { id: 'n1', kind: 'spending', categoryId: 'spd-n05', amountPaise: -1, entryDate: '2026-09-01T00:00:00Z' } as any,
      { id: 'n2', kind: 'adjustment', categoryId: 'spd-n05', amountPaise: -1, entryDate: '2026-09-01T00:00:00Z' } as any,
    ], 'u1');
    expect(prisma.entry.create).toHaveBeenCalledTimes(1);
    expect(prisma.entry.create.mock.calls[0][0].data.id).toBe('n2');
  });

  it('an update writes every mutable field (kind, category, date, amount, links)', async () => {
    const prisma: any = base();
    prisma.entry.findUnique.mockResolvedValue(existing);
    await new EntriesService(prisma).upsertBatch(HH, [{ id: 'e1', kind: 'spending', categoryId: 'spd-n05', amountPaise: 2500,
      entryDate: '2026-01-20T00:00:00.000Z', note: 'n', parentId: 'p', version: 2 } as any], 'u1');
    const data = prisma.entry.update.mock.calls[0][0].data;
    expect(data).toEqual(expect.objectContaining({ amountPaise: 2500, note: 'n', parentId: 'p', kind: 'spending', categoryId: `${HH}-spd-n05`, version: 3 }));
    expect(data.entryDate.toISOString()).toBe('2026-01-20T00:00:00.000Z');
  });

  it('a soft-deleted entry is not revived by an equal-version offline edit', async () => {
    const prisma: any = base();
    prisma.entry.findUnique.mockResolvedValue({ ...existing, deletedAt: new Date() });
    await new EntriesService(prisma).upsertBatch(HH, [{ id: 'e1', kind: 'spending', categoryId: 'spd-n05', amountPaise: 9999,
      entryDate: '2026-01-15T00:00:00.000Z', version: 2 } as any], 'u1');
    expect(prisma.entry.update).not.toHaveBeenCalled();
  });
});

describe('DEF-SEC-03 — budgets bulk update IDOR', () => {
  it('rejects a category from another household', async () => {
    const prisma: any = { category: { findMany: jest.fn().mockResolvedValue([]) }, budget: { upsert: jest.fn() }, $transaction: jest.fn() };
    await expect(new BudgetsService(prisma).upsertBulk(HH, '2026-09', [{ categoryId: 'hh-B-spd-n05', amountPaise: 1 } as any]))
      .rejects.toBeInstanceOf(ForbiddenException);
    expect(prisma.budget.upsert).not.toHaveBeenCalled();
  });
});

describe('DEF-SYNC-01 — hard deletions are propagated with tombstones', () => {
  const buildSync = () => {
    const prisma: any = {
      syncTombstone: { findMany: jest.fn().mockResolvedValue([]), upsert: jest.fn() },
      plannedBill: { findUnique: jest.fn(), deleteMany: jest.fn(), upsert: jest.fn(), findMany: jest.fn().mockResolvedValue([]) },
      receivable: { findUnique: jest.fn(), deleteMany: jest.fn() },
      category: { findUnique: jest.fn(), updateMany: jest.fn(), upsert: jest.fn() },
      annual_targets: { findUnique: jest.fn(), deleteMany: jest.fn() },
      entry: { findUnique: jest.fn() },
    };
    const entries: any = { upsertBatch: jest.fn().mockResolvedValue({ synced: 0, failed: 0 }) };
    return { prisma, svc: new SyncService(entries, prisma) };
  };

  it('deletes an owned record, scoped by household, and records a tombstone', async () => {
    const { prisma, svc } = buildSync();
    prisma.plannedBill.findUnique.mockResolvedValue({ id: 'pb1', householdId: HH });
    const res: any = await svc.syncBatch(HH, { deletions: [{ entity: 'planned_bill', id: 'pb1' }] } as any, 'u1');
    expect(prisma.plannedBill.deleteMany).toHaveBeenCalledWith({ where: { id: 'pb1', householdId: HH } });
    expect(prisma.syncTombstone.upsert).toHaveBeenCalledWith(expect.objectContaining({ create: { householdId: HH, entity: 'planned_bill', entityId: 'pb1' } }));
    expect(res.deletions).toBe(1);
  });

  it('refuses to delete another household\'s record and deletes nothing', async () => {
    const { prisma, svc } = buildSync();
    prisma.receivable.findUnique.mockResolvedValue({ id: 'r1', householdId: 'hh-B' });
    await expect(svc.syncBatch(HH, { deletions: [{ entity: 'receivable', id: 'r1' }] } as any, 'u1')).rejects.toBeInstanceOf(ForbiddenException);
    expect(prisma.receivable.deleteMany).not.toHaveBeenCalled();
    expect(prisma.syncTombstone.upsert).not.toHaveBeenCalled();
  });

  it('a stale device re-pushing a tombstoned record does not resurrect it', async () => {
    const { prisma, svc } = buildSync();
    prisma.syncTombstone.findMany.mockResolvedValue([{ entity: 'planned_bill', entityId: 'pb1' }]);
    await svc.syncBatch(HH, { plannedBills: [{ id: 'pb1', name: 'Rent', amountPaise: 1, dueDay: 1, yearMonth: '2026-09' }] } as any, 'u1');
    expect(prisma.plannedBill.upsert).not.toHaveBeenCalled();
  });

  it('categories are archived, never hard-deleted', async () => {
    const { prisma, svc } = buildSync();
    prisma.category.findUnique.mockResolvedValue({ id: 'custom-1', householdId: HH });
    await svc.syncBatch(HH, { deletions: [{ entity: 'category', id: 'custom-1' }] } as any, 'u1');
    expect(prisma.category.updateMany).toHaveBeenCalledWith(expect.objectContaining({ where: { id: 'custom-1', householdId: HH, isSystem: false } }));
  });

  it('unknown ids get no tombstone (cannot reserve another tenant\'s id)', async () => {
    const { prisma, svc } = buildSync();
    prisma.plannedBill.findUnique.mockResolvedValue(null);
    await svc.syncBatch(HH, { deletions: [{ entity: 'planned_bill', id: 'ghost' }] } as any, 'u1');
    expect(prisma.syncTombstone.upsert).not.toHaveBeenCalled();
  });
});

describe('DEF-DATA-03 — BIGINT paise serialise as JSON numbers', () => {
  it('BigInt JSON shim and snapshot response mapping', () => {
    expect(JSON.stringify({ a: BigInt(700000) })).toBe('{"a":700000}');
    const snap: any = toSnapshotResponse({ id: 's', incomePaise: BigInt(5), remainingPaise: BigInt(-3) } as any);
    expect(snap.incomePaise).toBe(5);
    expect(snap.remainingPaise).toBe(-3);
  });
});
