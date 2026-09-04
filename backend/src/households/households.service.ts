import { Injectable, Inject, NotFoundException } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

@Injectable()
export class HouseholdsService {
  constructor(@Inject('PRISMA') private readonly prisma: PrismaClient) {}

  async findOne(id: string) {
    const household = await this.prisma.household.findUnique({
      where: { id },
      include: { members: { include: { user: true } } },
    });
    if (!household) throw new NotFoundException(`Household ${id} not found.`);
    return household;
  }

  async updateName(id: string, name: string) {
    return this.prisma.household.update({
      where: { id },
      data: { name },
    });
  }
}
