import { Injectable, Inject, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { PrismaClient } from '@prisma/client';

export const DEFAULT_TOMBSTONE_RETENTION_DAYS = 90;

export function getTombstoneRetentionDays(): number {
  const envVal = process.env.SYNC_TOMBSTONE_RETENTION_DAYS;
  if (!envVal) return DEFAULT_TOMBSTONE_RETENTION_DAYS;
  const parsed = parseInt(envVal, 10);
  return isNaN(parsed) || parsed <= 0 ? DEFAULT_TOMBSTONE_RETENTION_DAYS : parsed;
}

@Injectable()
export class CleanupService {
  private readonly logger = new Logger(CleanupService.name);

  constructor(
    @Inject('PRISMA') private readonly prisma: PrismaClient,
  ) {}

  /**
   * Job 1: Prunes expired refresh tokens.
   * Runs daily at 3:00 AM server time (low-traffic window).
   * Safe and idempotent: rows past expiresAt are unusable; future expiresAt rows are preserved.
   */
  @Cron(CronExpression.EVERY_DAY_AT_3AM)
  async cleanupExpiredRefreshTokens(): Promise<{ count: number }> {
    try {
      const now = new Date();
      const result = await this.prisma.refreshToken.deleteMany({
        where: {
          expiresAt: { lt: now },
        },
      });

      this.logger.log(
        JSON.stringify({
          job: 'cleanup_expired_refresh_tokens',
          outcome: 'success',
          deletedCount: result.count,
          executedAt: now.toISOString(),
        }),
      );

      return result;
    } catch (err: any) {
      this.logger.error(
        JSON.stringify({
          job: 'cleanup_expired_refresh_tokens',
          outcome: 'failure',
          errorName: err?.name,
          errorMessage: err?.message,
        }),
        err?.stack,
      );
      return { count: 0 };
    }
  }

  /**
   * Job 2: Prunes old sync tombstones older than the retention window.
   * Runs daily at 3:00 AM server time (low-traffic window).
   * Safe and idempotent: bounds unbounded tombstone accumulation while preserving
   * recent tombstones for active offline device synchronization.
   */
  @Cron(CronExpression.EVERY_DAY_AT_3AM)
  async cleanupOldSyncTombstones(): Promise<{ count: number }> {
    try {
      const retentionDays = getTombstoneRetentionDays();
      const cutoffDate = new Date(Date.now() - retentionDays * 24 * 60 * 60 * 1000);

      const result = await this.prisma.syncTombstone.deleteMany({
        where: {
          deletedAt: { lt: cutoffDate },
        },
      });

      this.logger.log(
        JSON.stringify({
          job: 'cleanup_old_sync_tombstones',
          outcome: 'success',
          deletedCount: result.count,
          retentionDays,
          cutoffDate: cutoffDate.toISOString(),
        }),
      );

      return result;
    } catch (err: any) {
      this.logger.error(
        JSON.stringify({
          job: 'cleanup_old_sync_tombstones',
          outcome: 'failure',
          errorName: err?.name,
          errorMessage: err?.message,
        }),
        err?.stack,
      );
      return { count: 0 };
    }
  }
}
