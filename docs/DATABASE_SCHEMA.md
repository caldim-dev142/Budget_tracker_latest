# 5. Database Schema & Data Models

## 1. Schema Overview

The database contains **17 core tables** implemented in PostgreSQL (Supabase / Prisma) and mirrored in Drift SQLite for local offline storage.

All financial amounts are stored as **64-bit integer paise** (`INTEGER` or `BIGINT`).

---

## 2. Entity-Relationship Diagram

```mermaid
erDiagram
    HOUSEHOLDS ||--o{ USERS : "contains"
    HOUSEHOLDS ||--o{ ACCOUNTS : "owns"
    HOUSEHOLDS ||--o{ CATEGORIES : "defines"
    HOUSEHOLDS ||--o{ BUDGETS : "plans"
    HOUSEHOLDS ||--o{ ENTRIES : "records"
    HOUSEHOLDS ||--o{ SINKING_FUNDS : "allocates"
    HOUSEHOLDS ||--o{ SAVING_GOALS : "targets"
    HOUSEHOLDS ||--o{ CREDIT_CARDS : "manages"
    HOUSEHOLDS ||--o{ MONTH_SNAPSHOTS : "closes"
    
    CATEGORIES ||--o{ BUDGETS : "budgeted_in"
    CATEGORIES ||--o{ ENTRIES : "categorizes"
    
    ACCOUNTS ||--o{ ENTRIES : "funds"
    
    SINKING_FUNDS ||--o{ FUND_MOVEMENTS : "tracks"
    SAVING_GOALS ||--o{ GOAL_CONTRIBUTIONS : "accumulates"
    CREDIT_CARDS ||--o{ CARD_TRANSACTIONS : "charges"
```

---

## 3. Table-by-Table Reference

### 1. `users`
Stores user profile, authentication mapping, and household membership.
| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `TEXT` / `UUID` | PRIMARY KEY | Unique user ID |
| `email` | `TEXT` | NOT NULL, UNIQUE | User email address |
| `password` | `TEXT` | NULLABLE | Salted SHA-256 password hash (or null if OAuth) |
| `display_name` | `TEXT` | NOT NULL | User's full name |
| `household_id` | `TEXT` | NOT NULL | Associated household partition |
| `auth_provider` | `TEXT` | DEFAULT `'email'` | `'email'`, `'google'`, or `'offline'` |
| `created_at` | `TIMESTAMPTZ` | DEFAULT `NOW()` | Registration timestamp |

---

### 2. `accounts`
Stores liquid cash and bank accounts.
| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `TEXT` | PRIMARY KEY | Unique account ID |
| `household_id` | `TEXT` | NOT NULL | Household isolation key |
| `name` | `TEXT` | NOT NULL | E.g. "HDFC Savings", "Cash Wallet" |
| `type` | `TEXT` | NOT NULL | `'savings'`, `'checking'`, `'cash'`, `'investment'` |
| `current_balance_paise` | `INTEGER` | DEFAULT `0` | Current verified balance in paise |
| `is_active` | `BOOLEAN` | DEFAULT `true` | Soft toggle |
| `sort_order` | `INTEGER` | DEFAULT `0` | UI display ordering |

---

### 3. `categories`
Taxonomy of financial classifications (~141 seeded categories).
| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `TEXT` | PRIMARY KEY | Unique category ID |
| `household_id` | `TEXT` | NOT NULL | Household isolation key |
| `kind` | `TEXT` | NOT NULL | `'income'`, `'adjustment'`, `'spending'`, `'protection'`, `'saving'` |
| `group_code` | `TEXT` | NULLABLE | Group code: `'fees'`, `'needs'`, `'wants'`, `'travel'`, `'honorarium'`, etc. |
| `name` | `TEXT` | NOT NULL | E.g. "Groceries", "Dining Out", "Life Insurance" |
| `need_or_want` | `TEXT` | NULLABLE | `'need'` vs. `'want'` classification |
| `is_deduction` | `BOOLEAN` | DEFAULT `false` | **Critical**: If `true`, subtracts from adjustments total |
| `is_system` | `BOOLEAN` | DEFAULT `false` | If true, cannot be renamed or deleted |
| `sort_order` | `INTEGER` | DEFAULT `0` | UI order |
| `archived_at` | `TIMESTAMPTZ`| NULLABLE | Deletion/archive timestamp |

---

### 4. `budgets`
Monthly planned limits assigned per category.
| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `TEXT` | PRIMARY KEY | Unique budget ID |
| `household_id` | `TEXT` | NOT NULL | Household key |
| `category_id` | `TEXT` | FOREIGN KEY (`categories.id`) | Target category |
| `year_month` | `TEXT` | NOT NULL | Year-month string, e.g. `'2026-09'` |
| `amount_paise` | `INTEGER` | DEFAULT `0` | Budgeted limit in paise |
| *Constraint* | `UNIQUE(category_id, year_month)` | UNIQUE constraint | One budget per category per month |

