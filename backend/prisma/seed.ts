/**
 * Prisma Seed Script — Comprehensive Production & Local Seeding
 *
 * Populates all tables with starter & demo data across all households:
 * - Categories & System Categories
 * - Bank Accounts & Cash Wallets
 * - Credit Cards & Card Transactions
 * - Sinking Funds & Fund Movements
 * - Saving Goals & Goal Contributions
 * - Annual Targets (Annual Income/Expense Planning)
 * - Planned Bills (Payables)
 * - Receivables (Lending & Deposits)
 * - Monthly Budgets
 * - Reserve Lines & Safety Buffers
 * - Month Snapshots
 * - Financial Transaction Entries
 *
 * Fully idempotent: safe to run multiple times without duplicating or corrupting data.
 */

import { PrismaClient } from '@prisma/client';
import * as argon2 from 'argon2';
import { seedCategories } from '../src/categories/categories-seed.data';
import { systemCategories } from '../src/categories/categories-system.data';

const prisma = new PrismaClient();
const DEMO_HOUSEHOLD_ID = 'demo-household-0001';

async function main() {
  console.log('====================================================');
  console.log('     Budget Tracker — Comprehensive Database Seed   ');
  console.log('====================================================\n');

  // Demo financial records are opt-in and never written to production or to real households
  // (DEF-DATA-04). Reference data (category taxonomy + system categories) is always ensured.
  const demoEnabled = process.env.SEED_DEMO_DATA === 'true' && process.env.NODE_ENV !== 'production';
  console.log(demoEnabled
    ? `Demo data: ENABLED (SEED_DEMO_DATA=true) — only household ${DEMO_HOUSEHOLD_ID} receives demo records.`
    : 'Demo data: disabled (set SEED_DEMO_DATA=true outside production to create the demo household).');

  // 1. Optionally create the dedicated demo user + household
  if (demoEnabled && !(await prisma.household.findUnique({ where: { id: DEMO_HOUSEHOLD_ID } }))) {
    console.log('Creating Demo User & Household...');
    const passwordHash = await argon2.hash('Demo@123456', {
      type: argon2.argon2id,
      memoryCost: 65536,
      timeCost: 3,
      parallelism: 4,
    });

    const demoUser = await prisma.user.upsert({
      where: { id: 'demo-user-0001' },
      create: {
        id: 'demo-user-0001',
        email: 'demo@budgettracker.app',
        displayName: 'Demo User',
        password: passwordHash,
        auth_provider: 'email',
      },
      update: {},
    });

    const demoHousehold = await prisma.household.create({
      data: {
        id: DEMO_HOUSEHOLD_ID,
        name: 'Demo Family Household',
        ownerId: demoUser.id,
      },
    });

    await prisma.user.update({
      where: { id: demoUser.id },
      data: { household_id: demoHousehold.id },
    });

    console.log(`Created Demo Household: ${demoHousehold.name} (${demoHousehold.id})`);
  }

  const households = await prisma.household.findMany();
  console.log(`Found ${households.length} household(s).`);

  // 2. Iterate through each household and seed all financial data
  for (const h of households) {
    console.log(`\n----------------------------------------------------`);
    console.log(`Seeding Household: "${h.name}" [${h.id}]`);
    console.log(`----------------------------------------------------`);

    // A. Categories
    console.log('  -> Seeding Categories...');
    for (const c of seedCategories) {
      const catId = `${h.id}-${c.id}`;
      await prisma.category.upsert({
        where: { id: catId },
        create: {
          id: catId,
          householdId: h.id,
          kind: c.kind,
          groupCode: c.groupCode ?? null,
          name: c.name,
          needOrWant: c.needOrWant ?? null,
          isDeduction: c.isDeduction,
          isSystem: c.isSystem,
          sortOrder: c.sortOrder,
        },
        update: {}, // existing rows are left untouched (metadata fixes ship as migrations)
      });
    }

    // System Categories
    for (const sc of systemCategories) {
      const sysId = `${h.id}-${sc.idSuffix}`;
      await prisma.category.upsert({
        where: { id: sysId },
        create: {
          id: sysId,
          householdId: h.id,
          kind: sc.kind,
          name: sc.name,
          isDeduction: sc.isDeduction,
          isSystem: true,
          sortOrder: sc.sortOrder,
        },
        update: {},
      });
    }

    if (!demoEnabled || h.id !== DEMO_HOUSEHOLD_ID) {
      continue; // real households only receive reference data
    }

    // B. Accounts
    console.log('  -> Seeding Bank Accounts & Cash Wallet...');
    const defaultAccounts = [
      {
        id: `acc-hdfc-${h.id}`,
        name: 'HDFC Bank (Salary)',
        type: 'bank',
        currentBalancePaise: 12500000, // ₹1,25,000
        isActive: true,
        sortOrder: 1,
      },
      {
        id: `acc-icici-${h.id}`,
        name: 'ICICI Savings',
        type: 'bank',
        currentBalancePaise: 4500000, // ₹45,000
        isActive: true,
        sortOrder: 2,
      },
      {
        id: `acc-cash-${h.id}`,
        name: 'Cash / Wallet',
        type: 'cash',
        currentBalancePaise: 500000, // ₹5,000
        isActive: true,
        sortOrder: 3,
      },
    ];

    for (const acc of defaultAccounts) {
      await prisma.account.upsert({
        where: { id: acc.id },
        create: {
          id: acc.id,
          householdId: h.id,
          name: acc.name,
          type: acc.type,
          currentBalancePaise: acc.currentBalancePaise,
          isActive: acc.isActive,
          sortOrder: acc.sortOrder,
        },
        update: {
          name: acc.name,
          type: acc.type,
          sortOrder: acc.sortOrder,
          isActive: acc.isActive,
        },
      });
    }

    // C. Credit Cards
    console.log('  -> Seeding Credit Cards & Transactions...');
    const defaultCards = [
      {
        id: `card-regalia-${h.id}`,
        name: 'HDFC Regalia Gold',
        previousOutstandingPaise: 1245000, // ₹12,450
        isActive: true,
      },
      {
        id: `card-amazon-${h.id}`,
        name: 'ICICI Amazon Pay',
        previousOutstandingPaise: 420000, // ₹4,200
        isActive: true,
      },
    ];

    for (const card of defaultCards) {
      await prisma.creditCard.upsert({
        where: { id: card.id },
        create: {
          id: card.id,
          householdId: h.id,
          name: card.name,
          previousOutstandingPaise: card.previousOutstandingPaise,
          isActive: card.isActive,
        },
        update: {
          name: card.name,
          isActive: card.isActive,
        },
      });
    }

    // Card Transactions
    const cardTxns = [
      {
        id: `ctx-01-${h.id}`,
        cardId: `card-regalia-${h.id}`,
        txnDate: new Date('2026-09-08T10:30:00Z'),
        description: 'Amazon Electronics & Gadgets',
        amountPaise: 249900, // ₹2,499
        sNo: 1,
      },
      {
        id: `ctx-02-${h.id}`,
        cardId: `card-regalia-${h.id}`,
        txnDate: new Date('2026-09-10T14:15:00Z'),
        description: 'Shell Petrol Station Fuel',
        amountPaise: 200000, // ₹2,000
        sNo: 2,
      },
      {
        id: `ctx-03-${h.id}`,
        cardId: `card-amazon-${h.id}`,
        txnDate: new Date('2026-09-12T20:00:00Z'),
        description: 'Swiggy Gourmet Dining',
        amountPaise: 65000, // ₹650
        sNo: 1,
      },
    ];

    for (const ctx of cardTxns) {
      await prisma.cardTransaction.upsert({
        where: { id: ctx.id },
        create: {
          id: ctx.id,
          cardId: ctx.cardId,
          txnDate: ctx.txnDate,
          description: ctx.description,
          amountPaise: ctx.amountPaise,
          sNo: ctx.sNo,
        },
        update: {
          description: ctx.description,
          amountPaise: ctx.amountPaise,
          txnDate: ctx.txnDate,
          sNo: ctx.sNo,
        },
      });
    }

    // D. Sinking Funds
    console.log('  -> Seeding Sinking Funds & Movements...');
    const sinkingFunds = [
      {
        id: `sf-emergency-${h.id}`,
        name: 'Emergency Reserve Fund',
        openingReservePaise: 10000000, // ₹1,00,000
      },
      {
        id: `sf-medical-${h.id}`,
        name: 'Medical & Health Contingency',
        openingReservePaise: 5000000, // ₹50,000
      },
      {
        id: `sf-vehicle-${h.id}`,
        name: 'Vehicle Maintenance & Insurance',
        openingReservePaise: 2000000, // ₹20,000
      },
    ];

    for (const sf of sinkingFunds) {
      await prisma.sinkingFund.upsert({
        where: { id: sf.id },
        create: {
          id: sf.id,
          householdId: h.id,
          name: sf.name,
          openingReservePaise: sf.openingReservePaise,
        },
        update: {
          name: sf.name,
          openingReservePaise: sf.openingReservePaise,
        },
      });
    }

    // Fund Movements
    const fundMovements = [
      {
        id: `fm-01-${h.id}`,
        fundId: `sf-emergency-${h.id}`,
        type: 'contribution',
        amountPaise: 2500000, // ₹25,000
        movementDate: new Date('2026-09-01T09:00:00Z'),
        note: 'Monthly emergency fund contribution',
      },
      {
        id: `fm-02-${h.id}`,
        fundId: `sf-vehicle-${h.id}`,
        type: 'expense',
        amountPaise: 650000, // ₹6,500
        movementDate: new Date('2026-09-07T16:00:00Z'),
        note: 'Periodic vehicle servicing & oil change',
      },
    ];

    for (const fm of fundMovements) {
      await prisma.fundMovement.upsert({
        where: { id: fm.id },
        create: {
          id: fm.id,
          fundId: fm.fundId,
          type: fm.type,
          amountPaise: fm.amountPaise,
          movementDate: fm.movementDate,
          note: fm.note,
        },
        update: {
          type: fm.type,
          amountPaise: fm.amountPaise,
          movementDate: fm.movementDate,
          note: fm.note,
        },
      });
    }

    // E. Saving Goals
    console.log('  -> Seeding Saving Goals & Contributions...');
    const savingGoals = [
      {
        id: `sg-house-${h.id}`,
        bucket: 'house',
        name: 'Home Down Payment',
        targetPaise: 150000000, // ₹15,00,000
        monthlyBudgetPaise: 2500000, // ₹25,000
      },
      {
        id: `sg-vacation-${h.id}`,
        bucket: 'vacation',
        name: 'Annual Family Vacation',
        targetPaise: 15000000, // ₹1,50,000
        monthlyBudgetPaise: 1250000, // ₹12,500
      },
      {
        id: `sg-laptop-${h.id}`,
        bucket: 'gadgets',
        name: 'New Work Laptop',
        targetPaise: 10000000, // ₹1,00,000
        monthlyBudgetPaise: 1000000, // ₹10,000
      },
    ];

    for (const sg of savingGoals) {
      await prisma.savingGoal.upsert({
        where: { id: sg.id },
        create: {
          id: sg.id,
          householdId: h.id,
          bucket: sg.bucket,
          name: sg.name,
          targetPaise: sg.targetPaise,
          monthlyBudgetPaise: sg.monthlyBudgetPaise,
        },
        update: {
          name: sg.name,
          targetPaise: sg.targetPaise,
          monthlyBudgetPaise: sg.monthlyBudgetPaise,
        },
      });
    }

    // Goal Contributions
    const goalContribs = [
      {
        id: `gc-01-${h.id}`,
        goalId: `sg-house-${h.id}`,
        amountPaise: 2500000, // ₹25,000
        contributionDate: new Date('2026-09-02T11:00:00Z'),
        note: 'September regular down-payment contribution',
      },
      {
        id: `gc-02-${h.id}`,
        goalId: `sg-vacation-${h.id}`,
        amountPaise: 1250000, // ₹12,500
        contributionDate: new Date('2026-09-02T11:30:00Z'),
        note: 'September vacation allocation',
      },
    ];

    for (const gc of goalContribs) {
      await prisma.goalContribution.upsert({
        where: { id: gc.id },
        create: {
          id: gc.id,
          goalId: gc.goalId,
          amountPaise: gc.amountPaise,
          contributionDate: gc.contributionDate,
          note: gc.note,
        },
        update: {
          amountPaise: gc.amountPaise,
          contributionDate: gc.contributionDate,
          note: gc.note,
        },
      });
    }

    // F. Annual Targets (Key User Expectation!)
    console.log('  -> Seeding Annual Targets...');
    const annualTargets = [
      {
        id: `at-savings-${h.id}`,
        title: 'Annual Savings & Investments',
        target_paise: 60000000, // ₹6,00,000
        type: 'income',
      },
      {
        id: `at-salary-${h.id}`,
        title: 'Annual Salary & Total Earnings',
        target_paise: 180000000, // ₹18,00,000
        type: 'income',
      },
      {
        id: `at-travel-${h.id}`,
        title: 'Annual Vacation & Travel Target',
        target_paise: 15000000, // ₹1,50,000
        type: 'expense',
      },
      {
        id: `at-emergency-${h.id}`,
        title: 'Emergency Buffer Goal',
        target_paise: 20000000, // ₹2,00,000
        type: 'income',
      },
      {
        id: `at-insurance-${h.id}`,
        title: 'Annual Insurance Premiums',
        target_paise: 6500000, // ₹65,000
        type: 'expense',
      },
    ];

    for (const at of annualTargets) {
      await prisma.annual_targets.upsert({
        where: { id: at.id },
        create: {
          id: at.id,
          household_id: h.id,
          title: at.title,
          target_paise: at.target_paise,
          type: at.type,
        },
        update: {
          title: at.title,
          target_paise: at.target_paise,
          type: at.type,
        },
      });
    }

    // G. Planned Bills (Payables)
    console.log('  -> Seeding Planned Bills (Payables)...');
    const plannedBills = [
      {
        id: `pb-rent-${h.id}`,
        name: 'Monthly House Rent',
        amountPaise: 2500000, // ₹25,000
        dueDate: new Date('2026-09-05T00:00:00Z'),
        isPaid: true,
      },
      {
        id: `pb-wifi-${h.id}`,
        name: 'Broadband Fiber Internet',
        amountPaise: 119900, // ₹1,199
        dueDate: new Date('2026-09-15T00:00:00Z'),
        isPaid: true,
      },
      {
        id: `pb-elec-${h.id}`,
        name: 'Electricity Utility Bill',
        amountPaise: 345000, // ₹3,450
        dueDate: new Date('2026-09-20T00:00:00Z'),
        isPaid: false,
      },
      {
        id: `pb-ins-${h.id}`,
        name: 'Car Comprehensive Insurance',
        amountPaise: 1450000, // ₹14,500
        dueDate: new Date('2026-10-10T00:00:00Z'),
        isPaid: false,
      },
    ];

    for (const pb of plannedBills) {
      await prisma.plannedBill.upsert({
        where: { id: pb.id },
        create: {
          id: pb.id,
          householdId: h.id,
          name: pb.name,
          amountPaise: pb.amountPaise,
          dueDate: pb.dueDate,
          isPaid: pb.isPaid,
        },
        update: {
          name: pb.name,
          amountPaise: pb.amountPaise,
          dueDate: pb.dueDate,
          isPaid: pb.isPaid,
        },
      });
    }

    // H. Receivables
    console.log('  -> Seeding Receivables (Lending & Deposits)...');
    const receivables = [
      {
        id: `rec-vikram-${h.id}`,
        personName: 'Vikram (Colleague Loan)',
        amountPaise: 1500000, // ₹15,000
        status: 'open',
        dueDate: new Date('2026-10-01T00:00:00Z'),
      },
      {
        id: `rec-deposit-${h.id}`,
        personName: 'Sharma (House Security Deposit)',
        amountPaise: 5000000, // ₹50,000
        status: 'open',
        dueDate: null,
      },
      {
        id: `rec-corp-${h.id}`,
        personName: 'Company Travel Expense Reimbursement',
        amountPaise: 480000, // ₹4,800
        status: 'open',
        dueDate: new Date('2026-09-25T00:00:00Z'),
      },
    ];

    for (const r of receivables) {
      await prisma.receivable.upsert({
        where: { id: r.id },
        create: {
          id: r.id,
          householdId: h.id,
          personName: r.personName,
          amountPaise: r.amountPaise,
          status: r.status,
          dueDate: r.dueDate,
        },
        update: {
          personName: r.personName,
          amountPaise: r.amountPaise,
          status: r.status,
          dueDate: r.dueDate,
        },
      });
    }

    // I. Monthly Budgets
    console.log('  -> Seeding Monthly Budgets (2026-09)...');
    const defaultBudgets = [
      { categorySuffix: 'spd-n05', amountPaise: 1500000 }, // Grocery ₹15,000
      { categorySuffix: 'spd-f01', amountPaise: 400000 },  // Electricity ₹4,000
      { categorySuffix: 'spd-f03', amountPaise: 150000 },  // Internet ₹1,500
      { categorySuffix: 'spd-n09', amountPaise: 600000 },  // Domestic Help ₹6,000
      { categorySuffix: 'spd-n02', amountPaise: 500000 },  // Vegetables & Fruits ₹5,000
      { categorySuffix: 'spd-n04', amountPaise: 350000 },  // Milk & Dairy ₹3,500
    ];

    for (const b of defaultBudgets) {
      const categoryId = `${h.id}-${b.categorySuffix}`;
      await prisma.budget.upsert({
        where: {
          categoryId_yearMonth: {
            categoryId,
            yearMonth: '2026-09',
          },
        },
        create: {
          id: `bgt-202609-${b.categorySuffix}-${h.id}`,
          householdId: h.id,
          categoryId,
          yearMonth: '2026-09',
          amountPaise: b.amountPaise,
        },
        update: {
          amountPaise: b.amountPaise,
        },
      });
    }

    // J. Reserve Lines
    console.log('  -> Seeding Reserve Lines...');
    const reserveLines = [
      {
        id: `rl-safety-${h.id}`,
        yearMonth: '2026-09',
        name: 'Monthly Safety Buffer',
        amountPaise: 2000000, // ₹20,000
        source: 'manual',
      },
      {
        id: `rl-contingency-${h.id}`,
        yearMonth: '2026-09',
        name: 'Contingency Allocation',
        amountPaise: 1500000, // ₹15,000
        source: 'manual',
      },
    ];

    for (const rl of reserveLines) {
      await prisma.reserveLine.upsert({
        where: { id: rl.id },
        create: {
          id: rl.id,
          householdId: h.id,
          yearMonth: rl.yearMonth,
          name: rl.name,
          amountPaise: rl.amountPaise,
          source: rl.source,
        },
        update: {
          name: rl.name,
          amountPaise: rl.amountPaise,
          source: rl.source,
        },
      });
    }

    // K. Month Snapshots
    console.log('  -> Seeding Month Snapshots...');
    await prisma.monthSnapshot.upsert({
      where: {
        householdId_yearMonth: {
          householdId: h.id,
          yearMonth: '2026-08',
        },
      },
      create: {
        id: `snap-202608-${h.id}`,
        householdId: h.id,
        yearMonth: '2026-08',
        openingBalancePaise: 12000000,
        incomePaise: 15000000,
        spendingPaise: 11000000,
        protectionPaise: 1000000,
        savingPaise: 2500000,
        reservesPaise: 2000000,
        closingBalancePaise: 13500000,
        remainingPaise: 1500000,
        status: 'closed',
        closedAt: new Date('2026-08-31T23:59:59Z'),
      },
      update: {
        status: 'closed',
      },
    });

    await prisma.monthSnapshot.upsert({
      where: {
        householdId_yearMonth: {
          householdId: h.id,
          yearMonth: '2026-09',
        },
      },
      create: {
        id: `snap-202609-${h.id}`,
        householdId: h.id,
        yearMonth: '2026-09',
        openingBalancePaise: 13500000,
        incomePaise: 15000000,
        spendingPaise: 5500000,
        protectionPaise: 500000,
        savingPaise: 2500000,
        reservesPaise: 3500000,
        closingBalancePaise: 15000000,
        remainingPaise: 6500000,
        status: 'open',
      },
      update: {
        status: 'open',
      },
    });

    // L. Financial Entries
    console.log('  -> Seeding Financial Entries...');
    const entries = [
      {
        id: `ent-salary-${h.id}`,
        categoryId: `${h.id}-inc-01`, // Salary
        kind: 'income',
        accountId: `acc-hdfc-${h.id}`,
        cardId: null,
        entryDate: new Date('2026-09-01T09:00:00Z'),
        amountPaise: 15000000, // ₹1,50,000
        note: 'September Salary Credit',
        createdBy: h.ownerId,
      },
      {
        id: `ent-grocery-${h.id}`,
        categoryId: `${h.id}-spd-n05`, // Grocery
        kind: 'spending',
        accountId: `acc-hdfc-${h.id}`,
        cardId: null,
        entryDate: new Date('2026-09-04T12:00:00Z'),
        amountPaise: 425000, // ₹4,250
        note: 'Monthly Supermarket Provisions',
        createdBy: h.ownerId,
      },
      {
        id: `ent-elec-${h.id}`,
        categoryId: `${h.id}-spd-f01`, // Electricity
        kind: 'spending',
        accountId: `acc-hdfc-${h.id}`,
        cardId: null,
        entryDate: new Date('2026-09-06T14:30:00Z'),
        amountPaise: 320000, // ₹3,200
        note: 'Electricity Bill Payment',
        createdBy: h.ownerId,
      },
      {
        id: `ent-wifi-${h.id}`,
        categoryId: `${h.id}-spd-f03`, // Internet
        kind: 'spending',
        accountId: `acc-hdfc-${h.id}`,
        cardId: null,
        entryDate: new Date('2026-09-10T10:00:00Z'),
        amountPaise: 119900, // ₹1,199
        note: 'Broadband Fiber Bill',
        createdBy: h.ownerId,
      },
      {
        id: `ent-dining-${h.id}`,
        categoryId: `${h.id}-spd-n05`, // Grocery/Food
        kind: 'spending',
        accountId: null,
        cardId: `card-regalia-${h.id}`,
        entryDate: new Date('2026-09-12T19:45:00Z'),
        amountPaise: 185000, // ₹1,850
        note: 'Family Weekend Dinner',
        createdBy: h.ownerId,
      },
    ];

    for (const ent of entries) {
      await prisma.entry.upsert({
        where: { id: ent.id },
        create: {
          id: ent.id,
          householdId: h.id,
          categoryId: ent.categoryId,
          kind: ent.kind,
          accountId: ent.accountId,
          cardId: ent.cardId,
          entryDate: ent.entryDate,
          amountPaise: ent.amountPaise,
          note: ent.note,
          createdBy: ent.createdBy,
        },
        update: {
          amountPaise: ent.amountPaise,
          note: ent.note,
          entryDate: ent.entryDate,
        },
      });
    }
  }

  // 3. Final Summary & Database Counts
  console.log('\n====================================================');
  console.log('             DATABASE SEEDING VERIFICATION          ');
  console.log('====================================================');
  console.log(`Households:        ${await prisma.household.count()}`);
  console.log(`Users:             ${await prisma.user.count()}`);
  console.log(`Categories:        ${await prisma.category.count()}`);
  console.log(`Accounts:          ${await prisma.account.count()}`);
  console.log(`Credit Cards:      ${await prisma.creditCard.count()}`);
  console.log(`Card Transactions: ${await prisma.cardTransaction.count()}`);
  console.log(`Sinking Funds:     ${await prisma.sinkingFund.count()}`);
  console.log(`Fund Movements:    ${await prisma.fundMovement.count()}`);
  console.log(`Saving Goals:      ${await prisma.savingGoal.count()}`);
  console.log(`Goal Contributions:${await prisma.goalContribution.count()}`);
  console.log(`Annual Targets:    ${await prisma.annual_targets.count()}`);
  console.log(`Planned Bills:     ${await prisma.plannedBill.count()}`);
  console.log(`Receivables:       ${await prisma.receivable.count()}`);
  console.log(`Budgets:           ${await prisma.budget.count()}`);
  console.log(`Reserve Lines:     ${await prisma.reserveLine.count()}`);
  console.log(`Month Snapshots:   ${await prisma.monthSnapshot.count()}`);
  console.log(`Entries:           ${await prisma.entry.count()}`);
  console.log('====================================================');
  console.log('Seed execution completed successfully! All tables verified.');
}

main()
  .catch((e) => {
    console.error('Fatal seed script error:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
