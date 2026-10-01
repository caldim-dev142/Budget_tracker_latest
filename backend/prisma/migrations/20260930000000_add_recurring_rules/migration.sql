-- Migration: 20260930000000_add_recurring_rules
-- Adds the recurring_rules table only. No existing tables or columns are altered.

CREATE TABLE "recurring_rules" (
    "id"               TEXT        NOT NULL,
    "household_id"     TEXT        NOT NULL,
    "kind"             TEXT        NOT NULL,                              -- 'spending' | 'income'
    "category_id"      TEXT        NOT NULL,
    "account_id"       TEXT,
    "card_id"          TEXT,
    "amount_paise"     BIGINT      NOT NULL,
    "note"             TEXT,
    "day_of_month"     INTEGER     NOT NULL,                             -- 1–31
    "start_date"       TIMESTAMPTZ NOT NULL,
    "end_date"         TIMESTAMPTZ,
    "mode"             TEXT        NOT NULL DEFAULT 'remind',            -- 'auto' | 'remind'
    "is_active"        BOOLEAN     NOT NULL DEFAULT TRUE,
    "processed_through" TIMESTAMPTZ,
    "processed_dates"  TEXT        NOT NULL DEFAULT '[]',               -- JSON array of ISO date strings, max 60
    "updated_at"       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    "created_at"       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    "deleted_at"       TIMESTAMPTZ,

    CONSTRAINT "recurring_rules_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "recurring_rules_household_id_fkey"
        FOREIGN KEY ("household_id")
        REFERENCES "households"("id")
        ON DELETE RESTRICT
        ON UPDATE NO ACTION
);

CREATE INDEX "recurring_rules_household_id_idx" ON "recurring_rules"("household_id");
