const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function check() {
  const cards = await prisma.creditCard.findMany();
  console.log('=== ALL CREDIT CARDS IN DATABASE ===');
  console.table(
    cards.map((c) => ({
      ID: c.id,
      Household: c.householdId,
      Name: c.name,
      'Outstanding (INR)': '₹' + (Number(c.previousOutstandingPaise) / 100).toFixed(0),
      Active: c.isActive,
    })),
  );

  const accounts = await prisma.account.findMany();
  console.log('\n=== ALL ACCOUNTS IN DATABASE ===');
  console.table(
    accounts.map((a) => ({
      ID: a.id,
      Household: a.householdId,
      Name: a.name,
      Type: a.type,
      'Balance (INR)': '₹' + (Number(a.currentBalancePaise) / 100).toFixed(0),
    })),
  );
}

check()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
