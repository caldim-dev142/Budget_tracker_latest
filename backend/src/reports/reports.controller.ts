import { Controller, Get, Query, UseGuards, Req } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { ReportsService } from './reports.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@ApiTags('reports')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
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
}
