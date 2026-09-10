# 7. Developer Rules, Invariants & Roadmap

## 1. Non-Negotiable Invariants

All developers and AI assistants contributing to this codebase must adhere strictly to the following architectural rules:

### 1. Never Hardcode Database Data
- **Rule**: Category lists, account balances, transaction records, budget limits, and user profiles must **always** be read dynamically from the database (Drift SQLite on client, PostgreSQL via Prisma on backend).
- **Prohibition**: Never use `Random()` generators, mock lists, or hardcoded dummy arrays in user-facing production screens.

### 2. Maintain Architectural Structure
- **Rule**: Follow the established clean architecture boundaries:
  - `domain/`: Pure business models, use cases, and calculation engines. **Zero Flutter or network imports.**
  - `data/`: Drift DAOs, SQLite migrations, REST clients, and DTOs.
  - `features/`: Presentation screens and Riverpod state controllers.
  - `backend/`: NestJS domain modules mirroring the client.
- **Prohibition**: Do not refactor folder structures, rename domain entities, or merge independent modules without architectural approval.

### 3. Strict Integer Paise Arithmetic
- **Rule**: Financial math must strictly use integer paise ($1\text{ INR} = 100\text{ paise}$).
- **Prohibition**: Never use double or floating-point variables for storing or calculating monetary sums.

### 4. Approved Financial Calculation Invariant
$$\text{Opening} + \text{Last Month Reserves} + \text{Income} + \text{Adjustments} - \text{Spending} - \text{Protection} - \text{Saving} - \text{Reserves} = \text{Remaining}$$

### 5. Adjustment Sign Rule (4 Add / 2 Subtract)
- **Add (+)**: `Credit Card Borrow/Payment`, `Borrow/Return (+)`, `Temporary In/Out (+)`, `Others(Inflow)`.
- **Subtract (-)**: `Lending/Return (-)`, `Others(Outflow)`.

---

## 2. Implementation Status & Handover Roadmap

### Phase 1: Core System Alignment (Completed)
- [x] **Task 1.0 — 1:1 Integer Paise & Offline Sync Alignment**: Aligned backend Prisma schema, sync DTOs, and Drift SQLite models to standard 32/64-bit integer paise.
- [x] **Task 1.1 — Real Data & Plan Distribution in Reports**: Implemented live Drift DAO / Riverpod queries in reports alongside interactive Plan Distribution sliders (50/30/20).
- [x] **Task 1.2 — Multi-Entity Batch Sync Engine**: Comprehensive bidirectional synchronization for categories, accounts, cards, bills, receivables, saving goals, sinking funds, budgets, and entries (`/sync/batch`).
- [x] **Task 1.3 — Native Device Security & App Lock**: Implemented native biometric / PIN authentication (`local_auth`) with lifecycle-aware `LockGate`.
- [x] **Task 1.4 — Dynamic Category Icon Engine**: Implemented 60+ keyword-mapped icons with category kind color tinting.
- [x] **Task 1.5 — Multi-User Household Management**: Implemented full household lifecycle (create, join, member management, active household switching) across backend and Flutter settings.
- [x] **Task 1.6 — Global Timezone Localization**: Added timezone selection with UTC offset mapping across all transaction dates and reports.
- [x] **Task 1.7 — Cross-Platform Branding Pipeline**: Created `scripts/generate_app_icons.py` for Android, iOS, Windows, and Web.

### Phase 2: First-Time User Experience & Onboarding
- [ ] **Task 2.1 — Financial Setup Wizard**: Guided 4-step first-launch onboarding:
  1. Salary / Primary Income
  2. Core Mandatory Expense Estimates (selected from seeded taxonomy)
  3. Emergency Fund Target
  4. Primary Savings Goal Target

### Phase 3: Advanced Financial Extensions
- [ ] **Task 3.1 — Emergency Fund Calculator**: Target = $N \text{ months (default 3)} \times \text{Average(Fees + Needs spend)}$.
- [ ] **Task 3.2 — EMI-Aware Debt Commitments**: Dedicated loan/tenure tracking displaying debt-free milestone dates.
- [ ] **Task 3.3 — Payment Method Tagging**: Add optional payment mode tags (UPI, Cash, Card, Bank Transfer) to entries and report breakdowns.
- [ ] **Task 3.4 — Threshold Financial Insights & Push Alerts**: Rule-based budget warnings and overspend notifications.
- [ ] **Task 3.5 — Modular Screen Decomposition**: Break down large presentation files (`planning_screen.dart`, `budget_screen.dart`, `dashboard_screen.dart`) into smaller sub-widgets.
