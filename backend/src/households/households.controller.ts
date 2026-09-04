import { Controller, Get, Body, Patch, UseGuards, Req } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { HouseholdsService } from './households.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@ApiTags('households')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('households')
export class HouseholdsController {
  constructor(private readonly householdsService: HouseholdsService) {}

  @Get('me')
  @ApiOperation({ summary: 'Get current user household details' })
  findMe(@Req() req: any) {
    return this.householdsService.findOne(req.user.householdId);
  }

  @Patch('me')
  @ApiOperation({ summary: 'Update household name' })
  updateName(@Req() req: any, @Body('name') name: string) {
    return this.householdsService.updateName(req.user.householdId, name);
  }
}
