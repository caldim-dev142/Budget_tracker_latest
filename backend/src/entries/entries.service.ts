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
 * Authoritative set of seed category ID prefixes from category_seed.dart / categories-seed.data.ts:
 *  - inc- (Income)
 *  - ded- (Income Deductions)
 *  - adj- (Adjustments)
 *  - spd- (Spending: fees, needs, wants, travel, honorarium, unplanned, purchase_misc)
 *  - pro- (Protection: insurance, assets, events, vacation, medical, property, others, buffer)
 *  - sav- (Saving: retirement, children, other_goals)
 */
export const SEED_CATEGORY_PREFIXES = ['inc-', 'ded-', 'adj-', 'spd-', 'pro-', 'sav-'] as const;

/**
 * Maps a client category id to the server id for this household:
 *  - Flutter system category ids ('lend-system-cat-{householdId}') and ids that were previously
 *    mis-prefixed ('{householdId}-lend-system-cat-{householdId}') map to the canonical backend
 *    system category '{householdId}-lend-system-cat' (categories-system.data.ts).
 *  - If already prefixed with '{householdId}-', passes through unchanged.
 *  - Known seed categories matching SEED_CATEGORY_PREFIXES (e.g. 'spd-n05') are prefixed: '{householdId}-spd-n05'.
 *  - All other category IDs pass through unchanged (bare UUIDs from saving/protection, 'custom-*',
 *    'cat-*', or any custom/future category formats).
 */
