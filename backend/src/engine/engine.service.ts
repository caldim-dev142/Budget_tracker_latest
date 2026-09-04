import { Injectable } from '@nestjs/common';
import {
  computeWaterfall,
  computeNetIncome,
  computeBudgetLine,
  closingReserve,
  closingBalance,
  groupTotal,
  MonthActuals,
} from './engine';

/**
 * Injectable wrapper around the pure engine functions.
 * Used by MonthsService (close/rollover), ReportsService (dashboard), SyncService.
 */
@Injectable()
export class EngineService {
  computeWaterfall(actuals: MonthActuals) {
    return computeWaterfall(actuals);
  }

  computeNetIncome(inflows: bigint, deductions: bigint) {
    return computeNetIncome(inflows, deductions);
  }

  computeBudgetLine(budget: bigint, actual: bigint) {
    return computeBudgetLine(budget, actual);
  }

  closingReserve(opening: bigint, contributions: bigint, withdrawals: bigint) {
    return closingReserve(opening, contributions, withdrawals);
  }

  closingBalance(totalAvailable: bigint, reserves: bigint) {
    return closingBalance(totalAvailable, reserves);
  }

  groupTotal(amounts: bigint[]) {
    return groupTotal(amounts);
  }
}
