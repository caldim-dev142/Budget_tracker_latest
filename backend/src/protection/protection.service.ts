import { Injectable, Inject, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

@Injectable()
export class ProtectionService {
  constructor(@Inject('PRISMA') private readonly prisma: PrismaClient) {}

  async findAll(householdId: string) {
    const funds = await this.prisma.sinkingFund.findMany({
      where: { householdId, archivedAt: null },
      include: { movements: true },
    });

    return funds.map((f) => {
      const opening = Number(f.openingReservePaise);
      const contributions = f.movements
        .filter((m) => m.type === 'contribution')
        .reduce((sum, m) => sum + Number(m.amountPaise), 0);
      const withdrawals = f.movements
        .filter((m) => m.type === 'withdrawal')
        .reduce((sum, m) => sum + Number(m.amountPaise), 0);

      return {
        id: f.id,
        name: f.name,
        openingReservePaise: opening,
        contributionsPaise: contributions,
        withdrawalsPaise: withdrawals,
        closingReservePaise: opening + contributions - withdrawals,
        movements: f.movements.map((m) => ({
          ...m,
          amountPaise: Number(m.amountPaise),
        })),
      };
    });
  }

  async createFund(householdId: string, name: string, openingReservePaise: number) {
    return this.prisma.sinkingFund.create({
      data: {
        householdId,
        name,
        openingReservePaise: Math.round(Number(openingReservePaise)),
      },
    });
  }

  async addMovement(
    householdId: string,
    fundId: string,
    type: 'contribution' | 'withdrawal',
    amountPaise: number,
    note?: string,
  ) {
    const fund = await this.prisma.sinkingFund.findUnique({ where: { id: fundId } });
    if (!fund) throw new NotFoundException('Sinking fund not found.');
    if (fund.householdId !== householdId) throw new ForbiddenException();

    return this.prisma.fundMovement.create({
      data: {
        fundId,
        type,
        amountPaise: Math.round(Number(amountPaise)),
        movementDate: new Date(),
        note,
      },
    });
  }
}
