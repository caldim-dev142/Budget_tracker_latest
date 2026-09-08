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

  computeNetIncome(inflows: number, deductions: number) {
    return computeNetIncome(inflows, deductions);
  }

  computeBudgetLine(budget: number, actual: number) {
    return computeBudgetLine(budget, actual);
  }

  closingReserve(opening: number, contributions: number, withdrawals: number) {
    return closingReserve(opening, contributions, withdrawals);
  }

  closingBalance(totalAvailable: number, reserves: number) {
    return closingBalance(totalAvailable, reserves);
  }

  groupTotal(amounts: number[]) {
    return groupTotal(amounts);
  }
}
