import { Injectable, Inject, NotFoundException, ForbiddenException, BadRequestException } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import { v4 as uuidv4 } from 'uuid';

import { CreateEntryDto } from './dto/create-entry.dto';
import { UpdateEntryDto } from './dto/update-entry.dto';
import { seedCategories } from '../categories/categories-seed.data';
import { buildSystemCategoriesForHousehold } from '../categories/categories-system.data';
import { monthRange } from '../common/month-range';

/** EntryKind values used by the Flutter client (lib/domain/entities/entry.dart). */
export const ENTRY_KINDS = ['income', 'incomeDeduction', 'adjustment', 'spending', 'protection', 'saving'];
/** Same rule as the client AddEntryUseCase: only adjustments and income deductions may be negative. */
const NEGATIVE_ALLOWED_KINDS = ['adjustment', 'incomeDeduction'];

const SYSTEM_CATEGORY_SUFFIXES = ['lend', 'borrow', 'bill-pay', 'return-received'];

/**
 * Maps a client category id to the server id for this household.
 *  - Regular seeded ids ('spd-n05') are prefixed: '{householdId}-spd-n05'.
 *  - Flutter system category ids ('lend-system-cat-{householdId}') and ids that were previously
 *    mis-prefixed ('{householdId}-lend-system-cat-{householdId}') map to the canonical backend
 *    system category '{householdId}-lend-system-cat' (categories-system.data.ts).
 */
export function normalizeCategoryId(categoryId: string | undefined, householdId: string): string | undefined {
  if (!categoryId) return categoryId;
  for (const suffix of SYSTEM_CATEGORY_SUFFIXES) {
    const flutterId = `${suffix}-system-cat-${householdId}`;
    if (categoryId === flutterId || categoryId === `${householdId}-${flutterId}`) {
      return `${householdId}-${suffix}-system-cat`;
    }
  }
  if (!categoryId.startsWith(householdId) && !categoryId.startsWith('custom-')) {
    return `${householdId}-${categoryId}`;
  }
  return categoryId;
}

function sameInstant(a: Date | null | undefined, b: Date | null | undefined): boolean {
  if (!a || !b) return !a && !b;
  return a.getTime() === b.getTime();
}

function isUnchanged(existing: any, dto: CreateEntryDto, categoryId: string | undefined, amountPaise: number,
  entryDate: Date, deletedAt: Date | null): boolean {
  return existing.categoryId === categoryId
    && existing.kind === dto.kind
    && (existing.accountId ?? null) === (dto.accountId ?? null)
    && (existing.cardId ?? null) === (dto.cardId ?? null)
    && sameInstant(existing.entryDate, entryDate)
    && Number(existing.amountPaise) === amountPaise
    && (existing.note ?? null) === (dto.note ?? null)
    && (existing.parentId ?? null) === (dto.parentId ?? null)
    && sameInstant(existing.deletedAt, deletedAt);
}

@Injectable()
export class EntriesService {
  constructor(@Inject('PRISMA') private readonly prisma: PrismaClient) {}

