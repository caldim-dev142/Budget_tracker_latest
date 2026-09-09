# 4. Backend Architecture (NestJS)

## 1. Overview & Stack

The backend is built with **NestJS 10.x** (TypeScript) and **Prisma ORM**, connecting to a **PostgreSQL** database (or Supabase Postgres instance).

It provides REST endpoints for multi-device sync, household data sharing, forward planning, and server-side verification of month-end closures.

```
backend/
├── prisma/
│   ├── schema.prisma          # Database schema definition
│   └── migrations/            # SQL migration history
├── src/
│   ├── main.ts                # Application entrypoint, CORS, global validation pipe
│   ├── app.module.ts          # Root NestJS module importing all feature modules
│   ├── database/              # PrismaService database provider
│   ├── auth/                  # Authentication, JWT strategy, Firebase verification
│   ├── users/                 # User profiles and preferences
│   ├── households/            # Multi-user household grouping and permissions
│   ├── accounts/              # Bank & liquid account management
│   ├── cards/                 # Credit card operations
│   ├── categories/            # System & custom category taxonomy
│   ├── entries/               # Financial transactions & ledger mutations
│   ├── budgets/               # Category-level budget allocations
│   ├── protection/            # Sinking funds & protection balance calculations
│   ├── saving/                # Long-term saving goals & contributions
│   ├── planning/              # Forward month budgets, planned bills, targets
│   ├── months/                # Month snapshots and month-close execution
│   ├── reports/               # Aggregate spending analytics and distribution
│   ├── sync/                  # Batch sync controller and conflict resolver
│   └── engine/                # TypeScript financial engine (parity with Dart engine)
```

---

## 2. Dual-Engine Parity & Golden Fixtures

To ensure calculations are 100% identical between the client (offline) and the server (cloud):

- The TypeScript financial engine in [backend/src/engine/engine.ts](file:///c:/Users/USER/Desktop/caldim%20projects/Budget_tracker_latest/backend/src/engine/) implements the exact same 7-layer waterfall, integer paise arithmetic, and adjustment sign logic as the Flutter Dart engine.
- Both engines are tested against `golden_fixtures.json`, which contains dozens of test cases extracted from the reference Excel workbook.

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

## 3. Batch Synchronization Engine (`/sync/batch`)

The synchronization controller in [backend/src/sync/](file:///c:/Users/USER/Desktop/caldim%20projects/Budget_tracker_latest/backend/src/sync/) handles high-efficiency bidirectional syncing.

### Sync Flow:
1. **Client Push**:
   - The Flutter client collects pending mutations from its local `sync_queue` table.
   - It sends a `POST /sync/batch` request with an array of operations:
     ```json
     {
       "lastSyncedAt": "2026-09-01T10:00:00.000Z",
       "operations": [
         {
           "id": "queue-uuid-1",
           "op": "CREATE",
           "entity": "entries",
           "entityId": "entry-uuid-101",
           "payload": {
             "categoryId": "cat-groceries",
             "amountPaise": 150000,
             "entryDate": "2026-09-07T12:00:00.000Z",
             "kind": "expense",
             "note": "Supermarket"
           }
         }
       ]
     }
     ```

2. **Server Processing & Conflict Resolution**:
   - The server applies mutations in an atomic database transaction.
   - Uses **Last-Write-Wins (LWW)** with entity version tracking (`version` column).
   - Soft deletes (`deleted_at` timestamp) ensure deletions propagate cleanly across multiple household devices.

3. **Server Response (Pull)**:
   - The server acknowledges processed operation IDs and returns any entities updated on other devices since `lastSyncedAt`.

---

## 4. Household Multi-Tenancy & Management API

Every financial entity (Account, Category, Entry, Budget, SinkingFund, SavingGoal, MonthSnapshot, PlannedBill, Receivable) is strictly partitioned by `household_id`.

### Household Endpoints (`/households`):
- `POST /households`: Create a new household (assigning the creator as `owner_id`) and seed initial categories.
- `POST /households/join`: Join an existing household using a shared `householdId`.
- `GET /households/me`: Fetch the current user's active household metadata and all joined members.
- `PATCH /households/me`: Update the household display name (Owner only).
- `DELETE /households/me`: Delete the household and disassociate all members (Owner only).
- `DELETE /households/members/:memberId`: Remove an individual member from the household (Owner only).

### Security & Tenant Isolation:
- **JWT / Auth Guard**: Every request extracts the authenticated user's `userId` and active `householdId` from their validated token.
- **Tenant Isolation**: Prisma queries enforce `where: { householdId }` on every read and write operation, preventing cross-household data leakage.
- **Dual Authentication Modes**:
  - **Email / Password**: BCrypt / Salted hash authentication with standard JWT issuing.
  - **Google Sign-In**: Firebase Admin SDK token verification with `serverClientId` validation for Android / iOS / Web clients.

