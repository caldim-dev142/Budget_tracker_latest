import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  UseGuards,
  Req,
} from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { HouseholdsService } from './households.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@ApiTags('households')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('households')
export class HouseholdsController {
  constructor(private readonly householdsService: HouseholdsService) {}

  @Post()
  @ApiOperation({ summary: 'Create a new household and generate its ID' })
  create(@Req() req: any, @Body('name') name?: string) {
    return this.householdsService.create(req.user.userId, name);
  }

  @Post('join')
  @ApiOperation({ summary: 'Join an existing household by household ID' })
  join(@Req() req: any, @Body('householdId') householdId: string) {
    return this.householdsService.join(req.user.userId, householdId);
  }

  @Get('me')
  @ApiOperation({ summary: 'Get current user household details and joined members' })
  findMe(@Req() req: any) {
    return this.householdsService.findMe(req.user.userId);
  }

  @Patch('me')
  @ApiOperation({ summary: 'Update household name (Owner only)' })
  updateName(@Req() req: any, @Body('name') name: string) {
    return this.householdsService.updateName(req.user.userId, name);
  }

  @Delete('me')
  @ApiOperation({ summary: 'Delete household and disassociate all members (Owner only)' })
  deleteHousehold(@Req() req: any) {
    return this.householdsService.deleteHousehold(req.user.userId);
  }

  @Delete('members/:memberId')
  @ApiOperation({ summary: 'Remove an individual member from the household (Owner only)' })
  removeMember(@Req() req: any, @Param('memberId') memberId: string) {
    return this.householdsService.removeMember(req.user.userId, memberId);
  }
}
