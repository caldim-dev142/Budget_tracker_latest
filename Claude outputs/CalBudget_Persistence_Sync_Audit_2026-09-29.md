# CalBudget — Persistence & Sync Audit (post-VPS deployment)

**Date:** 2026-09-29 · **Type:** Audit only — no code, schema, config or data changed
**Method:** Static trace of the current repository (Flutter UI → Drift → sync → NestJS → Prisma → PostgreSQL) plus historical evidence from the repo's DB backup snapshot. No production DB or VPS log access was available to Claude; read-only confirmation steps are listed in §7.

---

## 1. Persistent entities discovered

Drift (local, 16 tables): accounts, categories, budgets, entries, sinking_funds, fund_movements, saving_goals, goal_contributions, credit_cards, card_transactions, receivables, planned_bills, reserve_lines, month_snapshots, annual_targets, users, (+ sync_queue, local-only).

Prisma/Postgres (20 models): households, household_invites, users, refresh_tokens, categories, accounts, entries, budgets, sinking_funds, fund_movements, saving_goals, goal_contributions, credit_cards, card_transactions, receivables, planned_bills, reserve_lines, month_snapshots, annual_targets, sync_tombstones (+ an unused server `sync_queue` model).

**Module → table map (where to look in Supabase):**

| App module | Postgres table(s) |
|---|---|
| Transactions | entries |
| Accounts | accounts |
| Credit Cards | credit_cards, card_transactions |
| Budgets | budgets (+ categories) |
| Categories / Subcategories | categories (subcategory = `name`, category = `group_code`) |
| Borrow & Lending | receivables (money lent), planned_bills (borrowed / bills to pay), plus linked rows in entries |
| Planning | annual_targets, reserve_lines, planned_bills, receivables |
| Saving | saving_goals, goal_contributions |
| Protection | sinking_funds, fund_movements (there is no table named "protection") |
| Months | month_snapshots (status only — see §2) |
| Notifications | **none — not persisted by design**; computed live from entries, snapshots and cards |
| User / Household | users, households, household_invites, refresh_tokens |

---

## 2. Persistence status per entity

Push paths in `lib/core/services/sync_service.dart → syncAllQueue()`:
- **Path A** — queued entry ops → `POST /entries/batch`, one entry per request.
- **Path B** — full-state snapshot of all 14 entity types → **one** `POST /sync/batch` → `SyncService.syncBatch()`, written in **one Postgres transaction**.

