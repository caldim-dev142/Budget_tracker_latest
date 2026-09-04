import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';

import { AuthService } from './auth.service';
import { AuthController } from './auth.controller';
import { JwtStrategy } from './strategies/jwt.strategy';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import { FirebaseAdminService } from './firebase-admin.service';

@Module({
  imports: [
    PassportModule.register({ defaultStrategy: 'jwt' }),
    JwtModule.register({}), // secrets injected dynamically in AuthService
  ],
  providers: [AuthService, JwtStrategy, JwtAuthGuard, FirebaseAdminService],
  controllers: [AuthController],
  exports: [AuthService, JwtAuthGuard, FirebaseAdminService],
})
export class AuthModule {}
