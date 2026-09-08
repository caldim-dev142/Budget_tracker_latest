import * as fs from 'fs';
import * as path from 'path';
import {
  computeWaterfall,
  computeBudgetLine,
  closingReserve,
  closingBalance,
  groupTotal,
} from '../src/engine/engine';

describe('TypeScript Calculation Engine - Parity Verification', () => {
  let fixtures: any;

  beforeAll(() => {
    // Read the shared golden fixtures from the budget_tracker project
    const filePath = path.resolve(__dirname, '../../test/golden_fixtures.json');
    const content = fs.readFileSync(filePath, 'utf-8');
    fixtures = JSON.parse(content);
  });

  it('should run scenario: base_case and match golden remaining', () => {
    const s = fixtures.scenarios.find((x: any) => x.id === 'base_case');
    const input = s.input;
    const expected = s.expected.remaining;

    const result = computeWaterfall({
      openingBalance: Number(input.openingBalance),
      lastMonthReserves: Number(input.lastMonthReserves),
      income: Number(input.income),
      adjustments: Number(input.adjustments),
      spending: Number(input.spending),
      protection: Number(input.protection),
      saving: Number(input.saving),
      reservesSetAside: Number(input.reservesSetAside),
    });

    expect(result.remaining).toBe(Number(expected));
  });

  it('should run scenario: with_opening_balance and match golden remaining', () => {
    const s = fixtures.scenarios.find((x: any) => x.id === 'with_opening_balance');
    const input = s.input;
    const expected = s.expected.remaining;

    const result = computeWaterfall({
      openingBalance: Number(input.openingBalance),
      lastMonthReserves: Number(input.lastMonthReserves),
      income: Number(input.income - input.incomeDeductions),
      adjustments: Number(input.adjustments),
      spending: Number(input.spending),
      protection: Number(input.protection),
      saving: Number(input.saving),
      reservesSetAside: Number(input.reservesSetAside),
    });

    expect(result.remaining).toBe(Number(expected));
  });

  it('should run scenario: budget_pct_over and match budget difference', () => {
    const s = fixtures.scenarios.find((x: any) => x.id === 'budget_pct_over');
    const input = s.input;
    const expected = s.expected;

    const result = computeBudgetLine(Number(input.budget), Number(input.actual));

    expect(result.difference).toBe(Number(expected.difference));
    expect(result.pctUsed).toBeCloseTo(expected.pctUsed, 3);
    expect(result.isOverBudget).toBe(expected.isOverBudget);
  });

  it('should run scenario: edge_negative_reserve and allow negative reserve closing', () => {
    const s = fixtures.scenarios.find((x: any) => x.id === 'edge_negative_reserve');
    const input = s.input;
    const expected = s.expected;

    const closing = closingReserve(
      Number(input.fundOpeningReserve),
      Number(input.fundContributions),
      Number(input.fundWithdrawals),
    );

    expect(closing).toBe(Number(expected.closingReserve));
  });

  it('should run scenario: rollover_next_month and compute closing balance', () => {
    const s = fixtures.scenarios.find((x: any) => x.id === 'rollover_next_month');
    const input = s.input;
    const expected = s.expected;

    const balance = closingBalance(Number(input.totalAvailable), Number(input.reservesAtClose));

    expect(balance).toBe(Number(expected.closingBalance));
  });
});
