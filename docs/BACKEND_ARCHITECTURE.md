# 4. Backend Architecture (NestJS)

## 1. Overview & Directory Layout

The backend is built with **NestJS 10.x** (TypeScript) and **Prisma ORM**, connecting to a **PostgreSQL** database (or Supabase Postgres instance).

It provides REST endpoints for multi-device sync, multi-user household partitioning, forward planning, and server-side verification of financial waterfall invariants.

```
backend/
├── prisma/
│   ├── schema.prisma          # Database schema definition (18 models)
│   └── migrations/            # SQL migration history
├── scripts/
│   ├── cleanup_default_accounts.ts # Utility script to prune legacy/duplicate accounts
│   └── clear_all_data.ts          # Safe reset script for clean development seeding
├── src/
│   ├── main.ts                # Application bootstrap, CORS, port 3001, global pipes
│   ├── app.module.ts          # Root NestJS module importing all domain modules
│   ├── database/              # PrismaService database provider
│   ├── auth/                  # Firebase Admin verification + JWT local auth
│   ├── users/                 # User profiles and preferences
│   ├── households/            # Multi-user household grouping & role management
│   ├── accounts/              # Bank & liquid account management
│   ├── cards/                 # Credit card operations & transactions
│   ├── categories/            # System & custom category taxonomy
│   ├── entries/               # Financial transactions & ledger mutations
│   ├── budgets/               # Category-level budget allocations
│   ├── protection/            # Sinking funds & protection balance calculations
│   ├── saving/                # Long-term saving goals & contributions
│   ├── planning/              # Forward month budgets, planned bills, targets
│   ├── months/                # Month snapshots and month-close execution
│   ├── reports/               # Aggregate spending analytics and distribution
│   ├── sync/                  # Multi-entity batch sync controller & service
│   └── engine/                # TypeScript financial waterfall engine
```

---

## 2. Dual-Engine Parity & Golden Fixtures

To ensure calculations are 100% identical between client (offline Dart) and server (TypeScript):

- The TypeScript financial engine in [backend/src/engine/engine.ts](file:///c:/Users/USER/Desktop/caldim%20projects/Budget_tracker_latest/backend/src/engine/) implements the exact same 7-layer waterfall, integer paise arithmetic, and adjustment sign logic as the Flutter Dart engine.
- Both engines are tested against `golden_fixtures.json`, extracted from the reference financial model (~1,550 Excel formulas).

```typescript
// TypeScript Engine Waterfall Invariant
export function calculateWaterfall(actuals: MonthActualsInput): WaterfallResult {
  const totalInflow = actuals.openingBalancePaise +
                      actuals.lastMonthReservesPaise +
                      actuals.incomePaise +
                      actuals.adjustmentsPaise;

  const totalOutflow = actuals.spendingPaise +
                       actuals.protectionPaise +
                       actuals.savingPaise +
                       actuals.reservesPaise;

  const remainingPaise = totalInflow - totalOutflow;

  return {
    totalInflowPaise: totalInflow,
    totalOutflowPaise: totalOutflow,
    remainingPaise,
  };
}
```

---

## 3. Multi-Entity Batch Sync Engine (`POST /sync/batch`)

The sync controller in [backend/src/sync/](file:///c:/Users/USER/Desktop/caldim%20projects/Budget_tracker_latest/backend/src/sync/) handles full-state bidirectional syncing across **9 core entities**:

### Synchronized Entities:
1. **`categories`**: Household-specific categories and system category mapping.
2. **`accounts`**: Cash, savings, and investment accounts.
3. **`creditCards` & `cardTransactions`**: Credit cards and card transaction entries.
4. **`plannedBills`**: Scheduled payables and forward commitments.
5. **`receivables`**: Peer lending and informal loans.
6. **`savingGoals` & `goalContributions`**: Wealth building targets.
7. **`sinkingFunds` & `fundMovements`**: Protection reserve funds.
8. **`budgets`**: Monthly category limits.
9. **`entries`**: Core ledger records.

### Sync Pipeline:
- **Upsert Execution**: Incoming records are upserted atomically within database transactions.
- **Foreign Key Consistency**: Category IDs and Account IDs are verified and mapped per household to prevent orphaned records.
- **Last-Write-Wins (LWW)**: `version` and `updated_at` columns prevent older client state from overwriting newer server records.
- **Soft Deletes**: Deletions are captured via `deleted_at` timestamps to synchronize removals cleanly across all household devices.

---

## 4. Household Multi-Tenancy System (`/households`)

Every financial entity in the database is partitioned by `household_id`.

### Endpoints:
- `POST /households`: Create a new household (assigning creator as `owner_id`) and seed default categories.
- `POST /households/join`: Join an existing household via a 36-character UUID household ID.
- `GET /households/me`: Retrieve active household details, owner info, and joined member list.
- `PATCH /households/me`: Update household display name (Owner only).
- `DELETE /households/me`: Delete the household and disassociate members (Owner only).
- `DELETE /households/members/:memberId`: Remove an individual member from the household (Owner only).

### Multi-Tenant Isolation:
- NestJS guards extract the authenticated user's `householdId` from the JWT / Firebase token.
- Prisma queries enforce `where: { householdId }` across all CRUD handlers.

---

## 5. Authentication & Security

- **Firebase Admin SDK**:
  - Validates Google Sign-In ID tokens from Android, iOS, and Web.
  - Verifies token claims against the configured `FIREBASE_PROJECT_ID`.
- **JWT Authentication**:
  - Issues signed JWT access tokens with user ID, email, and active household ID.
- **Offline / Guest Mode**:
  - Supports local guest users who can later upgrade and bind their local database to a cloud household account.

---

## 6. Database Utility Scripts

Located in `backend/scripts/`:

```bash
# Prune legacy or redundant accounts
npx ts-node scripts/cleanup_default_accounts.ts

# Wipe test data for fresh development seeding
npx ts-node scripts/clear_all_data.ts
```
