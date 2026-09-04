# Budget Tracker — Developer Handover Bible for Antigravity

**Purpose of this document**: this is a task-by-task implementation spec, not a single prompt. Feed Antigravity **one task at a time**, in the order listed, using the exact scope boundaries given. Do not paste this entire document into the agent as one instruction — that invites it to touch far more of the codebase than any single task requires.

---

> ## ⚠️ READ FIRST — Task 1.2 clarification, stated plainly
> The adjustment rule — 4 categories added, 2 subtracted — is the client's **correct, verified, unchangeable** business logic (see Excel formula `Income!D23 = SUM(D24:D27) − SUM(D28:D29)`). **Task 1.2 below does not change this rule.** It fixes a code bug where `rollups.dart` fails to apply this already-correct rule, while three other files in the same codebase already apply it correctly. Antigravity must treat Task 1.2 as "make one file match the rule the other three already implement," never as "reconsider or redesign how adjustments are calculated."

---

## 0. Ground Rules — read this to the agent before Task 1

Give Antigravity this preamble (or paste it as a persistent project instruction if the tool supports one) before starting any task below:

> This is an existing, partially-built Flutter + NestJS personal finance app. The financial calculation logic (the "waterfall": Opening + Income + Adjustments − Spending − Protection − Saving − Reserves = Remaining) was reverse-engineered from a client's Excel workbook and is the approved, correct business logic. **Do not change the waterfall formula, the layer order, category groupings (need/want, protection groups, saving buckets), or any calculation rule — only fix implementation bugs that cause the code to contradict this already-approved logic.** For every task below, only touch the files listed under "Files in scope." If a fix seems to require touching a file not listed, stop and report that back instead of proceeding. Do not refactor, rename, or restructure anything outside the stated scope of the task, even if you notice other issues — note them instead and move to the next task.

**Recommended mode**: use checkpoint/review-driven mode (not full autonomy) for every task in Section 1 and Section 2, since they touch financial calculations, auth, or sync. Full-autonomy mode is acceptable for Section 3 (pure UI/new-feature tasks) once Sections 1–2 are merged and verified.

**Before Task 1**: run `flutter analyze` and the existing test suite (`flutter test`) and report results before any code changes. This was not done during the static audit and should be the true starting point.

---

## SECTION 1 — Bug Fixes (P0, do these first, one at a time)

### Task 1.1 — Reports screen uses fabricated data instead of real data
**Files in scope**: `lib/features/reports/presentation/report_detail_screen.dart`
**Problem**: `_initMockData()` generates trend lines, category breakdowns, and cashflow percentages using `Random(seed)`, disconnected from the user's real entries. Hardcoded category names (`'Food & Dining'`, `'Housing & Rent'`, etc.) don't even match the app's real category taxonomy.
**Required fix**: Replace `_initMockData()` and any code path that calls it with real data sourced the same way `dashboard_providers.dart` or `budget_screen.dart` source theirs — via the existing repository/provider pattern (Drift DAOs → Riverpod providers), for the same month range the mock data currently fakes (trends, category breakdown, cashflow distribution).
**Acceptance criteria**: No `Random()`-generated financial figures remain reachable from any user-facing path in this file. Numbers shown match what `Transactions`/`Budget` screens show for the same month. Existing UI layout/charts (fl_chart usage) should be preserved — only the data source changes, not the visual design.
**Out of scope**: Do not redesign the Reports screen's UI/layout in this task.

---

