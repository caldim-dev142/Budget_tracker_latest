import { Injectable, Inject, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

@Injectable()
export class SavingService {
  constructor(@Inject('PRISMA') private readonly prisma: PrismaClient) {}

  async findAll(householdId: string) {
    const goals = await this.prisma.savingGoal.findMany({
      where: { householdId, archivedAt: null },
      include: { contributions: true },
    });

    return goals.map((g) => {
      const target = g.targetPaise ? Number(g.targetPaise) : null;
      const monthlyBudget = Number(g.monthlyBudgetPaise);
      const lifetimeContributed = g.contributions.reduce(
        (sum, c) => sum + Number(c.amountPaise),
        0,
      );

      return {
        id: g.id,
        bucket: g.bucket,
        name: g.name,
        targetPaise: target,
        monthlyBudgetPaise: monthlyBudget,
        lifetimeContributedPaise: lifetimeContributed,
        progressFraction: target ? lifetimeContributed / target : null,
        contributions: g.contributions.map((c) => ({
          ...c,
          amountPaise: Number(c.amountPaise),
        })),
      };
    });
  }

  async createGoal(
    householdId: string,
    bucket: string,
    name: string,
    monthlyBudgetPaise: number,
    targetPaise?: number,
  ) {
    return this.prisma.savingGoal.create({
      data: {
        householdId,
        bucket,
        name,
        monthlyBudgetPaise: Math.round(Number(monthlyBudgetPaise)),
        targetPaise: targetPaise ? Math.round(Number(targetPaise)) : null,
      },
    });
  }

  async addContribution(
    householdId: string,
    goalId: string,
    amountPaise: number,
    note?: string,
  ) {
    const goal = await this.prisma.savingGoal.findUnique({ where: { id: goalId } });
    if (!goal) throw new NotFoundException('Saving goal not found.');
    if (goal.householdId !== householdId) throw new ForbiddenException();

    return this.prisma.goalContribution.create({
      data: {
        goalId,
        amountPaise: Math.round(Number(amountPaise)),
        contributionDate: new Date(),
        note,
      },
    });
  }
}