export function normalizeCategoryId(categoryId: string | undefined, householdId: string): string | undefined {
  if (!categoryId) return categoryId;
  for (const suffix of SYSTEM_CATEGORY_SUFFIXES) {
    const flutterId = `${suffix}-system-cat-${householdId}`;
    if (categoryId === flutterId || categoryId === `${householdId}-${flutterId}`) {
      return `${householdId}-${suffix}-system-cat`;
    }
  }
  if (categoryId.startsWith(`${householdId}-`)) {
    return categoryId;
  }
  if (SEED_CATEGORY_PREFIXES.some((prefix) => categoryId.startsWith(prefix))) {
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

export interface ValidEntryWrite {
  action: 'create' | 'update';
  id: string;
  data: any;
}

export interface BatchContext {
  createdAccountIds?: Set<string>;
  createdCardIds?: Set<string>;
  createdEntryIds?: Set<string>;
}

export async function findManyBatch<T = any>(
  model: any,
  ids: string[],
  whereExtra?: any,
  include?: any,
): Promise<T[]> {
  if (!model || ids.length === 0) return [];
  return model.findMany({
    where: { id: { in: ids }, ...(whereExtra ?? {}) },
    ...(include ? { include } : {}),
  });
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
   * Phase 1: Validate a batch of entries without performing database writes.
   * Returns valid entry write operations, needed categories to ensure, counts of synced vs rejected entries,
   * and rejected entries with reasons.
   */
  async validateBatch(
    householdId: string,
    entries: CreateEntryDto[],
    userId: string,
    batchContext?: BatchContext,
  ) {
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

    const createdAccountIds = batchContext?.createdAccountIds ?? new Set<string>();
    const createdCardIds = batchContext?.createdCardIds ?? new Set<string>();

    // Batch lookups for referenced records
    const entryIds = entries.map((e) => e.id).filter(Boolean);
    const referencedAccountIds = [...new Set(entries.map((e) => e.accountId).filter(Boolean) as string[])];
    const referencedCardIds = [...new Set(entries.map((e) => e.cardId).filter(Boolean) as string[])];
    const referencedParentIds = [...new Set(entries.map((e) => e.parentId).filter(Boolean) as string[])];
    const referencedCategoryIds = [
      ...new Set(
        entries
          .map((e) => normalizeCategoryId(e.categoryId, householdId))
          .filter(Boolean) as string[],
      ),
    ];

    const [existingEntries, existingAccounts, existingCards, existingParents, existingCategories] =
      await Promise.all([
        findManyBatch(this.prisma.entry, entryIds),
        findManyBatch(this.prisma.account, referencedAccountIds),
        findManyBatch(this.prisma.creditCard, referencedCardIds),
        findManyBatch(this.prisma.entry, referencedParentIds),
        findManyBatch(this.prisma.category, referencedCategoryIds),
      ]);

    const entriesMap = new Map(existingEntries.map((e: any) => [e.id, e]));
    const accountsMap = new Map(existingAccounts.map((a: any) => [a.id, a]));
    const cardsMap = new Map(existingCards.map((c: any) => [c.id, c]));
    const parentsMap = new Map(existingParents.map((p: any) => [p.id, p]));
    const categoriesMap = new Map(existingCategories.map((c: any) => [c.id, c]));

    // Batched closed-month lookup: collect all unique yearMonths and query once
    const allMonthsToCheck = new Set<string>();
    for (const dto of entries) {
      if (dto.entryDate && typeof dto.entryDate === 'string' && dto.entryDate.length >= 7) {
        allMonthsToCheck.add(dto.entryDate.substring(0, 7));
      }
      const existing = entriesMap.get(dto.id);
      if (existing?.entryDate instanceof Date) {
        allMonthsToCheck.add(existing.entryDate.toISOString().substring(0, 7));
      } else if (typeof existing?.entryDate === 'string' && existing.entryDate.length >= 7) {
        allMonthsToCheck.add(existing.entryDate.substring(0, 7));
      }
    }

    const closedMonths = new Set<string>();
    if (allMonthsToCheck.size > 0 && typeof (this.prisma as any).monthSnapshot?.findMany === 'function') {
      const closedSnaps = await (this.prisma as any).monthSnapshot.findMany({
        where: {
          householdId,
          yearMonth: { in: Array.from(allMonthsToCheck) },
          status: 'closed',
        },
        select: { yearMonth: true },
      });
      if (Array.isArray(closedSnaps)) {
        for (const snap of closedSnaps) {
          closedMonths.add(snap.yearMonth);
        }
      }
    }

    // Pass 1: Validate everything except parentId existence
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

        const existing = entriesMap.get(dto.id);
        if (existing && existing.householdId !== householdId) {
          throw new ForbiddenException(`Access denied: Entry ${dto.id} belongs to a different household.`);
        }

        const incomingDate = new Date(dto.entryDate);
        const incomingDeletedAt = dto.deletedAt ? new Date(dto.deletedAt) : null;

        // A re-sent, unchanged entry (full-state push) is acknowledged without touching the row.
        if (existing && isUnchanged(existing, dto, categoryId, amountPaise, incomingDate, incomingDeletedAt)) {
          return { type: 'noop', id: dto.id };
        }

        // Closed month guard: both current month and target month must be open
        const monthsToCheck = [dto.entryDate.substring(0, 7)];
        const existingMonth = existing?.entryDate instanceof Date
          ? existing.entryDate.toISOString().substring(0, 7)
          : (typeof existing?.entryDate === 'string' && existing.entryDate.length >= 7 ? existing.entryDate.substring(0, 7) : null);
        if (existingMonth && !monthsToCheck.includes(existingMonth)) {
          monthsToCheck.push(existingMonth);
        }
        for (const ym of monthsToCheck) {
          if (closedMonths.has(ym)) {
            throw new BadRequestException(
              `Cannot modify entries in closed month ${ym}. Month has been closed.`,
            );
          }
        }

        // Ensure category exists and belongs to this household
        if (categoryId) {
          const catExists = categoriesMap.get(categoryId);
          if (catExists && catExists.householdId && catExists.householdId !== householdId) {
            throw new ForbiddenException(`Category ${categoryId} belongs to a different household.`);
          }
        }

        // Validate accountId if provided
        if (dto.accountId) {
          const accExists = accountsMap.get(dto.accountId);
          if (accExists && accExists.householdId && accExists.householdId !== householdId) {
            throw new ForbiddenException(`Account ${dto.accountId} belongs to a different household.`);
          }
          if (!accExists && !createdAccountIds.has(dto.accountId)) {
            throw new BadRequestException(`Referenced account ${dto.accountId} does not exist.`);
          }
        }

        // Validate cardId if provided
        if (dto.cardId) {
          const cardExists = cardsMap.get(dto.cardId);
          if (cardExists && cardExists.householdId && cardExists.householdId !== householdId) {
            throw new ForbiddenException(`Credit card ${dto.cardId} belongs to a different household.`);
          }
          if (!cardExists && !createdCardIds.has(dto.cardId)) {
            throw new BadRequestException(`Referenced credit card ${dto.cardId} does not exist.`);
          }
        }

        // Validate parentId household if existing in DB
        if (dto.parentId) {
          const parentExists = parentsMap.get(dto.parentId);
          if (parentExists && parentExists.householdId && parentExists.householdId !== householdId) {
            throw new ForbiddenException(`Parent entry ${dto.parentId} belongs to a different household.`);
          }
          // Note: parent existence check is deferred to Pass 2
        }

        if (existing) {
          // Stale version protection: skip update if incoming version is older than server version.
          // Last-write-wins only when incoming version >= server version.
          if (dto.version !== undefined && dto.version !== null && dto.version < existing.version) {
            // Stale update — do not overwrite newer server data
            return { type: 'noop', id: dto.id };
          }

          // Tombstone protection: a deleted entry is only revived by a strictly newer version.
          // An offline edit made on an older copy must not silently undo a deletion.
          if (existing.deletedAt && !incomingDeletedAt && !(typeof dto.version === 'number' && dto.version > existing.version)) {
            return { type: 'noop', id: dto.id };
          }

          return {
            type: 'write',
            write: {
              action: 'update' as const,
              id: dto.id,
              data: {
                categoryId: categoryId,
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
            },
          };
        } else {
          return {
            type: 'write',
            write: {
              action: 'create' as const,
              id: dto.id,
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
            },
          };
        }
      }),
    );

    const acceptedEntriesMap = new Map<
      string,
      { dto: CreateEntryDto; value: any }
    >();
    const rejected: Array<{ id: string; reason: string }> = [];
    let failedCount = 0;

    results.forEach((r, idx) => {
      const entryId = entries[idx]?.id;
      if (r.status === 'fulfilled') {
        acceptedEntriesMap.set(entryId, { dto: entries[idx], value: r.value });
      } else {
        failedCount++;
        const reason = (r as PromiseRejectedResult).reason?.message || 'Validation failed';
        rejected.push({ id: entryId, reason });
        console.error(`Failed to validate entry ${entryId}:`, (r as PromiseRejectedResult).reason);
      }
    });

    // Pass 2: Cascading parentId validation
    // Rejects any entry whose parentId is not in the DB and not among the entries accepted in pass 1.
    // Repeat until nothing changes (handles arbitrary chains).
    const acceptedEntryIds = new Set(acceptedEntriesMap.keys());
    let changed = true;
    while (changed) {
      changed = false;
      for (const [id, { dto }] of Array.from(acceptedEntriesMap.entries())) {
        if (dto.parentId) {
          const parentInDb = parentsMap.has(dto.parentId);
          const parentInBatch = acceptedEntryIds.has(dto.parentId);
          if (!parentInDb && !parentInBatch) {
            acceptedEntriesMap.delete(id);
            acceptedEntryIds.delete(id);
            failedCount++;
            const reason = `Referenced parent entry ${dto.parentId} does not exist.`;
            rejected.push({ id, reason });
            console.error(`Failed to validate entry ${id}:`, reason);
            changed = true;
          }
        }
      }
    }

    const validWrites: ValidEntryWrite[] = [];
    let syncedCount = 0;
    for (const { value } of acceptedEntriesMap.values()) {
      syncedCount++;
      if (value.type === 'write') {
        validWrites.push(value.write);
      }
    }

    return {
      validWrites,
      neededCategories,
      syncedCount,
      failedCount,
      rejected,
    };
  }

  /**
   * Phase 2: Execute valid entry writes in a transactional client.
   */
  async applyBatch(
    householdId: string,
    validWrites: ValidEntryWrite[],
    neededCategories: Map<string, { kind: string; name: string }>,
    userId: string,
    tx: any,
  ) {
    // Ensure default categories exist for this household if missing
    const catCount = await tx.category.count({ where: { householdId } });
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
        await tx.category.createMany({
          data,
          skipDuplicates: true,
        });
      } catch (e) {
        console.error('Failed to auto-seed categories in applyBatch:', e);
      }
    }

    // Ensure all needed categories exist in DB using upsert (atomic and collision-free).
    const systemCategoryData = new Map(buildSystemCategoriesForHousehold(householdId).map((c) => [c.id, c]));
    for (const [catId, info] of neededCategories.entries()) {
      try {
        const existingCat = await tx.category.findUnique({ where: { id: catId } });
        if (existingCat) continue;
        await tx.category.upsert({
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

    // In applyBatch, write parents before children: sort validWrites so any entry whose parentId is also in validWrites comes after its parent.
    const sortedWrites: ValidEntryWrite[] = [];
    const writeIds = new Set(validWrites.map((w) => w.id));
    const visited = new Set<string>();
    const visiting = new Set<string>();
    const writeMap = new Map(validWrites.map((w) => [w.id, w]));

    function visit(w: ValidEntryWrite) {
      if (visited.has(w.id)) return;
      if (visiting.has(w.id)) return;
      visiting.add(w.id);
      const parentId = w.data?.parentId;
      if (parentId && writeIds.has(parentId)) {
        const parentWrite = writeMap.get(parentId);
        if (parentWrite) {
          visit(parentWrite);
        }
      }
      visiting.delete(w.id);
      visited.add(w.id);
      sortedWrites.push(w);
    }

    for (const w of validWrites) {
      visit(w);
    }

    for (const item of sortedWrites) {
      if (item.action === 'create') {
        await tx.entry.create({ data: item.data });
      } else {
        await tx.entry.update({ where: { id: item.id }, data: item.data });
      }
    }
  }

  /**
   * Upsert a batch of entries — idempotent sync (doc 07 POST /sync/batch).
   * Validates in Phase 1 without writing, then writes in Phase 2 inside a transaction.
   */
  async upsertBatch(householdId: string, entries: CreateEntryDto[], userId: string, tx?: any) {
    const validation = await this.validateBatch(householdId, entries, userId);

    if (validation.validWrites.length > 0) {
      if (tx) {
        await this.applyBatch(householdId, validation.validWrites, validation.neededCategories, userId, tx);
      } else {
        const runner = this.prisma?.$transaction
          ? (fn: any) => this.prisma.$transaction(fn, { timeout: 45000, maxWait: 10000 })
          : (fn: any) => fn(this.prisma);
        await runner(async (innerTx: any) => {
          await this.applyBatch(householdId, validation.validWrites, validation.neededCategories, userId, innerTx);
        });
      }
    }

    return {
      synced: validation.syncedCount,
      failed: validation.failedCount,
      rejected: validation.rejected,
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
