-- Phase 3 Batch 1: Indexes (D2) and Foreign Key Constraints (D5)

-- ─── 1. Indexes (D2) ──────────────────────────────────────────────────────────

-- Tenant-scoped household_id indexes
CREATE INDEX "categories_household_id_idx" ON "categories"("household_id");
CREATE INDEX "accounts_household_id_idx" ON "accounts"("household_id");
CREATE INDEX "entries_household_id_idx" ON "entries"("household_id");
CREATE INDEX "budgets_household_id_idx" ON "budgets"("household_id");
CREATE INDEX "sinking_funds_household_id_idx" ON "sinking_funds"("household_id");
CREATE INDEX "saving_goals_household_id_idx" ON "saving_goals"("household_id");
CREATE INDEX "credit_cards_household_id_idx" ON "credit_cards"("household_id");
CREATE INDEX "receivables_household_id_idx" ON "receivables"("household_id");
CREATE INDEX "planned_bills_household_id_idx" ON "planned_bills"("household_id");
CREATE INDEX "reserve_lines_household_id_idx" ON "reserve_lines"("household_id");
CREATE INDEX "month_snapshots_household_id_idx" ON "month_snapshots"("household_id");
CREATE INDEX "annual_targets_household_id_idx" ON "annual_targets"("household_id");
CREATE INDEX "users_household_id_idx" ON "users"("household_id");

-- Composite indexes on (household_id, year_month)
CREATE INDEX "budgets_household_id_year_month_idx" ON "budgets"("household_id", "year_month");
CREATE INDEX "reserve_lines_household_id_year_month_idx" ON "reserve_lines"("household_id", "year_month");

-- Child entity and foreign key indexes
CREATE INDEX "card_transactions_card_id_idx" ON "card_transactions"("card_id");
CREATE INDEX "entries_account_id_idx" ON "entries"("account_id");
CREATE INDEX "entries_card_id_idx" ON "entries"("card_id");
CREATE INDEX "entries_parent_id_idx" ON "entries"("parent_id");
CREATE INDEX "fund_movements_fund_id_idx" ON "fund_movements"("fund_id");
CREATE INDEX "goal_contributions_goal_id_idx" ON "goal_contributions"("goal_id");


-- ─── 2. Foreign Key Constraints with ON DELETE RESTRICT (D5) ─────────────────

-- Tenant tables referencing households
ALTER TABLE "categories" ADD CONSTRAINT "categories_household_id_fkey"
  FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE RESTRICT ON UPDATE NO ACTION;

ALTER TABLE "accounts" ADD CONSTRAINT "accounts_household_id_fkey"
  FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE RESTRICT ON UPDATE NO ACTION;

ALTER TABLE "entries" ADD CONSTRAINT "entries_household_id_fkey"
  FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE RESTRICT ON UPDATE NO ACTION;

ALTER TABLE "budgets" ADD CONSTRAINT "budgets_household_id_fkey"
  FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE RESTRICT ON UPDATE NO ACTION;

ALTER TABLE "sinking_funds" ADD CONSTRAINT "sinking_funds_household_id_fkey"
  FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE RESTRICT ON UPDATE NO ACTION;

ALTER TABLE "saving_goals" ADD CONSTRAINT "saving_goals_household_id_fkey"
  FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE RESTRICT ON UPDATE NO ACTION;

ALTER TABLE "credit_cards" ADD CONSTRAINT "credit_cards_household_id_fkey"
  FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE RESTRICT ON UPDATE NO ACTION;

ALTER TABLE "receivables" ADD CONSTRAINT "receivables_household_id_fkey"
  FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE RESTRICT ON UPDATE NO ACTION;

ALTER TABLE "planned_bills" ADD CONSTRAINT "planned_bills_household_id_fkey"
  FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE RESTRICT ON UPDATE NO ACTION;

ALTER TABLE "reserve_lines" ADD CONSTRAINT "reserve_lines_household_id_fkey"
  FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE RESTRICT ON UPDATE NO ACTION;

ALTER TABLE "month_snapshots" ADD CONSTRAINT "month_snapshots_household_id_fkey"
  FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE RESTRICT ON UPDATE NO ACTION;

ALTER TABLE "annual_targets" ADD CONSTRAINT "annual_targets_household_id_fkey"
  FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE RESTRICT ON UPDATE NO ACTION;

ALTER TABLE "users" ADD CONSTRAINT "users_household_id_fkey"
  FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE RESTRICT ON UPDATE NO ACTION;

ALTER TABLE "household_invites" ADD CONSTRAINT "household_invites_household_id_fkey"
  FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE RESTRICT ON UPDATE NO ACTION;

ALTER TABLE "sync_tombstones" ADD CONSTRAINT "sync_tombstones_household_id_fkey"
  FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- Entry child foreign keys referencing accounts, credit_cards, and self-referencing parent entry
ALTER TABLE "entries" ADD CONSTRAINT "entries_account_id_fkey"
  FOREIGN KEY ("account_id") REFERENCES "accounts"("id") ON DELETE RESTRICT ON UPDATE NO ACTION;

ALTER TABLE "entries" ADD CONSTRAINT "entries_card_id_fkey"
  FOREIGN KEY ("card_id") REFERENCES "credit_cards"("id") ON DELETE RESTRICT ON UPDATE NO ACTION;

ALTER TABLE "entries" ADD CONSTRAINT "entries_parent_id_fkey"
  FOREIGN KEY ("parent_id") REFERENCES "entries"("id") ON DELETE RESTRICT ON UPDATE NO ACTION;
