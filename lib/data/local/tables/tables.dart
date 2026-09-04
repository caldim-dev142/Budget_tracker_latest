import 'package:drift/drift.dart';

// ─── Accounts (doc 05 §accounts) ────────────────────────────────────────────
class AccountsTable extends Table {
  @override
  String get tableName => 'accounts';

  TextColumn get id => text()();
  TextColumn get householdId => text()();
  TextColumn get name => text()();
  TextColumn get type => text()(); // 'bank' | 'cash'
  IntColumn get currentBalancePaise => integer().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

// ─── Categories (doc 05 §categories) ────────────────────────────────────────
class CategoriesTable extends Table {
  @override
  String get tableName => 'categories';

  TextColumn get id => text()();
  TextColumn get householdId => text()();
  TextColumn get kind => text()(); // EntryKind name
  TextColumn get groupCode => text().nullable()();
  TextColumn get name => text()();
  TextColumn get needOrWant => text().nullable()(); // 'need' | 'want'
  BoolColumn get isDeduction => boolean().withDefault(const Constant(false))();
  BoolColumn get isSystem => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get archivedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ─── Budgets (doc 05 §budgets) ──────────────────────────────────────────────
class BudgetsTable extends Table {
  @override
  String get tableName => 'budgets';

  TextColumn get id => text()();
  TextColumn get householdId => text()();
  TextColumn get categoryId => text().references(CategoriesTable, #id)();
  TextColumn get yearMonth => text()(); // 'YYYY-MM'
  IntColumn get amountPaise => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'UNIQUE(category_id, year_month)',
  ];
}

// ─── Entries (doc 05 §entries) — the core table ─────────────────────────────
class EntriesTable extends Table {
  @override
  String get tableName => 'entries';

  TextColumn get id => text()(); // client-generated UUID for idempotent sync
  TextColumn get householdId => text()();
  TextColumn get categoryId => text().references(CategoriesTable, #id)();
  TextColumn get kind => text()(); // EntryKind name
  TextColumn get accountId => text().nullable()();
  TextColumn get cardId => text().nullable()();
  DateTimeColumn get entryDate => dateTime()();
  IntColumn get amountPaise => integer()(); // signed; ≠ 0 for non-system (CHECK constraint)
  TextColumn get note => text().nullable()();
  TextColumn get parentId => text().nullable()(); // split sub-entry
  TextColumn get createdBy => text()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()(); // soft delete

  @override
  Set<Column> get primaryKey => {id};
}

// ─── Sinking Funds (doc 05 §sinking_funds) ──────────────────────────────────
class SinkingFundsTable extends Table {
  @override
  String get tableName => 'sinking_funds';

  TextColumn get id => text()();
  TextColumn get householdId => text()();
  TextColumn get name => text()();
  IntColumn get openingReservePaise => integer().withDefault(const Constant(0))();
  DateTimeColumn get archivedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ─── Fund Movements (doc 05 §fund_movements) ────────────────────────────────
class FundMovementsTable extends Table {
  @override
  String get tableName => 'fund_movements';

