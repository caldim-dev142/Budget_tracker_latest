import { IsOptional, IsString, MaxLength, MinLength } from 'class-validator';
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

export class JoinHouseholdDto {
  @ApiProperty()
  @KeepRawValue()
  @IsString()
  @MinLength(1)
  @MaxLength(100)
  householdId: string;
}

export class UpdateHouseholdDto {
  @ApiProperty()
  @KeepRawValue()
  @IsString()
  @MinLength(1)
  @MaxLength(100)
  name: string;
}
