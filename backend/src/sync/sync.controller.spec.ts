import { ForbiddenException } from '@nestjs/common';
import { SyncController } from './sync.controller';
import { SyncService } from './sync.service';
import { SyncBatchDto } from './dto/sync-batch.dto';

describe('SyncController — Structured Sync Logging Observability', () => {
  let controller: SyncController;
  let mockSyncService: Partial<SyncService>;
  let mockReq: {
    user: { householdId: string; userId: string };
    id: string;
    log: { info: jest.Mock; error: jest.Mock };
  };

  beforeEach(() => {
    mockSyncService = {
      syncBatch: jest.fn(),
      pullData: jest.fn(),
    };

    mockReq = {
      user: {
        householdId: 'household-uuid-1',
        userId: 'user-uuid-1',
      },
      id: 'req-test-123',
      log: {
        info: jest.fn(),
        error: jest.fn(),
      },
    };

    controller = new SyncController(mockSyncService as SyncService);
  });

  describe('syncBatch', () => {
    it('logs structured success event with counts and duration on successful sync', async () => {
      const mockResult = {
        applied: { categories: 1, accounts: 2, entries: 3 },
        conflicts: [],
        timestamp: new Date().toISOString(),
      };
      (mockSyncService.syncBatch as jest.Mock).mockResolvedValueOnce(mockResult);

      const dto: SyncBatchDto = {
        categories: [{ id: 'c-1', kind: 'expense', name: 'Groceries' }],
        accounts: [
          { id: 'a-1', name: 'Checking', type: 'bank', currentBalancePaise: 10000 },
          { id: 'a-2', name: 'Savings', type: 'bank', currentBalancePaise: 50000 },
        ],
        entries: [
          { id: 'e-1', entryDate: '2026-09-01', amountPaise: 1000, kind: 'expense', categoryId: 'c-1' },
          { id: 'e-2', entryDate: '2026-09-02', amountPaise: 2000, kind: 'expense', categoryId: 'c-1' },
          { id: 'e-3', entryDate: '2026-09-03', amountPaise: 3000, kind: 'expense', categoryId: 'c-1' },
        ],
      };

      const result = await controller.syncBatch(mockReq as any, dto);

      expect(mockSyncService.syncBatch).toHaveBeenCalledWith(
        'household-uuid-1',
        dto,
        'user-uuid-1',
      );
      expect(result).toBe(mockResult);

      expect(mockReq.log.info).toHaveBeenCalledTimes(1);
      expect(mockReq.log.info).toHaveBeenCalledWith(
        expect.objectContaining({
          event: 'sync_batch',
          outcome: 'success',
          requestId: 'req-test-123',
          householdId: 'household-uuid-1',
          durationMs: expect.any(Number),
          counts: expect.objectContaining({
            categories: 1,
            accounts: 2,
            entries: 3,
            budgets: 0,
            creditCards: 0,
            cardTransactions: 0,
            plannedBills: 0,
            receivables: 0,
            savingGoals: 0,
            goalContributions: 0,
            sinkingFunds: 0,
            fundMovements: 0,
            reserveLines: 0,
            annualTargets: 0,
            deletions: 0,
          }),
        }),
      );
      expect(mockReq.log.error).not.toHaveBeenCalled();
    });

    it('logs structured failure event and rethrows error on failed sync', async () => {
      const syncError = new ForbiddenException('Access denied: Category belongs to another household.');
      (mockSyncService.syncBatch as jest.Mock).mockRejectedValueOnce(syncError);

      const dto: SyncBatchDto = {
        categories: [{ id: 'c-alien', kind: 'expense', name: 'Alien' }],
      };

      await expect(controller.syncBatch(mockReq as any, dto)).rejects.toThrow(ForbiddenException);

      expect(mockReq.log.error).toHaveBeenCalledTimes(1);
      expect(mockReq.log.error).toHaveBeenCalledWith(
        expect.objectContaining({
          event: 'sync_batch',
          outcome: 'failure',
          requestId: 'req-test-123',
          householdId: 'household-uuid-1',
          durationMs: expect.any(Number),
          errorName: 'ForbiddenException',
          errorMessage: 'Access denied: Category belongs to another household.',
        }),
      );
      expect(mockReq.log.info).not.toHaveBeenCalled();
    });
  });

  describe('pullData', () => {
    it('delegates pullData to syncService without modification', async () => {
      const pullResult = { categories: [], accounts: [], entries: [] };
      (mockSyncService.pullData as jest.Mock).mockResolvedValueOnce(pullResult);

      const result = await controller.pullData(mockReq as any);

      expect(mockSyncService.pullData).toHaveBeenCalledWith('household-uuid-1');
      expect(result).toBe(pullResult);
    });
  });
});
