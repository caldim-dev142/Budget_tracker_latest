# 💰 BudgetIQ — Household Financial Planning Platform

> A full-stack, **offline-first** household budget tracker built with **Flutter** + **NestJS**, featuring a layered financial waterfall engine, real-time sync, and multi-member household support.

---

## ✨ Features

### 📱 App (Flutter)
| Feature | Description |
|---|---|
| **Dashboard** | Net worth summary, monthly cashflow, budget bars, quick entry FAB |
| **Transactions** | Day-grouped list with search, filter by kind, swipe-to-delete |
| **Budget** | Monthly budget allocations per category with progress bars |
| **Reports** | Trends, Breakdown, Cashflow Distribution (user-driven plan sliders) |
| **Planning** | Recurring bills, sinking funds, saving goals |
| **Accounts** | Multi-account tracking (bank, cash, wallet) |
| **Cards** | Credit/debit card tracking with statement cycles |
| **Saving** | Saving goals with contribution tracking |
| **Protection** | Insurance & protection plan management |
| **Borrow & Lend** | Loan tracking with due dates |
| **Household** | Create / Join household, member management, household ID sharing |
| **Settings** | Theme (light/dark/system), Timezone, Categories, Server URL, Biometric Lock, CSV Export |
| **Notifications** | Budget alerts and reminders |
| **Onboarding** | First-launch setup wizard |

### ⚙️ Backend (NestJS)
| Module | Description |
|---|---|
| **Auth** | Firebase + email/password authentication, JWT tokens |
| **Households** | Create/join/leave household, member roles |
| **Users** | User profiles, onboarding state |
| **Entries** | Income/expense/saving/protection transaction CRUD |
| **Categories** | System + custom category taxonomy per household |
| **Budgets** | Monthly budget targets per category |
| **Accounts** | Balance tracking across accounts |
| **Cards** | Card statement cycles and transactions |
| **Planning** | Recurring bills, sinking funds |
| **Saving** | Goal tracking and contributions |
| **Protection** | Insurance policy management |
| **Reports** | Aggregated cashflow & trend reports |
| **Months** | Month snapshot management |
| **Engine** | Financial waterfall calculation engine |
| **Sync** | Offline-first bidirectional sync |

---

## 🏗️ Architecture

```
┌──────────────────────────────────────────────────────┐
│                 Flutter App (Android/iOS)             │
│   Riverpod (State) · Drift SQLite (Offline DB)        │
│   GoRouter (Navigation) · Material 3 (UI)             │
└─────────────────┬────────────────────────────────────┘
                  │ HTTP (Dio) — Local Network / Internet
┌─────────────────▼────────────────────────────────────┐
│              NestJS Backend (REST API)                │
│   Prisma ORM · PostgreSQL · Firebase Admin Auth       │
│   Financial Waterfall Engine                          │
└──────────────────────────────────────────────────────┘
```

**Offline-First:** All data is written to local SQLite (Drift) first. A background sync service pushes pending changes to the NestJS backend and pulls remote changes when connectivity is available.

---

## 🛠️ Tech Stack

### Frontend
| Layer | Technology |
|---|---|
| Framework | Flutter 3.19+ / Dart 3.3+ |
| State Management | Riverpod 2.x |
| Local Database | Drift (SQLite) |
| Navigation | GoRouter |
| Networking | Dio |
| Auth | Firebase Auth + Google Sign-In |
| Storage | Flutter Secure Storage |
| Charts | fl_chart |
| Formatting | intl |
| Biometrics | local_auth |

### Backend
| Layer | Technology |
|---|---|
| Framework | NestJS |
| ORM | Prisma |
| Database | PostgreSQL |
| Auth | Firebase Admin SDK |
| Runtime | Node.js |

---

## ⚡ Quick Start

### 1. Prerequisites
- Flutter SDK ≥ 3.19
- Node.js ≥ 18
- PostgreSQL running locally
- Firebase project configured

### 2. Backend
```bash
cd backend
npm install

# Set up your .env (see backend/.env.example)
# DATABASE_URL=postgresql://user:pass@localhost:5432/budgetiq

npx prisma db push        # Apply schema to DB
npm run start:dev         # Start on http://localhost:3001
```

