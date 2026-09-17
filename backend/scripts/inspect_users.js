const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function check() {
  const users = await prisma.user.findMany();
  const households = await prisma.household.findMany();
  const hhMap = new Map(households.map(h => [h.id, h.name]));

  console.log('=== USERS ===');
  console.table(users.map(u => ({
    id: u.id,
    email: u.email,
    displayName: u.displayName,
    householdId: u.household_id,
    householdName: hhMap.get(u.household_id) || 'N/A',
    createdAt: u.createdAt,
  })));

  const syncQueues = await prisma.sync_queue.findMany({
    orderBy: { created_at: 'desc' },
    take: 20
  });
  console.log('=== LATEST SYNC QUEUE ENTRIES IN BACKEND ===');
  console.table(syncQueues.map(s => ({
    id: s.id,
    entity_type: s.entity_type,
    operation: s.operation,
    created_at: s.created_at,
    household_id: s.household_id,
  })));
}

check().catch(console.error).finally(() => prisma.$disconnect());
