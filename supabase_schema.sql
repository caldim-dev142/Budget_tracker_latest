-- Supabase PostgreSQL Schema for Budget Tracker

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Users Table
CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    email TEXT NOT NULL,
    password TEXT,
    display_name TEXT NOT NULL,
    household_id TEXT NOT NULL,
    auth_provider TEXT NOT NULL DEFAULT 'email',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Accounts Table
CREATE TABLE IF NOT EXISTS accounts (
    id TEXT PRIMARY KEY,
    household_id TEXT NOT NULL,
    name TEXT NOT NULL,
    type TEXT NOT NULL,
    current_balance_paise INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true,
    sort_order INTEGER NOT NULL DEFAULT 0
);

-- 3. Categories Table
CREATE TABLE IF NOT EXISTS categories (
    id TEXT PRIMARY KEY,
    household_id TEXT NOT NULL,
    kind TEXT NOT NULL,
    group_code TEXT,
    name TEXT NOT NULL,
    need_or_want TEXT,
    is_deduction BOOLEAN NOT NULL DEFAULT false,
    is_system BOOLEAN NOT NULL DEFAULT false,
    sort_order INTEGER NOT NULL DEFAULT 0,
    archived_at TIMESTAMPTZ
);

-- 4. Budgets Table
CREATE TABLE IF NOT EXISTS budgets (
    id TEXT PRIMARY KEY,
    household_id TEXT NOT NULL,
    category_id TEXT NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    year_month TEXT NOT NULL,
    amount_paise INTEGER NOT NULL DEFAULT 0,
    UNIQUE(category_id, year_month)
);

-- 5. Entries Table (Core)
CREATE TABLE IF NOT EXISTS entries (
    id TEXT PRIMARY KEY,
    household_id TEXT NOT NULL,
    category_id TEXT NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    kind TEXT NOT NULL,
    account_id TEXT,
    card_id TEXT,
    entry_date TIMESTAMPTZ NOT NULL,
    amount_paise INTEGER NOT NULL,
    note TEXT,
    parent_id TEXT,
    created_by TEXT NOT NULL,
    version INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

-- 6. Sinking Funds Table
CREATE TABLE IF NOT EXISTS sinking_funds (
    id TEXT PRIMARY KEY,
    household_id TEXT NOT NULL,
    name TEXT NOT NULL,
    opening_reserve_paise INTEGER NOT NULL DEFAULT 0,
    archived_at TIMESTAMPTZ
);

-- 7. Fund Movements Table
CREATE TABLE IF NOT EXISTS fund_movements (
    id TEXT PRIMARY KEY,
    fund_id TEXT NOT NULL REFERENCES sinking_funds(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    amount_paise INTEGER NOT NULL,
    movement_date TIMESTAMPTZ NOT NULL,
    note TEXT
);

-- 8. Saving Goals Table
CREATE TABLE IF NOT EXISTS saving_goals (
    id TEXT PRIMARY KEY,
    household_id TEXT NOT NULL,
    bucket TEXT NOT NULL,
    name TEXT NOT NULL,
    target_paise INTEGER,
    monthly_budget_paise INTEGER NOT NULL DEFAULT 0,
    archived_at TIMESTAMPTZ
);

-- 9. Goal Contributions Table
CREATE TABLE IF NOT EXISTS goal_contributions (
    id TEXT PRIMARY KEY,
    goal_id TEXT NOT NULL REFERENCES saving_goals(id) ON DELETE CASCADE,
    amount_paise INTEGER NOT NULL,
    contribution_date TIMESTAMPTZ NOT NULL,
    note TEXT
);

-- 10. Credit Cards Table
CREATE TABLE IF NOT EXISTS credit_cards (
    id TEXT PRIMARY KEY,
    household_id TEXT NOT NULL,
    name TEXT NOT NULL,
    previous_outstanding_paise INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true
);

-- 11. Card Transactions Table
CREATE TABLE IF NOT EXISTS card_transactions (
    id TEXT PRIMARY KEY,
    card_id TEXT NOT NULL REFERENCES credit_cards(id) ON DELETE CASCADE,
    txn_date TIMESTAMPTZ NOT NULL,
    description TEXT NOT NULL,
    amount_paise INTEGER NOT NULL,
    s_no INTEGER
);

-- 12. Receivables Table
CREATE TABLE IF NOT EXISTS receivables (
    id TEXT PRIMARY KEY,
    household_id TEXT NOT NULL,
    person_name TEXT NOT NULL,
    amount_paise INTEGER NOT NULL,
    status TEXT NOT NULL DEFAULT 'open',
    due_date TIMESTAMPTZ,
    entry_id TEXT
);

-- 13. Planned Bills Table
CREATE TABLE IF NOT EXISTS planned_bills (
    id TEXT PRIMARY KEY,
    household_id TEXT NOT NULL,
    name TEXT NOT NULL,
    amount_paise INTEGER NOT NULL,
    due_date TIMESTAMPTZ,
    is_paid BOOLEAN NOT NULL DEFAULT false,
    entry_id TEXT
);

-- 14. Reserve Lines Table
CREATE TABLE IF NOT EXISTS reserve_lines (
    id TEXT PRIMARY KEY,
    household_id TEXT NOT NULL,
    year_month TEXT NOT NULL,
    name TEXT NOT NULL,
    amount_paise INTEGER NOT NULL,
    source TEXT NOT NULL DEFAULT 'manual'
);

-- 15. Month Snapshots Table
CREATE TABLE IF NOT EXISTS month_snapshots (
    id TEXT PRIMARY KEY,
    household_id TEXT NOT NULL,
    year_month TEXT NOT NULL,
    opening_balance_paise INTEGER NOT NULL DEFAULT 0,
    last_month_reserves_paise INTEGER NOT NULL DEFAULT 0,
    income_paise INTEGER NOT NULL DEFAULT 0,
    adjustments_paise INTEGER NOT NULL DEFAULT 0,
    spending_paise INTEGER NOT NULL DEFAULT 0,
    protection_paise INTEGER NOT NULL DEFAULT 0,
    saving_paise INTEGER NOT NULL DEFAULT 0,
    reserves_paise INTEGER NOT NULL DEFAULT 0,
    closing_balance_paise INTEGER NOT NULL DEFAULT 0,
    remaining_paise INTEGER NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'open',
    closed_at TIMESTAMPTZ,
    UNIQUE(household_id, year_month)
);

-- 16. Sync Queue Table
CREATE TABLE IF NOT EXISTS sync_queue (
    id TEXT PRIMARY KEY,
    op TEXT NOT NULL,
    entity TEXT NOT NULL,
    entity_id TEXT NOT NULL,
    payload TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    attempts INTEGER NOT NULL DEFAULT 0,
    synced_at TIMESTAMPTZ
);

-- 17. Annual Targets Table
CREATE TABLE IF NOT EXISTS annual_targets (
    id TEXT PRIMARY KEY,
    household_id TEXT NOT NULL,
    title TEXT NOT NULL,
    target_paise INTEGER NOT NULL,
    type TEXT NOT NULL DEFAULT 'income'
);
