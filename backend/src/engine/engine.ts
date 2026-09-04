/**
 * TypeScript calculation engine — must produce identical paise-exact results
 * as the Dart engine on the same golden fixtures (doc 15 §1, doc 03 §1).
 *
 * All values are BigInt (BIGINT paise equivalent).
 * Never use floating point for money arithmetic.
 */

export interface MonthActuals {
  openingBalance: bigint;
  lastMonthReserves: bigint;
  income: bigint;
  adjustments: bigint; // signed
  spending: bigint;
  protection: bigint;
  saving: bigint;
  reservesSetAside: bigint;
}

export interface WaterfallResult {
  opening: bigint;
  income: bigint;
  adjustments: bigint;
  spending: bigint;
  protection: bigint;
  saving: bigint;
  reserves: bigint;
  remaining: bigint;
}

/**
 * Waterfall engine (mirrors Dart WaterfallEngine, doc 01 §7.2).
 * Formula:
 *   remaining = (openingBalance + lastMonthReserves)
 *             + income
 *             + adjustments   ← signed
 *             − spending
 *             − protection
 *             − saving
 *             − reservesSetAside
 */
export function computeWaterfall(m: MonthActuals): WaterfallResult {
  const opening = m.openingBalance + m.lastMonthReserves;
  const afterIncome = opening + m.income;
  const afterAdjustments = afterIncome + m.adjustments; // signed
  const afterSpending = afterAdjustments - m.spending;
  const afterProtection = afterSpending - m.protection;
  const afterSaving = afterProtection - m.saving;
  const remaining = afterSaving - m.reservesSetAside;

  return {
    opening,
    income: m.income,
    adjustments: m.adjustments,
    spending: m.spending,
    protection: m.protection,
    saving: m.saving,
    reserves: m.reservesSetAside,
    remaining,
  };
}

/**
 * Net income = inflows − deductions (doc 01 §2.1).
 */
export function computeNetIncome(
  inflows: bigint,
  deductions: bigint,
): bigint {
  return inflows - deductions;
}

/**
 * Budget line computation (doc 01 §6).
 * difference = actual − budget
 * pctUsed = actual / budget (as number for UI, never stored)
 */
export function computeBudgetLine(
  budget: bigint,
  actual: bigint,
): {
  difference: bigint;
  pctUsed: number;
  isOverBudget: boolean;
  isNearBudget: boolean;
} {
  const difference = actual - budget;
  const pctUsed = budget === 0n ? 0 : Number(actual) / Number(budget);
  return {
    difference,
    pctUsed,
    isOverBudget: pctUsed > 1.0,
    isNearBudget: pctUsed >= 0.8 && pctUsed <= 1.0,
  };
}

/**
 * Sinking fund closing reserve (doc 01 §4).
 * closingReserve = openingReserve + contributions − withdrawals
 * CAN be negative (doc 02 §5 edge 5).
 */
export function closingReserve(
  openingReserve: bigint,
  contributions: bigint,
  withdrawals: bigint,
): bigint {
  return openingReserve + contributions - withdrawals;
}

/**
 * Rollover: next month opening (doc 06 §4).
 * closingBalance = totalAvailable − reserves
 */
export function closingBalance(
  totalAvailable: bigint,
  reserves: bigint,
): bigint {
  return totalAvailable - reserves;
}

/**
 * Group rollup: sum of all item amounts.
 */
export function groupTotal(amounts: bigint[]): bigint {
  return amounts.reduce((s, a) => s + a, 0n);
}
