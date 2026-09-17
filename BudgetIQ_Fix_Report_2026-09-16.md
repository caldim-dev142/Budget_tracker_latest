# BudgetIQ — Master 39-Defect Fix & Production Hardening Report

**Date:** 2026-09-16
**Baseline:** audit snapshot of commit `341790d`
**Scope:** all 39 defects from the Master QA Audit Report
**Rule applied:** the implementation was corrected; the business rules were not redefined. The waterfall formula, the 4 ADD / 2 SUBTRACT adjustment split, integer paise and the Remaining − Closing diagnostic are all unchanged. The engine and golden fixtures are byte-identical to the baseline.

---

## A. Executive summary

| Final status | Count | Defects |
|---|---|---|
| FIXED + VERIFIED | **23** | SEC-01, SEC-02, SEC-03, AUTH-01, AUTH-04, API-01, API-02, API-03, DATA-01, DATA-02, DATA-03, DATA-04, SYNC-02, SYNC-03, SYNC-06, FIN-01, FIN-02, FIN-04, FIN-06, DEP-01, DEP-02, DEP-03, DEP-05 |
| FIXED + PARTIALLY VERIFIED | **11** | AUTH-02, AUTH-03, DATA-05, SYNC-01, SYNC-04, SYNC-05, SYNC-07, SYNC-08, FIN-05, FIN-09, DEP-04 |
| BLOCKED | **1** | SEC-04 |
| REQUIREMENT UNCLEAR (not changed) | **4** | FIN-03, FIN-07, FIN-08, DEP-06 |
| NOT A DEFECT | 0 | — |
| **Total** | **39** | |

"Partially verified" almost always means one of two things:

- The server side was verified live, but the Flutter side could only be checked statically. The Flutter SDK and pub.dev are unreachable from the sandbox.
- For DEP-04, an external action is still required: rotating the database password.

**Headline results**

