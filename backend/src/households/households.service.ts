import {
  Injectable,
  Inject,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import { v4 as uuidv4 } from 'uuid';
import { AuthService } from '../auth/auth.service';
import { seedCategories } from '../categories/categories-seed.data';
import { buildSystemCategoriesForHousehold } from '../categories/categories-system.data';

@Injectable()
export class HouseholdsService {
  constructor(
    @Inject('PRISMA') private readonly prisma: PrismaClient,
    private readonly authService: AuthService,
  ) {}

  /**
   * Create a new household.
   * Generates a new household ID ONLY after this action is triggered.
   */
  async create(userId: string, name?: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });
    if (!user) {
      throw new NotFoundException('User not found.');
    }

    // Generate household ID ONLY upon create action execution
    const householdId = uuidv4();
    const householdName =
      name && name.trim().length > 0
        ? name.trim()
        : `${user.displayName}'s Household`;

    const household = await this.prisma.household.create({
      data: {
        id: householdId,
        name: householdName,
        ownerId: user.id,
      },
    });

    await this.prisma.user.update({
      where: { id: user.id },
      data: { household_id: householdId },
    });

    // Seed default categories and system categories for this newly created household
    await this.seedCategoriesForHousehold(householdId);
    await this.seedSystemCategoriesForHousehold(householdId);

    const tokens = await this.authService.issueTokens(user.id, householdId);

    return {
      household: {
        id: household.id,
        name: household.name,
        ownerId: household.ownerId,
        isOwner: true,
        members: [
          {
            id: user.id,
            email: user.email,
            displayName: user.displayName,
            role: 'owner',
          },
        ],
      },
      tokens,
    };
  }

  /**
   * Generate a short single-use invite code for this household.
   *
   * SECURITY:
   * - Only the household owner may generate codes.
   * - Max 5 unexpired+unused codes per household (prevents code-spam enumeration).
   * - Each code is 8 characters of uppercase alphanumeric, excluding visually
   *   ambiguous chars (O, 0, I, 1) — 32^8 ≈ 1 trillion combinations.
   * - Codes expire after 24 hours.
   */
  async generateInvite(userId: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user || !user.household_id) {
      throw new NotFoundException('You do not belong to any household.');
    }

    const household = await this.prisma.household.findUnique({
      where: { id: user.household_id },
    });
    if (!household) {
      throw new NotFoundException('Household not found.');
    }
    if (household.ownerId !== user.id) {
      throw new ForbiddenException('Only the household owner can generate invite codes.');
    }

    // Rate-limit: max 5 active (unexpired + unused) codes per household at a time.
    const now = new Date();
    const activeCount = await this.prisma.householdInvite.count({
      where: {
        householdId: household.id,
        usedAt: null,
        expiresAt: { gt: now },
      },
    });
    if (activeCount >= 5) {
      throw new HttpException(
        'Too many active invite codes. Wait for existing codes to expire or be used.',
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }

    const code = this.generateCode();
    const expiresAt = new Date(now.getTime() + 24 * 60 * 60 * 1000); // +24h

    await this.prisma.householdInvite.create({
      data: {
        id: uuidv4(),
        householdId: household.id,
        code,
        createdBy: user.id,
        expiresAt,
      },
    });

    return { code, expiresAt };
  }

  /**
   * Join an existing household by redeeming a single-use invite code.
   *
   * SECURITY:
   * - Accepts only the 8-char invite code, never the raw household UUID.
   * - Expired or already-redeemed codes are rejected.
   * - Redemption is atomic: usedAt + usedBy are written in the same transaction
   *   with a guarded updateMany({ where: { code, usedAt: null, expiresAt: { gt: now } } }).
   *   If another concurrent request burned the code first, count is 0 and it throws.
   */
  async joinByCode(userId: string, inviteCode: string) {
    const code = inviteCode.trim().toUpperCase();

    const invite = await this.prisma.householdInvite.findUnique({
      where: { code },
    });

    if (!invite) {
      throw new NotFoundException(
        'Invite code not found. Please ask the household owner for a new code.',
      );
    }

    const now = new Date();
    if (invite.usedAt !== null) {
      throw new BadRequestException(
        'This invite code has already been used. Please ask the household owner for a new code.',
      );
    }
    if (invite.expiresAt < now) {
      throw new BadRequestException(
        'This invite code has expired. Please ask the household owner for a new code.',
      );
    }

    const household = await this.prisma.household.findUnique({
      where: { id: invite.householdId },
    });
    if (!household) {
      throw new NotFoundException('The household associated with this invite no longer exists.');
    }

    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) {
      throw new NotFoundException('User not found.');
    }

    // Atomic redemption: guarded update ensures only one concurrent request succeeds.
    await this.prisma.$transaction(async (tx) => {
      const burned = await tx.householdInvite.updateMany({
        where: { code, usedAt: null, expiresAt: { gt: now } },
        data: { usedAt: now, usedBy: user.id },
      });
      if (burned.count !== 1) {
        throw new BadRequestException(
          'This invite code has already been used. Please ask the household owner for a new code.',
        );
      }
      await tx.user.update({
        where: { id: user.id },
        data: { household_id: household.id },
      });
    });

    const tokens = await this.authService.issueTokens(user.id, household.id);
    const members = await this.getHouseholdMembers(household.id, household.ownerId);

    return {
      household: {
        id: household.id,
        name: household.name,
        ownerId: household.ownerId,
        isOwner: household.ownerId === user.id,
        members,
      },
      tokens,
    };
  }

  /**
   * Generates an 8-character uppercase alphanumeric code.
   * Excludes visually ambiguous characters: O, 0, I, 1.
   */
  private generateCode(): string {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // 32 chars, no O/0/I/1
    const crypto = require('crypto');
    let result = '';
    // Use rejection sampling to avoid modulo bias.
    while (result.length < 8) {
      const byte = crypto.randomBytes(1)[0];
      // Accept bytes 0..223 (7 complete sets of 32), reject 224..255.
      if (byte < alphabet.length * Math.floor(256 / alphabet.length)) {
        result += alphabet[byte % alphabet.length];
      }
    }
    return result;
  }

  /**
   * Read details and joined members of the current user's household.
   */
  async findMe(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });
    if (!user || !user.household_id) {
      return { household: null };
    }

    let household = await this.prisma.household.findUnique({
      where: { id: user.household_id },
    });

    // If household record does not exist in households table yet, initialize it
    if (!household) {
      household = await this.prisma.household.create({
        data: {
          id: user.household_id,
          name: `${user.displayName}'s Household`,
          ownerId: user.id,
        },
      });
    }

    const members = await this.getHouseholdMembers(household.id, household.ownerId);

    return {
      household: {
        id: household.id,
        name: household.name,
        ownerId: household.ownerId,
        isOwner: household.ownerId === user.id,
        members,
      },
    };
  }

  /**
   * Update household information (name).
   * Only the household owner is allowed to perform this operation.
   */
  async updateName(userId: string, name: string) {
    if (!name || name.trim().length === 0) {
      throw new BadRequestException('Household name cannot be empty.');
    }

    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });
    if (!user || !user.household_id) {
      throw new NotFoundException('You do not belong to any household.');
    }

    const household = await this.prisma.household.findUnique({
      where: { id: user.household_id },
    });
    if (!household) {
      throw new NotFoundException('Household not found.');
    }

    if (household.ownerId !== user.id) {
      throw new ForbiddenException(
        'Only the household owner is allowed to update household information.',
      );
    }

    const updated = await this.prisma.household.update({
      where: { id: household.id },
      data: { name: name.trim() },
    });

    return {
      id: updated.id,
      name: updated.name,
      ownerId: updated.ownerId,
    };
  }

  /**
   * Delete the household.
   * Only the household owner is allowed to perform the household-level delete operation.
   * Removes the household and disassociates all members belonging to this household.
   * Does not affect unrelated users or households.
   */
  async deleteHousehold(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });
    if (!user || !user.household_id) {
      throw new NotFoundException('You do not belong to any household.');
    }

    const household = await this.prisma.household.findUnique({
      where: { id: user.household_id },
    });
    if (!household) {
      throw new NotFoundException('Household not found.');
    }

    if (household.ownerId !== user.id) {
      throw new ForbiddenException(
        'Only the household owner is allowed to delete the household.',
      );
    }

    const targetHouseholdId = household.id;

    // Transaction to safely delete household data, disassociate all members, and delete household
    await this.prisma.$transaction(async (tx) => {
      // 1. Disassociate all members belonging to this household
      await tx.user.updateMany({
        where: { household_id: targetHouseholdId },
        data: { household_id: null },
      });

      // 2. Cascade cleanup of household records to avoid orphaned data
      await tx.monthSnapshot.deleteMany({ where: { householdId: targetHouseholdId } });
      await tx.syncTombstone.deleteMany({ where: { householdId: targetHouseholdId } });
      await tx.budget.deleteMany({ where: { householdId: targetHouseholdId } });
      await tx.entry.deleteMany({ where: { householdId: targetHouseholdId } });
      await tx.category.deleteMany({ where: { householdId: targetHouseholdId } });
      await tx.account.deleteMany({ where: { householdId: targetHouseholdId } });
      await tx.creditCard.deleteMany({ where: { householdId: targetHouseholdId } });
      await tx.sinkingFund.deleteMany({ where: { householdId: targetHouseholdId } });
      await tx.savingGoal.deleteMany({ where: { householdId: targetHouseholdId } });
      await tx.receivable.deleteMany({ where: { householdId: targetHouseholdId } });
      await tx.plannedBill.deleteMany({ where: { householdId: targetHouseholdId } });
      await tx.reserveLine.deleteMany({ where: { householdId: targetHouseholdId } });
      await tx.annual_targets.deleteMany({ where: { household_id: targetHouseholdId } });

      // 3. Delete the household itself
      await tx.household.delete({
        where: { id: targetHouseholdId },
      });
    });

    const tokens = await this.authService.issueTokens(user.id, '');

    return {
      success: true,
      message: 'Household deleted successfully.',
      tokens,
    };
  }

  /**
   * Remove an individual member from the household.
   * Only the household owner is allowed to perform this operation.
   * Removes that member without affecting the household or other members.
   */
  async removeMember(userId: string, memberId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });
    if (!user || !user.household_id) {
      throw new NotFoundException('You do not belong to any household.');
    }

    const household = await this.prisma.household.findUnique({
      where: { id: user.household_id },
    });
    if (!household) {
      throw new NotFoundException('Household not found.');
    }

    if (household.ownerId !== user.id) {
      throw new ForbiddenException(
        'Only the household owner is allowed to remove members from the household.',
      );
    }

    if (memberId === user.id) {
      throw new BadRequestException(
        'The household owner cannot be removed as a member. To delete the entire household, use the Delete Household option.',
      );
    }

    const targetMember = await this.prisma.user.findUnique({
      where: { id: memberId },
    });
    if (!targetMember || targetMember.household_id !== household.id) {
      throw new NotFoundException('User is not a member of this household.');
    }

    // Disassociate the specific member without affecting the household or other members
    await this.prisma.user.update({
      where: { id: memberId },
      data: { household_id: null },
    });

    return {
      success: true,
      message: `Member "${targetMember.displayName}" removed from the household.`,
    };
  }

  private async getHouseholdMembers(householdId: string, ownerId: string) {
    const users = await this.prisma.user.findMany({
      where: { household_id: householdId },
      select: { id: true, email: true, displayName: true },
      orderBy: { createdAt: 'asc' },
    });

    return users.map((u) => ({
      id: u.id,
      email: u.email,
      displayName: u.displayName,
      role: u.id === ownerId ? 'owner' : 'member',
    }));
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
    } catch (_) {}
  }

  /**
   * Seed the 4 internal system categories required for borrow/lending and planning settlement.
   * Idempotent — safe to call multiple times (skipDuplicates).
   */
  private async seedSystemCategoriesForHousehold(householdId: string) {
    try {
      const data = buildSystemCategoriesForHousehold(householdId);
      await this.prisma.category.createMany({
        data,
        skipDuplicates: true,
      });
    } catch (_) {}
  }

}
