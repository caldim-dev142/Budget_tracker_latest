-- DEF-DATA-03: money columns are 64-bit integer paise (docs/FINANCIAL_WATERFALL_ENGINE.md §2).
-- INTEGER -> BIGINT is a widening conversion; no value changes.
ALTER TABLE "accounts" ALTER COLUMN "current_balance_paise" SET DATA TYPE BIGINT;
ALTER TABLE "entries" ALTER COLUMN "amount_paise" SET DATA TYPE BIGINT;
ALTER TABLE "budgets" ALTER COLUMN "amount_paise" SET DATA TYPE BIGINT;
ALTER TABLE "sinking_funds" ALTER COLUMN "opening_reserve_paise" SET DATA TYPE BIGINT;
ALTER TABLE "fund_movements" ALTER COLUMN "amount_paise" SET DATA TYPE BIGINT;
ALTER TABLE "saving_goals" ALTER COLUMN "target_paise" SET DATA TYPE BIGINT, ALTER COLUMN "monthly_budget_paise" SET DATA TYPE BIGINT;
ALTER TABLE "goal_contributions" ALTER COLUMN "amount_paise" SET DATA TYPE BIGINT;
ALTER TABLE "credit_cards" ALTER COLUMN "previous_outstanding_paise" SET DATA TYPE BIGINT;
ALTER TABLE "card_transactions" ALTER COLUMN "amount_paise" SET DATA TYPE BIGINT;
ALTER TABLE "receivables" ALTER COLUMN "amount_paise" SET DATA TYPE BIGINT;
ALTER TABLE "planned_bills" ALTER COLUMN "amount_paise" SET DATA TYPE BIGINT;
ALTER TABLE "reserve_lines" ALTER COLUMN "amount_paise" SET DATA TYPE BIGINT;
ALTER TABLE "month_snapshots" ALTER COLUMN "opening_balance_paise" SET DATA TYPE BIGINT, ALTER COLUMN "last_month_reserves_paise" SET DATA TYPE BIGINT, ALTER COLUMN "income_paise" SET DATA TYPE BIGINT, ALTER COLUMN "adjustments_paise" SET DATA TYPE BIGINT, ALTER COLUMN "spending_paise" SET DATA TYPE BIGINT, ALTER COLUMN "protection_paise" SET DATA TYPE BIGINT, ALTER COLUMN "saving_paise" SET DATA TYPE BIGINT, ALTER COLUMN "reserves_paise" SET DATA TYPE BIGINT, ALTER COLUMN "closing_balance_paise" SET DATA TYPE BIGINT, ALTER COLUMN "remaining_paise" SET DATA TYPE BIGINT;
ALTER TABLE "annual_targets" ALTER COLUMN "target_paise" SET DATA TYPE BIGINT;
