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
  syncBatch(@Req() req: any, @Body() dto: SyncBatchDto) {
    return this.syncService.syncBatch(req.user.householdId, dto, req.user.userId);
  }
}
