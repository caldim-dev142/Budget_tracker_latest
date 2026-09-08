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
}
