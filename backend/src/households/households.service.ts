import { Injectable, Inject, NotFoundException } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

@Injectable()
export class HouseholdsService {
  constructor(@Inject('PRISMA') private readonly prisma: PrismaClient) {}

  async findOne(id: string) {
    const user = await this.prisma.user.findFirst({
      where: { household_id: id },
    });
    return {
      id,
      name: user ? `${user.displayName}'s Household` : 'Default Household',
      members: user ? [{ user }] : [],
    };
  }

  async updateName(id: string, name: string) {
    return { id, name };
  }
}
