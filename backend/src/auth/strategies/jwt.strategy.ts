import { Inject, Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';
import { PrismaClient } from '@prisma/client';

export interface AuthenticatedUser {
  userId: string;
  /** Active household resolved from the database. `null` when the user has no household. */
  householdId: string | null;
}

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(
    config: ConfigService,
    @Inject('PRISMA') private readonly prisma: PrismaClient,
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: config.get<string>('JWT_ACCESS_SECRET'),
    });
  }

  /**
   * The signed claims are only trusted after re-checking the current account state:
   *  - the user must still exist (deleted accounts are rejected), and
   *  - the household in the token must still be the user's active household
   *    (removed members / users who left or deleted a household are rejected).
   * An empty household claim is normalised to `null` so it can never act as a shared tenant key.
   */
  async validate(payload: { sub?: string; householdId?: string | null }): Promise<AuthenticatedUser> {
    if (!payload || typeof payload.sub !== 'string' || payload.sub.length === 0) {
      throw new UnauthorizedException('Invalid access token.');
    }

    const user = await this.prisma.user.findUnique({
      where: { id: payload.sub },
      select: { id: true, household_id: true },
    });
    if (!user) {
      throw new UnauthorizedException('Account no longer exists.');
    }

    const tokenHouseholdId = payload.householdId ? payload.householdId : null;
    const currentHouseholdId = user.household_id ? user.household_id : null;
    if (tokenHouseholdId !== currentHouseholdId) {
      throw new UnauthorizedException('Household membership has changed. Please sign in again.');
    }

    return { userId: user.id, householdId: currentHouseholdId };
  }
}
