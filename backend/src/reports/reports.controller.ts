import { Controller, Get, Query, UseGuards, Req, BadRequestException } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { ReportsService } from './reports.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { HouseholdGuard } from '../auth/guards/household.guard';

@ApiTags('reports')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, HouseholdGuard)
@Controller('reports')
export class ReportsController {
  constructor(private readonly reportsService: ReportsService) {}

  private getYearMonth(yearMonth?: string): string {
    if (yearMonth && /^\d{4}-\d{2}$/.test(yearMonth)) {
      return yearMonth;
    }
    const d = new Date();
    return `${d.getFullYear()}-${(d.getMonth() + 1).toString().padStart(2, '0')}`;
  }

  @Get('dashboard')
  @ApiOperation({ summary: 'Get dashboard summaries & waterfall calculations' })
  getDashboard(@Req() req: any, @Query('yearMonth') yearMonth?: string) {
    const ym = this.getYearMonth(yearMonth);
    return this.reportsService.getDashboard(req.user.householdId, ym);
  }

  @Get('budget-vs-actual')
  @ApiOperation({ summary: 'Get budget vs actual comparison per category' })
  getBudgetVsActual(@Req() req: any, @Query('yearMonth') yearMonth?: string) {
    const ym = this.getYearMonth(yearMonth);
    return this.reportsService.getBudgetVsActual(req.user.householdId, ym);
  }

  @Get('trends')
  @ApiOperation({ summary: 'Get monthly trends from closed snapshots (real data only)' })
  getMonthlyTrends(@Req() req: any, @Query('months') months?: string) {
    const n = months ? Math.min(Math.max(parseInt(months, 10) || 6, 1), 24) : 6;
    return this.reportsService.getMonthlyTrends(req.user.householdId, n);
  }

  @Get('yearly')
  @ApiOperation({ summary: 'Get yearly summary from closed snapshots (real data only)' })
  getYearlySummary(@Req() req: any, @Query('year') year?: string) {
    if (year !== undefined && !/^\d{4}$/.test(year)) {
      throw new BadRequestException('year must be a 4-digit year.');
    }
    const y = year ? parseInt(year, 10) : new Date().getFullYear();
    return this.reportsService.getYearlySummary(req.user.householdId, y);
  }
}