### 3. Flutter App
```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

### 4. Connect App to Backend
- Open app → **Settings → Server Connection → Backend Server URL**
- Enter your machine's local IP: `http://192.168.x.x:3001`
- Both phone and PC must be on the **same Wi-Fi network**

---

## 📁 Project Structure

```
budget_tracker/
├── lib/
│   ├── app.dart                    # App root (MaterialApp.router)
│   ├── main.dart                   # Entry point + DB seed
│   ├── core/
│   │   ├── constants/              # Category seed data
│   │   ├── router/                 # GoRouter config
│   │   ├── security/               # Biometric lock, password hasher
│   │   ├── services/               # AppInitService, SyncService
│   │   ├── theme/                  # Material 3 theme (teal seed)
│   │   ├── utils/                  # Money, month, category icons, timezone
│   │   └── widgets/                # NavShell, global FAB, shared widgets
│   ├── data/
│   │   ├── local/                  # Drift DB, DAOs, tables
│   │   └── repositories/           # Repository implementations
│   ├── domain/
│   │   ├── entities/               # Entry, Category, etc.
│   │   ├── engine/                 # Financial waterfall engine
│   │   └── usecases/               # Add/edit/delete entry usecases
│   ├── features/                   # One folder per screen/feature
│   └── shared/widgets/             # Reusable UI components
├── backend/
│   ├── src/
│   │   ├── auth/                   # Firebase auth guard
│   │   ├── engine/                 # Waterfall engine (server-side)
│   │   ├── sync/                   # Offline sync endpoint
│   │   └── [feature modules]/      # entries, budgets, accounts, etc.
│   └── prisma/schema.prisma        # DB schema
└── assets/icon/                    # App icon assets
```

---

## 🏠 Household Flow

```
New User
  └─► Login (Firebase / Email)
        └─► Settings → Manage Household
              ├─► Create Household → generates unique household ID
              │     └─► Share ID with family members
              └─► Join Household → enter household ID
                    └─► Access shared categories, budgets & entries
```

---

## 💡 Key Design Decisions

| Decision | Rationale |
|---|---|
| **Offline-first** | Works without internet; syncs when available |
| **Local SQLite** | Zero-latency reads, no spinner for every UI action |
| **Household-scoped data** | All records tagged with `householdId` for multi-user isolation |
| **Financial Waterfall Engine** | Deterministic income → spending → saving → protection layering |
| **Timezone-aware dates** | User-selectable timezone; all dates converted from UTC on display |
| **Semantic category icons** | 60+ name-matched icons, kind-tinted colours, consistent across app |

---

## 📦 Building the APK

```bash
flutter clean
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

Install over existing version — Android treats it as an update, preserving all local data.

---

## 📖 Documentation

Full documentation is in the [`docs/`](./docs/) directory:

| Doc | Description |
|---|---|
| [PROJECT_OVERVIEW.md](./docs/PROJECT_OVERVIEW.md) | Architecture & design goals |
| [FINANCIAL_WATERFALL_ENGINE.md](./docs/FINANCIAL_WATERFALL_ENGINE.md) | Calculation engine deep-dive |
| [FRONTEND_ARCHITECTURE.md](./docs/FRONTEND_ARCHITECTURE.md) | Flutter app structure |
| [BACKEND_ARCHITECTURE.md](./docs/BACKEND_ARCHITECTURE.md) | NestJS API structure |
| [DATABASE_SCHEMA.md](./docs/DATABASE_SCHEMA.md) | Prisma schema & data models |
| [GETTING_STARTED_GUIDE.md](./docs/GETTING_STARTED_GUIDE.md) | Full setup guide |
| [DEVELOPER_RULES_AND_ROADMAP.md](./docs/DEVELOPER_RULES_AND_ROADMAP.md) | Dev rules & roadmap |

---

## 🔐 Environment Variables

Create `backend/.env`:
```env
DATABASE_URL=postgresql://user:password@localhost:5432/budgetiq
FIREBASE_PROJECT_ID=your-firebase-project-id
PORT=3001
```

---

*Built with Flutter · NestJS · PostgreSQL · Firebase*
