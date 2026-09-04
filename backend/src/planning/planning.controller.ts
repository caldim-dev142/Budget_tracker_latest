import { Controller, Get, Post, Patch, Body, Param, Query, UseGuards, Req } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { PlanningService } from './planning.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@ApiTags('planning')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('planning')
export class PlanningController {
  constructor(private readonly planningService: PlanningService) {}

  @Get('receivables')
  @ApiOperation({ summary: 'Get all receivables' })
  getReceivables(@Req() req: any) {
    return this.planningService.getReceivables(req.user.householdId);
  }

  @Post('receivables')
  @ApiOperation({ summary: 'Create a new receivable record' })
  createReceivable(
    @Req() req: any,
    @Body('personName') personName: string,
    @Body('amountPaise') amountPaise: number,
    @Body('dueDate') dueDate?: string,
  ) {
    return this.planningService.createReceivable(req.user.householdId, personName, amountPaise, dueDate);
  }

  @Patch('receivables/:id')
  @ApiOperation({ summary: 'Mark receivable as open/returned' })
  updateReceivableStatus(
    @Req() req: any,
    @Param('id') id: string,
    @Body('status') status: 'open' | 'returned',
  ) {
    return this.planningService.updateReceivableStatus(req.user.householdId, id, status);
  }

  @Get('bills')
  @ApiOperation({ summary: 'Get all planned bills' })
  getPlannedBills(@Req() req: any) {
    return this.planningService.getPlannedBills(req.user.householdId);
  }

  @Post('bills')
  @ApiOperation({ summary: 'Create a new planned bill' })
  createPlannedBill(
    @Req() req: any,
    @Body('name') name: string,
    @Body('amountPaise') amountPaise: number,
    @Body('dueDate') dueDate?: string,
  ) {
    return this.planningService.createPlannedBill(req.user.householdId, name, amountPaise, dueDate);
  }

  @Patch('bills/:id')
  @ApiOperation({ summary: 'Mark planned bill as paid/unpaid' })
  markBillPaid(
    @Req() req: any,
    @Param('id') id: string,
    @Body('isPaid') isPaid: boolean,
  ) {
    return this.planningService.markBillPaid(req.user.householdId, id, isPaid);
  }

  @Get('reserves')
  @ApiOperation({ summary: 'Get reserve lines for a given year-month' })
  getReserveLines(@Req() req: any, @Query('yearMonth') yearMonth: string) {
    return this.planningService.getReserveLines(req.user.householdId, yearMonth);
  }

  @Post('reserves')
  @ApiOperation({ summary: 'Upsert reserve lines for a given year-month' })
  upsertReserveLines(
    @Req() req: any,
    @Query('yearMonth') yearMonth: string,
    @Body() lines: { name: string; amountPaise: number }[],
  ) {
    return this.planningService.upsertReserveLines(req.user.householdId, yearMonth, lines);
  }
}
