import { Controller, Get, Post, Body, Query, UseGuards, Req } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { BudgetsService } from './budgets.service';
import { UpdateBudgetDto } from './dto/update-budget.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@ApiTags('budgets')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('budgets')
export class BudgetsController {
  constructor(private readonly budgetsService: BudgetsService) {}

  @Get()
  @ApiOperation({ summary: 'Get budgets for a given year-month' })
  findByMonth(@Req() req: any, @Query('yearMonth') yearMonth: string) {
    return this.budgetsService.findByMonth(req.user.householdId, yearMonth);
  }

  @Post('bulk')
  @ApiOperation({ summary: 'Bulk upsert budgets for a given year-month' })
  upsertBulk(
    @Req() req: any,
    @Query('yearMonth') yearMonth: string,
    @Body() items: UpdateBudgetDto[],
  ) {
    return this.budgetsService.upsertBulk(req.user.householdId, yearMonth, items);
  }
}
