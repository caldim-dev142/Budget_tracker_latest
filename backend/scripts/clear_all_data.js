const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function safeDelete(name, fn) {
  try {
    const res = await fn();
    console.log(`  ${name.padEnd(20)}: ${res.count} rows deleted`);
  } catch (e) {
    if (e.code === 'P2021') {
      console.log(`  ${name.padEnd(20)}: table does not exist (skipped)`);
    } else {
      console.warn(`  ${name.padEnd(20)}: warning - ${e.message}`);
    }
  }
}

async function main() {
  console.log('🗑️  Clearing all data from the database...\n');

  // Delete in child-first order to respect FK constraints
  await safeDelete('refresh_tokens', () => prisma.refreshToken.deleteMany());
  await safeDelete('sync_tombstones', () => prisma.syncTombstone.deleteMany());
  await safeDelete('sync_queue', () => prisma.sync_queue.deleteMany());
  await safeDelete('annual_targets', () => prisma.annual_targets.deleteMany());
  await safeDelete('reserve_lines', () => prisma.reserveLine.deleteMany());
  await safeDelete('planned_bills', () => prisma.plannedBill.deleteMany());
  await safeDelete('receivables', () => prisma.receivable.deleteMany());
  await safeDelete('card_transactions', () => prisma.cardTransaction.deleteMany());
  await safeDelete('credit_cards', () => prisma.creditCard.deleteMany());
  await safeDelete('goal_contributions', () => prisma.goalContribution.deleteMany());
  await safeDelete('saving_goals', () => prisma.savingGoal.deleteMany());
  await safeDelete('fund_movements', () => prisma.fundMovement.deleteMany());
  await safeDelete('sinking_funds', () => prisma.sinkingFund.deleteMany());
  await safeDelete('month_snapshots', () => prisma.monthSnapshot.deleteMany());
  await safeDelete('entries', () => prisma.entry.deleteMany());
  await safeDelete('budgets', () => prisma.budget.deleteMany());
  await safeDelete('categories', () => prisma.category.deleteMany());
  await safeDelete('accounts', () => prisma.account.deleteMany());
  await safeDelete('users', () => prisma.user.deleteMany());
  await safeDelete('households', () => prisma.household.deleteMany());

  console.log('\n✅ All database data has been completely cleared. Schema and tables are intact.');
}

main()
  .catch((e) => {
    console.error('❌ Clear failed:', e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
