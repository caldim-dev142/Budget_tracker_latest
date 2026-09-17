import { Controller, Get, Post, Patch, Body, Param, UseGuards, Req } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { AccountsService } from './accounts.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { HouseholdGuard } from '../auth/guards/household.guard';
import { CreateAccountDto, UpdateAccountBalanceDto } from './dto/account.dto';

@ApiTags('accounts')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, HouseholdGuard)
@Controller('accounts')
export class AccountsController {
  constructor(private readonly accountsService: AccountsService) {}

  @Get()
  @ApiOperation({ summary: 'Get all active bank/cash accounts' })
  findAll(@Req() req: any) {
    return this.accountsService.findAll(req.user.householdId);
  }

  @Post()
  @ApiOperation({ summary: 'Create a new account' })
  createAccount(@Req() req: any, @Body() body: CreateAccountDto) {
    return this.accountsService.createAccount(req.user.householdId, body.name, body.type as 'bank' | 'cash', body.balancePaise);
  }

  @Patch(':id/balance')
  @ApiOperation({ summary: 'Update/reconcile account balance' })
  updateBalance(
    @Req() req: any,
    @Param('id') id: string,
    @Body() body: UpdateAccountBalanceDto,
  ) {
    return this.accountsService.updateBalance(req.user.householdId, id, body.balancePaise);
  }
}
