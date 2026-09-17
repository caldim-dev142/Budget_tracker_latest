import { IsIn, IsInt, IsString, Max, MaxLength, Min, MinLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { KeepRawValue } from '../../common/decorators/strict-type.decorator';

/** Account types offered by the app (accounts_screen.dart: Bank Account / Cash Wallet). */
export const ACCOUNT_TYPES = ['bank', 'cash'] as const;

export class CreateAccountDto {
  @ApiProperty()
  @KeepRawValue()
  @IsString()
  @MinLength(1)
  @MaxLength(100)
  name: string;

  @ApiProperty({ enum: ACCOUNT_TYPES, example: 'bank' })
  @KeepRawValue()
  @IsIn(ACCOUNT_TYPES)
  type: string;

  @ApiProperty()
  @IsInt()
  @Min(Number.MIN_SAFE_INTEGER)
  @Max(Number.MAX_SAFE_INTEGER)
  balancePaise: number;
}

export class UpdateAccountBalanceDto {
  @ApiProperty()
  @IsInt()
  @Min(Number.MIN_SAFE_INTEGER)
  @Max(Number.MAX_SAFE_INTEGER)
  balancePaise: number;
}
