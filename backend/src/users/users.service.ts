import { Injectable, Inject, NotFoundException } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

@Injectable()
export class UsersService {
  constructor(@Inject('PRISMA') private readonly prisma: PrismaClient) {}

  async findOne(id: string) {
    const user = await this.prisma.user.findUnique({
      where: { id },
      select: {
        id: true,
        email: true,
        displayName: true,
        createdAt: true,
      },
    });
    if (!user) throw new NotFoundException(`User ${id} not found.`);
    return user;
  }

  async updateDisplayName(id: string, displayName: string) {
    return this.prisma.user.update({
      where: { id },
      data: { displayName },
      select: {
        id: true,
        email: true,
        displayName: true,
      },
    });
  }

  /**
   * Delete the authenticated user's account (Google Play compliance).
   * Safely handles household membership, reassigns ownership if other members exist,
   * or cleans up orphaned household data if this was the sole member.
   */
  async deleteAccount(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });
    if (!user) {
      throw new NotFoundException(`User not found.`);
    }

    const householdId = user.household_id;

    if (householdId) {
      const otherMembers = await this.prisma.user.findMany({
        where: {
          household_id: householdId,
          id: { not: userId },
        },
        orderBy: { createdAt: 'asc' },
      });

      if (otherMembers.length > 0) {
        // Reassign household ownership to the next oldest member if the deleting user was the owner
        const household = await this.prisma.household.findUnique({
          where: { id: householdId },
        });
        if (household && household.ownerId === userId) {
          await this.prisma.household.update({
            where: { id: householdId },
            data: { ownerId: otherMembers[0].id },
          });
        }
      } else {
        // Sole member: cleanly delete the household and its associated scoped data
        await this.prisma.$transaction(async (tx) => {
          await tx.entry.deleteMany({ where: { householdId } });
          await tx.budget.deleteMany({ where: { householdId } });
          await tx.category.deleteMany({ where: { householdId } });
          await tx.account.deleteMany({ where: { householdId } });
          await tx.creditCard.deleteMany({ where: { householdId } });
          await tx.cardTransaction.deleteMany({ where: { householdId } });
          await tx.savingGoal.deleteMany({ where: { householdId } });
          await tx.goalContribution.deleteMany({ where: { householdId } });
          await tx.sinkingFund.deleteMany({ where: { householdId } });
          await tx.fundMovement.deleteMany({ where: { householdId } });
          await tx.receivable.deleteMany({ where: { householdId } });
          await tx.plannedBill.deleteMany({ where: { householdId } });
          await tx.reserveLine.deleteMany({ where: { householdId } });
          await tx.annual_targets.deleteMany({ where: { household_id: householdId } });
          await tx.household.delete({ where: { id: householdId } }).catch(() => {});
        });
      }
    }

    // Delete the user record
    await this.prisma.user.delete({
      where: { id: userId },
    });

    return {
      success: true,
      message: 'User account and associated data successfully deleted.',
    };
  }
}
