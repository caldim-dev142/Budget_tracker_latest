import { Injectable, Inject, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

@Injectable()
export class PlanningService {
  constructor(@Inject('PRISMA') private readonly prisma: PrismaClient) {}

  // ─── Receivables ───────────────────────────────────────────────────────────

  async getReceivables(householdId: string) {
    const list = await this.prisma.receivable.findMany({ where: { householdId } });
    return list.map((item) => ({ ...item, amountPaise: Number(item.amountPaise) }));
  }

  async createReceivable(householdId: string, personName: string, amountPaise: number, dueDate?: string) {
    return this.prisma.receivable.create({
      data: {
        householdId,
        personName,
        amountPaise: BigInt(amountPaise),
        dueDate: dueDate ? new Date(dueDate) : null,
      },
    });
  }

  async updateReceivableStatus(householdId: string, id: string, status: 'open' | 'returned') {
    const item = await this.prisma.receivable.findUnique({ where: { id } });
    if (!item) throw new NotFoundException('Receivable not found.');
    if (item.householdId !== householdId) throw new ForbiddenException();

    return this.prisma.receivable.update({
      where: { id },
      data: { status },
    });
  }

  // ─── Planned Bills ─────────────────────────────────────────────────────────

  async getPlannedBills(householdId: string) {
    const list = await this.prisma.plannedBill.findMany({ where: { householdId } });
    return list.map((item) => ({ ...item, amountPaise: Number(item.amountPaise) }));
  }

  async createPlannedBill(householdId: string, name: string, amountPaise: number, dueDate?: string) {
    return this.prisma.plannedBill.create({
      data: {
        householdId,
        name,
        amountPaise: BigInt(amountPaise),
        dueDate: dueDate ? new Date(dueDate) : null,
      },
    });
  }

  async markBillPaid(householdId: string, id: string, isPaid: boolean) {
    const item = await this.prisma.plannedBill.findUnique({ where: { id } });
    if (!item) throw new NotFoundException('Bill not found.');
    if (item.householdId !== householdId) throw new ForbiddenException();

    return this.prisma.plannedBill.update({
      where: { id },
      data: { isPaid },
    });
  }

  // ─── Reserve Lines ─────────────────────────────────────────────────────────

  async getReserveLines(householdId: string, yearMonth: string) {
    const list = await this.prisma.reserveLine.findMany({ where: { householdId, yearMonth } });
    return list.map((item) => ({ ...item, amountPaise: Number(item.amountPaise) }));
  }

  async upsertReserveLines(householdId: string, yearMonth: string, lines: { name: string; amountPaise: number }[]) {
    const operations = lines.map((l) =>
      this.prisma.reserveLine.upsert({
        where: { id: `${householdId}-${yearMonth}-${l.name}` }, // compound ID for simpler upsert
        create: {
          id: `${householdId}-${yearMonth}-${l.name}`,
          householdId,
          yearMonth,
          name: l.name,
          amountPaise: BigInt(l.amountPaise),
        },
        update: {
          amountPaise: BigInt(l.amountPaise),
        },
      }),
    );

    await this.prisma.$transaction(operations);
    return { success: true, count: lines.length };
  }
}
