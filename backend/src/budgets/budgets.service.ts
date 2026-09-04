import { Injectable, Inject } from '@nestjs/common';
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
          amountPaise: BigInt(item.amountPaise),
        },
        update: {
          amountPaise: BigInt(item.amountPaise),
        },
      }),
    );

    await this.prisma.$transaction(operations);
    return { success: true, count: items.length };
  }
}
