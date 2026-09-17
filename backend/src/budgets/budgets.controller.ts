import { Controller, Get, Post, Body, Query, UseGuards, Req, ParseArrayPipe } from '@nestjs/common';
import { YearMonthPipe } from '../common/pipes/year-month.pipe';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { BudgetsService } from './budgets.service';
import { UpdateBudgetDto } from './dto/update-budget.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { HouseholdGuard } from '../auth/guards/household.guard';

@ApiTags('budgets')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, HouseholdGuard)
@Controller('budgets')
export class BudgetsController {
  constructor(private readonly budgetsService: BudgetsService) {}

  @Get()
  @ApiOperation({ summary: 'Get budgets for a given year-month' })
  findByMonth(@Req() req: any, @Query('yearMonth', YearMonthPipe) yearMonth: string) {
    return this.budgetsService.findByMonth(req.user.householdId, yearMonth);
  }

  @Post('bulk')
  @ApiOperation({ summary: 'Bulk upsert budgets for a given year-month' })
  upsertBulk(
    @Req() req: any,
    @Query('yearMonth', YearMonthPipe) yearMonth: string,
    @Body(new ParseArrayPipe({ items: UpdateBudgetDto, whitelist: true, forbidNonWhitelisted: true }))
    items: UpdateBudgetDto[],
  ) {
    return this.budgetsService.upsertBulk(req.user.householdId, yearMonth, items);
  }
}
