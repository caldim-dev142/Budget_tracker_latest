import { Controller, Post, Body, HttpCode, HttpStatus, Get, UseGuards, Req, Res, Inject } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { PrismaClient } from '@prisma/client';
import { FastifyReply } from 'fastify';

import { AuthService } from './auth.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { RequestOtpDto } from './dto/request-otp.dto';
import { VerifyOtpDto } from './dto/verify-otp.dto';
import { RefreshTokenDto, LogoutDto } from './dto/refresh-token.dto';
import { JwtAuthGuard } from './guards/jwt-auth.guard';

@ApiTags('auth')
@Controller('auth')
export class AuthController {
  constructor(
    private readonly authService: AuthService,
    @Inject('PRISMA') private readonly prisma?: PrismaClient,
  ) {}

  @Get('health')
  @ApiOperation({ summary: 'Health and DB connectivity check' })
  @ApiResponse({ status: 200, description: 'Application and database are healthy' })
  @ApiResponse({ status: 503, description: 'Database is unreachable' })
  async health(@Res({ passthrough: true }) res?: FastifyReply) {
    try {
      await this.prisma.$queryRaw`SELECT 1`;
      return {
        status: 'ok',
        db: 'ok',
        service: 'budget-tracker-backend',
        timestamp: new Date().toISOString(),
      };
    } catch {
      res?.status(HttpStatus.SERVICE_UNAVAILABLE);
      return {
        status: 'error',
        db: 'unreachable',
        timestamp: new Date().toISOString(),
      };
    }
  }

  @Post('request-otp')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Request a 6-digit email OTP for passwordless login or registration' })
  @Throttle({ default: { limit: 5, ttl: 60000 } }) // 5 requests per minute per IP
  requestOtp(@Body() dto: RequestOtpDto) {
    return this.authService.requestOtp(dto);
  }

  @Post('verify-otp')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Verify the 6-digit OTP and receive JWT access/refresh tokens' })
  @Throttle({ default: { limit: 10, ttl: 60000 } }) // 10 verification attempts per minute per IP
  verifyOtp(@Body() dto: VerifyOtpDto) {
    return this.authService.verifyOtp(dto);
  }

  @Post('register')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Register new user and household with email/password (legacy)' })
  @Throttle({ default: { limit: 5, ttl: 60000 } })
  register(@Body() dto: RegisterDto) {
    return this.authService.register(dto);
  }

  @Post('login')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Authenticate via password and get tokens (legacy)' })
  @Throttle({ default: { limit: 10, ttl: 60000 } })
  login(@Body() dto: LoginDto) {
    return this.authService.login(dto);
  }

  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Rotate refresh token' })
  @Throttle({ default: { limit: 20, ttl: 60000 } })
  refresh(@Body() body: RefreshTokenDto) {
    return this.authService.refresh(body.userId, body.refreshToken, body.family);
  }

  @Post('logout')
  @HttpCode(HttpStatus.NO_CONTENT)
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  logout(@Req() req: any, @Body() body: LogoutDto) {
    return this.authService.logout(req.user.userId, body?.family);
  }

  @Get('me')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get current user' })
  me(@Req() req: any) {
    return req.user;
  }
}
