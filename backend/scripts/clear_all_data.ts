import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('🗑️  Clearing all data from the database...\n');

  // Delete in child-first order to respect FK constraints
  const sq  = await prisma.sync_queue.deleteMany();
  const at  = await prisma.annual_targets.deleteMany();
  const rl  = await prisma.reserveLine.deleteMany();
  const pb  = await prisma.plannedBill.deleteMany();
  const rec = await prisma.receivable.deleteMany();
  const ct  = await prisma.cardTransaction.deleteMany();
  const cc  = await prisma.creditCard.deleteMany();
  const gc  = await prisma.goalContribution.deleteMany();
  const sg  = await prisma.savingGoal.deleteMany();
  const fm  = await prisma.fundMovement.deleteMany();
  const sf  = await prisma.sinkingFund.deleteMany();
  const ms  = await prisma.monthSnapshot.deleteMany();
  const en  = await prisma.entry.deleteMany();
  const bu  = await prisma.budget.deleteMany();
  const ca  = await prisma.category.deleteMany();
  const ac  = await prisma.account.deleteMany();
  const hh  = await prisma.household.deleteMany();
  const us  = await prisma.user.deleteMany();

  console.log(`  sync_queue       : ${sq.count} rows deleted`);
  console.log(`  annual_targets   : ${at.count} rows deleted`);
  console.log(`  reserve_lines    : ${rl.count} rows deleted`);
  console.log(`  planned_bills    : ${pb.count} rows deleted`);
  console.log(`  receivables      : ${rec.count} rows deleted`);
  console.log(`  card_transactions: ${ct.count} rows deleted`);
  console.log(`  credit_cards     : ${cc.count} rows deleted`);
  console.log(`  goal_contributions:${gc.count} rows deleted`);
  console.log(`  saving_goals     : ${sg.count} rows deleted`);
  console.log(`  fund_movements   : ${fm.count} rows deleted`);
  console.log(`  sinking_funds    : ${sf.count} rows deleted`);
  console.log(`  month_snapshots  : ${ms.count} rows deleted`);
  console.log(`  entries          : ${en.count} rows deleted`);
  console.log(`  budgets          : ${bu.count} rows deleted`);
  console.log(`  categories       : ${ca.count} rows deleted`);
  console.log(`  accounts         : ${ac.count} rows deleted`);
  console.log(`  households       : ${hh.count} rows deleted`);
  console.log(`  users            : ${us.count} rows deleted`);

  console.log('\n✅ All data cleared. Schema and tables are intact.');
}

main()
  .catch((e) => {
    console.error('❌ Clear failed:', e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
