/**
 * One-time cleanup script: removes default "Savings Account" and "Cash Wallet"
 * accounts that were auto-seeded by older versions of the app.
 *
 * Run from the backend directory:
 *   npx ts-node src/cleanup_default_accounts.ts
 *
 * This is safe to run multiple times (idempotent).
 */
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  const deleted = await prisma.account.deleteMany({
    where: {
      name: {
        in: ['Savings Account', 'Cash Wallet'],
      },
    },
  });

  console.log(`✅ Deleted ${deleted.count} default account(s) (Savings Account / Cash Wallet).`);
  console.log('Users can now create their own accounts manually in Accounts & Institutions.');
}

main()
  .catch((e) => {
    console.error('❌ Cleanup failed:', e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
