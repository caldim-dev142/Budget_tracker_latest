import { Controller, Get, Post, Body, Param, UseGuards, Req } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { ProtectionService } from './protection.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@ApiTags('protection')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('protection')
export class ProtectionController {
  constructor(private readonly protectionService: ProtectionService) {}

  @Get()
  @ApiOperation({ summary: 'Get all sinking funds and their details' })
  findAll(@Req() req: any) {
    return this.protectionService.findAll(req.user.householdId);
  }

  @Post()
  @ApiOperation({ summary: 'Create a new sinking fund' })
  createFund(
    @Req() req: any,
    @Body('name') name: string,
    @Body('openingReservePaise') openingReservePaise: number,
  ) {
    return this.protectionService.createFund(req.user.householdId, name, openingReservePaise);
  }

  @Post(':fundId/movements')
  @ApiOperation({ summary: 'Record contribution or withdrawal movement' })
  addMovement(
    @Req() req: any,
    @Param('fundId') fundId: string,
    @Body('type') type: 'contribution' | 'withdrawal',
    @Body('amountPaise') amountPaise: number,
    @Body('note') note?: string,
  ) {
    return this.protectionService.addMovement(
      req.user.householdId,
      fundId,
      type,
      amountPaise,
      note,
    );
  }
}
