import { CanActivate, ExecutionContext, ForbiddenException, Injectable } from '@nestjs/common';

/**
 * Tenant guard for household-scoped resources. Must run after JwtAuthGuard.
 * Fails closed: requests without an active household are rejected so that a missing/empty
 * household id can never be used as a query scope.
 */
@Injectable()
export class HouseholdGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const req = context.switchToHttp().getRequest();
    const householdId = req?.user?.householdId;
    if (typeof householdId !== 'string' || householdId.trim().length === 0) {
      throw new ForbiddenException('No active household. Create or join a household first.');
    }
    return true;
  }
}
