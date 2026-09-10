import { PrismaClient } from '@prisma/client';
import { AuthService } from './auth/auth.service';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { FirebaseAdminService } from './auth/firebase-admin.service';

const prisma = new PrismaClient();

async function runVerification() {
  console.log('=== VERIFYING SUPABASE REGISTRATION & PERSISTENCE FLOW ===');

  const configService = new ConfigService({
    JWT_ACCESS_SECRET: 'test_super_secret_jwt_access_token_min_32_chars_123',
    JWT_ACCESS_EXPIRY: '15m',
    JWT_REFRESH_SECRET: 'test_super_secret_jwt_refresh_token_min_32_chars_123',
    JWT_REFRESH_EXPIRY: '30d',
    FIREBASE_PROJECT_ID: 'budget-tracker-d034f',
  });

  const jwtService = new JwtService({});
  const firebaseAdmin = new FirebaseAdminService(configService);
  const authService = new AuthService(prisma, jwtService, configService, firebaseAdmin);

  const testEmail = `test.user.${Date.now()}@example.com`;
  const testPassword = 'SecurePassword123!';
  const testDisplayName = 'Antigravity Test User';
  const testHouseholdName = 'Antigravity Test Family';

  try {
    // 1. Execute Registration Flow
    console.log(`\n1. Registering user: ${testEmail}...`);
    const regResult = await authService.register({
      email: testEmail,
      password: testPassword,
      displayName: testDisplayName,
      householdName: testHouseholdName,
    });

    console.log('Registration response tokens and user:', {
      userId: regResult.user.id,
      householdId: regResult.user.householdId,
      email: regResult.user.email,
      hasAccessToken: !!regResult.accessToken,
    });

    const userId = regResult.user.id;
    const householdId = regResult.user.householdId;

    // 2. Query Supabase directly for User record
    console.log('\n2. Verifying User record in Supabase `users` table...');
    const dbUser = await prisma.user.findUnique({
      where: { id: userId },
    });

    if (!dbUser) {
      throw new Error(`FAILED: User ${userId} not found in Supabase users table!`);
    }
    console.log('✔ User found in Supabase:', {
      id: dbUser.id,
      email: dbUser.email,
      displayName: dbUser.displayName,
      household_id: dbUser.household_id,
      auth_provider: dbUser.auth_provider,
    });

    // 3. Query Supabase directly for Household record
    console.log('\n3. Verifying Household record in Supabase `households` table...');
    const dbHousehold = await prisma.household.findUnique({
      where: { id: householdId },
    });

    if (!dbHousehold) {
      throw new Error(`FAILED: Household ${householdId} not found in Supabase households table!`);
    }
    console.log('✔ Household found in Supabase:', {
      id: dbHousehold.id,
      name: dbHousehold.name,
      ownerId: dbHousehold.ownerId,
    });

    if (dbHousehold.ownerId !== userId) {
      throw new Error(`FAILED: Household ownerId ${dbHousehold.ownerId} does not match userId ${userId}!`);
    }

    if (dbHousehold.name !== testHouseholdName) {
      throw new Error(`FAILED: Household name ${dbHousehold.name} does not match expected ${testHouseholdName}!`);
    }

    // 4. Query Supabase directly for Categories seeded for this household
    console.log('\n4. Verifying Category seed records in Supabase `categories` table...');
    const dbCategories = await prisma.category.findMany({
      where: { householdId: householdId },
    });

    console.log(`✔ Categories found for household ${householdId}: ${dbCategories.length} categories.`);
    if (dbCategories.length === 0) {
      throw new Error(`FAILED: No categories seeded for household ${householdId}!`);
    }

    // 5. Test Duplicate Registration (Idempotency / Conflict check)
    console.log('\n5. Testing Duplicate Registration handling...');
    try {
      await authService.register({
        email: testEmail,
        password: testPassword,
        displayName: testDisplayName,
        householdName: testHouseholdName,
      });
      throw new Error('FAILED: Duplicate registration should have thrown ConflictException!');
    } catch (err: any) {
      if (err.message.includes('Email already registered')) {
        console.log('✔ Duplicate registration correctly rejected with ConflictException.');
      } else {
        throw err;
      }
    }

    // 6. Test Login for Existing User
    console.log('\n6. Testing Login flow for registered user...');
    const loginResult = await authService.login({
      email: testEmail,
      password: testPassword,
    });
    console.log('✔ Login successful. User ID and Household match:', {
      userId: loginResult.user.id,
      householdId: loginResult.user.householdId,
    });

    // 7. Cleanup test data from Supabase
    console.log('\n7. Cleaning up test data...');
    await prisma.category.deleteMany({ where: { householdId } });
    await prisma.user.delete({ where: { id: userId } });
    await prisma.household.delete({ where: { id: householdId } });
    console.log('✔ Test data cleaned up successfully.');

    console.log('\n=== ALL SUPABASE REGISTRATION & PERSISTENCE TESTS PASSED! ===\n');
  } catch (error) {
    console.error('\n❌ VERIFICATION FAILED:', error);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

runVerification();
