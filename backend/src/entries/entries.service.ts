import { Injectable, Inject, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import { v4 as uuidv4 } from 'uuid';

import { CreateEntryDto } from './dto/create-entry.dto';
import { UpdateEntryDto } from './dto/update-entry.dto';

@Injectable()
export class EntriesService {
  constructor(@Inject('PRISMA') private readonly prisma: PrismaClient) {}

  /**
   * List all non-deleted entries for a month (doc 07 GET /entries).
   * Filtered by householdId (RLS equivalent at service layer).
   */
  async findByMonth(householdId: string, yearMonth: string) {
    const [year, month] = yearMonth.split('-').map(Number);
    const from = new Date(year, month - 1, 1);
    const to = new Date(year, month, 0, 23, 59, 59);

    return this.prisma.entry.findMany({
      where: {
        householdId,
        entryDate: { gte: from, lte: to },
        deletedAt: null,
      },
      orderBy: { entryDate: 'desc' },
    });
  }

  /**
   * Upsert a batch of entries — idempotent sync (doc 07 POST /sync/batch).
   * Last-write-wins on version number.
   */
  async upsertBatch(householdId: string, entries: CreateEntryDto[], userId: string) {
    const results = await Promise.allSettled(
      entries.map((dto) => {
        // Map categoryId to database format (householdId-categoryId) if needed
        let categoryId = dto.categoryId;
        if (categoryId && !categoryId.startsWith(householdId) && !categoryId.startsWith('custom-')) {
          categoryId = `${householdId}-${categoryId}`;
        }

        return this.prisma.entry.upsert({
          where: { id: dto.id },
          create: {
            id: dto.id,
            householdId,
            categoryId: categoryId,
            kind: dto.kind,
            accountId: dto.accountId ?? null,
            cardId: dto.cardId ?? null,
            entryDate: new Date(dto.entryDate),
            amountPaise: BigInt(dto.amountPaise),
            note: dto.note ?? null,
            parentId: dto.parentId ?? null,
            createdBy: userId,
            version: dto.version ?? 1,
            createdAt: new Date(dto.createdAt ?? Date.now()),
            updatedAt: new Date(dto.updatedAt ?? Date.now()),
            deletedAt: dto.deletedAt ? new Date(dto.deletedAt) : null,
          },
          update: {
            // Last-write-wins: only update if incoming version > stored version (doc 11)
            amountPaise: BigInt(dto.amountPaise),
            note: dto.note ?? null,
            updatedAt: new Date(dto.updatedAt ?? Date.now()),
            deletedAt: dto.deletedAt ? new Date(dto.deletedAt) : null,
            version: dto.version ?? 1,
          },
        });
      }),
    );

    return {
      synced: results.filter((r) => r.status === 'fulfilled').length,
      failed: results.filter((r) => r.status === 'rejected').length,
    };
  }

  async findById(id: string, householdId: string) {
    const entry = await this.prisma.entry.findUnique({ where: { id } });
    if (!entry) throw new NotFoundException(`Entry ${id} not found.`);
    if (entry.householdId !== householdId) throw new ForbiddenException();
    return entry;
  }

  async softDelete(id: string, householdId: string) {
    const entry = await this.findById(id, householdId);
    return this.prisma.entry.update({
      where: { id },
      data: { deletedAt: new Date(), version: entry.version + 1 },
    });
  }
}
