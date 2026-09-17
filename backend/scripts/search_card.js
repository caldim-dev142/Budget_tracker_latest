const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function search() {
  const cards = await prisma.creditCard.findMany({
    where: {
      OR: [
        { name: { contains: 'iscc', mode: 'insensitive' } },
        { name: { contains: 'cc', mode: 'insensitive' } },
      ]
    }
  });
  console.log('Cards matching "cc":', cards);

  const allCards = await prisma.creditCard.findMany();
  console.log('All credit cards in DB:');
  console.table(allCards.map(c => ({ id: c.id, householdId: c.householdId, name: c.name, outstanding: Number(c.previousOutstandingPaise) })));
}

search().catch(console.error).finally(() => prisma.$disconnect());
