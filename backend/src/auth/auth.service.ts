import { Injectable, Inject, UnauthorizedException, ConflictException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { PrismaClient } from '@prisma/client';
import * as argon2 from 'argon2';
import { randomBytes, createHash } from 'crypto';
import { v4 as uuidv4 } from 'uuid';

import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { FirebaseAdminService } from './firebase-admin.service';
import { seedCategories } from '../categories/categories-seed.data';

@Injectable()
export class AuthService {
  constructor(
    @Inject('PRISMA') private readonly prisma: PrismaClient,
    private readonly jwtService: JwtService,
    private readonly config: ConfigService,
    private readonly firebaseAdmin: FirebaseAdminService,
  ) {}

  async googleSignIn(idToken: string) {
    if (!idToken || typeof idToken !== 'string' || idToken.trim().length === 0) {
      throw new UnauthorizedException('Missing or invalid Firebase ID token.');
    }

    const decodedToken = await this.firebaseAdmin.verifyIdToken(idToken);
    const email = decodedToken.email;

    if (!email) {
      throw new UnauthorizedException('Firebase ID token missing verified email address.');
    }

    const displayName = decodedToken.name || email.split('@')[0];

    let user = await this.prisma.user.findFirst({
      where: { email },
    });

    if (!user) {
      const userId = uuidv4();
      const householdId = uuidv4();

      user = await this.prisma.user.create({
        data: {
          id: userId,
          email,
          displayName,
          household_id: householdId,
          auth_provider: 'google',
        },
      });

      await this.ensureHouseholdAndDefaults(userId, householdId, displayName);
    } else if (user.household_id) {
      await this.ensureHouseholdAndDefaults(user.id, user.household_id, user.displayName);
    }

    const tokens = await this.issueTokens(user.id, user.household_id ?? '');
    return {
      ...tokens,
      user: {
        id: user.id,
        email: user.email,
        displayName: user.displayName,
        householdId: user.household_id ?? '',
      },
    };
  }

  async register(dto: RegisterDto) {
    const existing = await this.prisma.user.findFirst({ where: { email: dto.email } });
    if (existing) throw new ConflictException('Email already registered.');

    const passwordHash = await argon2.hash(dto.password, {
      type: argon2.argon2id,
      memoryCost: 65536,
      timeCost: 3,
      parallelism: 1,
    });

    const userId = uuidv4();
    const householdId = uuidv4();

    const user = await this.prisma.user.create({
      data: {
        id: userId,
        email: dto.email,
        password: passwordHash,
        displayName: dto.displayName,
        household_id: householdId,
        auth_provider: 'email',
      },
    });

    await this.ensureHouseholdAndDefaults(userId, householdId, dto.displayName);

    const tokens = await this.issueTokens(user.id, householdId);
    return {
      ...tokens,
      user: {
        id: user.id,
        email: user.email,
        displayName: user.displayName,
        householdId,
      },
    };
  }

  async login(dto: LoginDto) {
    const user = await this.prisma.user.findFirst({
      where: { email: dto.email },
    });

    if (!user || !user.password) {
      throw new UnauthorizedException('Invalid credentials.');
    }

    const valid = await argon2.verify(user.password, dto.password);
    if (!valid) throw new UnauthorizedException('Invalid credentials.');

    if (user.household_id) {
      await this.ensureHouseholdAndDefaults(user.id, user.household_id, user.displayName);
    }

    const tokens = await this.issueTokens(user.id, user.household_id ?? '');
    return {
      ...tokens,
      user: {
        id: user.id,
        email: user.email,
        displayName: user.displayName,
        householdId: user.household_id ?? '',
      },
    };
  }

  async refresh(userId: string, tokenHash: string, family?: string) {
    const user = await this.prisma.user.findFirst({
      where: { id: userId },
    });
    if (!user) throw new UnauthorizedException('User not found.');
    return this.issueTokens(userId, user.household_id ?? '', family);
  }

  async logout(userId: string, family: string) {
    // Stateless logout fallback
  }

  async issueTokens(userId: string, householdId: string, family?: string) {
    const payload = { sub: userId, householdId };
    const accessToken = this.jwtService.sign(payload, {
      secret: this.config.get('JWT_ACCESS_SECRET'),
      expiresIn: this.config.get('JWT_ACCESS_EXPIRY', '15m'),
    });

    const rawRefresh = randomBytes(64).toString('hex');
    const tokenFamily = family ?? uuidv4();

    return {
      accessToken,
      refreshToken: rawRefresh,
      refreshTokenFamily: tokenFamily,
    };
  }

  async ensureHouseholdAndDefaults(userId: string, householdId: string, displayName: string) {
    try {
      await this.prisma.household.upsert({
        where: { id: householdId },
        create: {
          id: householdId,
          name: `${displayName}'s Household`,
          ownerId: userId,
        },
        update: {},
      });

      await this.seedCategoriesForHousehold(householdId);
      await this.seedDefaultAccountsForHousehold(householdId);
    } catch (e) {
      console.error('Failed to ensure household and defaults:', e);
    }
  }

  async seedDefaultAccountsForHousehold(householdId: string) {
    // Remove any stale default accounts seeded by older app versions.
    // Accounts are now created explicitly by the user only.
    try {
      await this.prisma.account.deleteMany({
        where: {
          householdId,
          name: { in: ['Savings Account', 'Cash Wallet'] },
        },
      });
    } catch (_) {}
  }

  private async seedCategoriesForHousehold(householdId: string) {
    try {
      const data = seedCategories.map((c) => ({
        id: `${householdId}-${c.id}`,
        householdId,
        kind: c.kind,
        groupCode: c.groupCode ?? null,
        name: c.name,
        needOrWant: c.needOrWant ?? null,
        isDeduction: c.isDeduction,
        isSystem: c.isSystem,
        sortOrder: c.sortOrder,
      }));

      await this.prisma.category.createMany({
        data,
        skipDuplicates: true,
      });
    } catch (e) {
      console.error(`Failed to seed categories for household ${householdId}:`, e);
    }
  }
}
