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

## 2. Implementation & Handover Roadmap

### Phase 1: Critical Bug Fixes (P0)
- [x] **Task 1.0 — 1:1 Integer Paise & Offline Sync Alignment**: Aligned backend Prisma schema, sync DTOs, and Drift SQLite models to standard 32/64-bit integer paise.
- [ ] **Task 1.1 — Real Data in Reports**: Replace `_initMockData()` in `report_detail_screen.dart` with live Drift DAO / Riverpod queries matching the budget & transaction screens.
- [ ] **Task 1.2 — Engine Adjustment Sign Fix**: Update `RollupEngine.netAdjustments()` in `rollups.dart` to respect the `isDeduction` category flag (matching `dashboard_providers.dart` and `account_dao.dart`).
- [ ] **Task 1.3 — Plan-vs-Actual Reconciliation Insight**: Compute and surface `reconciliationDifference = remaining − closingBalance` at month-close as a diagnostic insight.
- [ ] **Task 1.4 — Snapshot Household ID**: Pass explicit `householdId` into `CloseMonthUseCase.execute()` rather than using the `yearMonth` placeholder.
- [ ] **Task 1.5 — Typed AuthMode Enum**: Replace string sentinel checks (`'mock-token'`, `'offline-token'`) with a strongly-typed `AuthMode` enum.
- [ ] **Task 1.6 — Foreground Connectivity Listener**: Re-enable network change detection for auto-sync upon reconnection.

### Phase 2: First-Time User Experience (P0)
- [ ] **Task 2.1 — Financial Setup Wizard**: Guided 4-step first-launch onboarding:
  1. Salary / Primary Income
  2. Core Mandatory Expense Estimates (selected from seeded taxonomy)
  3. Emergency Fund Target
  4. Primary Savings Goal Target

### Phase 3: Core Feature Extensions (P1 / P2)
- [ ] **Task 3.1 — Emergency Fund Calculator**: Target = $N \text{ months (default 3)} \times \text{Average(Fees + Needs spend)}$.
- [ ] **Task 3.2 — EMI-Aware Debt Commitments**: Dedicated loan/tenure tracking displaying debt-free milestone dates.
- [ ] **Task 3.3 — Payment Method Tagging**: Add optional payment mode tags (UPI, Cash, Card, Bank Transfer) to entries and report breakdowns.
- [ ] **Task 3.4 — Threshold Financial Insights**: Rule-based budget warnings and overspend notifications.
- [x] **Task 3.5 — Multi-User Household Invites**: Multi-device household sharing via backend `/households` endpoints and Flutter Settings screen.
- [ ] **Task 3.6 — Split Large Screen Files**: Modularize `planning_screen.dart` (1,429 lines), `budget_screen.dart` (1,286 lines), and `dashboard_screen.dart` (1,033 lines) into sub-widgets.
