import {
  Injectable,
  Inject,
  UnauthorizedException,
  ConflictException,
  NotFoundException,
  BadRequestException,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { PrismaClient } from '@prisma/client';
import * as argon2 from 'argon2';
import { randomBytes, randomInt, createHash, timingSafeEqual } from 'crypto';
import { v4 as uuidv4 } from 'uuid';

import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { RequestOtpDto } from './dto/request-otp.dto';
import { VerifyOtpDto } from './dto/verify-otp.dto';
import { EmailService } from '../email/email.service';
import { seedCategories } from '../categories/categories-seed.data';
import { buildSystemCategoriesForHousehold } from '../categories/categories-system.data';

export function normalizeEmail(email: string | undefined | null): string {
  return (email ?? '').trim().toLowerCase();
}

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(
    @Inject('PRISMA') private readonly prisma: PrismaClient,
    private readonly jwtService: JwtService,
    private readonly config: ConfigService,
    private readonly emailService: EmailService,
  ) {}

  /**
   * Request a 6-digit OTP sent to the user's email.
   * Rate limited: min 30s between requests, max 5 requests per 10m window.
   */
  async requestOtp(dto: RequestOtpDto) {
    const email = normalizeEmail(dto.email);
    if (!email) {
      throw new BadRequestException('Valid email address is required.');
    }

    const existingUser = await this.findUserByEmail(email);

    // If registration is requested (displayName provided) but user already exists
    if (dto.displayName && existingUser) {
      throw new ConflictException('Email is already registered. Please sign in instead.');
    }

    // If sign in is requested (no displayName provided) but user does not exist
    if (!dto.displayName && !existingUser) {
      throw new NotFoundException('Account not found. Please create an account first.');
    }

    // Rate Limiting: Minimum 30s interval between consecutive requests for same email
    const thirtySecondsAgo = new Date(Date.now() - 30 * 1000);
    const recentOtp = await (this.prisma as any).emailOtp.findFirst({
      where: {
        email,
        createdAt: { gte: thirtySecondsAgo },
      },
    });
    if (recentOtp) {
      throw new HttpException(
        'Please wait 30 seconds before requesting another verification code.',
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }

    // Rate Limiting: Maximum 5 OTP requests in a 10 minute window
    const tenMinutesAgo = new Date(Date.now() - 10 * 60 * 1000);
    const recentCount = await (this.prisma as any).emailOtp.count({
      where: {
        email,
        createdAt: { gte: tenMinutesAgo },
      },
    });
    if (recentCount >= 5) {
      throw new HttpException(
        'Too many OTP requests. Please wait 10 minutes before requesting again.',
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }

    // Invalidate previous unconsumed OTPs for this email to enforce single active OTP
    await (this.prisma as any).emailOtp.updateMany({
      where: { email, usedAt: null },
      data: { usedAt: new Date() },
    });

    // Generate cryptographically secure 6-digit numeric OTP (100000 - 999999)
    const otp = randomInt(100000, 1000000).toString();
    const otpHash = createHash('sha256').update(otp).digest('hex');
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000); // 5 minutes

    await (this.prisma as any).emailOtp.create({
      data: {
        id: uuidv4(),
        email,
        otpHash,
        displayName: dto.displayName,
        householdName: dto.householdName,
        expiresAt,
        attempts: 0,
      },
    });

    // Send email via real SMTP service (or mock in test/dev if SMTP unconfigured)
    await this.emailService.sendOtpEmail(email, otp);

    return {
      success: true,
      message: 'Verification code sent to your email.',
    };
  }

  /**
   * Verify the 6-digit OTP, authenticate or register the user, and issue access + refresh tokens.
   */
  async verifyOtp(dto: VerifyOtpDto) {
    const email = normalizeEmail(dto.email);
    const cleanOtp = (dto.otp ?? '').trim();

    if (!email || !cleanOtp) {
      throw new BadRequestException('Email and verification code are required.');
    }

    const latestOtp = await (this.prisma as any).emailOtp.findFirst({
      where: { email },
      orderBy: { createdAt: 'desc' },
    });

    if (!latestOtp) {
      throw new BadRequestException('No verification code found. Please request a new code.');
    }

    if (latestOtp.usedAt !== null) {
      throw new BadRequestException('Verification code has already been used. Please request a new code.');
    }

    if (new Date() > latestOtp.expiresAt) {
      throw new BadRequestException('Verification code has expired. Please request a new code.');
    }

    if (latestOtp.attempts >= 5) {
      throw new BadRequestException('Too many incorrect attempts. Please request a new code.');
    }

    // Increment attempt count on every verification try
    await (this.prisma as any).emailOtp.update({
      where: { id: latestOtp.id },
      data: { attempts: { increment: 1 } },
    });

    // Verify hash with constant-time equality check to prevent timing attacks
    const inputHash = createHash('sha256').update(cleanOtp).digest('hex');
    const inputBuffer = Buffer.from(inputHash, 'utf8');
    const storedBuffer = Buffer.from(latestOtp.otpHash, 'utf8');

    const isValid = inputBuffer.length === storedBuffer.length && timingSafeEqual(inputBuffer, storedBuffer);
    if (!isValid) {
      throw new UnauthorizedException('Invalid verification code.');
    }

    // Mark OTP as used (one-time consumption)
    await (this.prisma as any).emailOtp.update({
      where: { id: latestOtp.id },
      data: { usedAt: new Date() },
    });

    let user = await this.findUserByEmail(email);

    if (!user) {
      // New user registration flow
      const userId = uuidv4();
      const householdId = uuidv4();
      const displayName = latestOtp.displayName || email.split('@')[0];
      const householdName =
        latestOtp.householdName && latestOtp.householdName.trim().length > 0
          ? latestOtp.householdName.trim()
          : `${displayName}'s Household`;

      user = await this.prisma.$transaction(async (tx) => {
        await tx.household.create({
          data: {
            id: householdId,
            name: householdName,
            ownerId: userId,
          },
        });

        const createdUser = await tx.user.create({
          data: {
            id: userId,
            email,
            displayName,
            household_id: householdId,
            auth_provider: 'email_otp',
          },
        });

        await this.seedCategoriesForHousehold(householdId, tx);
        await this.seedSystemCategoriesForHousehold(householdId, tx);

        return createdUser;
      });
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
      user = await this.prisma.$transaction(async (tx) => {
        await tx.household.create({
          data: {
            id: householdId,
            name: householdName,
            ownerId: userId,
          },
        });

        const createdUser = await tx.user.create({
          data: {
            id: userId,
            email,
            password: passwordHash,
            displayName: dto.displayName,
            household_id: householdId,
            auth_provider: 'email',
          },
        });

        await this.seedCategoriesForHousehold(householdId, tx);
        await this.seedSystemCategoriesForHousehold(householdId, tx);

        return createdUser;
      });
    } catch (e: any) {
      if (e?.code === 'P2002') throw new ConflictException('Email already registered.');
      throw e;
    }

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
      await (this.prisma as any).refreshToken.deleteMany({
        where: { userId, family },
      });
    } else {
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
    tx?: any,
  ) {
    const client = tx ?? this.prisma;
    const name =
      householdName && householdName.trim().length > 0
        ? householdName.trim()
        : `${displayName}'s Household`;

    await client.household.upsert({
      where: { id: householdId },
      create: {
        id: householdId,
        name,
        ownerId: userId,
      },
      update: {},
    });

    await this.seedCategoriesForHousehold(householdId, client);
    await this.seedSystemCategoriesForHousehold(householdId, client);
  }

  async seedCategoriesForHousehold(householdId: string, tx?: any) {
    const client = tx ?? this.prisma;
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

    await client.category.createMany({
      data,
      skipDuplicates: true,
    });
  }

  async seedSystemCategoriesForHousehold(householdId: string, tx?: any) {
    const client = tx ?? this.prisma;
    const data = buildSystemCategoriesForHousehold(householdId);
    await client.category.createMany({
      data,
      skipDuplicates: true,
    });
  }

  private parseExpiry(expiry: string): Date {
    const match = expiry.match(/^(\d+)([smhd])$/);
    if (!match) return new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
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