  /**
   * List all non-deleted entries for a month (doc 07 GET /entries).
   * Filtered by householdId (RLS equivalent at service layer).
   */
  async findByMonth(householdId: string, yearMonth: string) {
    const { from, to } = monthRange(yearMonth);

    return this.prisma.entry.findMany({
      where: {
        householdId,
        entryDate: { gte: from, lt: to },
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
    // Ensure default categories exist for this household if missing
    const catCount = await this.prisma.category.count({ where: { householdId } });
    if (catCount === 0) {
      try {
        const data = seedCategories.map((c) => ({
          id: `${householdId}-${c.id}`,
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
          skipDuplicates: true,
        });
      } catch (e) {
        console.error('Failed to auto-seed categories in upsertBatch:', e);
      }
    }

    // Collect distinct category IDs needed by incoming entries
    const neededCategories = new Map<string, { kind: string; name: string }>();
    for (const dto of entries) {
      const categoryId = normalizeCategoryId(dto.categoryId, householdId);
      if (categoryId && !neededCategories.has(categoryId)) {
        neededCategories.set(categoryId, {
          kind: dto.kind ?? 'spending',
          name: dto.categoryId ?? 'Uncategorized',
        });
      }
    }

    // Ensure all needed categories exist in DB using upsert (atomic and collision-free).
    // Canonical system categories are created with their approved metadata (isDeduction etc.).
    const systemCategoryData = new Map(buildSystemCategoriesForHousehold(householdId).map((c) => [c.id, c]));
    for (const [catId, info] of neededCategories.entries()) {
      try {
        const existingCat = await this.prisma.category.findUnique({ where: { id: catId } });
        if (existingCat) continue;
        await this.prisma.category.upsert({
          where: { id: catId },
          create: systemCategoryData.get(catId) ?? {
            id: catId,
            householdId,
            kind: info.kind,
            name: info.name,
            sortOrder: 999,
          },
          update: {},
        });
      } catch (_) {
        // Safe to ignore if already created
      }
    }

    const results = await Promise.allSettled(
      entries.map(async (dto) => {
        // Map categoryId to database format (householdId-categoryId) if needed
        const categoryId = normalizeCategoryId(dto.categoryId, householdId);

        if (!ENTRY_KINDS.includes(dto.kind)) {
          throw new BadRequestException(`Invalid entry kind "${dto.kind}".`);
        }
        const amountPaise = Number(dto.amountPaise);
        if (!Number.isSafeInteger(amountPaise)) {
          throw new BadRequestException('amountPaise must be an integer number of paise.');
        }
        if (amountPaise < 0 && !NEGATIVE_ALLOWED_KINDS.includes(dto.kind)) {
          throw new BadRequestException('Only adjustments and income deductions may be negative.');
        }

        const existing = await this.prisma.entry.findUnique({ where: { id: dto.id } });
        if (existing && existing.householdId !== householdId) {
          throw new ForbiddenException(`Access denied: Entry ${dto.id} belongs to a different household.`);
        }

        const incomingDate = new Date(dto.entryDate);
        const incomingDeletedAt = dto.deletedAt ? new Date(dto.deletedAt) : null;

        // A re-sent, unchanged entry (full-state push) is acknowledged without touching the row.
        if (existing && isUnchanged(existing, dto, categoryId, amountPaise, incomingDate, incomingDeletedAt)) {
          return existing;
        }

        // Closed month guard: both the month the entry currently belongs to and the month it
        // would move to must be open (changing the date must not bypass the guard).
        const monthsToCheck = new Set<string>([dto.entryDate.substring(0, 7)]);
        if (existing?.entryDate instanceof Date) monthsToCheck.add(existing.entryDate.toISOString().substring(0, 7));
        for (const ym of monthsToCheck) {
          const monthSnap = await (this.prisma as any).monthSnapshot?.findUnique?.({
            where: { householdId_yearMonth: { householdId, yearMonth: ym } },
            select: { status: true },
          });
          if (monthSnap && monthSnap.status === 'closed') {
            throw new BadRequestException(
              `Cannot modify entries in closed month ${ym}. Month has been closed.`,
            );
          }
        }

        // Ensure category exists and belongs to this household
        if (categoryId) {
          const catExists = await this.prisma.category.findUnique({ where: { id: categoryId } });
          if (catExists && catExists.householdId && catExists.householdId !== householdId) {
            throw new ForbiddenException(`Category ${categoryId} belongs to a different household.`);
          }
          if (!catExists) {
            await this.prisma.category.create({
              data: systemCategoryData.get(categoryId) ?? {
                id: categoryId,
                householdId,
                kind: dto.kind ?? 'spending',
                name: dto.categoryId ?? 'Uncategorized',
                sortOrder: 999,
              },
            }).catch(() => {});
          }
        }

        // Validate accountId if provided
        if (dto.accountId) {
          const accExists = await this.prisma.account.findUnique({ where: { id: dto.accountId } });
          if (accExists && accExists.householdId && accExists.householdId !== householdId) {
            throw new ForbiddenException(`Account ${dto.accountId} belongs to a different household.`);
          }
        }

        // Validate cardId if provided
        if (dto.cardId) {
          const cardExists = await this.prisma.creditCard.findUnique({ where: { id: dto.cardId } });
          if (cardExists && cardExists.householdId && cardExists.householdId !== householdId) {
            throw new ForbiddenException(`Credit card ${dto.cardId} belongs to a different household.`);
          }
        }

        if (existing) {
          // Stale version protection: skip update if incoming version is older than server version.
          // Last-write-wins only when incoming version >= server version.
          if (dto.version !== undefined && dto.version !== null && dto.version < existing.version) {
            // Stale update — do not overwrite newer server data
            return existing;
          }

          // Tombstone protection: a deleted entry is only revived by a strictly newer version.
          // An offline edit made on an older copy must not silently undo a deletion.
          if (existing.deletedAt && !incomingDeletedAt && !(typeof dto.version === 'number' && dto.version > existing.version)) {
            return existing;
          }

          return this.prisma.entry.update({
            where: { id: dto.id },
            data: {
              categoryId,
              kind: dto.kind,
              accountId: dto.accountId ?? null,
              cardId: dto.cardId ?? null,
              entryDate: incomingDate,
              amountPaise,
              note: dto.note ?? null,
              parentId: dto.parentId ?? null,
              updatedAt: new Date(dto.updatedAt ?? Date.now()),
              deletedAt: incomingDeletedAt,
              version: Math.max(dto.version ?? existing.version, existing.version) + 1,
            },
          });
        } else {
          return this.prisma.entry.create({
            data: {
              id: dto.id,
              householdId,
              categoryId: categoryId,
              kind: dto.kind,
              accountId: dto.accountId ?? null,
              cardId: dto.cardId ?? null,
              entryDate: incomingDate,
              amountPaise,
              note: dto.note ?? null,
              parentId: dto.parentId ?? null,
              createdBy: userId,
              version: dto.version ?? 1,
              createdAt: new Date(dto.createdAt ?? Date.now()),
              updatedAt: new Date(dto.updatedAt ?? Date.now()),
              deletedAt: incomingDeletedAt,
            },
          });
        }
      }),
    );

    results.forEach((r, idx) => {
      if (r.status === 'rejected') {
        console.error(`Failed to upsert entry ${entries[idx]?.id}:`, (r as PromiseRejectedResult).reason);
      }
    });

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

    // Closed month guard: reject deletes in closed months
    const entryYearMonth = entry.entryDate.toISOString().substring(0, 7);
    const monthSnap = await this.prisma.monthSnapshot.findUnique({
      where: { householdId_yearMonth: { householdId, yearMonth: entryYearMonth } },
      select: { status: true },
    });
    if (monthSnap && monthSnap.status === 'closed') {
      throw new BadRequestException(
        `Cannot delete entries in closed month ${entryYearMonth}. Month has been closed.`,
      );
    }

    return this.prisma.entry.update({
      where: { id },
      data: { deletedAt: new Date(), version: entry.version + 1 },
    });
  }
}
