import {
  Injectable,
  Inject,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import { v4 as uuidv4 } from 'uuid';
import { AuthService } from '../auth/auth.service';
import { seedCategories } from '../categories/categories-seed.data';

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

    // Seed default categories for this newly created household
    await this.seedCategoriesForHousehold(householdId);

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
   * Join an existing household using the provided household ID.
   */
  async join(userId: string, householdId: string) {
    if (!householdId || householdId.trim().length === 0) {
      throw new BadRequestException('Household ID is required.');
    }

    const trimmedId = householdId.trim();

    const household = await this.prisma.household.findUnique({
      where: { id: trimmedId },
    });
    if (!household) {
      throw new NotFoundException(
        `Household not found with ID: "${trimmedId}". Please verify the ID and try again.`,
      );
    }

    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });
    if (!user) {
      throw new NotFoundException('User not found.');
    }

    await this.prisma.user.update({
      where: { id: user.id },
      data: { household_id: household.id },
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
}
