import { IsOptional, IsString, MaxLength, MinLength, Matches } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { KeepRawValue } from '../../common/decorators/strict-type.decorator';

export class CreateHouseholdDto {
  @ApiPropertyOptional()
  @IsOptional()
  @KeepRawValue()
  @IsString()
  @MaxLength(100)
  name?: string;
}

/**
 * Body for POST /households/join.
 * The joiner submits the 8-character invite code they received from the owner.
 * Raw household UUIDs are no longer accepted — the code is resolved server-side.
 */
export class JoinHouseholdDto {
  @ApiProperty({ description: '8-character uppercase invite code from household owner', example: '7K2P9XQ4' })
  @KeepRawValue()
  @IsString()
  @MinLength(8)
  @MaxLength(8)
  @Matches(/^[A-Z0-9]{8}$/, { message: 'inviteCode must be 8 uppercase alphanumeric characters' })
  inviteCode: string;
}

export class UpdateHouseholdDto {
  @ApiProperty()
  @KeepRawValue()
  @IsString()
  @MinLength(1)
  @MaxLength(100)
  name: string;
}
