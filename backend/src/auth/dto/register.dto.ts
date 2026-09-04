import { IsEmail, IsString, MinLength, MaxLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class RegisterDto {
  @ApiProperty({ example: 'admin@smithfamily.in' })
  @IsEmail()
  email: string;

  @ApiProperty({ example: 'securePassword123!', minLength: 8 })
  @IsString()
  @MinLength(8)
  @MaxLength(128)
  password: string;

  @ApiProperty({ example: 'Ramesh Smith' })
  @IsString()
  @MinLength(1)
  @MaxLength(100)
  displayName: string;

  @ApiProperty({ example: 'Smith Family' })
  @IsString()
  @MinLength(1)
  @MaxLength(100)
  householdName: string;
}
