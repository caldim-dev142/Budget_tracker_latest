const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function check() {
  const entries = await prisma.entry.findMany({
    orderBy: { createdAt: 'desc' },
    take: 10,
  });
  console.log(`=== TOP 10 RECENT ENTRIES ===`);
  console.table(entries.map(e => ({
    id: e.id,
    householdId: e.householdId,
    amountRupees: (Number(e.amountPaise) / 100).toFixed(2),
    kind: e.kind,
    note: e.note,
    entryDate: e.entryDate.toISOString().split('T')[0],
    createdAt: e.createdAt.toISOString(),
  })));
}

check().catch(console.error).finally(() => prisma.$disconnect());
