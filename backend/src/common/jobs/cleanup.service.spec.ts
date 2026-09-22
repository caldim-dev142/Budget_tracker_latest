import { CleanupService, DEFAULT_TOMBSTONE_RETENTION_DAYS, getTombstoneRetentionDays } from './cleanup.service';

describe('CleanupService (B7 Cleanup Jobs)', () => {
  let service: CleanupService;
  let mockPrisma: {
    refreshToken: { deleteMany: jest.Mock };
    syncTombstone: { deleteMany: jest.Mock };
  };
  const originalEnv = process.env;

  beforeEach(() => {
    jest.clearAllMocks();
    process.env = { ...originalEnv };

    mockPrisma = {
      refreshToken: { deleteMany: jest.fn() },
      syncTombstone: { deleteMany: jest.fn() },
    };

    service = new CleanupService(mockPrisma as any);
  });

  afterAll(() => {
    process.env = originalEnv;
  });

  describe('getTombstoneRetentionDays', () => {
    it('returns default 90 days when environment variable is unset', () => {
      delete process.env.SYNC_TOMBSTONE_RETENTION_DAYS;
      expect(getTombstoneRetentionDays()).toBe(DEFAULT_TOMBSTONE_RETENTION_DAYS);
    });

    it('returns parsed number when valid positive integer is provided', () => {
      process.env.SYNC_TOMBSTONE_RETENTION_DAYS = '45';
      expect(getTombstoneRetentionDays()).toBe(45);
    });

    it('falls back to default 90 days when non-numeric string is provided', () => {
      process.env.SYNC_TOMBSTONE_RETENTION_DAYS = 'invalid_days';
      expect(getTombstoneRetentionDays()).toBe(DEFAULT_TOMBSTONE_RETENTION_DAYS);
    });

    it('falls back to default 90 days when zero or negative number is provided', () => {
      process.env.SYNC_TOMBSTONE_RETENTION_DAYS = '0';
      expect(getTombstoneRetentionDays()).toBe(DEFAULT_TOMBSTONE_RETENTION_DAYS);

      process.env.SYNC_TOMBSTONE_RETENTION_DAYS = '-15';
      expect(getTombstoneRetentionDays()).toBe(DEFAULT_TOMBSTONE_RETENTION_DAYS);
    });
  });

  describe('cleanupExpiredRefreshTokens', () => {
    it('deletes expired refresh tokens with exact expiresAt < now where clause', async () => {
      mockPrisma.refreshToken.deleteMany.mockResolvedValueOnce({ count: 3 });
      const before = Date.now();

      const result = await service.cleanupExpiredRefreshTokens();

      const after = Date.now();
      expect(mockPrisma.refreshToken.deleteMany).toHaveBeenCalledTimes(1);

      const callArg = mockPrisma.refreshToken.deleteMany.mock.calls[0][0];
      expect(callArg).toEqual({
        where: {
          expiresAt: { lt: expect.any(Date) },
        },
      });

      const calledDate = callArg.where.expiresAt.lt.getTime();
      expect(calledDate).toBeGreaterThanOrEqual(before);
      expect(calledDate).toBeLessThanOrEqual(after);
      expect(result).toEqual({ count: 3 });
    });

    it('is fail-safe: catches Prisma errors and logs without throwing', async () => {
      mockPrisma.refreshToken.deleteMany.mockRejectedValueOnce(new Error('DB connection reset'));

      const result = await expect(service.cleanupExpiredRefreshTokens()).resolves.toEqual({ count: 0 });
      expect(mockPrisma.refreshToken.deleteMany).toHaveBeenCalledTimes(1);
    });

    it('is idempotent: consecutive run deletes 0 rows if nothing new expired', async () => {
      mockPrisma.refreshToken.deleteMany
        .mockResolvedValueOnce({ count: 3 })
        .mockResolvedValueOnce({ count: 0 });

      const firstRun = await service.cleanupExpiredRefreshTokens();
      const secondRun = await service.cleanupExpiredRefreshTokens();

      expect(firstRun).toEqual({ count: 3 });
      expect(secondRun).toEqual({ count: 0 });
      expect(mockPrisma.refreshToken.deleteMany).toHaveBeenCalledTimes(2);
    });
  });

  describe('cleanupOldSyncTombstones', () => {
    it('deletes tombstones older than default 90 days with exact deletedAt < cutoffDate where clause', async () => {
      delete process.env.SYNC_TOMBSTONE_RETENTION_DAYS;
      mockPrisma.syncTombstone.deleteMany.mockResolvedValueOnce({ count: 12 });

      const expectedCutoffApprox = Date.now() - 90 * 24 * 60 * 60 * 1000;
      const result = await service.cleanupOldSyncTombstones();

      expect(mockPrisma.syncTombstone.deleteMany).toHaveBeenCalledTimes(1);
      const callArg = mockPrisma.syncTombstone.deleteMany.mock.calls[0][0];

      expect(callArg).toEqual({
        where: {
          deletedAt: { lt: expect.any(Date) },
        },
      });

      const actualCutoff = callArg.where.deletedAt.lt.getTime();
      expect(Math.abs(actualCutoff - expectedCutoffApprox)).toBeLessThan(2000);
      expect(result).toEqual({ count: 12 });
    });

    it('respects custom SYNC_TOMBSTONE_RETENTION_DAYS environment variable', async () => {
      process.env.SYNC_TOMBSTONE_RETENTION_DAYS = '30';
      mockPrisma.syncTombstone.deleteMany.mockResolvedValueOnce({ count: 5 });

      const expectedCutoffApprox = Date.now() - 30 * 24 * 60 * 60 * 1000;
      const result = await service.cleanupOldSyncTombstones();

      expect(mockPrisma.syncTombstone.deleteMany).toHaveBeenCalledTimes(1);
      const callArg = mockPrisma.syncTombstone.deleteMany.mock.calls[0][0];

      const actualCutoff = callArg.where.deletedAt.lt.getTime();
      expect(Math.abs(actualCutoff - expectedCutoffApprox)).toBeLessThan(2000);
      expect(result).toEqual({ count: 5 });
    });

    it('is fail-safe: catches Prisma errors and logs without throwing', async () => {
      mockPrisma.syncTombstone.deleteMany.mockRejectedValueOnce(new Error('Timeout during deleteMany'));

      const result = await expect(service.cleanupOldSyncTombstones()).resolves.toEqual({ count: 0 });
      expect(mockPrisma.syncTombstone.deleteMany).toHaveBeenCalledTimes(1);
    });

    it('is idempotent: consecutive run deletes 0 rows if nothing new reached retention cutoff', async () => {
      mockPrisma.syncTombstone.deleteMany
        .mockResolvedValueOnce({ count: 8 })
        .mockResolvedValueOnce({ count: 0 });

      const firstRun = await service.cleanupOldSyncTombstones();
      const secondRun = await service.cleanupOldSyncTombstones();

      expect(firstRun).toEqual({ count: 8 });
      expect(secondRun).toEqual({ count: 0 });
      expect(mockPrisma.syncTombstone.deleteMany).toHaveBeenCalledTimes(2);
    });
  });
});
