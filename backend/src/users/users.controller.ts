import { Controller, Get, Body, Patch, Delete, UseGuards, Req } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { UsersService } from './users.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { UpdateUserDto } from './dto/update-user.dto';

@ApiTags('users')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get('me')
  @ApiOperation({ summary: 'Get current user profile' })
  findMe(@Req() req: any) {
    return this.usersService.findOne(req.user.userId);
  }

  @Patch('me')
  @ApiOperation({ summary: 'Update profile display name' })
  updateDisplayName(@Req() req: any, @Body() body: UpdateUserDto) {
    return this.usersService.updateDisplayName(req.user.userId, body.displayName.trim());
  }

  @Delete('me')
  @ApiOperation({ summary: 'Permanently delete user account and associated personal data' })
  deleteMe(@Req() req: any) {
    return this.usersService.deleteAccount(req.user.userId);
  }
}
