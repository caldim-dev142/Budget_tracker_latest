import { Controller, Post, Body, HttpCode, HttpStatus, Get, UseGuards, Req } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';

import { AuthService } from './auth.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { RefreshTokenDto, LogoutDto } from './dto/refresh-token.dto';
import { GoogleSignInDto } from './dto/google-sign-in.dto';
import { JwtAuthGuard } from './guards/jwt-auth.guard';

@ApiTags('auth')
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Get('health')
  @ApiOperation({ summary: 'Health and DB connectivity check' })
  health() {
    return {
      status: 'ok',
      service: 'budget-tracker-backend',
      timestamp: new Date().toISOString(),
    };
  }

  @Post('register')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Register new user and household' })
  @Throttle({ default: { limit: 5, ttl: 60000 } }) // 5/min for registration
  register(@Body() dto: RegisterDto) {
    return this.authService.register(dto);
  }

  @Post('google')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Authenticate via Google ID token' })
  // Credential endpoint: throttle it like login rather than leaving it on the
  // 100/min global default, which allows sustained token probing.
  @Throttle({ default: { limit: 10, ttl: 60000 } })
  googleSignIn(@Body() dto: GoogleSignInDto) {
    return this.authService.googleSignIn(dto.idToken);
  }

  @Post('login')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Authenticate and get tokens' })
  @Throttle({ default: { limit: 10, ttl: 60000 } })
  login(@Body() dto: LoginDto) {
    return this.authService.login(dto);
  }

  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Rotate refresh token' })
  // Credential endpoint: a refresh token is a bearer secret, so this must not
  // sit on the permissive global default.
  @Throttle({ default: { limit: 20, ttl: 60000 } })
  refresh(@Body() body: RefreshTokenDto) {
    // The raw token is passed through; AuthService hashes it exactly once before lookup.
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