- **Live API scenarios (the audit's own 136):** before the fix, 81 PASS / 44 FAIL / 11 BLOCKED. After the fix, 126 PASS / 9 FAIL / 1 BLOCKED. Each of the remaining 9 is explained in section I.
- **New fix-verification scenarios:** 13 / 13 PASS.
- **Backend unit tests:** 98 / 98 PASS (baseline was 59). **e2e:** 4 / 4. **Golden fixtures:** 11 / 11.
- **Production boot:** `npm run start:prod` returns `/health` 200. Placeholder JWT secrets are refused. Swagger is disabled. Foreign CORS origins are not reflected.
- **Regression caught during verification:** the first empty-body JSON parser fix (API-02) crashed app bootstrap with `FST_ERR_CTP_ALREADY_PRESENT`. Unit tests could not see this; the live harness did. It was fixed with `bodyParser: false` plus explicit JSON and urlencoded parsers, then re-verified.

---

## B. Critical and High fixes with root cause

| Defect | Root cause | Fix |
|---|---|---|
| **SEC-01**: users without a household shared tenant `""` | JWT `householdId: ''` was used directly as the query scope | New `HouseholdGuard` (fail-closed 403) on all 11 household-scoped controllers. JwtStrategy normalises `''` to `null`. |
| **SEC-02**: removed or deleted users kept access | JWT claims were trusted for their full lifetime | `JwtStrategy.validate()` re-reads the user. It rejects deleted accounts and any token whose household differs from the DB. |
| **SEC-03**: budgets bulk IDOR | No ownership check on `categoryId` | `upsertBulk` verifies every category belongs to the household (403). DTO array validation added. |
| **AUTH-01**: refresh always failed | Controller hashed the token, then the service hashed it again | Controller passes the raw token through a `RefreshTokenDto`. |
| **AUTH-02**: logout did not revoke | Client sent the refresh token as `family`; the server used `req.user.sub` (undefined), so a bare logout could delete **every user's** tokens | Server scopes logout by `req.user.userId`. The client now sends the stored family. |
| **API-02**: body-less requests returned 500 | Fastify rejected an empty body with `Content-Type: application/json` | Empty-body-tolerant JSON parser. Malformed JSON still returns 400. |
| **DATA-01**: login deleted "Cash Wallet"/"Bank Account" accounts | Legacy default-account cleanup ran on every login | Removed from `auth.service` and `households.service`. |
| **DATA-03**: 32-bit money columns | `Int` paise columns | 24 columns changed to `BigInt` (migration), plus a JSON serialisation shim and `Number()` at arithmetic sites. |
| **DATA-04**: seed polluted every household | Demo data looped over all households | Demo data only runs when `SEED_DEMO_DATA=true` and not in production, and only for `demo-household-0001`. Taxonomy seeding is idempotent. |
| **SYNC-01**: deleted records resurrected | No deletion protocol for 8 entity types | New `deletions[]` in `/sync/batch`, a `sync_tombstones` table, and `deletedRecords` in `/sync/pull`. The client enqueues every hard delete. |
| **SYNC-07**: month status not synced | Snapshots were excluded from the sync contract; reopen returned 500 | `monthStatuses` added to pull. Reopen works (API-02). The client applies closes. |
| **FIN-01**: adj-05 and adj-06 seeded as ADD | Wrong `isDeduction` flag in the backend seed | Seed flags corrected, plus a data migration for existing households. |
| **FIN-02**: ₹7,000 lend entry counted as +7,000 | Flutter ID `lend-system-cat-{hh}` was prefixed into a new non-deduction category | `normalizeCategoryId()` maps to the canonical `{hh}-lend-system-cat`, plus an ID-normalisation migration. |
| **FIN-04**: closed-month bypass by changing the date | The guard only checked the incoming date's month | The guard checks both the existing and the incoming month. |
| **DEP-01**: fresh DB could not be provisioned | No baseline migration | Added `0_init` baseline, `migration_lock.toml` and 5 new migrations. |
| **DEP-03**: production accepted placeholder secrets | No env validation | Joi schema: in production, secrets must be ≥32 characters, not placeholders, and access ≠ refresh. |

The Medium and Low fixes are listed in section H and the matrix at the end.

---

## C. Security status

- **Tenant isolation:** verified live on 11 routes for a user with no household (all 403). Also verified: a removed member's token returns 401, a deleted user's token returns 401, a cross-tenant budget write returns 403, and a cross-tenant sync deletion returns 403 with no tombstone created.
- **Auth:**
  - Refresh rotation works, and reuse of an old token revokes the whole family (verified live).
  - Logout revokes only the caller's session. Another user's family ID has no effect.
  - Email is unique and case-insensitive: concurrent registration gives `201, 409, 409`.
- **Secrets:**
  - The hard-coded Supabase connection strings were removed from `scripts/*.js`, which now read `DATABASE_URL` from the environment.
  - **Credential rotation required.** The old password is still in git history. I did **not** rotate it (no access) and did **not** rewrite history (not authorised).
- **Production hardening:** placeholder secrets refused, Swagger off, CORS allow-list only. Validation errors are generic 400s, not stack traces.
- **Offline login (AUTH-03):** a Google or password-less cached account can no longer be unlocked offline with an arbitrary password. This is a static client fix.
- **Not done:** SEC-04 (local SQLite is not encrypted). This is BLOCKED because it needs a device runtime and an on-device DB migration plan.

---

## D. Financial integrity statement

- The waterfall engine (`backend/src/engine/engine.ts`, `lib/domain/engine/waterfall.dart`) and `test/golden_fixtures.json` are **unchanged** from the baseline. All 11 golden scenarios pass.
- **4 ADD / 2 SUBTRACT:** the backend seed now matches the Flutter seed (adj-05 and adj-06 are deductions). Verified live: net adjustments for one entry per category give the approved result.
- **₹7,000 lending regression:** a Flutter-shaped lend entry (positive 700000 paise on `lend-system-cat-{hh}`) now yields dashboard adjustments **−700000** with no alias category rows. Verified live and by unit test.
- **Waterfall identity:** re-checked live on BIGINT columns. Remaining = Opening + LMR + Income + Adj − Spending − Protection − Saving − Reserves.
- **Large amounts:** 25,000,000,000 paise (above 2³¹) is stored and reported exactly.
- **Month boundaries:** entries at 23:59:59.5 on the last day now fall in the correct month.
- **Closed months:**
  - A date change cannot move an entry out of or into a closed month.
  - Re-closing a reopened month no longer rewrites an already-closed next month. Fixed on both server and client.
- **Caveat:** snapshots that were already closed with wrong adjustment signs are **not** recomputed by the migration, by design, because closed statements are frozen. Review them manually if needed.

---

## E. Sync integrity

- **Protocol additions (server):**
  - `POST /sync/batch` accepts `deletions: [{entity, id}]` for planned_bill, receivable, card_transaction, budget, reserve_line, goal_contribution, fund_movement, annual_target and category (categories are archived, never hard-deleted). Legacy `deletedAnnualTargetIds` is still accepted.
  - `GET /sync/pull` returns `deletedRecords`, `deletedAnnualTargetIds` and `monthStatuses`.
- **Verified live:**
  - Device A deletes all 8 entity types; pull omits and advertises them.
  - Stale device B re-pushes its full state; nothing is resurrected.
  - A cross-tenant deletion is refused.
  - A batch containing a foreign record persists nothing (pre-validation).
  - A closed month appears in pull.
- **Entries:**
  - All edited fields are persisted (not just amount and note).
  - Stale versions are skipped.
  - A soft-deleted entry is only revived by a strictly newer version.
  - Invalid kinds and negative non-adjustment amounts are rejected.
- **Budgets:** a second device's budget for the same category and month updates the existing cell instead of being dropped. The client removes its duplicate local row on pull.
- **Client (static only):**
  - Every hard delete enqueues `delete:{entity}:{id}`.
  - Push sends `deletions`; pull applies `deletedRecords` and `monthStatuses`.
  - Queued entry ops stay queued when the server reports `failed > 0`, and `incrementAttempts` now actually increments.
  - Vault derivation is household-scoped and tolerates duplicate names.
- **Atomicity (SYNC-06):** solved by validating ownership for the whole batch before any write. It is not a single DB transaction, so an infrastructure failure mid-batch can still leave a partial write.

---

## F. Database and deployment

**Migrations** (`backend/prisma/migrations/`):

| Migration | Purpose |
|---|---|
| `0_init` | Baseline schema before phase 1 |
| `20260915_phase1_…` | Existing, unchanged |
| `20260916100000_bigint_paise` | 24 money columns changed to BIGINT |
| `20260916100100_users_email_unique` | Unique index. **Aborts if duplicate emails exist.** |
| `20260916100200_fix_adjustment_deduction_flags` | adj-05 and adj-06 set to deductions in existing households |
| `20260916100300_normalize_system_category_ids` | Repoints alias system-category rows to canonical IDs |
| `20260916100400_sync_tombstones` | New tombstone table |

**Verification**

- Full chain applied to an **empty** PostgreSQL 16 DB. The API then ran the full scenario suite on it.
- Applied to a **clone of the existing audit DB**:
  - The email migration correctly aborted on duplicate test users.
  - After de-duplicating the clone only: wrong adjustment flags went from 52 to 0, alias entries from 1 to 0, and entry sums were unchanged.
- `0_init` + phase 1 produces a schema identical (`pg_dump` diff) to the audited DDL.

**Seed (verified on a copy of live data)**

- Default run: no rows added to existing households.
- `NODE_ENV=production` with `SEED_DEMO_DATA=true`: nothing added.
- Local with `SEED_DEMO_DATA=true`: only `demo-household-0001` is created. A second run is idempotent.

**Build:** `tsconfig.build.json` now excludes `prisma/`, so `npm run build` emits `dist/main.js` and `start:prod` works.

**Deployment steps (in order)**

1. **Rotate the Supabase database password** and update the `DATABASE_URL` secret wherever it is used.
2. On the existing database, resolve duplicate emails (the migration will refuse to run otherwise).
3. Mark the migrations that are already applied as applied:
   ```
   npx prisma migrate resolve --applied 0_init
   npx prisma migrate resolve --applied 20260915_phase1_refresh_tokens_and_restrict_fk
   ```
   Run the second command only if phase 1 was already applied.
4. `npx prisma migrate deploy`. Never run `migrate reset` against production.
5. Set production `JWT_ACCESS_SECRET` and `JWT_REFRESH_SECRET` (random, ≥32 characters, different from each other) and `CORS_ORIGINS`.
6. **Deploy the backend before releasing the app.** The new client sends `deletions`, which an old server rejects with 400.
7. Regenerate the Flutter Drift code locally (`dart run build_runner build`). No table definitions changed, so no schema migration is expected; this just keeps generated files current.

---

## G. Test commands and results

| Command / suite | Result |
|---|---|
| `cd backend && npx tsc -p tsconfig.build.json --noEmit` | OK |
| `cd backend && npx jest` | **10 suites, 98 tests passed** (baseline 59). New: `test/fix-regression.spec.ts` (33), `test/env-validation.spec.ts` (6). |
| `cd backend && npm run test:e2e` | **4 / 4 passed** (new `test/jest-e2e.json` + `test/app.e2e-spec.ts`) |
| `cd backend && npm run build` → `npm run start:prod` | `dist/main.js` built; `/health` 200 with production env |
| Production boot with placeholder JWT secrets | Refused ("template/placeholder value … not allowed") |
| Live API harness, phases 1–4 (audit scenarios, 136) | 126 PASS / 9 FAIL / 1 BLOCKED (was 81 / 44 / 11) |
| Live fix-verification harness, phase 5 (13 scenarios) | **13 / 13 PASS** |
| Golden fixtures (TS engine, all 11 scenarios) | **11 / 11 PASS** |
| Migrations: fresh DB and existing-data clone | PASS (see F) |
| Seed gating: 4 runs on a live-data copy | PASS (see F) |
| **Flutter `flutter test` / `flutter analyze`** | **BLOCKED — Flutter runtime unavailable** (SDK and pub.dev unreachable) |
| Dart syntax parse (tree-sitter-dart) of the 13 edited Dart files | No new parse errors vs baseline. The grammar cannot parse Dart 3 records, so the same pre-existing errors appear in both. This is **not** a compile or type check. |

Harness-only changes (the WASM Prisma engine and pg adapter) were applied to a separate copy outside the repository and are **not** part of the delivered code.

---

## H. Files changed (70), grouped

**Security / auth**

- `backend/src/auth/strategies/jwt.strategy.ts`
- `auth/guards/household.guard.ts` (new)
- `auth/auth.controller.ts`, `auth/auth.service.ts`
- `auth/dto/refresh-token.dto.ts` (new)
- `config/env.validation.ts` (new)
- `app.module.ts`
- `scripts/migrate.js`, `scripts/test_connection.js`, `scripts/insert_sample_data.js`
- HouseholdGuard added to these controllers: accounts, budgets, cards, categories, entries, months, planning, protection, reports, saving, sync

**Validation / API**

- `main.ts`
- `common/pipes/year-month.pipe.ts` (new)
- `accounts/dto/account.dto.ts` (new), `households/dto/household.dto.ts` (new), `users/dto/update-user.dto.ts` (new)
- `budgets/dto/update-budget.dto.ts`
- `accounts.controller.ts`, `households.controller.ts`, `users.controller.ts`, `months.controller.ts`, `reports.controller.ts`, `entries.controller.ts`, `budgets.controller.ts`

**Financial**

- `categories/categories-seed.data.ts`
- `entries/entries.service.ts`
- `months/months.service.ts`, `reports/reports.service.ts`
- `common/month-range.ts` (new), `common/bigint-json.ts` (new)
- `budgets/budgets.service.ts`

**Sync**

- `sync/sync.service.ts`, `sync/dto/sync-batch.dto.ts`

**Data / DB**

- `prisma/schema.prisma`, `prisma/seed.ts`
- `prisma/migrations/*` (7 new)
- `households/households.service.ts`, `users/users.service.ts`
- `tsconfig.build.json`

**Tests**

- New: `test/fix-regression.spec.ts`, `test/env-validation.spec.ts`, `test/app.e2e-spec.ts`, `test/jest-e2e.json`
- Updated mocks or assertions (new dependencies only, nothing weakened): `test/sync-isolation.spec.ts`, `src/households/households.service.spec.ts`, `test/auth.security.spec.ts`

**Flutter (static)**

- `lib/features/auth/providers/auth_providers.dart` (logout family, offline login)
- `lib/core/services/sync_service.dart` (deletions push/pull, failed-op handling, budgets, month status)
- `lib/data/local/daos/sync_queue_dao.dart` (`enqueueDeletion`, `incrementAttempts`)
- `lib/data/local/daos/borrow_lend_dao.dart`
- `lib/data/repositories/entry_repository_impl.dart` (vault scoping, linked deletes)
- `lib/core/services/app_init_service.dart` (guest category remap)
- `lib/features/more/presentation/more_screen.dart` (closed next month)
- `lib/features/settings/presentation/settings_screen.dart` (CSV, category delete)
- `budget_screen.dart`, `cards_screen.dart`, `planning_screen.dart`, `saving_screen.dart`, `protection_screen.dart` (deletion enqueue)

Line endings and BOMs were preserved per file. No mass reformatting, and no generated files were edited.

---

## I. Remaining issues

**Remaining FAILs in the audit harness, explained**

| Test | Why it still fails | Assessment |
|---|---|---|
| AUTH-18 | Sends the *old* client payload (`family = refresh token`). The server correctly revokes nothing. | Fixed in the client (AUTH-02). Verified with the correct payload in FX-AUTH-03. |
| SYNC-07 (harness) | Pushes full state *without* `deletions[]`. The server cannot infer deletions from absence. | Protocol requires the new client. Verified with `deletions[]` in FX-SYNC-01/02. |
| HH-04, HH-09 | A numeric `householdId` or `name` is implicitly converted to a string (global `enableImplicitConversion`), giving 404 or 200 instead of 400. | The 500 is gone (API-01 fixed). Stricter typing would change global validation behaviour, so it was left as is. |
| VAL-13 | A string `"100"` is converted to 100 by the same global setting. | Same as above; it was already marked PASS in the original audit. |
| VAL-06 | Account `type` is a free string (e.g. "hacker"). | Not among the 39 defects. POTENTIAL RISK; the allowed set (bank/cash?) needs confirmation. |
| SEC-03 | CORS reflects any origin when `NODE_ENV=local`. | By design for LAN development. Production verified locked down. |
| SEC-04 (harness) | The scenario needed an unhandled 500; that endpoint now returns a validation 400. | Test is obsolete. Production error bodies remain generic. |
| FIN-03 | Reserves formula differs between device and server. | REQUIREMENT UNCLEAR. |

**Open items**

1. **Credential rotation required** for the exposed Supabase password (DEP-04). Git history still contains it; purging it needs your authorisation.
2. **SEC-04 (BLOCKED):** SQLCipher encryption needs a device runtime and an on-device migration plan.
3. **REQUIREMENT UNCLEAR, needs a product decision:**
   - FIN-03: which "Current Reserves" formula is canonical.
   - FIN-07: whether an account's opening balance counts as Income.
   - FIN-08: whether manual balance edits override recalculation.
   - DEP-06: the production API URL and release signing configuration.
4. **Flutter verification pending:** run `flutter analyze` and `flutter test`, then a two-device smoke test covering deletions, month close, logout and offline login.
5. **Known limitations of these fixes:**
   - A month *reopen* is not propagated to other devices (only closes are). Without timestamps it cannot be told apart from an unsent local close.
   - Queued entry ops the server permanently rejects (e.g. a closed month) retry indefinitely; they are counted in pending.
   - Web CSV export still produces no download file (DATA-05, web part).
   - Refresh does not cross-check the client-supplied `family` against the stored family (the stored family is used).
6. Already-closed snapshots with wrong adjustment signs are not recomputed.

---

## Defect status matrix

| ID | Sev | Status | Evidence |
|---|---|---|---|
| DEF-SEC-01 | Critical | FIXED + VERIFIED | HH-18, FX-SEC-01, unit (guard, strategy) |
| DEF-SEC-02 | Critical | FIXED + VERIFIED | HH-14, HH-21, unit |
| DEF-SEC-03 | High | FIXED + VERIFIED | IDOR-01/02, unit, e2e |
| DEF-SEC-04 | High | BLOCKED | Needs device runtime and on-device DB migration |
| DEF-AUTH-01 | High | FIXED + VERIFIED | AUTH-14, FX-AUTH-01/02, unit, e2e |
| DEF-AUTH-02 | High | FIXED + PARTIALLY VERIFIED | Server FX-AUTH-03/04 live; client static |
| DEF-AUTH-03 | High | FIXED + PARTIALLY VERIFIED | Client static |
| DEF-AUTH-04 | Medium | FIXED + VERIFIED | AUTH-07/08, migration abort on duplicates |
| DEF-API-01 | Medium | FIXED + VERIFIED | HH-04/09 no longer 500; VAL-03/04/08 |
| DEF-API-02 | High | FIXED + VERIFIED | API-01, production boot |
| DEF-API-03 | Medium | FIXED + VERIFIED | VAL-01..18, RPT-03, unit, e2e |
| DEF-DATA-01 | High | FIXED + VERIFIED | HH-22 |
| DEF-DATA-02 | Medium | FIXED + VERIFIED | HH-20 |
| DEF-DATA-03 | Medium | FIXED + VERIFIED | VAL-05, VAL-19, FX-DATA-01, migration |
| DEF-DATA-04 | High | FIXED + VERIFIED | 4 seed runs on live-data copy |
| DEF-DATA-05 | Low | FIXED + PARTIALLY VERIFIED | Client static; web download not implemented |
| DEF-SYNC-01 | High | FIXED + PARTIALLY VERIFIED | Server FX-SYNC-01/02/03 live; client static |
| DEF-SYNC-02 | High | FIXED + VERIFIED | SYNC-01, unit |
| DEF-SYNC-03 | Medium | FIXED + VERIFIED | SYNC-06, unit |
| DEF-SYNC-04 | Medium | FIXED + PARTIALLY VERIFIED | Server SYNC-10 live; client static |
| DEF-SYNC-05 | Medium | FIXED + PARTIALLY VERIFIED | Client static |
| DEF-SYNC-06 | Medium | FIXED + VERIFIED | IDOR-23, FX-SYNC-04 (pre-validation) |
| DEF-SYNC-07 | High | FIXED + PARTIALLY VERIFIED | Server FX-SYNC-05 live; client static; reopen not propagated |
| DEF-SYNC-08 | Medium | FIXED + PARTIALLY VERIFIED | Client static |
| DEF-FIN-01 | High | FIXED + VERIFIED | FIN-01, SEED-01, migration, unit |
| DEF-FIN-02 | High | FIXED + VERIFIED | FIN-04, FX-FIN-01 (₹7,000 → −700000), unit |
| DEF-FIN-03 | Medium | REQUIREMENT UNCLEAR | No change |
| DEF-FIN-04 | High | FIXED + VERIFIED | MONTH-05/06, unit |
| DEF-FIN-05 | Medium | FIXED + PARTIALLY VERIFIED | Server MONTH-08 live; client static |
| DEF-FIN-06 | Medium | FIXED + VERIFIED | MONTH-09/10, unit |
| DEF-FIN-07 | Medium | REQUIREMENT UNCLEAR | No change |
| DEF-FIN-08 | Medium | REQUIREMENT UNCLEAR | No change |
| DEF-FIN-09 | Medium | FIXED + PARTIALLY VERIFIED | Client static |
| DEF-DEP-01 | High | FIXED + VERIFIED | Fresh DB chain + existing clone |
| DEF-DEP-02 | Medium | FIXED + VERIFIED | `start:prod` health 200 |
| DEF-DEP-03 | High | FIXED + VERIFIED | SEC-06, placeholder boot refused, unit |
| DEF-DEP-04 | Critical | FIXED + PARTIALLY VERIFIED | Code verified; **rotation required externally** |
| DEF-DEP-05 | Low | FIXED + VERIFIED | `npm run test:e2e` 4/4 |
| DEF-DEP-06 | High | REQUIREMENT UNCLEAR | Production URL and signing unknown |
