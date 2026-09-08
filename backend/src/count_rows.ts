import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('Querying Supabase database tables...');
  
  try {
    const userCount = await prisma.user.count();
    const entryCount = await prisma.entry.count();
    const categoryCount = await prisma.category.count();
    const accountCount = await prisma.account.count();
    const cardCount = await prisma.creditCard.count();

    console.log('\n--- ROW COUNTS ---');
    console.log(`Users: ${userCount}`);
    console.log(`Entries (Transactions): ${entryCount}`);
    console.log(`Categories: ${categoryCount}`);
    console.log(`Accounts: ${accountCount}`);
    console.log(`Credit Cards: ${cardCount}`);
    console.log('-------------------\n');

  } catch (error) {
    console.error('Error querying database:', error);
  } finally {
    await prisma.$disconnect();
  }
}

main();
