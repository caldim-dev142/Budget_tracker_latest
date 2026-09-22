import { Controller, Get, Post, Body, UseGuards, Req } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { SyncService } from './sync.service';
import { SyncBatchDto } from './dto/sync-batch.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { HouseholdGuard } from '../auth/guards/household.guard';

@ApiTags('sync')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, HouseholdGuard)
@Controller('sync')
export class SyncController {
  constructor(private readonly syncService: SyncService) {}

  @Get('pull')
  @ApiOperation({ summary: 'Pull all household data from server to client' })
  pullData(@Req() req: any) {
    return this.syncService.pullData(req.user.householdId);
  }

  @Post('batch')
  @ApiOperation({ summary: 'Synchronize offline client actions' })
  async syncBatch(@Req() req: any, @Body() dto: SyncBatchDto) {
    const startTime = Date.now();
    const householdId = req.user?.householdId;
    const requestId = req.id || req.headers?.['x-request-id'] || '';

    try {
      const result = await this.syncService.syncBatch(householdId, dto, req.user?.userId);
      const durationMs = Date.now() - startTime;

      req.log?.info?.({
        event: 'sync_batch',
        outcome: 'success',
        requestId,
        householdId,
        durationMs,
        counts: {
          categories: dto.categories?.length ?? 0,
          accounts: dto.accounts?.length ?? 0,
          creditCards: dto.creditCards?.length ?? 0,
          cardTransactions: dto.cardTransactions?.length ?? 0,
          plannedBills: dto.plannedBills?.length ?? 0,
          receivables: dto.receivables?.length ?? 0,
          savingGoals: dto.savingGoals?.length ?? 0,
          goalContributions: dto.goalContributions?.length ?? 0,
          sinkingFunds: dto.sinkingFunds?.length ?? 0,
          fundMovements: dto.fundMovements?.length ?? 0,
          budgets: dto.budgets?.length ?? 0,
          reserveLines: dto.reserveLines?.length ?? 0,
          annualTargets: dto.annualTargets?.length ?? 0,
          entries: dto.entries?.length ?? 0,
          deletions: dto.deletions?.length ?? 0,
        },
      });

      return result;
    } catch (err: any) {
      const durationMs = Date.now() - startTime;

      req.log?.error?.({
        event: 'sync_batch',
        outcome: 'failure',
        requestId,
        householdId,
        durationMs,
        errorName: err?.name,
        errorMessage: err?.message,
      });

      throw err;
    }
  }
}
