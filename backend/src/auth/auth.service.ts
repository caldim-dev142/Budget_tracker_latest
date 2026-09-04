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

    // Strictly verify Firebase ID Token using Firebase Admin SDK
    const decodedToken = await this.firebaseAdmin.verifyIdToken(idToken);

    const firebaseUid = decodedToken.uid;
    const email = decodedToken.email;

    if (!email) {
      throw new UnauthorizedException('Firebase ID token missing verified email address.');
    }

    const displayName = decodedToken.name || email.split('@')[0];

    // Prefer lookup by firebaseUid, fallback to verified email match
    let user = await this.prisma.user.findFirst({
      where: {
        OR: [
          { firebaseUid },
          { email },
        ],
      },
      include: { memberships: true },
    });

    if (user) {
      // Link firebaseUid if not linked yet
      if (!user.firebaseUid) {
        user = await this.prisma.user.update({
          where: { id: user.id },
          data: { firebaseUid },
          include: { memberships: true },
        });
      }
    } else {
      // Provision new user from verified Firebase identity
      const userId = uuidv4();
      const householdId = uuidv4();
      const passwordHash = await argon2.hash(randomBytes(32).toString('hex'));

      const [newUser] = await this.prisma.$transaction([
        this.prisma.user.create({
          data: {
            id: userId,
            email,
            firebaseUid,
            passwordHash,
            displayName,
            role: 'owner',
          },
        }),
        this.prisma.household.create({
          data: {
            id: householdId,
            name: `${displayName}'s Household`,
          },
        }),
      ]);

      await this.prisma.householdMember.create({
        data: {
          householdId,
          userId,
          role: 'owner',
        },
      });

      user = {
        ...newUser,
        memberships: [{ householdId, userId, role: 'owner', joinedAt: new Date() }],
      };
    }

    if (!user.memberships.length) {
      throw new UnauthorizedException('User has no household assigned.');
    }

    const householdId = user.memberships[0].householdId;
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

  async register(dto: RegisterDto) {
    const existing = await this.prisma.user.findUnique({ where: { email: dto.email } });
    if (existing) throw new ConflictException('Email already registered.');

    const passwordHash = await argon2.hash(dto.password, {
      type: argon2.argon2id,
      memoryCost: 65536,
      timeCost: 3,
      parallelism: 1,
    });

    const userId = uuidv4();
    const householdId = uuidv4();

    const [user] = await this.prisma.$transaction([
      this.prisma.user.create({
        data: {
          id: userId,
          email: dto.email,
          passwordHash,
          displayName: dto.displayName,
          role: 'owner',
        },
      }),
      this.prisma.household.create({
        data: {
          id: householdId,
          name: dto.householdName,
        },
      }),
    ]);

    await this.prisma.householdMember.create({
      data: {
        householdId,
        userId,
        role: 'owner',
      },
    });

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
    const user = await this.prisma.user.findUnique({
      where: { email: dto.email },
      include: { memberships: true },
    });

    if (!user || !user.memberships.length) {
      throw new UnauthorizedException('Invalid credentials.');
    }

    const valid = await argon2.verify(user.passwordHash, dto.password);
    if (!valid) throw new UnauthorizedException('Invalid credentials.');

    const householdId = user.memberships[0].householdId;
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

  async refresh(userId: string, tokenHash: string, family: string) {
    // Validate token (doc 12 §4 — rotation with reuse detection)
    const stored = await this.prisma.refreshToken.findFirst({
      where: { userId, family },
      orderBy: { createdAt: 'desc' },
    });

    if (!stored || stored.tokenHash !== tokenHash) {
      // Reuse detected — invalidate whole family
      await this.prisma.refreshToken.deleteMany({ where: { userId, family } });
      throw new UnauthorizedException('Refresh token reuse detected.');
    }

    if (stored.usedAt || new Date() > stored.expiresAt) {
      throw new UnauthorizedException('Refresh token expired.');
    }

    // Mark old token as used
    await this.prisma.refreshToken.update({
      where: { id: stored.id },
      data: { usedAt: new Date() },
    });

    const user = await this.prisma.user.findUniqueOrThrow({
      where: { id: userId },
      include: { memberships: true },
    });

    const householdId = user.memberships[0].householdId;
    return this.issueTokens(userId, householdId, family);
  }

  async logout(userId: string, family: string) {
    await this.prisma.refreshToken.deleteMany({ where: { userId, family } });
  }

  private async issueTokens(userId: string, householdId: string, family?: string) {
    const payload = { sub: userId, householdId };
    const accessToken = this.jwtService.sign(payload, {
      secret: this.config.get('JWT_ACCESS_SECRET'),
      expiresIn: this.config.get('JWT_ACCESS_EXPIRY', '15m'),
    });

    // Rotating refresh token (doc 12 §4)
    const rawRefresh = randomBytes(64).toString('hex');
    const hash = createHash('sha256').update(rawRefresh).digest('hex');
    const tokenFamily = family ?? uuidv4();
    const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000); // 30d

    await this.prisma.refreshToken.create({
      data: {
        userId,
        tokenHash: hash,
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
}
