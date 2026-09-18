import { IsString, MaxLength, MinLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { KeepRawValue } from '../../common/decorators/strict-type.decorator';

/// Body for POST /auth/google.
///
/// SECURITY: this previously used an inline `@Body() body: { idToken: string }`.
/// Nest's global ValidationPipe skips parameters whose metatype is a native
/// type or absent, so that signature received NO validation at all on an
/// UNAUTHENTICATED endpoint — and an omitted body made `body` undefined, so
/// `body.idToken` threw a 500 instead of returning 401.
export class GoogleSignInDto {
  @ApiProperty({ description: 'Firebase or Google ID token from the client' })
  @KeepRawValue()
  @IsString()
  @MinLength(1)
  // JWTs are large but bounded; reject anything absurd before it reaches the
  // verification libraries.
  @MaxLength(8192)
  idToken: string;
}