### Task 1.2 — Adjustment-sign inconsistency across the engine and three screens
**⚠️ This is a code-consistency fix, not a business-logic change.** The 4-add/2-subtract rule below is client-approved and verified against the Excel — do not alter it. Only align the one non-conforming file with the rule.
**Files in scope**: `lib/domain/engine/rollups.dart` (primary fix), plus read-only reference to `lib/features/dashboard/providers/dashboard_providers.dart`, `lib/data/local/daos/account_dao.dart`, `lib/features/more/presentation/more_screen.dart` (do not modify these three — they are already correct and are your reference implementation)
**Problem**: The Excel-derived rule is that outflow-type adjustment categories (`Lending/Return(-)`, `Others(Outflow)` — both seeded with `isDeduction: true`) must **reduce** the Adjustments total. Three files (`dashboard_providers.dart`, `account_dao.dart`, `more_screen.dart`) each independently implement this correctly:
```dart
if (isDeduction) { adjustmentsPaise -= amount; } else { adjustmentsPaise += amount; }
```
But `RollupEngine.netAdjustments()` in `rollups.dart` — the tested, golden-fixture-verified engine used by the waterfall and month-close — does not do this check; it sums every adjustment entry's raw (always-positive) amount, silently inflating adjustments instead of reducing them for outflow categories.
**Required fix**: Modify `RollupEngine.netAdjustments()` (and any other `RollupEngine` function that sums adjustment entries) to accept the category map and apply the same `isDeduction` check the three reference files use, so `netAdjustments` matches their output for identical input data. Do not modify the calling signature more than necessary — check `waterfall.dart` and `close_month.dart` for any call sites that will need an additional category-map argument passed through.
**Acceptance criteria**: Run (or add, if missing) a unit test that creates one `Lending/Return(-)` adjustment entry and one regular inflow adjustment entry, and asserts `RollupEngine.netAdjustments()` produces the same signed total that `dashboard_providers.dart`'s hand-rolled loop would produce for the same data. All existing entries in `test/engine_golden_test.dart` and `test/engine/engine_test.dart` must still pass unchanged (this is a bug fix, not a formula change — golden fixtures should not need updating; if they do, stop and report why before proceeding).
**Out of scope**: Do not consolidate the three duplicate implementations in Task 1.2 — that's Task 3.x (optional cleanup) after this fix is verified correct.

---

### Task 1.3 — Surface the plan-vs-actual reconciliation difference (corrected — verified against client Excel)
**Files in scope**: `lib/domain/usecases/close_month.dart`, `lib/domain/entities/month_snapshot.dart`, month-close/dashboard display screen
**Verified against source**: `Summary!R9` in the client's Excel = `Total Inward − Total Outward − Total Available`. The Excel deliberately keeps the calculated waterfall ("Remaining") and the real-bank-reconciled figure ("Closing Balance", from `Total Available` = sum of actual account balances) as two separate numbers and shows their difference to the user as a diagnostic — it is NOT an error condition. Do not implement equality-blocking here; that was an earlier, incorrect version of this task.
**Problem**: `closingBalance = totalAvailable − reserves` and `remaining` (from the waterfall) are both computed today, but the app never shows the user the difference between them the way the Excel does — losing a genuinely useful "did I miss recording a transaction somewhere" signal.
**Required fix**: Compute `reconciliationDifference = remaining − closingBalance` at month-close and surface it as a visible, non-blocking insight (e.g. "Plan vs. actual balance: ₹X difference — check for missing entries"). Do not fail or block the save on any value of this difference.
**Acceptance criteria**: A test with `totalAvailable` differing from the waterfall-implied balance still successfully saves the `MonthSnapshot`, and `reconciliationDifference` is computed and available to the UI layer with the correct signed value.
**Out of scope**: Do not change how `totalAvailable` is computed or sourced elsewhere in the app — only add the computed diagnostic field and its UI display.

---

### Task 1.4 — `MonthSnapshot.householdId` placeholder bug
**Files in scope**: `lib/domain/usecases/close_month.dart`, `lib/domain/entities/month_snapshot.dart`
**Problem**:
```dart
householdId: actuals.yearMonth.toApiString(), // will be set by repo
```
sets `householdId` to a year-month string as a placeholder, trusting the repository layer to overwrite it — fragile and unenforced by the compiler.
**Required fix**: Add a required `householdId` parameter to `CloseMonthUseCase.execute()` (or to wherever `MonthActuals`/the use-case already has access to the real household ID), and pass the real value through instead of the placeholder string. Remove the placeholder comment.
**Acceptance criteria**: No string interpolation of `yearMonth` is used anywhere as a stand-in for `householdId`. Existing callers of `execute()` are updated to pass the real household ID (search all call sites before finishing).
**Out of scope**: Do not change the `MonthSnapshot` entity's other fields.

---

