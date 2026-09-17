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
import { buildSystemCategoriesForHousehold } from '../categories/categories-system.data';

export function normalizeEmail(email: string | undefined | null): string {
  return (email ?? '').trim().toLowerCase();
}

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
    const email = normalizeEmail(decodedToken.email);

    if (!email) {
      throw new UnauthorizedException('Firebase ID token missing verified email address.');
    }

    const displayName = decodedToken.name || email.split('@')[0];

    let user = await this.findUserByEmail(email);

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
    const email = normalizeEmail(dto.email);
    const existing = await this.findUserByEmail(email);
    if (existing) throw new ConflictException('Email already registered.');

    const passwordHash = await argon2.hash(dto.password, {
      type: argon2.argon2id,
      memoryCost: 65536,
      timeCost: 3,
      parallelism: 1,
    });

    const userId = uuidv4();
    const householdId = uuidv4();
    const householdName =
      dto.householdName && dto.householdName.trim().length > 0
        ? dto.householdName.trim()
        : `${dto.displayName}'s Household`;

    let user;
    try {
      user = await this.prisma.user.create({
      data: {
        id: userId,
        email,
        password: passwordHash,
        displayName: dto.displayName,
        household_id: householdId,
        auth_provider: 'email',
      },
      });
    } catch (e: any) {
      // users.email is unique: a concurrent registration for the same address loses the race.
      if (e?.code === 'P2002') throw new ConflictException('Email already registered.');
      throw e;
    }

    await this.ensureHouseholdAndDefaults(userId, householdId, dto.displayName, householdName);

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
    const user = await this.findUserByEmail(normalizeEmail(dto.email));

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

  /** Case-insensitive lookup; the oldest account wins if legacy case-variant duplicates exist. */
  private findUserByEmail(email: string) {
    return this.prisma.user.findFirst({
      where: { email: { equals: email, mode: 'insensitive' } },
      orderBy: { createdAt: 'asc' },
    });
  }

  /**
   * Rotate refresh token:
   * 1. Hash the incoming raw token.
   * 2. Look it up in the DB - must exist, not used, not expired, and belong to the correct user.
   * 3. Mark it as used (invalidated).
   * 4. Issue a new token pair in the same family.
   *
   * If the token is already used (reuse detected), invalidate the entire family to protect
   * against refresh token theft (RFC 6819 Section 5.2.2.3).
   */
  async refresh(userId: string, rawRefreshToken: string, family: string) {
    if (!rawRefreshToken || !userId || !family) {
      throw new UnauthorizedException('Missing refresh token parameters.');
    }

    const tokenHash = createHash('sha256').update(rawRefreshToken).digest('hex');

    const stored = await (this.prisma as any).refreshToken.findUnique({
      where: { tokenHash },
    });

    if (!stored) {
      throw new UnauthorizedException('Invalid or unrecognized refresh token.');
    }

    // Verify ownership - token must belong to the requesting user
    if (stored.userId !== userId) {
      throw new UnauthorizedException('Refresh token ownership mismatch.');
    }

    // The client-supplied family must match the stored session family.
    if (stored.family !== family) {
      throw new UnauthorizedException('Refresh token family mismatch.');
    }

    // Detect token reuse: if already used, invalidate entire family (theft detection)
    if (stored.usedAt !== null) {
      await (this.prisma as any).refreshToken.deleteMany({ where: { family: stored.family } });
      throw new UnauthorizedException('Refresh token already used. All sessions invalidated for security.');
    }

    // Check expiry
    if (new Date() > stored.expiresAt) {
      await (this.prisma as any).refreshToken.delete({ where: { tokenHash } });
      throw new UnauthorizedException('Refresh token has expired. Please log in again.');
    }

    // Mark current token as used (rotate)
    await (this.prisma as any).refreshToken.update({
      where: { tokenHash },
      data: { usedAt: new Date() },
    });

    const user = await this.prisma.user.findFirst({ where: { id: userId } });
    if (!user) throw new UnauthorizedException('User not found.');

    // Issue new token pair in the same family
    return this.issueTokens(userId, user.household_id ?? '', stored.family);
  }

  /**
   * Logout: invalidate all refresh tokens in the given family,
   * preventing further token rotation after logout.
   */
  async logout(userId: string, family?: string) {
    if (family) {
      // Revoke specific session by family
      await (this.prisma as any).refreshToken.deleteMany({
        where: { userId, family },
      });
    } else {
      // Revoke all sessions for this user (sign out everywhere)
      await (this.prisma as any).refreshToken.deleteMany({
        where: { userId },
      });
    }
  }

  /**
   * Issue a new access token + refresh token pair.
   * The refresh token is stored as a SHA-256 hash. The raw value is returned to the client once only.
   */
  async issueTokens(userId: string, householdId: string, family?: string) {
    const payload = { sub: userId, householdId };
    const accessToken = this.jwtService.sign(payload, {
      secret: this.config.get('JWT_ACCESS_SECRET'),
      expiresIn: this.config.get('JWT_ACCESS_EXPIRY', '15m'),
    });

    const rawRefresh = randomBytes(64).toString('hex');
    const tokenHash = createHash('sha256').update(rawRefresh).digest('hex');
    const tokenFamily = family ?? uuidv4();

    const refreshExpiry = this.config.get<string>('JWT_REFRESH_EXPIRY', '30d');
    const expiresAt = this.parseExpiry(refreshExpiry);

    // Store hashed refresh token - raw value is never stored
    await (this.prisma as any).refreshToken.create({
      data: {
        id: uuidv4(),
        userId,
        tokenHash,
        family: tokenFamily,
        expiresAt,
      },
    });

    return {
      accessToken,
      refreshToken: rawRefresh,
      refreshTokenFamily: tokenFamily,
    };
  }

  async ensureHouseholdAndDefaults(
    userId: string,
    householdId: string,
    displayName: string,
    householdName?: string,
  ) {
    const name =
      householdName && householdName.trim().length > 0
        ? householdName.trim()
        : `${displayName}'s Household`;

    await this.prisma.household.upsert({
      where: { id: householdId },
      create: {
        id: householdId,
        name,
        ownerId: userId,
      },
      update: {},
    });

    await this.seedCategoriesForHousehold(householdId);
    await this.seedSystemCategoriesForHousehold(householdId);
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

  /**
   * Seed the 4 internal system categories required for borrow/lending and planning settlement.
   * These are created with isSystem=true and never appear in the user-facing category picker.
   * Idempotent — safe to call on every login (skipDuplicates).
   */
  private async seedSystemCategoriesForHousehold(householdId: string) {
    try {
      const data = buildSystemCategoriesForHousehold(householdId);
      await this.prisma.category.createMany({
        data,
        skipDuplicates: true,
      });
    } catch (e) {
      console.error(`Failed to seed system categories for household ${householdId}:`, e);
    }
  }

  /**
   * Parse expiry string like '30d', '15m', '1h' into a Date offset from now.
   */
  private parseExpiry(expiry: string): Date {
    const match = expiry.match(/^(\d+)([smhd])$/);
    if (!match) return new Date(Date.now() + 30 * 24 * 60 * 60 * 1000); // default 30 days
    const value = parseInt(match[1], 10);
    const unit = match[2];
    const multipliers: Record<string, number> = {
      s: 1000,
      m: 60 * 1000,
      h: 60 * 60 * 1000,
      d: 24 * 60 * 60 * 1000,
    };
    return new Date(Date.now() + value * multipliers[unit]);
  }
}