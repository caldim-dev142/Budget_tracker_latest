import { Injectable, Inject, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

@Injectable()
export class CardsService {
  constructor(@Inject('PRISMA') private readonly prisma: PrismaClient) {}

  async findAll(householdId: string) {
    const cards = await this.prisma.creditCard.findMany({
      where: { householdId, isActive: true },
      include: { transactions: true },
    });

    return cards.map((c) => {
      const prev = Number(c.previousOutstandingPaise);
      const spend = c.transactions
        .filter((t) => Number(t.amountPaise) > 0)
        .reduce((sum, t) => sum + Number(t.amountPaise), 0);
      const pay = c.transactions
        .filter((t) => Number(t.amountPaise) < 0)
        .reduce((sum, t) => sum + Number(t.amountPaise), 0);

      const outstanding = prev + spend + pay;

      return {
        id: c.id,
        name: c.name,
        previousOutstandingPaise: prev,
        currentOutstandingPaise: outstanding,
        monthDeltaPaise: outstanding - prev,
        transactions: c.transactions.map((t) => ({
          ...t,
          amountPaise: Number(t.amountPaise),
        })),
      };
    });
  }

  async createCard(householdId: string, name: string, previousOutstandingPaise: number) {
    return this.prisma.creditCard.create({
      data: {
        householdId,
        name,
        previousOutstandingPaise: BigInt(previousOutstandingPaise),
      },
    });
  }

  async addTransaction(
    householdId: string,
    cardId: string,
    description: string,
    amountPaise: number,
  ) {
    const card = await this.prisma.creditCard.findUnique({ where: { id: cardId } });
    if (!card) throw new NotFoundException('Credit card not found.');
    if (card.householdId !== householdId) throw new ForbiddenException();

    return this.prisma.cardTransaction.create({
      data: {
        cardId,
        description,
        amountPaise: BigInt(amountPaise),
        txnDate: new Date(),
      },
    });
  }
}
