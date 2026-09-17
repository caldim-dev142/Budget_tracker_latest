const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function test() {
  const householdId = 'f596b3e3-5110-4008-b2b1-dedcd699f717';
  console.log('Testing credit card sync for household', householdId);

  // Check if credit card exists
  const existing = await prisma.creditCard.findMany({
    where: { householdId }
  });
  console.log('Existing cards for household:', existing);
}

test().catch(console.error).finally(() => prisma.$disconnect());