### Task 1.5 — Auth mode uses string sentinels instead of a typed value
**Files in scope**: `lib/core/services/sync_service.dart`, `lib/features/auth/providers/auth_providers.dart`
**Problem**: `token == 'mock-token'` / `token == 'offline-token'` string comparisons determine online/offline behavior in at least 5 call sites — fragile, no compiler safety.
**Required fix**: Introduce `enum AuthMode { authenticated, offline, guest }` (or similar), have the auth provider expose the mode explicitly rather than inferring it from token string comparison, and update `sync_service.dart` and all 4+ call sites in `auth_providers.dart` to branch on the enum instead of string equality.
**Acceptance criteria**: No remaining string-literal comparisons against `'mock-token'` or `'offline-token'` in the codebase. Existing offline/online behavior is unchanged (verify manually against the current `if` branches before and after).
**Out of scope**: Do not change the actual token storage/retrieval mechanism (`flutter_secure_storage` usage) — only the mode-detection logic.

---

### Task 1.6 — No connectivity detection → sync never triggers automatically
**Files in scope**: `pubspec.yaml`, `lib/core/services/sync_service.dart`
**Problem**: `connectivity_plus` is commented out in `pubspec.yaml` due to a "Windows plugin has broken symlink" note. This means the app has no way to detect reconnection and trigger sync automatically.
**Required fix**: Since Windows is being deprioritized per this project's own scope decisions (confirm with the person before proceeding — this is a product decision, not purely technical), re-enable `connectivity_plus` for Android/iOS/Web targets, or evaluate a lighter alternative package if the symlink issue persists across all targets. Wire a listener that triggers the existing sync queue drain when connectivity transitions from offline → online.
**Acceptance criteria**: Manually toggling airplane mode off after being offline triggers a sync attempt without user action. No regression to existing manual sync triggers.
**Out of scope**: Do not implement a full background-sync/WorkManager solution in this task — foreground reconnect-triggered sync only.

---

## SECTION 2 — New Feature: Onboarding (P0, do after Section 1 is merged)

