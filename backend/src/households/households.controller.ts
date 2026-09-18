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
import { Throttle } from '@nestjs/throttler';
import { HouseholdsService } from './households.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CreateHouseholdDto, JoinHouseholdDto, UpdateHouseholdDto } from './dto/household.dto';

@ApiTags('households')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('households')
export class HouseholdsController {
  constructor(private readonly householdsService: HouseholdsService) {}

  @Post()
  @ApiOperation({ summary: 'Create a new household and generate its ID' })
  create(@Req() req: any, @Body() body: CreateHouseholdDto) {
    return this.householdsService.create(req.user.userId, body.name);
  }

  /**
   * Generate a single-use invite code for this household.
   * Only the household owner may call this endpoint.
   * Rate-limited to 5 req/min to prevent code-generation abuse.
   */
  @Post('invite')
  @Throttle({ default: { limit: 5, ttl: 60000 } })
  @ApiOperation({ summary: 'Generate a single-use invite code for the household (Owner only)' })
  generateInvite(@Req() req: any) {
    return this.householdsService.generateInvite(req.user.userId);
  }

  /**
   * Join a household by redeeming a single-use invite code.
   * The raw household UUID is no longer accepted — codes are resolved server-side.
   * Rate-limited to 10 req/min to prevent brute-force code enumeration.
   */
  @Post('join')
  @Throttle({ default: { limit: 10, ttl: 60000 } })
  @ApiOperation({ summary: 'Join a household by redeeming a single-use invite code' })
  join(@Req() req: any, @Body() body: JoinHouseholdDto) {
    return this.householdsService.joinByCode(req.user.userId, body.inviteCode);
  }

  @Get('me')
  @ApiOperation({ summary: 'Get current user household details and joined members' })
  findMe(@Req() req: any) {
    return this.householdsService.findMe(req.user.userId);
  }

  @Patch('me')
  @ApiOperation({ summary: 'Update household name (Owner only)' })
  updateName(@Req() req: any, @Body() body: UpdateHouseholdDto) {
    return this.householdsService.updateName(req.user.userId, body.name);
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
