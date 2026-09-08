# 1. Project Overview & System Vision

## 1. Introduction

**Budget Tracker** is a full-featured, offline-first personal and household financial planning platform. Unlike simple expense loggers, it implements a disciplined **7-layer financial waterfall** derived from real-world financial planning workflows.

The system ensures that every rupee earned is tracked across income, short-term adjustments, essential and discretionary spending, contingency/sinking funds (Protection), long-term goal accumulation (Saving), and monthly reserve roll-overs.

---

## 2. Core Architecture Philosophy

1. **Offline-First Resilience**:
   - The Flutter mobile client can run 100% offline using a local SQLite database powered by [Drift](file:///c:/Users/USER/Desktop/caldim%20projects/Budget_tracker_latest/lib/data/local/app_database.dart).
   - Any transaction, budget alteration, or goal update made offline is queued in the local `sync_queue` table and automatically synced with the NestJS backend upon reconnection.

2. **Dual-Engine Deterministic Math**:
   - Financial logic is encapsulated in two identical pure engines:
     - **Dart Engine**: [lib/domain/engine/](file:///c:/Users/USER/Desktop/caldim%20projects/Budget_tracker_latest/lib/domain/engine/) for instant client-side computation.
     - **TypeScript Engine**: [backend/src/engine/](file:///c:/Users/USER/Desktop/caldim%20projects/Budget_tracker_latest/backend/src/engine/) for server-side validation and multi-device rollups.
   - Both engines are verified against shared golden fixtures (`golden_fixtures.json`) extracted from an Excel workbook (~1,550 formulas).

3. **Strict Integer Currency Arithmetic (Paise)**:
   - Floating-point calculations (`0.1 + 0.2 = 0.30000000000000004`) lead to accumulated rounding errors.
   - All financial figures across frontend, backend, and database are stored as **integer paise** ($1\text{ INR} = 100\text{ paise}$).
   - The UI formats values into Indian Numbering System (`₹1,50,000.00`) using custom formatters.

---

## 3. Technology Stack

### Frontend (Mobile / Cross-Platform)
- **Framework**: Flutter 3.19+ (Dart 3.3+)
- **State Management**: [Riverpod 2.5+](https://riverpod.dev) (`flutter_riverpod`, `riverpod_annotation`, `riverpod_generator`)
- **Routing**: `go_router`
- **Local Persistence**: `drift` (SQLite ORM) with `sqlite3_flutter_libs` and `path_provider`
- **Networking**: `dio`, `connectivity_plus`
- **Security & Biometrics**: `flutter_secure_storage`, `local_auth`, `crypto` (SHA-256 password hashing)
- **Charts & Motion**: `fl_chart`, custom Tween animations

### Backend (API Server)
- **Framework**: [NestJS 10.x](https://nestjs.com) (TypeScript)
- **ORM / Database Access**: [Prisma ORM](file:///c:/Users/USER/Desktop/caldim%20projects/Budget_tracker_latest/backend/prisma/)
- **Database**: PostgreSQL 15+ (or Supabase Postgres)
- **Authentication**: JWT, Firebase Auth integration, and guest/offline mode support
- **Architecture**: Modular Domain-Driven Design mirroring frontend features

---

## 4. Feature Modules Directory

| Module Name | Frontend Path | Backend Path | Purpose |
|---|---|---|---|
| **Dashboard** | [lib/features/dashboard/](file:///c:/Users/USER/Desktop/caldim%20projects/Budget_tracker_latest/lib/features/dashboard/) | [backend/src/budgets/](file:///c:/Users/USER/Desktop/caldim%20projects/Budget_tracker_latest/backend/src/budgets/) | Displays month overview, waterfall bar, remaining balance, and month switcher. |
| **Transactions** | [lib/features/transactions/](file:///c:/Users/USER/Desktop/caldim%20projects/Budget_tracker_latest/lib/features/transactions/) | [backend/src/entries/](file:///c:/Users/USER/Desktop/caldim%20projects/Budget_tracker_latest/backend/src/entries/) | Fast entry creation, custom keypad, category selection, and transaction history. |
| **Budget Planning** | [lib/features/budget/](file:///c:/Users/USER/Desktop/caldim%20projects/Budget_tracker_latest/lib/features/budget/) | [backend/src/budgets/](file:///c:/Users/USER/Desktop/caldim%20projects/Budget_tracker_latest/backend/src/budgets/) | Category-level budget assignment, actual vs. planned tracking, overspend flags. |
| **Protection (Sinking Funds)** | [lib/features/protection/](file:///c:/Users/USER/Desktop/caldim%20projects/Budget_tracker_latest/lib/features/protection/) | [backend/src/protection/](file:///c:/Users/USER/Desktop/caldim%20projects/Budget_tracker_latest/backend/src/protection/) | Sinking funds for insurance, medical buffers, vacation funds, and depreciating assets. |
| **Saving (Goals)** | [lib/features/saving/](file:///c:/Users/USER/Desktop/caldim%20projects/Budget_tracker_latest/lib/features/saving/) | [backend/src/saving/](file:///c:/Users/USER/Desktop/caldim%20projects/Budget_tracker_latest/backend/src/saving/) | Target-based savings split across Retirement, Children, and Custom Goals. |
| **Forward Planning** | [lib/features/planning/](file:///c:/Users/USER/Desktop/caldim%20projects/Budget_tracker_latest/lib/features/planning/) | [backend/src/planning/](file:///c:/Users/USER/Desktop/caldim%20projects/Budget_tracker_latest/backend/src/planning/) | Multi-month forward forecasting, planned bills, and annual targets. |
| **Accounts** | [lib/features/accounts/](file:///c:/Users/USER/Desktop/caldim%20projects/Budget_tracker_latest/lib/features/accounts/) | [backend/src/accounts/](file:///c:/Users/USER/Desktop/caldim%20projects/Budget_tracker_latest/backend/src/accounts/) | Bank accounts, cash balances, and reconciliation. |
| **Credit Cards** | [lib/features/cards/](file:///c:/Users/USER/Desktop/caldim%20projects/Budget_tracker_latest/lib/features/cards/) | [backend/src/cards/](file:///c:/Users/USER/Desktop/caldim%20projects/Budget_tracker_latest/backend/src/cards/) | Tracking credit card statements, payments, and outstanding balances. |
| **Borrow & Lending** | [lib/features/borrow_lending/](file:///c:/Users/USER/Desktop/caldim%20projects/Budget_tracker_latest/lib/features/borrow_lending/) | [backend/src/entries/](file:///c:/Users/USER/Desktop/caldim%20projects/Budget_tracker_latest/backend/src/entries/) | Tracking informal loans, peer lending, receivables, and settlements. |
| **Reports & Analytics** | [lib/features/reports/](file:///c:/Users/USER/Desktop/caldim%20projects/Budget_tracker_latest/lib/features/reports/) | [backend/src/reports/](file:///c:/Users/USER/Desktop/caldim%20projects/Budget_tracker_latest/backend/src/reports/) | Monthly spending trends, category breakdown, cash flow distributions. |
| **Notifications** | [lib/features/notifications/](file:///c:/Users/USER/Desktop/caldim%20projects/Budget_tracker_latest/lib/features/notifications/) | N/A (Client Stream) | Reactive threshold alerts, overspend warnings, upcoming bill reminders. |
| **Auth & Security** | [lib/features/auth/](file:///c:/Users/USER/Desktop/caldim%20projects/Budget_tracker_latest/lib/features/auth/) | [backend/src/auth/](file:///c:/Users/USER/Desktop/caldim%20projects/Budget_tracker_latest/backend/src/auth/) | Login, register, guest mode, PIN/Biometric lock screen. |
| **Settings** | [lib/features/settings/](file:///c:/Users/USER/Desktop/caldim%20projects/Budget_tracker_latest/lib/features/settings/) | [backend/src/users/](file:///c:/Users/USER/Desktop/caldim%20projects/Budget_tracker_latest/backend/src/users/) | Currency format, dark/light theme, export CSV, data reset. |
