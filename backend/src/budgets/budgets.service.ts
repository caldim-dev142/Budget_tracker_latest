import { Injectable, Inject, ForbiddenException } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import { UpdateBudgetDto } from './dto/update-budget.dto';

@Injectable()
export class BudgetsService {
  constructor(@Inject('PRISMA') private readonly prisma: PrismaClient) {}

  async findByMonth(householdId: string, yearMonth: string) {
    const budgets = await this.prisma.budget.findMany({
      where: { householdId, yearMonth },
    });
    // Convert BigInt to string/number for JSON response
    return budgets.map((b) => ({
      ...b,
      amountPaise: Number(b.amountPaise),
    }));
  }

  async upsertBulk(householdId: string, yearMonth: string, items: UpdateBudgetDto[]) {
    // Tenant check: every referenced category must belong to the caller's household.
    const categoryIds = [...new Set(items.map((i) => i.categoryId))];
    if (categoryIds.length > 0) {
      const owned = await this.prisma.category.findMany({
        where: { id: { in: categoryIds }, householdId },
        select: { id: true },
      });
      if (owned.length !== categoryIds.length) {
        throw new ForbiddenException('One or more categories do not belong to this household.');
      }
    }

    const operations = items.map((item) =>
      this.prisma.budget.upsert({
        where: {
          categoryId_yearMonth: {
            categoryId: item.categoryId,
            yearMonth,
          },
        },
        create: {
          householdId,
          categoryId: item.categoryId,
          yearMonth,
          amountPaise: Math.round(Number(item.amountPaise)),
        },
        update: {
          amountPaise: Math.round(Number(item.amountPaise)),
        },
      }),
    );

    await this.prisma.$transaction(operations);
    return { success: true, count: items.length };
  }
}
