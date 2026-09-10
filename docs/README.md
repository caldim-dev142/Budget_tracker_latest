# Budget Tracker — Project Documentation

Welcome to the comprehensive technical and operational documentation for the **Budget Tracker (BudgetIQ)** platform.

This directory contains modular, in-depth documentation covering every layer of the application — from the reverse-engineered financial waterfall engine to the Flutter client, NestJS backend, offline-first database synchronization, and developer guidelines.

---

## 📚 Documentation Index

| Document | Description |
|---|---|
| [1. Project Overview](file:///c:/Users/USER/Desktop/caldim%20projects/Budget_tracker_latest/docs/PROJECT_OVERVIEW.md) | High-level system design, core purpose, tech stack, and module map. |
| [2. Financial Waterfall Engine](file:///c:/Users/USER/Desktop/caldim%20projects/Budget_tracker_latest/docs/FINANCIAL_WATERFALL_ENGINE.md) | The mathematical money-flow model, 7-layer waterfall, adjustment rules, and plan customizer. |
| [3. Frontend Architecture (Flutter)](file:///c:/Users/USER/Desktop/caldim%20projects/Budget_tracker_latest/docs/FRONTEND_ARCHITECTURE.md) | Clean architecture, Riverpod state, Drift SQLite DAOs, App Lock, Timezone & Category icons. |
| [4. Backend Architecture (NestJS)](file:///c:/Users/USER/Desktop/caldim%20projects/Budget_tracker_latest/docs/BACKEND_ARCHITECTURE.md) | NestJS modular architecture, Prisma ORM, Dual-engine parity, Multi-entity batch sync, and Households. |
| [5. Database Schema & Data Models](file:///c:/Users/USER/Desktop/caldim%20projects/Budget_tracker_latest/docs/DATABASE_SCHEMA.md) | Schema specification for all 18 tables (PostgreSQL/Supabase + Drift SQLite). |
| [6. Getting Started & Setup Guide](file:///c:/Users/USER/Desktop/caldim%20projects/Budget_tracker_latest/docs/GETTING_STARTED_GUIDE.md) | Prerequisites, environment configuration, local development commands, and utility scripts. |
| [7. Developer Rules & Invariants](file:///c:/Users/USER/Desktop/caldim%20projects/Budget_tracker_latest/docs/DEVELOPER_RULES_AND_ROADMAP.md) | Non-negotiable coding rules, paise arithmetic, business invariants, and handover roadmap. |

---

## 💡 System Architecture

```mermaid
graph TD
    subgraph Client ["Flutter Mobile Client (Offline-First)"]
        UI["Flutter Presentation Layer (15 Feature Modules)"]
        Riverpod["Riverpod Providers & Controllers"]
        EngineDart["Dart Financial Engine (Integer Paise)"]
        Drift["Drift SQLite Local Database"]
        SyncClient["Sync Service (Multi-Entity Batch Sync)"]
        Security["App Lock (Biometrics / PIN Gate)"]
    end

    subgraph Backend ["NestJS Backend Server"]
        SyncController["Sync Module (POST /sync/batch)"]
        EngineTS["TypeScript Engine (Fixture Verified)"]
        Prisma["Prisma ORM (18 Models)"]
        NestModules["Feature Modules (Auth, Budgets, Entries, Households, etc.)"]
    end

    subgraph Database ["Cloud Database"]
        Postgres[("PostgreSQL / Supabase")]
    end

    UI --> Riverpod
    UI --> Security
    Riverpod --> EngineDart
    Riverpod --> Drift
    Drift --> SyncClient
    SyncClient <-->|REST Batch Sync (9 Entities)| SyncController
    SyncController --> NestModules
    NestModules --> EngineTS
    NestModules --> Prisma
    Prisma --> Postgres
```

---

## 🔒 Critical Project Rules

1. **No Hardcoding of DB Data**: All accounts, categories, entries, budgets, and snapshots must come from Drift / PostgreSQL.
2. **Paise Integer Arithmetic**: Floating-point currency calculations are strictly prohibited. 1 INR = 100 paise.
3. **Waterfall Formula Invariant**:
   $$\text{Opening} + \text{Last Month Reserves} + \text{Income} + \text{Adjustments} - \text{Spending} - \text{Protection} - \text{Saving} - \text{Reserves} = \text{Remaining}$$
4. **Adjustment Sign Rules**: 4 categories added (`Credit Card Borrow/Payment`, `Borrow/Return`, `Temporary In/Out`, `Others-Inflow`) and 2 categories subtracted (`Lending/Return`, `Others-Outflow`).
