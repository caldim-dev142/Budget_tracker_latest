import { Injectable, Inject } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import { seedCategories } from './categories-seed.data';

@Injectable()
export class CategoriesService {
  constructor(@Inject('PRISMA') private readonly prisma: PrismaClient) {}

  async findAll(householdId: string) {
    // If not seeded yet, seed them automatically
    const count = await this.prisma.category.count({ where: { householdId } });
    if (count === 0) {
      await this.seedHouseholdCategories(householdId);
    }

    return this.prisma.category.findMany({
      where: { householdId, archivedAt: null },
      orderBy: { sortOrder: 'asc' },
    });
  }

  async seedHouseholdCategories(householdId: string) {
    const data = seedCategories.map((c) => ({
      id: `${householdId}-${c.id}`, // Scope IDs per household to prevent collision
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
    });
  }
}