  TextColumn get id => text()();
  TextColumn get fundId => text().references(SinkingFundsTable, #id)();
  TextColumn get type => text()(); // 'contribution' | 'withdrawal'
  IntColumn get amountPaise => integer()();
  DateTimeColumn get movementDate => dateTime()();
  TextColumn get note => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ─── Saving Goals (doc 05 §saving_goals) ────────────────────────────────────
class SavingGoalsTable extends Table {
  @override
  String get tableName => 'saving_goals';

  TextColumn get id => text()();
  TextColumn get householdId => text()();
  TextColumn get bucket => text()(); // 'retirement' | 'children' | 'other_goals'
  TextColumn get name => text()();
  IntColumn get targetPaise => integer().nullable()();
  IntColumn get monthlyBudgetPaise => integer().withDefault(const Constant(0))();
  DateTimeColumn get archivedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ─── Goal Contributions (doc 05 §goal_contributions) ────────────────────────
class GoalContributionsTable extends Table {
  @override
  String get tableName => 'goal_contributions';

  TextColumn get id => text()();
  TextColumn get goalId => text().references(SavingGoalsTable, #id)();
  IntColumn get amountPaise => integer()();
  DateTimeColumn get contributionDate => dateTime()();
  TextColumn get note => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ─── Credit Cards (doc 05 §credit_cards) ────────────────────────────────────
class CreditCardsTable extends Table {
  @override
  String get tableName => 'credit_cards';

  TextColumn get id => text()();
  TextColumn get householdId => text()();
  TextColumn get name => text()();
  IntColumn get previousOutstandingPaise => integer().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

// ─── Card Transactions (doc 05 §card_transactions) ──────────────────────────
class CardTransactionsTable extends Table {
  @override
  String get tableName => 'card_transactions';

  TextColumn get id => text()();
  TextColumn get cardId => text().references(CreditCardsTable, #id)();
  DateTimeColumn get txnDate => dateTime()();
  TextColumn get description => text()();
  IntColumn get amountPaise => integer()(); // payment < 0, spend > 0
  IntColumn get sNo => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ─── Receivables (doc 05 §receivables) ──────────────────────────────────────
class ReceivablesTable extends Table {
  @override
  String get tableName => 'receivables';

  TextColumn get id => text()();
  TextColumn get householdId => text()();
  TextColumn get personName => text()();
  IntColumn get amountPaise => integer()();
  TextColumn get status => text().withDefault(const Constant('open'))(); // 'open' | 'returned'
  DateTimeColumn get dueDate => dateTime().nullable()();
  /// Linked entry ID for transaction sync (Feature 2: borrow/lending sync)
  TextColumn get entryId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ─── Planned Bills (doc 05 §planned_bills) ──────────────────────────────────
class PlannedBillsTable extends Table {
  @override
  String get tableName => 'planned_bills';

  TextColumn get id => text()();
  TextColumn get householdId => text()();
  TextColumn get name => text()();
  IntColumn get amountPaise => integer()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  BoolColumn get isPaid => boolean().withDefault(const Constant(false))();
  /// Linked entry ID for transaction sync (Feature 2: borrow/lending sync)
  TextColumn get entryId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ─── Reserve Lines (doc 05 §reserve_lines) ──────────────────────────────────
class ReserveLinesTable extends Table {
  @override
  String get tableName => 'reserve_lines';

  TextColumn get id => text()();
  TextColumn get householdId => text()();
  TextColumn get yearMonth => text()(); // 'YYYY-MM'
  TextColumn get name => text()();
  IntColumn get amountPaise => integer()();
  TextColumn get source => text().withDefault(const Constant('manual'))(); // 'manual' | 'derived'

  @override
  Set<Column> get primaryKey => {id};
}

// ─── Month Snapshots (doc 05 §month_snapshots) ──────────────────────────────
class MonthSnapshotsTable extends Table {
  @override
  String get tableName => 'month_snapshots';

  TextColumn get id => text()();
  TextColumn get householdId => text()();
  TextColumn get yearMonth => text()(); // 'YYYY-MM' — unique per household
  IntColumn get openingBalancePaise => integer().withDefault(const Constant(0))();
  IntColumn get lastMonthReservesPaise => integer().withDefault(const Constant(0))();
  IntColumn get incomePaise => integer().withDefault(const Constant(0))();
  IntColumn get adjustmentsPaise => integer().withDefault(const Constant(0))();
  IntColumn get spendingPaise => integer().withDefault(const Constant(0))();
  IntColumn get protectionPaise => integer().withDefault(const Constant(0))();
  IntColumn get savingPaise => integer().withDefault(const Constant(0))();
  IntColumn get reservesPaise => integer().withDefault(const Constant(0))();
  IntColumn get closingBalancePaise => integer().withDefault(const Constant(0))();
  IntColumn get remainingPaise => integer().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(const Constant('open'))(); // 'open' | 'closed'
  DateTimeColumn get closedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'UNIQUE(household_id, year_month)',
  ];
}

// ─── Sync Queue (doc 11 §2) ──────────────────────────────────────────────────
class SyncQueueTable extends Table {
  @override
  String get tableName => 'sync_queue';

  TextColumn get id => text()(); // op UUID
  TextColumn get op => text()(); // 'insert' | 'update' | 'delete'
  TextColumn get entity => text()(); // 'entry' | 'card_txn' | ...
  TextColumn get entityId => text()();
  TextColumn get payload => text()(); // JSON
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ─── Annual Targets ─────────────────────────────────────────────────────────
class AnnualTargetsTable extends Table {
  @override
  String get tableName => 'annual_targets';

  TextColumn get id => text()();
  TextColumn get householdId => text()();
  TextColumn get title => text()();
  IntColumn get targetPaise => integer()();
  TextColumn get type => text().withDefault(const Constant('income'))(); // 'income' | 'expense'

  @override
  Set<Column> get primaryKey => {id};
}

// ─── Users (Authentication & Persistence) ──────────────────────────────────
class UsersTable extends Table {
  @override
  String get tableName => 'users';

  TextColumn get id => text()();
  TextColumn get email => text()();
  TextColumn get password => text().nullable()();
  TextColumn get displayName => text()();
  TextColumn get householdId => text()();
  TextColumn get authProvider => text().withDefault(const Constant('email'))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

