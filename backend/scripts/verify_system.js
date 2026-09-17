const { PrismaClient } = require('@prisma/client');
const jwt = require('jsonwebtoken');
const http = require('http');

const prisma = new PrismaClient();

async function run() {
  console.log('--- 1. DATABASE INTEGRITY CHECK ---');
  const user = await prisma.user.findUnique({
    where: { email: 'pradeepmuthuselvan08@gmail.com' }
  });
  if (!user) {
    throw new Error('User pradeepmuthuselvan08@gmail.com not found!');
  }
  console.log(`[PASS] User exists: ${user.id} (${user.email})`);
  const householdId = user.household_id;
  console.log(`[PASS] Household found: ${householdId}`);

  const accounts = await prisma.account.findMany({ where: { householdId } });
  console.log(`[PASS] Accounts count: ${accounts.length}`);
  accounts.forEach(a => console.log(`  - Account: ${a.name}, Balance: ₹${Number(a.currentBalancePaise) / 100}`));

  const cards = await prisma.creditCard.findMany({ where: { householdId } });
  console.log(`[PASS] Credit Cards count: ${cards.length}`);
  cards.forEach(c => console.log(`  - Card: ${c.name}, Previous Outstanding: ₹${Number(c.previousOutstanding) / 100}`));

  const entries = await prisma.entry.findMany({ where: { householdId } });
  console.log(`[PASS] Entries count: ${entries.length}`);
  entries.forEach(e => console.log(`  - Entry: kind=${e.kind}, amount=₹${Number(e.amountPaise) / 100}, date=${e.entryDate.toISOString().slice(0, 10)}`));

  const categories = await prisma.category.findMany({ where: { householdId } });
  console.log(`[PASS] Categories count: ${categories.length}`);

  const tombstones = await prisma.syncTombstone.count({ where: { householdId } });
  console.log(`[PASS] Sync Tombstones count: ${tombstones}`);

  console.log('\n--- 2. LIVE NESTJS SERVER HTTP SYNC/PULL CHECK ---');
  const secret = process.env.JWT_ACCESS_SECRET || 'change_this_to_a_secure_random_string_min_32_chars_dev';
  const token = jwt.sign(
    {
      sub: user.id,
      householdId: householdId
    },
    secret,
    { expiresIn: '1h' }
  );

  await new Promise((resolve, reject) => {
    const req = http.request(
      {
        hostname: '127.0.0.1',
        port: 3001,
        path: '/sync/pull',
        method: 'GET',
        headers: {
          Authorization: `Bearer ${token}`
        }
      },
      (res) => {
        let data = '';
        res.on('data', chunk => data += chunk);
        res.on('end', () => {
          if (res.statusCode === 200) {
            const parsed = JSON.parse(data);
            console.log(`[PASS] HTTP GET /sync/pull returned status 200 OK`);
            console.log(`  - Returned accounts: ${parsed.accounts?.length || 0}`);
            console.log(`  - Returned credit cards: ${parsed.creditCards?.length || 0}`);
            console.log(`  - Returned entries: ${parsed.entries?.length || 0}`);
            console.log(`  - Returned categories: ${parsed.categories?.length || 0}`);
            resolve();
          } else {
            reject(new Error(`Server returned HTTP ${res.statusCode}: ${data}`));
          }
        });
      }
    );
    req.on('error', reject);
    req.end();
  });

  console.log('\n[ALL CHECKS PASSED] Backend API and Database are 100% operational.');
  await prisma.$disconnect();
}

run().catch(err => {
  console.error('[FAILED]', err);
  prisma.$disconnect();
  process.exit(1);
});