| Entity | Flutter save | Drift | Push path | Backend | Prisma/PG | Pull | Status |
|---|---|---|---|---|---|---|---|
| Users / Households / Invites | ✅ | ✅ | auth & household endpoints | ✅ | ✅ | ✅ | ✅ Fully persisted |
| Entries | ✅ | ✅ | A **and** B | ✅ | ⚠️ | ✅ | ⚠️ Partial — entries referencing an account/card/parent not yet on the server fail on A and depend on B |
| Categories (custom) | ✅ | ✅ | B only | ✅ | ⚠️ | ✅ | ⚠️ Depends on B (seed categories are created server-side, so they're present) |
| Accounts | ✅ | ✅ | B only | ✅ | ❌/⚠️ | ✅ | ⚠️ Depends on B + name-merge defect (§4 R3) |
| Credit cards / card transactions | ✅ | ✅ | B only | ✅ | ⚠️ | ✅ | ⚠️ Depends on B |
| Planned bills / Receivables | ✅ | ✅ | B only | ✅ | ⚠️ | ✅ | ⚠️ Depends on B |
| Saving goals / contributions | ✅ | ✅ | B only | ✅ | ⚠️ | ✅ | ⚠️ Depends on B |
| Sinking funds / movements (Protection) | ✅ | ✅ | B only | ✅ | ⚠️ | ✅ | ⚠️ Depends on B |
| Budgets | ✅ | ✅ | B only | ✅ | ⚠️ | ✅ | ⚠️ Depends on B |
| Reserve lines / Annual targets (Planning) | ✅ | ✅ | B only | ✅ | ⚠️ | ✅ | ⚠️ Depends on B |
| Month snapshots | ✅ | ✅ | status only via `/months/close|reopen` + queue | ✅ | ✅ (closed months only) | ✅ (`monthStatuses`) | ✅ By design — figures are recomputed locally |
| Notifications | n/a | n/a | n/a | n/a | n/a | n/a | ✅ Not persisted by design |
| Deletions (tombstones) | ✅ | queue | inside B | ✅ | ✅ | ✅ | ⚠️ Depends on B |

Verified clean: every screen writes to Drift with the active `householdId` and calls `triggerSync()`; every required DTO field maps to a non-nullable Drift column; the client never sends a field the DTO rejects (`forbidNonWhitelisted`); `pullData()` returns all 14 entity types and the client reads every key. **So the losses are not in UI saving, local storage, DTO validation, or pull — they are in Path B on the server.**

---

## 3. Exact symptom explained

What you see — users and entries present, everything else missing — matches **Path B (`/sync/batch`) failing while Path A (`/entries/batch`) keeps working**. Users/households go through auth endpoints; entries have their own endpoint; every other module exists only inside the single `/sync/batch` request.

**Historical evidence** (`backend/prisma/backups/backup_before_clear_2026-09-21T09-05-00-500Z.json`, taken just *before* the FK migration that day): accounts 1, credit_cards 1, planned_bills 1, saving_goals 1, goal_contributions 1, sinking_funds 1, fund_movements 1, entries 11. Non-entry data **was** reaching Postgres before 21 Sept. The previous persistence audit (17 Sept) also found all entities syncing.

---

## 4. Root causes (ordered by severity)

### R1 — P0 · `/sync/batch` is all-or-nothing across 13 entity types
- **Where:** `backend/src/sync/sync.service.ts → syncBatch()`, Phase 2 `runner(async (tx) => { … })` (single `$transaction`, 45 s).
- **Layer:** Backend / DB transaction.
- **Effect:** One failing row anywhere (any FK violation, timeout or error) rolls back **every** account, card, bill, receivable, goal, fund, budget, reserve line and target in the batch. Nothing is partially saved. Because the client re-sends the same full snapshot, the same row fails again on every sync — a permanent block.
- Also: `.catch(() => {})` (missing parent card create) and `try/catch` around category upserts in `entries.service.ts → applyBatch()` cannot recover in Postgres — a failed statement aborts the whole transaction.

### R2 — P0 · Entry validation lets through references the new foreign keys reject
- **Where:** `backend/src/entries/entries.service.ts → validateBatch()` — `accountId` / `cardId` checks only reject a record owned by *another* household (`if (accExists && …)`); a **missing** account/card/parent passes validation. `applyBatch()` then runs `tx.entry.create()`.
- **Trigger:** migration `20260921123000_indexes_and_foreign_keys` added `entries_account_id_fkey`, `entries_card_id_fkey`, `entries_parent_id_fkey` (ON DELETE RESTRICT) on 21 Sept — after the last clean audit.
- **Layer:** Backend service + DB schema interaction.
- **Effect:** Any entry pointing at an account/card/parent ID that does not exist server-side throws P2003 inside the transaction → R1 rolls back everything.

### R3 — P0 · Account name-merge means the device's account ID may never exist on the server
- **Where:** `sync.service.ts → syncBatch()` step "1. Accounts": `findFirst({ householdId, name: { equals, mode: 'insensitive' } })` → `targetId = existing.id`; the upsert writes to the **server's** ID, not the device's.
- **Where it's triggered:** the device keeps its own account ID, and its entries (including automatic `ob-<accountId>` opening-balance entries from `lib/data/local/daos/account_dao.dart → ensureOpeningBalanceEntries()`, run before every sync) reference the device ID.
- **Likely when:** after reinstall / clearing data / DB reset, or any time two accounts share a name (e.g. "Cash", "HDFC"). The pull then also adds the server's copy locally → duplicate accounts on the device.
- **Effect:** Those entries violate `entries_account_id_fkey` on every sync → R2 → R1 → nothing but users and account-less entries ever reaches Postgres.

### R4 — P1 · Slow server validation over cross-region DB; short client timeouts
- **Where:** `sync.service.ts → syncBatch()` Phase 1: sequential `findUnique`/`findFirst` per row for accounts (2), card transactions (2), bills/receivables (1–2), goals, funds, contributions, movements, budgets (2–3), reserve lines, annual targets. Only categories were batched in the earlier N+1 fix. Phase 2 re-upserts **every** non-entry row on every sync (no change detection). Supabase is in AWS Tokyo.
- **Client:** automatic syncs use `syncAllQueue()` default `timeout: 30s` (`sync_service.dart`); Force Sync uses 60 s. The server transaction limit is 45 s.
- **Effect:** As data grows, `/sync/batch` times out; if Phase 2 exceeds 45 s the whole transaction rolls back (R1).

### R5 — P1 · `/entries/batch` has the same FK blind spot
- **Where:** `entries.controller.ts → upsertBatch` → same `validateBatch/applyBatch`.
- **Effect:** An entry for a new account or card fails (HTTP 500) until the account reaches the server via Path B; after `SyncQueueDao.maxAttempts = 10` it is skipped from the queue and relies entirely on Path B.

### R6 — P2 · Request size limit on full-state push
- **Where:** Fastify default `bodyLimit` of 1 MiB (never set in `main.ts`) + Nginx default `client_max_body_size 1m`. Every `/sync/batch` includes **all** entries.
- **Effect:** For heavier users, `/sync/batch` is rejected (413) before reaching the service. Latent today.

### R7 — P2 · Rate limit shared by all users if `TRUST_PROXY` is not `true` on the VPS
- **Where:** `main.ts` (`trustProxy`) + `ThrottlerModule` 100 req/min.
- **Effect:** 429 responses on `/sync/batch` once several users sync. Not confirmed — VPS `.env` not inspected.

### R8 — P3 · Category `archivedAt` not in the push payload
- **Where:** client `categoriesPayload` omits `archivedAt`; server upsert ignores it. Archive still propagates via the `category` deletion op, so there's no data loss — just inconsistent.

---

## 5. Where each problem lives

| # | Layer | File → function |
|---|---|---|
| R1 | Backend / DB transaction | `backend/src/sync/sync.service.ts → syncBatch()` Phase 2; `entries.service.ts → applyBatch()` |
| R2 | Backend service + schema | `backend/src/entries/entries.service.ts → validateBatch()`, `applyBatch()`; `prisma/migrations/20260921123000_indexes_and_foreign_keys` |
| R3 | Backend sync + Flutter DAO | `sync.service.ts → syncBatch()` accounts step; `lib/data/local/daos/account_dao.dart → ensureOpeningBalanceEntries()` |
| R4 | Backend performance + client timeout | `sync.service.ts → syncBatch()` Phase 1; `lib/core/services/sync_service.dart → syncAllQueue()` |
| R5 | Backend service | `entries.controller.ts → upsertBatch`; `sync_queue_dao.dart → maxAttempts` |
| R6 | Infra | `backend/src/main.ts`; Nginx site config |
| R7 | Infra | VPS `.env` `TRUST_PROXY`; `app.module.ts` throttler |
| R8 | Flutter + backend | `sync_service.dart` categories payload; `sync.service.ts` category upsert |

---

## 6. Proposed fix plan (not implemented — awaiting approval)

1. **R2 + R5** — In `validateBatch()`, treat a missing `accountId`/`cardId`/`parentId` (not on server and not in the same batch) as a per-entry validation failure (counted in `failed`, left queued), never as a write that throws inside the transaction. No change to amounts or financial logic.
2. **R3** — Stop silently merging accounts by name, or keep the merge but return and apply an ID remap (device ID → server ID) to the entries in the same batch, and send the mapping to the client so it can rewrite its local references. Needs a design decision.
3. **R1** — Make `/sync/batch` report per-entity results instead of all-or-nothing (a transaction or savepoint per entity group, parents before children); return which records were rejected and why. Remove swallowed errors inside the transaction.
4. **R4** — Batch Phase 1 lookups with `findMany({ id: { in } })` (same pattern as the categories fix) and skip unchanged rows in Phase 2.
5. **Visibility** — Log the Prisma error code and entity/ID for any `/sync/batch` failure; show the server's reason in the app's backup status banner.
6. **R6** — Set matching explicit body limits in Fastify and Nginx, or move to incremental (changed-only) pushes.
7. **R7** — Confirm `TRUST_PROXY=true` on the VPS.
8. **R8** — Include `archivedAt` in the category push/upsert.

Each fix needs regression tests: batch with an entry → missing account; name-merged account; one bad row not blocking other entity types; timing test with realistic row counts.

**Out of scope, untouched:** `engine.ts`, `waterfall.dart`, the waterfall formula, balance calculations, paise math, month close/reopen/rollover.

---

## 7. Read-only confirmation steps (to pin the exact failing row in production)

1. **Phone:** Settings → Force Sync → note the exact error text in the backup status.
2. **VPS logs** (the backend logs every request with status and duration):
   `pm2 logs --lines 2000 --nostream | grep -E "POST /(sync|entries)/batch"`
   `pm2 logs --lines 2000 --nostream | grep -iE "P2003|foreign key|entries_account_id_fkey|entries_card_id_fkey|timed out|413|429"`
   - 500 + P2003 → R2/R3 confirmed. 413 → R6. 429 → R7. Durations near 30–45 s → R4.
3. **Supabase SQL editor (SELECT only):**
   ```sql
   select 'accounts' t, count(*) from accounts where household_id = '<HH>'
   union all select 'credit_cards', count(*) from credit_cards where household_id = '<HH>'
   union all select 'planned_bills', count(*) from planned_bills where household_id = '<HH>'
   union all select 'receivables', count(*) from receivables where household_id = '<HH>'
   union all select 'saving_goals', count(*) from saving_goals where household_id = '<HH>'
   union all select 'sinking_funds', count(*) from sinking_funds where household_id = '<HH>'
   union all select 'budgets', count(*) from budgets where household_id = '<HH>'
   union all select 'reserve_lines', count(*) from reserve_lines where household_id = '<HH>'
   union all select 'annual_targets', count(*) from annual_targets where household_id = '<HH>'
   union all select 'entries', count(*) from entries where household_id = '<HH>'
   union all select 'entries_with_account', count(*) from entries where household_id = '<HH>' and account_id is not null;
   select id, name, created_at from accounts where household_id = '<HH>' order by name;
   ```
   Compare account names/IDs with the device's accounts to confirm R3.

---

## 8. Confirmation

No source files, configuration, schema, migrations or production data were modified. All inspection used read-only copies staged into Claude's workspace; nothing was written back to the repository, no commits were made, and no database or VPS commands were run.