---

### 5. `entries`
The primary double-entry financial transaction ledger.
| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `TEXT` | PRIMARY KEY | Unique transaction ID |
| `household_id` | `TEXT` | NOT NULL | Household key |
| `category_id` | `TEXT` | FOREIGN KEY (`categories.id`) | Category assignment |
| `kind` | `TEXT` | NOT NULL | `'income'`, `'expense'`, `'adjustment'`, `'transfer'` |
| `account_id` | `TEXT` | NULLABLE | Originating bank/cash account |
| `card_id` | `TEXT` | NULLABLE | Associated credit card |
| `entry_date` | `TIMESTAMPTZ` | NOT NULL | Date and time of transaction |
| `amount_paise` | `INTEGER` | NOT NULL | Always positive integer paise amount |
| `note` | `TEXT` | NULLABLE | User description / note |
| `parent_id` | `TEXT` | NULLABLE | For split transactions |
| `created_by` | `TEXT` | NOT NULL | User ID who logged entry |
| `version` | `INTEGER` | DEFAULT `1` | Optimistic locking / sync version |
| `created_at` | `TIMESTAMPTZ` | DEFAULT `NOW()` | Creation timestamp |
| `updated_at` | `TIMESTAMPTZ` | DEFAULT `NOW()` | Modification timestamp |
| `deleted_at` | `TIMESTAMPTZ` | NULLABLE | Soft-delete timestamp for sync |

---

### 6. `sinking_funds` & `fund_movements`
Protection sinking funds (Layer 2) tracking cumulative reserves.
- **`sinking_funds`**: `id`, `household_id`, `name`, `opening_reserve_paise`, `archived_at`.
- **`fund_movements`**: `id`, `fund_id` (FK), `type` (`'inflow'`, `'outflow'`), `amount_paise`, `movement_date`, `note`.

---

### 7. `saving_goals` & `goal_contributions`
Goal-oriented savings (Layer 3).
- **`saving_goals`**: `id`, `household_id`, `bucket` (`'retirement'`, `'children'`, `'custom'`), `name`, `target_paise`, `monthly_budget_paise`, `archived_at`.
- **`goal_contributions`**: `id`, `goal_id` (FK), `amount_paise`, `contribution_date`, `note`.

---

### 8. `credit_cards` & `card_transactions`
Credit card debt and monthly billing cycles.
- **`credit_cards`**: `id`, `household_id`, `name`, `previous_outstanding_paise`, `is_active`.
- **`card_transactions`**: `id`, `card_id` (FK), `txn_date`, `description`, `amount_paise`, `s_no`.

---

### 9. `month_snapshots`
Sealed monthly financial statements capturing the exact state of the 7-layer waterfall.
| Column | Type | Description |
|---|---|---|
| `id` | `TEXT` (PK) | Snapshot ID |
| `household_id` | `TEXT` | Household key |
| `year_month` | `TEXT` | Formatted `'YYYY-MM'` |
| `opening_balance_paise` | `INTEGER` | Actual start balance |
| `last_month_reserves_paise` | `INTEGER` | Carried-in reserves |
| `income_paise` | `INTEGER` | Total income |
| `adjustments_paise` | `INTEGER` | Total net adjustments |
| `spending_paise` | `INTEGER` | Total actual spend |
| `protection_paise` | `INTEGER` | Total protection allocated |
| `saving_paise` | `INTEGER` | Total savings allocated |
| `reserves_paise` | `INTEGER` | Earmarked reserve |
| `closing_balance_paise` | `INTEGER` | Verified bank closing balance |
| `remaining_paise` | `INTEGER` | Surplus = Inflow - Outflow |
| `status` | `TEXT` | `'open'` or `'closed'` |
| `closed_at` | `TIMESTAMPTZ` | Timestamp of month closure |

---

### 10. `sync_queue`
Local SQLite table storing offline mutations waiting for cloud sync.
| Column | Type | Description |
|---|---|---|
| `id` | `TEXT` (PK) | Unique mutation ID |
| `op` | `TEXT` | `'CREATE'`, `'UPDATE'`, `'DELETE'` |
| `entity` | `TEXT` | Target entity table (e.g. `'entries'`) |
| `entity_id` | `TEXT` | Primary key of affected entity |
| `payload` | `TEXT` | JSON payload of the mutation |
| `created_at` | `TIMESTAMPTZ` | When mutation occurred |
| `attempts` | `INTEGER` | Number of failed sync attempts |
| `synced_at` | `TIMESTAMPTZ` | When sync succeeded |
