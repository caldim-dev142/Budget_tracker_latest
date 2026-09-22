import 'dotenv/config';
import { PrismaClient } from '@prisma/client';
import { v4 as uuidv4 } from 'uuid';

describe('D5 — Live Database Foreign Key Constraint Enforcement', () => {
  let prisma: PrismaClient;
  let testHouseholdId: string;
  let testCategoryId: string;

  beforeAll(async () => {
    prisma = new PrismaClient();
    await prisma.$connect();

    // Create a dedicated valid household and category for testing foreign keys
    testHouseholdId = `fk-test-hsh-${uuidv4()}`;
    await prisma.household.create({
      data: {
        id: testHouseholdId,
        name: 'FK Test Household',
        ownerId: `fk-owner-${uuidv4()}`,
      },
    });

    testCategoryId = `fk-test-cat-${uuidv4()}`;
    await prisma.category.create({
      data: {
        id: testCategoryId,
        householdId: testHouseholdId,
        kind: 'expense',
        name: 'FK Test Category',
      },
    });
  });

  afterAll(async () => {
    try {
      // Clean up test records
      await prisma.entry.deleteMany({ where: { householdId: testHouseholdId } });
      await prisma.category.deleteMany({ where: { id: testCategoryId } });
      await prisma.household.deleteMany({ where: { id: testHouseholdId } });
    } catch (e) {
      // Ignore cleanup error if already removed
    } finally {
      await prisma.$disconnect();
    }
  });

  it('rejects entry insert with non-existent household_id against live database', async () => {
    const invalidHouseholdId = `non-existent-hsh-${uuidv4()}`;

    await expect(
      prisma.entry.create({
        data: {
          id: `entry-${uuidv4()}`,
          householdId: invalidHouseholdId,
          categoryId: testCategoryId,
          kind: 'expense',
          entryDate: new Date(),
          amountPaise: BigInt(50000),
          createdBy: 'test-user',
        },
      }),
    ).rejects.toMatchObject({
      code: 'P2003', // Prisma error for foreign key constraint violation
    });
  });

  it('rejects entry insert with non-existent account_id against live database', async () => {
    const invalidAccountId = `non-existent-acc-${uuidv4()}`;

    await expect(
      prisma.entry.create({
        data: {
          id: `entry-${uuidv4()}`,
          householdId: testHouseholdId,
          categoryId: testCategoryId,
          accountId: invalidAccountId,
          kind: 'expense',
          entryDate: new Date(),
          amountPaise: BigInt(50000),
          createdBy: 'test-user',
        },
      }),
    ).rejects.toMatchObject({
      code: 'P2003',
    });
  });

  it('rejects entry insert with non-existent card_id against live database', async () => {
    const invalidCardId = `non-existent-card-${uuidv4()}`;

    await expect(
      prisma.entry.create({
        data: {
          id: `entry-${uuidv4()}`,
          householdId: testHouseholdId,
          categoryId: testCategoryId,
          cardId: invalidCardId,
          kind: 'expense',
          entryDate: new Date(),
          amountPaise: BigInt(50000),
          createdBy: 'test-user',
        },
      }),
    ).rejects.toMatchObject({
      code: 'P2003',
    });
  });

  it('rejects account insert with non-existent household_id against live database', async () => {
    const invalidHouseholdId = `non-existent-hsh-${uuidv4()}`;

    await expect(
      prisma.account.create({
        data: {
          id: `acc-${uuidv4()}`,
          householdId: invalidHouseholdId,
          name: 'Invalid Account',
          type: 'bank',
        },
      }),
    ).rejects.toMatchObject({
      code: 'P2003',
    });
  });

  it('rejects credit_card insert with non-existent household_id against live database', async () => {
    const invalidHouseholdId = `non-existent-hsh-${uuidv4()}`;

    await expect(
      prisma.creditCard.create({
        data: {
          id: `card-${uuidv4()}`,
          householdId: invalidHouseholdId,
          name: 'Invalid Card',
        },
      }),
    ).rejects.toMatchObject({
      code: 'P2003',
    });
  });
});
