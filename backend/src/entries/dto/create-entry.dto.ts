import {
  IsString, IsNumber, IsOptional, IsDateString, Min,
} from 'class-validator';

export class CreateEntryDto {
  @IsString() id: string;        // client UUID
  @IsString() categoryId: string;
  @IsString() kind: string;
  @IsOptional() @IsString() accountId?: string;
  @IsOptional() @IsString() cardId?: string;
  @IsDateString() entryDate: string;
  @IsNumber() amountPaise: number; // number in DTO; BigInt in DB
  @IsOptional() @IsString() note?: string;
  @IsOptional() @IsString() parentId?: string;
  @IsOptional() @IsNumber() version?: number;
  @IsOptional() @IsString() createdAt?: string;
  @IsOptional() @IsString() updatedAt?: string;
  @IsOptional() @IsString() deletedAt?: string;
}
