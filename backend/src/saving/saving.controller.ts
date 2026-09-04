import { Controller, Get, Post, Body, Param, UseGuards, Req } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { SavingService } from './saving.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@ApiTags('saving')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('saving')
export class SavingController {
  constructor(private readonly savingService: SavingService) {}

  @Get()
  @ApiOperation({ summary: 'Get all saving goals and their contributions' })
  findAll(@Req() req: any) {
    return this.savingService.findAll(req.user.householdId);
  }

  @Post()
  @ApiOperation({ summary: 'Create a new saving goal' })
  createGoal(
    @Req() req: any,
    @Body('bucket') bucket: string,
    @Body('name') name: string,
    @Body('monthlyBudgetPaise') monthlyBudgetPaise: number,
    @Body('targetPaise') targetPaise?: number,
  ) {
    return this.savingService.createGoal(
      req.user.householdId,
      bucket,
      name,
      monthlyBudgetPaise,
      targetPaise,
    );
  }

  @Post(':goalId/contributions')
  @ApiOperation({ summary: 'Record goal contribution' })
  addContribution(
    @Req() req: any,
    @Param('goalId') goalId: string,
    @Body('amountPaise') amountPaise: number,
    @Body('note') note?: string,
  ) {
    return this.savingService.addContribution(
      req.user.householdId,
      goalId,
      amountPaise,
      note,
    );
  }
}
