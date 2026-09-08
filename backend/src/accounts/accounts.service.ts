import { Injectable, Inject, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

@Injectable()
export class AccountsService {
  constructor(@Inject('PRISMA') private readonly prisma: PrismaClient) {}

  async findAll(householdId: string) {
    const accounts = await this.prisma.account.findMany({
      where: { householdId, isActive: true },
      orderBy: { sortOrder: 'asc' },
    });

    return accounts.map((a) => ({
      ...a,
      currentBalancePaise: Number(a.currentBalancePaise),
    }));
  }

  async createAccount(householdId: string, name: string, type: 'bank' | 'cash', balancePaise: number) {
    return this.prisma.account.create({
      data: {
        householdId,
        name,
        type,
        currentBalancePaise: balancePaise,
      },
    });
  }

  async updateBalance(householdId: string, id: string, balancePaise: number) {
    const account = await this.prisma.account.findUnique({ where: { id } });
    if (!account) throw new NotFoundException('Account not found.');
    if (account.householdId !== householdId) throw new ForbiddenException();

    return this.prisma.account.update({
      where: { id },
      data: { currentBalancePaise: balancePaise },
    });
  }
}
