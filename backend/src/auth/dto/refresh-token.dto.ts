import { IsOptional, IsString, MinLength } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { KeepRawValue } from '../../common/decorators/strict-type.decorator';

export class RefreshTokenDto {
  @ApiProperty()
  @KeepRawValue()
  @IsString()
  @MinLength(1)
  userId: string;

  @ApiProperty({ description: 'Raw refresh token returned by login/register/refresh' })
  @KeepRawValue()
  @IsString()
  @MinLength(1)
  refreshToken: string;

  @ApiProperty({ description: 'refreshTokenFamily returned with the token' })
  @KeepRawValue()
  @IsString()
  @MinLength(1)
  family: string;
}

export class LogoutDto {
  @ApiPropertyOptional({ description: 'refreshTokenFamily of the session to revoke; omit to revoke all sessions' })
  @IsOptional()
  @KeepRawValue()
  @IsString()
  family?: string;
}
