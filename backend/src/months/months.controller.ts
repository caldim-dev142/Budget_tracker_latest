import { Controller, Get, Post, Body, Query, UseGuards, Req } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { MonthsService } from './months.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { HouseholdGuard } from '../auth/guards/household.guard';
import { YearMonthPipe } from '../common/pipes/year-month.pipe';

@ApiTags('months')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, HouseholdGuard)
@Controller('months')
export class MonthsController {
  constructor(private readonly monthsService: MonthsService) {}

  @Get('snapshot')
  @ApiOperation({ summary: 'Get frozen/open month snapshot details' })
  getSnapshot(@Req() req: any, @Query('yearMonth', YearMonthPipe) yearMonth: string) {
    return this.monthsService.getSnapshot(req.user.householdId, yearMonth);
  }

  @Post('close')
  @ApiOperation({ summary: 'Close a month and execute rollover' })
  closeMonth(
    @Req() req: any,
    @Query('yearMonth', YearMonthPipe) yearMonth: string,
    @Body()
    actuals: {
      openingBalance: number;
      lastMonthReserves: number;
      income: number;
      adjustments: number;
      spending: number;
      protection: number;
      saving: number;
      reserves: number;
      totalAvailable: number;
    },
  ) {
    return this.monthsService.closeMonth(req.user.householdId, yearMonth, actuals);
  }

  @Post('reopen')
  @ApiOperation({ summary: 'Reopen a previously closed month (idempotent)' })
  reopenMonth(@Req() req: any, @Query('yearMonth', YearMonthPipe) yearMonth: string) {
    return this.monthsService.reopenMonth(req.user.householdId, yearMonth);
  }
}
