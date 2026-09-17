import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function run() {
  const households = await prisma.household.findMany();
  console.log('--- Households ---');
  for (const h of households) {
    console.log(`ID: ${h.id}, Name: ${h.name}, OwnerId: ${h.ownerId}`);
  }

  const users = await prisma.user.findMany();
  console.log('\n--- Users ---');
  for (const u of users) {
    console.log(`ID: ${u.id}, Email: ${u.email}, Household: ${u.household_id}`);
  }

  console.log('\n--- Table Counts ---');
  console.log('Households:       ', await prisma.household.count());
  console.log('Users:            ', await prisma.user.count());
  console.log('Categories:       ', await prisma.category.count());
  console.log('Accounts:         ', await prisma.account.count());
  console.log('Annual Targets:   ', await prisma.annual_targets.count());
  console.log('Sync Queue:        ', await prisma.sync_queue.count());
  console.log('Budgets:          ', await prisma.budget.count());
  console.log('Credit Cards:     ', await prisma.creditCard.count());
  console.log('Card Transactions:', await prisma.cardTransaction.count());
  console.log('Entries:          ', await prisma.entry.count());
  console.log('Sinking Funds:    ', await prisma.sinkingFund.count());
  console.log('Fund Movements:   ', await prisma.fundMovement.count());
  console.log('Saving Goals:     ', await prisma.savingGoal.count());
  console.log('Goal Contributions:', await prisma.goalContribution.count());
  console.log('Planned Bills:    ', await prisma.plannedBill.count());
  console.log('Receivables:      ', await prisma.receivable.count());
  console.log('Reserve Lines:    ', await prisma.reserveLine.count());
  console.log('Month Snapshots:  ', await prisma.monthSnapshot.count());
}

run()
  .catch((e) => console.error(e))
  .finally(() => prisma.$disconnect());
