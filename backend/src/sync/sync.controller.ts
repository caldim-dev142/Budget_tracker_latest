import { Controller, Get, Post, Body, UseGuards, Req } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { SyncService, SyncBatchDto } from './sync.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@ApiTags('sync')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
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
