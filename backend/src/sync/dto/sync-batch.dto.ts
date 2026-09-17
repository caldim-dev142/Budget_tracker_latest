import {
  IsString,
  IsNumber,
  IsOptional,
  IsBoolean,
  IsArray,
  ValidateNested,
  IsDateString,
  IsInt,
  IsIn,
} from 'class-validator';
import { Type } from 'class-transformer';
import { CreateEntryDto } from '../../entries/dto/create-entry.dto';

export class SyncCategoryDto {
  @IsString()
  id: string;

  @IsString()
  kind: string;

  @IsOptional()
  @IsString()
  groupCode?: string | null;

  @IsString()
  name: string;

  @IsOptional()
  @IsString()
  needOrWant?: string | null;

  @IsOptional()
  @IsBoolean()
  isDeduction?: boolean;

  @IsOptional()
  @IsBoolean()
  isSystem?: boolean;

  @IsOptional()
  @IsInt()
  sortOrder?: number;

  @IsOptional()
  @IsDateString()
  archivedAt?: string | null;
}

export class SyncAccountDto {
  @IsString()
  id: string;

  @IsString()
  name: string;

  @IsString()
  type: string;

  @IsNumber()
  currentBalancePaise: number;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;

  @IsOptional()
  @IsInt()
  sortOrder?: number;
}

export class SyncCreditCardDto {
  @IsString()
  id: string;

  @IsString()
  name: string;

  @IsOptional()
  @IsNumber()
  previousOutstandingPaise?: number;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

export class SyncCardTransactionDto {
  @IsString()
  id: string;

  @IsString()
  cardId: string;

  @IsDateString()
  txnDate: string;

  @IsString()
  description: string;

  @IsNumber()
  amountPaise: number;

  @IsOptional()
  @IsInt()
  sNo?: number;
}

export class SyncPlannedBillDto {
  @IsString()
  id: string;

  @IsString()
  name: string;

  @IsNumber()
  amountPaise: number;

  @IsOptional()
  @IsDateString()
  dueDate?: string | null;

  @IsOptional()
  @IsBoolean()
  isPaid?: boolean;

  @IsOptional()
  @IsString()
  entryId?: string | null;
}

export class SyncReceivableDto {
  @IsString()
  id: string;

  @IsString()
  personName: string;

  @IsNumber()
  amountPaise: number;

  @IsOptional()
  @IsString()
  status?: string;

  @IsOptional()
  @IsDateString()
  dueDate?: string | null;

  @IsOptional()
  @IsString()
  entryId?: string | null;
}

export class SyncSavingGoalDto {
  @IsString()
  id: string;

  @IsString()
  bucket: string;

  @IsString()
  name: string;

  @IsOptional()
  @IsNumber()
  targetPaise?: number | null;

  @IsOptional()
  @IsNumber()
  monthlyBudgetPaise?: number;

  @IsOptional()
  @IsDateString()
  archivedAt?: string | null;
}

export class SyncGoalContributionDto {
  @IsString()
  id: string;

  @IsString()
  goalId: string;

  @IsNumber()
  amountPaise: number;

  @IsDateString()
  contributionDate: string;

  @IsOptional()
  @IsString()
  note?: string | null;
}

export class SyncSinkingFundDto {
  @IsString()
  id: string;

  @IsString()
  name: string;

  @IsOptional()
  @IsNumber()
  openingReservePaise?: number;

  @IsOptional()
  @IsDateString()
  archivedAt?: string | null;
}

export class SyncFundMovementDto {
  @IsString()
  id: string;

  @IsString()
  fundId: string;

  @IsString()
  type: string;

  @IsNumber()
  amountPaise: number;

  @IsDateString()
  movementDate: string;

  @IsOptional()
  @IsString()
  note?: string | null;
}

export class SyncBudgetDto {
  @IsString()
  id: string;

  @IsString()
  categoryId: string;

  @IsString()
  yearMonth: string;

  @IsNumber()
  amountPaise: number;
}

export class SyncReserveLineDto {
  @IsString()
  id: string;

  @IsString()
  yearMonth: string;

  @IsString()
  name: string;

  @IsNumber()
  amountPaise: number;

  @IsOptional()
  @IsString()
  source?: string;
}

export const SYNC_DELETABLE_ENTITIES = [
  'planned_bill',
  'receivable',
  'card_transaction',
  'budget',
  'reserve_line',
  'goal_contribution',
  'fund_movement',
  'annual_target',
  'category',
] as const;
export type SyncDeletableEntity = (typeof SYNC_DELETABLE_ENTITIES)[number];

/** A record deleted on the device. Applied server-side and recorded as a tombstone. */
export class SyncDeletionDto {
  @IsIn(SYNC_DELETABLE_ENTITIES as unknown as string[])
  entity: string;

  @IsString()
  id: string;
}

export class SyncBatchDto {
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => SyncCategoryDto)
  categories?: SyncCategoryDto[];

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => SyncAccountDto)
  accounts?: SyncAccountDto[];

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => SyncCreditCardDto)
  creditCards?: SyncCreditCardDto[];

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => SyncCardTransactionDto)
  cardTransactions?: SyncCardTransactionDto[];

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => SyncPlannedBillDto)
  plannedBills?: SyncPlannedBillDto[];

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => SyncReceivableDto)
  receivables?: SyncReceivableDto[];

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => SyncSavingGoalDto)
  savingGoals?: SyncSavingGoalDto[];

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => SyncGoalContributionDto)
  goalContributions?: SyncGoalContributionDto[];

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => SyncSinkingFundDto)
  sinkingFunds?: SyncSinkingFundDto[];

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => SyncFundMovementDto)
  fundMovements?: SyncFundMovementDto[];

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => SyncBudgetDto)
  budgets?: SyncBudgetDto[];

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => SyncReserveLineDto)
  reserveLines?: SyncReserveLineDto[];

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => SyncAnnualTargetDto)
  annualTargets?: SyncAnnualTargetDto[];

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateEntryDto)
  entries?: CreateEntryDto[];

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  deletedAnnualTargetIds?: string[];

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => SyncDeletionDto)
  deletions?: SyncDeletionDto[];
}

export class SyncAnnualTargetDto {
  @IsString()
  id: string;

  @IsString()
  title: string;

  @IsNumber()
  targetPaise: number;

  @IsOptional()
  @IsString()
  type?: string;
}

