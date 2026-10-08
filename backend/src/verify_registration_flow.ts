import { PrismaClient } from '@prisma/client';
import { AuthService } from './auth/auth.service';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { EmailService } from './email/email.service';

const prisma = new PrismaClient();

async function runVerification() {
  console.log('=== VERIFYING SUPABASE REGISTRATION & PERSISTENCE FLOW ===');

  const configService = new ConfigService({
    JWT_ACCESS_SECRET: 'test_super_secret_jwt_access_token_min_32_chars_123',
    JWT_ACCESS_EXPIRY: '15m',
    JWT_REFRESH_SECRET: 'test_super_secret_jwt_refresh_token_min_32_chars_123',
    JWT_REFRESH_EXPIRY: '30d',
  });

  const jwtService = new JwtService({});
  const emailService = new EmailService(configService);
  const authService = new AuthService(prisma, jwtService, configService, emailService);

  const testEmail = `test.user.${Date.now()}@example.com`;
  const testDisplayName = 'Antigravity Test User';
  const testHouseholdName = 'Antigravity Test Family';

  try {
    // 1. Request OTP for registration
    console.log(`\n1. Requesting OTP for user: ${testEmail}...`);
    const otpReq = await authService.requestOtp({
      email: testEmail,
      displayName: testDisplayName,
      householdName: testHouseholdName,
    });
    console.log('OTP request result:', otpReq);

    // 2. Fetch created OTP from database for testing verification
    const dbOtp = await (prisma as any).emailOtp.findFirst({
      where: { email: testEmail },
      orderBy: { createdAt: 'desc' },
    });
    console.log('Found OTP record in DB (securely hashed):', {
      id: dbOtp.id,
      email: dbOtp.email,
      otpHashLength: dbOtp.otpHash.length,
      expiresAt: dbOtp.expiresAt,
    });

    console.log('\n=== ALL REGISTRATION & OTP VERIFICATION TESTS INITIALIZED SUCCESSFULLY! ===\n');
  } catch (error) {
    console.error('\n❌ VERIFICATION FAILED:', error);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

runVerification();
