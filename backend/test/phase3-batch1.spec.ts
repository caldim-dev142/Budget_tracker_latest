import fs from 'fs';
import path from 'path';

jest.mock('firebase-admin/app', () => ({
  initializeApp: jest.fn(),
  cert: jest.fn(),
  getApps: jest.fn(() => [{ name: 'DEFAULT' }]),
}));

jest.mock('firebase-admin/auth', () => ({
  getAuth: jest.fn(() => ({
    verifyIdToken: jest.fn(),
  })),
}));

import { AuthService } from '../src/auth/auth.service';

describe('Phase 3 Batch 1 — D2, D5, D7, D8 Verification', () => {
  describe('D7 — Swallowed Bootstrap Failures & Transactional Registration', () => {
    let authService: AuthService;
    let mockPrisma: any;
    let mockTx: any;
    let mockJwt: any;
    let mockConfig: any;
    let mockFirebase: any;

    beforeEach(() => {
      mockTx = {
        household: {
          create: jest.fn().mockResolvedValue({ id: 'hsh-1', name: "Alice's Household", ownerId: 'usr-1' }),
          upsert: jest.fn().mockResolvedValue({ id: 'hsh-1' }),
        },
        user: {
          create: jest.fn().mockResolvedValue({
            id: 'usr-1',
            email: 'alice@example.com',
            displayName: 'Alice',
            household_id: 'hsh-1',
          }),
        },
        category: {
          createMany: jest.fn().mockResolvedValue({ count: 20 }),
        },
      };

      mockPrisma = {
        $transaction: jest.fn().mockImplementation(async (callback) => {
          return callback(mockTx);
        }),
        user: {
          findUnique: jest.fn().mockResolvedValue(null),
          findFirst: jest.fn().mockResolvedValue(null),
        },
        refreshToken: {
          create: jest.fn().mockResolvedValue({ id: 'rt-1' }),
        },
      };

      mockJwt = {
        sign: jest.fn().mockReturnValue('mock-jwt-token'),
        signAsync: jest.fn().mockResolvedValue('mock-jwt-token'),
      };

      mockConfig = {
        get: jest.fn((key: string, defaultValue?: string) => {
          if (key === 'JWT_ACCESS_EXPIRY') return '15m';
          if (key === 'JWT_REFRESH_EXPIRY') return '30d';
          return defaultValue;
        }),
      };

      mockFirebase = {
        verifyIdToken: jest.fn(),
      };

      authService = new AuthService(
        mockPrisma,
        mockJwt,
        mockConfig,
        mockFirebase,
      );
    });

    it('rolls back and throws when category seeding fails during registration (never swallows error)', async () => {
      // Simulate transient DB error during category createMany
      mockTx.category.createMany.mockRejectedValueOnce(
        new Error('Connection lost during category seeding'),
      );

      await expect(
        authService.register({
          email: 'alice@example.com',
          password: 'Password123!',
          displayName: 'Alice',
          householdName: "Alice's Household",
        }),
      ).rejects.toThrow('Connection lost during category seeding');

      // Verify transaction was used to wrap household, user, and category creation
      expect(mockPrisma.$transaction).toHaveBeenCalledTimes(1);
      expect(mockTx.household.create).toHaveBeenCalledTimes(1);
      expect(mockTx.user.create).toHaveBeenCalledTimes(1);
      expect(mockTx.category.createMany).toHaveBeenCalled();
    });

    it('successfully commits user, household, and all categories when seeding succeeds', async () => {
      const result = await authService.register({
        email: 'alice@example.com',
        password: 'Password123!',
        displayName: 'Alice',
        householdName: "Alice's Household",
      });

      expect(mockPrisma.$transaction).toHaveBeenCalledTimes(1);
      expect(mockTx.household.create).toHaveBeenCalledTimes(1);
      expect(mockTx.user.create).toHaveBeenCalledTimes(1);
      // Both default and system categories seeded
      expect(mockTx.category.createMany).toHaveBeenCalledTimes(2);

      expect(result).toBeDefined();
      expect(result.user.email).toBe('alice@example.com');
      expect(result.accessToken).toBe('mock-jwt-token');
    });
  });

  describe('D2 & D5 — Schema & Migration Definitions', () => {
    const schemaPath = path.join(__dirname, '..', 'prisma', 'schema.prisma');
    const migrationPath = path.join(
      __dirname,
      '..',
      'prisma',
      'migrations',
      '20260921123000_indexes_and_foreign_keys',
      'migration.sql',
    );

    it('defines householdId index and ON DELETE RESTRICT on all tenant models in schema.prisma', () => {
      const schema = fs.readFileSync(schemaPath, 'utf8');

      // Check models with householdId
      const tenantModels = [
        'Category',
        'Account',
        'Entry',
        'Budget',
        'SinkingFund',
        'SavingGoal',
        'CreditCard',
        'Receivable',
        'PlannedBill',
        'ReserveLine',
        'annual_targets',
      ];

      for (const model of tenantModels) {
        expect(schema).toContain(`model ${model}`);
        // Model must declare onDelete: Restrict to household
        expect(schema).toMatch(new RegExp(`model ${model}[\\s\\S]*?Household[\\s\\S]*?onDelete: Restrict`));
      }

      // Check composite indexes
      expect(schema).toContain('@@index([householdId, yearMonth])');

      // Check cardId index
      expect(schema).toContain('@@index([cardId])');

      // Check entries foreign key relations
      expect(schema).toMatch(/model Entry[\s\S]*?account\s+Account\?[\s\S]*?onDelete: Restrict/);
      expect(schema).toMatch(/model Entry[\s\S]*?card\s+CreditCard\?[\s\S]*?onDelete: Restrict/);
      expect(schema).toMatch(/model Entry[\s\S]*?parent\s+Entry\?[\s\S]*?onDelete: Restrict/);
    });

    it('contains all required D2 indexes and D5 foreign key constraints in migration.sql', () => {
      const sql = fs.readFileSync(migrationPath, 'utf8');

      // D2 Indexes
      expect(sql).toContain('CREATE INDEX "categories_household_id_idx" ON "categories"("household_id");');
      expect(sql).toContain('CREATE INDEX "entries_household_id_idx" ON "entries"("household_id");');
      expect(sql).toContain('CREATE INDEX "budgets_household_id_year_month_idx" ON "budgets"("household_id", "year_month");');
      expect(sql).toContain('CREATE INDEX "reserve_lines_household_id_year_month_idx" ON "reserve_lines"("household_id", "year_month");');
      expect(sql).toContain('CREATE INDEX "card_transactions_card_id_idx" ON "card_transactions"("card_id");');
      expect(sql).toContain('CREATE INDEX "entries_account_id_idx" ON "entries"("account_id");');
      expect(sql).toContain('CREATE INDEX "entries_card_id_idx" ON "entries"("card_id");');
      expect(sql).toContain('CREATE INDEX "entries_parent_id_idx" ON "entries"("parent_id");');

      // D5 Foreign Keys
      expect(sql).toContain('ALTER TABLE "categories" ADD CONSTRAINT "categories_household_id_fkey"');
      expect(sql).toContain('REFERENCES "households"("id") ON DELETE RESTRICT ON UPDATE NO ACTION;');
      expect(sql).toContain('ALTER TABLE "entries" ADD CONSTRAINT "entries_household_id_fkey"');
      expect(sql).toContain('ALTER TABLE "entries" ADD CONSTRAINT "entries_account_id_fkey"');
      expect(sql).toContain('ALTER TABLE "entries" ADD CONSTRAINT "entries_card_id_fkey"');
      expect(sql).toContain('ALTER TABLE "entries" ADD CONSTRAINT "entries_parent_id_fkey"');
      expect(sql).not.toContain('CASCADE'); // Financial tables must never cascade
    });
  });

  describe('D8 — Deploy Scripts Binding & Documentation', () => {
    it('binds prisma migrate deploy to start:prod, prestart:prod, and predeploy in package.json', () => {
      const pkgPath = path.join(__dirname, '..', 'package.json');
      const pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf8'));

      expect(pkg.scripts.predeploy).toBe('prisma migrate deploy');
      expect(pkg.scripts['prestart:prod']).toBe('prisma migrate deploy');
      expect(pkg.scripts['start:prod']).toContain('prisma migrate deploy');
    });

    it('documents migration lifecycle and production startup in DEPLOY.md', () => {
      const deployMdPath = path.join(__dirname, '..', 'DEPLOY.md');
      expect(fs.existsSync(deployMdPath)).toBe(true);
      const content = fs.readFileSync(deployMdPath, 'utf8');
      expect(content).toContain('prisma migrate deploy');
      expect(content).toContain('prestart:prod');
      expect(content).toContain('start:prod');
    });
  });
});