### Task 2.1 — Guided financial setup wizard
**Files in scope**: new files under `lib/features/onboarding/`; read-only reference to `lib/core/router/app_router.dart` (routing), `lib/features/auth/presentation/splash_screen.dart` (entry point), `lib/core/constants/category_seed.dart` (category list to pull common ones from)
**Problem**: No dedicated first-run flow exists. A user is dropped directly into a 141-category, 7-layer money model with no guidance.
**Required fix**: Build a 4-step wizard, shown once per household on first launch (persist a "onboarding_complete" flag, check it in `splash_screen.dart`'s routing decision):
1. Salary/income: amount + pay date
2. Mandatory expenses: let the user pick 5–8 from the existing seeded categories (don't invent new ones) and enter a monthly estimate for each
3. Protection: one goal — emergency fund target (see Task 2.2 dependency, or a simple manual target amount for v1)
4. Savings: one goal — amount + target date, using the existing `saving_goal.dart` entity
Each step writes real data through the existing repositories (`AddEntryUseCase`, category/budget repos) — do not create a parallel data path.
**Acceptance criteria**: Skipping the wizard is possible but discouraged (a "skip for now" option is fine); completing it populates real budget/category data visible immediately on the Dashboard. Wizard does not show again after completion or skip.
**Out of scope**: Do not attempt to onboard all 141 categories — only the small guided subset above. Do not build household-invite flows here (that's Task 3.5).

---

## SECTION 3 — New Features & Housekeeping (P1/P2, do after Sections 1–2 are stable)

Each of these is independent — order within this section is flexible, but do not start any of them until Section 1 is fully merged and verified.

### Task 3.1 — Emergency Fund target calculator
**Files in scope**: `lib/features/protection/presentation/protection_screen.dart`, new logic in `lib/domain/engine/` (e.g. a new `emergency_fund.dart`)
**Required fix**: Add a target = N months (default 3, user-editable) × trailing-3-month average of Fees + Needs spend groups. Show current Protection balance against this target as a progress indicator on the Protection screen.

### Task 3.2 — EMI-aware recurring commitments
**Files in scope**: new entity (e.g. `lib/domain/entities/emi.dart`), new DAO/table migration, relevant screens for entry/display
**Required fix**: New entity with principal, tenure (months), start date → derived monthly amount and payoff date. Surface "frees up ₹X/month in N months" on the Dashboard.

### Task 3.3 — Payment-method tagging
**Files in scope**: `lib/domain/entities/entry.dart`, Drift table migration, `add_entry_screen.dart`, relevant report views
**Required fix**: Optional `paymentMethod` field (Cash / UPI / Card / Bank transfer) on `Entry`. Add to the entry form as an optional selector. Add one report slice by payment method.

### Task 3.4 — Rules-based financial insights
**Files in scope**: new file(s) under `lib/features/dashboard/` or a new `insights` feature module
**Required fix**: Simple threshold rules comparing actuals to the user's own budget (e.g., "Wants spending is 12% above budget this month"). Explicitly rules-based — no ML/AI model in this task.

### Task 3.5 — Household sharing / multi-user
**Files in scope**: new feature module, backend `households` module (`backend/src/households/`)
**Required fix**: Invite/permission UI leveraging the existing `householdId` field already present on every entity. Backend work required — confirm backend is verified working (Task 4.1) before starting this.

### Task 3.6 — Split oversized screens
**Files in scope**: `lib/features/planning/presentation/planning_screen.dart` (1,429 lines), `lib/features/budget/presentation/budget_screen.dart` (1,286 lines), `lib/features/dashboard/presentation/dashboard_screen.dart` (1,033 lines)
**Required fix**: Extract logical sections into separate widget files (e.g. `planning_screen/planning_header.dart`, `planning_screen/planning_month_list.dart`). Pure refactor — no behavior change. Do this file-by-file, one screen per task, and diff-review carefully since these are the app's most complex screens.
**Acceptance criteria**: App behaves identically before/after; existing tests still pass; no widget's public API changes in a way that breaks other screens referencing it.

### Task 3.7 — Consolidate the 3 duplicate adjustment-sign implementations (optional cleanup, after Task 1.2 is verified)
**Files in scope**: `lib/features/dashboard/providers/dashboard_providers.dart`, `lib/data/local/daos/account_dao.dart`, `lib/features/more/presentation/more_screen.dart`
**Required fix**: Once `RollupEngine` (Task 1.2) is the verified correct source of truth, refactor these three to call it instead of re-implementing the same loop independently.
**Out of scope**: Do not attempt this before Task 1.2 is merged and tested — these three are your reference implementation until then.

---

## SECTION 4 — Verification Tasks (do in parallel with Section 1, not code changes)

### Task 4.1 — Verify the backend actually runs end-to-end
**Scope**: `backend/` directory — build, apply Prisma migrations against a real Postgres instance, run one full sync cycle between two simulated devices.
**Deliverable**: A report (not a code change) confirming: does `npm install && npm run build` succeed; do Prisma migrations apply cleanly; does `/sync/batch` round-trip correctly. Fix only what's broken, and report anything that requires a product decision (e.g., missing environment config) rather than guessing.

### Task 4.2 — Add repository/widget test coverage
**Scope**: `test/` directory
**Required fix**: Add tests for the Drift DAOs and for the 3 screens touched in Task 3.6, at minimum. Do this incrementally alongside Sections 1 and 3, not as one giant task.

---

## Explicitly out of scope for Antigravity, in all tasks above

- The waterfall formula (`WaterfallEngine`), the layer order (Spending → Protection → Saving → Reserves), category groupings (need/want, protection groups, saving buckets) — these came from the client's Excel workbook and are approved; do not reinterpret them.
- SMS/bank/UPI auto-import — deferred, needs a product/legal decision before any code is written.
- Platform target decisions (dropping Windows/Linux/macOS/Web) — flag for the product owner to decide; don't unilaterally remove build targets.

---

## Suggested execution order (copy-paste as a checklist)

- [ ] Task 0 — `flutter analyze` + `flutter test`, report results
- [ ] Task 1.1 — Reports mock data
- [ ] Task 1.2 — Adjustment sign bug in engine
- [ ] Task 1.3 — Plan-vs-actual reconciliation insight (corrected)
- [ ] Task 1.4 — householdId placeholder
- [ ] Task 1.5 — Auth mode enum
- [ ] Task 1.6 — Connectivity detection
- [ ] Task 4.1 — Backend verification (parallel with above)
- [ ] Task 2.1 — Onboarding wizard
- [ ] Task 3.1 — Emergency Fund calculator
- [ ] Task 3.2 — EMI tracking
- [ ] Task 3.3 — Payment-method tagging
- [ ] Task 3.4 — Insights
- [ ] Task 3.5 — Household sharing
- [ ] Task 3.6 — Split large screens (one at a time)
- [ ] Task 3.7 — Consolidate duplicate sign logic
- [ ] Task 4.2 — Test coverage (ongoing)
