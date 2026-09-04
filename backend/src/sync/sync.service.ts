import { Injectable, Inject } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import { EntriesService } from '../entries/entries.service';
import { CreateEntryDto } from '../entries/dto/create-entry.dto';

export interface SyncBatchDto {
  entries?: CreateEntryDto[];
  // Future sync entities (e.g. card_txns, fund_movements) added here
}

@Injectable()
export class SyncService {
  constructor(
    private readonly entriesService: EntriesService,
    @Inject('PRISMA') private readonly prisma: PrismaClient,
  ) {}

  /**
   * Idempotent batch synchronization (doc 07 POST /sync/batch, doc 11 §2).
   * Returns confirmation/results counts.
   */
  async syncBatch(householdId: string, dto: SyncBatchDto, userId: string) {
    let entriesResult = { synced: 0, failed: 0 };

    if (dto.entries && dto.entries.length > 0) {
      entriesResult = await this.entriesService.upsertBatch(householdId, dto.entries, userId);
    }

    return {
      entries: entriesResult,
      syncedAt: new Date(),
    };
  }
}
