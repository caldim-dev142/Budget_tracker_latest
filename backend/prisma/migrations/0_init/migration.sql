-- Baseline migration (DEF-DEP-01).
-- Recreates the schema that existed before 20260915_phase1_refresh_tokens_and_restrict_fk so that
-- `prisma migrate deploy` can build a fresh database from the migration history.
--
-- EXISTING DATABASES (already created with `prisma db push` / supabase_schema.sql): do NOT run this
-- migration against them. Mark it as applied instead:
--   npx prisma migrate resolve --applied 0_init
CREATE TABLE "households" ("id" TEXT PRIMARY KEY, "name" TEXT NOT NULL, "owner_id" TEXT NOT NULL,
  "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP, "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE "users" ("id" TEXT PRIMARY KEY, "email" TEXT NOT NULL, "password" TEXT, "display_name" TEXT NOT NULL,
  "household_id" TEXT, "auth_provider" TEXT NOT NULL DEFAULT 'email', "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE "categories" ("id" TEXT PRIMARY KEY, "household_id" TEXT NOT NULL, "kind" TEXT NOT NULL, "group_code" TEXT,
  "name" TEXT NOT NULL, "need_or_want" TEXT, "is_deduction" BOOLEAN NOT NULL DEFAULT false, "is_system" BOOLEAN NOT NULL DEFAULT false,
  "sort_order" INTEGER NOT NULL DEFAULT 0, "archived_at" TIMESTAMPTZ(6));
CREATE TABLE "accounts" ("id" TEXT PRIMARY KEY, "household_id" TEXT NOT NULL, "name" TEXT NOT NULL, "type" TEXT NOT NULL,
  "current_balance_paise" INTEGER NOT NULL DEFAULT 0, "is_active" BOOLEAN NOT NULL DEFAULT true, "sort_order" INTEGER NOT NULL DEFAULT 0);
CREATE TABLE "entries" ("id" TEXT PRIMARY KEY, "household_id" TEXT NOT NULL, "category_id" TEXT NOT NULL, "kind" TEXT NOT NULL,
  "account_id" TEXT, "card_id" TEXT, "entry_date" TIMESTAMPTZ(6) NOT NULL, "amount_paise" INTEGER NOT NULL, "note" TEXT, "parent_id" TEXT,
  "created_by" TEXT NOT NULL, "version" INTEGER NOT NULL DEFAULT 1, "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP, "deleted_at" TIMESTAMPTZ(6),
  CONSTRAINT "entries_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "categories"("id") ON DELETE CASCADE ON UPDATE NO ACTION);
CREATE TABLE "budgets" ("id" TEXT PRIMARY KEY, "household_id" TEXT NOT NULL, "category_id" TEXT NOT NULL, "year_month" TEXT NOT NULL,
  "amount_paise" INTEGER NOT NULL DEFAULT 0,
  CONSTRAINT "budgets_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "categories"("id") ON DELETE CASCADE ON UPDATE NO ACTION);
CREATE UNIQUE INDEX "budgets_category_id_year_month_key" ON "budgets"("category_id","year_month");
CREATE TABLE "sinking_funds" ("id" TEXT PRIMARY KEY, "household_id" TEXT NOT NULL, "name" TEXT NOT NULL,
  "opening_reserve_paise" INTEGER NOT NULL DEFAULT 0, "archived_at" TIMESTAMPTZ(6));
CREATE TABLE "fund_movements" ("id" TEXT PRIMARY KEY, "fund_id" TEXT NOT NULL, "type" TEXT NOT NULL, "amount_paise" INTEGER NOT NULL,
  "movement_date" TIMESTAMPTZ(6) NOT NULL, "note" TEXT,
  CONSTRAINT "fund_movements_fund_id_fkey" FOREIGN KEY ("fund_id") REFERENCES "sinking_funds"("id") ON DELETE CASCADE ON UPDATE NO ACTION);
CREATE TABLE "saving_goals" ("id" TEXT PRIMARY KEY, "household_id" TEXT NOT NULL, "bucket" TEXT NOT NULL, "name" TEXT NOT NULL,
  "target_paise" INTEGER, "monthly_budget_paise" INTEGER NOT NULL DEFAULT 0, "archived_at" TIMESTAMPTZ(6));
CREATE TABLE "goal_contributions" ("id" TEXT PRIMARY KEY, "goal_id" TEXT NOT NULL, "amount_paise" INTEGER NOT NULL,
  "contribution_date" TIMESTAMPTZ(6) NOT NULL, "note" TEXT,
  CONSTRAINT "goal_contributions_goal_id_fkey" FOREIGN KEY ("goal_id") REFERENCES "saving_goals"("id") ON DELETE CASCADE ON UPDATE NO ACTION);
CREATE TABLE "credit_cards" ("id" TEXT PRIMARY KEY, "household_id" TEXT NOT NULL, "name" TEXT NOT NULL,
  "previous_outstanding_paise" INTEGER NOT NULL DEFAULT 0, "is_active" BOOLEAN NOT NULL DEFAULT true);
CREATE TABLE "card_transactions" ("id" TEXT PRIMARY KEY, "card_id" TEXT NOT NULL, "txn_date" TIMESTAMPTZ(6) NOT NULL,
  "description" TEXT NOT NULL, "amount_paise" INTEGER NOT NULL, "s_no" INTEGER,
  CONSTRAINT "card_transactions_card_id_fkey" FOREIGN KEY ("card_id") REFERENCES "credit_cards"("id") ON DELETE CASCADE ON UPDATE NO ACTION);
CREATE TABLE "receivables" ("id" TEXT PRIMARY KEY, "household_id" TEXT NOT NULL, "person_name" TEXT NOT NULL, "amount_paise" INTEGER NOT NULL,
  "status" TEXT NOT NULL DEFAULT 'open', "due_date" TIMESTAMPTZ(6), "entry_id" TEXT);
CREATE TABLE "planned_bills" ("id" TEXT PRIMARY KEY, "household_id" TEXT NOT NULL, "name" TEXT NOT NULL, "amount_paise" INTEGER NOT NULL,
  "due_date" TIMESTAMPTZ(6), "is_paid" BOOLEAN NOT NULL DEFAULT false, "entry_id" TEXT);
CREATE TABLE "reserve_lines" ("id" TEXT PRIMARY KEY, "household_id" TEXT NOT NULL, "year_month" TEXT NOT NULL, "name" TEXT NOT NULL,
  "amount_paise" INTEGER NOT NULL, "source" TEXT NOT NULL DEFAULT 'manual');
CREATE TABLE "month_snapshots" ("id" TEXT PRIMARY KEY, "household_id" TEXT NOT NULL, "year_month" TEXT NOT NULL,
  "opening_balance_paise" INTEGER NOT NULL DEFAULT 0, "last_month_reserves_paise" INTEGER NOT NULL DEFAULT 0, "income_paise" INTEGER NOT NULL DEFAULT 0,
  "adjustments_paise" INTEGER NOT NULL DEFAULT 0, "spending_paise" INTEGER NOT NULL DEFAULT 0, "protection_paise" INTEGER NOT NULL DEFAULT 0,
  "saving_paise" INTEGER NOT NULL DEFAULT 0, "reserves_paise" INTEGER NOT NULL DEFAULT 0, "closing_balance_paise" INTEGER NOT NULL DEFAULT 0,
  "remaining_paise" INTEGER NOT NULL DEFAULT 0, "status" TEXT NOT NULL DEFAULT 'open', "closed_at" TIMESTAMPTZ(6));
CREATE UNIQUE INDEX "month_snapshots_household_id_year_month_key" ON "month_snapshots"("household_id","year_month");
CREATE TABLE "annual_targets" ("id" TEXT PRIMARY KEY, "household_id" TEXT NOT NULL, "title" TEXT NOT NULL, "target_paise" INTEGER NOT NULL,
  "type" TEXT NOT NULL DEFAULT 'income');
CREATE TABLE "sync_queue" ("id" TEXT PRIMARY KEY, "op" TEXT NOT NULL, "entity" TEXT NOT NULL, "entity_id" TEXT NOT NULL, "payload" TEXT NOT NULL,
  "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP, "attempts" INTEGER NOT NULL DEFAULT 0, "synced_at" TIMESTAMPTZ(6));
