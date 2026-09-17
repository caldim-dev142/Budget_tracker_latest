import { IsString, MaxLength, MinLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { KeepRawValue } from '../../common/decorators/strict-type.decorator';

export class UpdateUserDto {
  @ApiProperty()
  @KeepRawValue()
  @IsString()
  @MinLength(1)
  @MaxLength(100)
  displayName: string;
}
