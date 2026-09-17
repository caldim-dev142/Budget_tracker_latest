/**
 * HTTP-level e2e checks (no database): Fastify + global ValidationPipe + guards, with services mocked.
 * Run with: npm run test:e2e
 */
import { Test } from '@nestjs/testing';
import { ValidationPipe, ExecutionContext } from '@nestjs/common';
import { FastifyAdapter, NestFastifyApplication } from '@nestjs/platform-fastify';

jest.mock('firebase-admin/app', () => ({ initializeApp: jest.fn(), cert: jest.fn(), getApps: jest.fn(() => [{}]) }));
jest.mock('firebase-admin/auth', () => ({ getAuth: jest.fn(() => ({ verifyIdToken: jest.fn() })) }));

import { AuthController } from '../src/auth/auth.controller';
import { AuthService } from '../src/auth/auth.service';
import { BudgetsController } from '../src/budgets/budgets.controller';
import { BudgetsService } from '../src/budgets/budgets.service';
import { JwtAuthGuard } from '../src/auth/guards/jwt-auth.guard';
import { AccountsController } from '../src/accounts/accounts.controller';
import { AccountsService } from '../src/accounts/accounts.service';
import { HouseholdsController } from '../src/households/households.controller';
import { HouseholdsService } from '../src/households/households.service';

describe('HTTP e2e (mocked services)', () => {
  let app: NestFastifyApplication;
  let currentUser: any;
  const authService = { refresh: jest.fn().mockResolvedValue({ accessToken: 'a' }), logout: jest.fn() };
  const budgetsService = { findByMonth: jest.fn().mockResolvedValue([]), upsertBulk: jest.fn().mockResolvedValue([]) };
  const ok = () => jest.fn().mockResolvedValue({});
  const accountsService = { findAll: ok(), createAccount: ok(), updateBalance: ok() };
  const householdsService = { create: ok(), join: ok(), findMe: ok(), updateName: ok(), removeMember: ok(), deleteHousehold: ok() };

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      controllers: [AuthController, BudgetsController, AccountsController, HouseholdsController],
      providers: [
        { provide: AuthService, useValue: authService },
        { provide: BudgetsService, useValue: budgetsService },
        { provide: AccountsService, useValue: accountsService },
        { provide: HouseholdsService, useValue: householdsService },
      ],
    })
      .overrideGuard(JwtAuthGuard)
      .useValue({ canActivate: (c: ExecutionContext) => { c.switchToHttp().getRequest().user = currentUser; return true; } })
      .compile();

    app = moduleRef.createNestApplication<NestFastifyApplication>(new FastifyAdapter());
    app.useGlobalPipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true,
      transformOptions: { enableImplicitConversion: true } }));
    await app.init();
    await app.getHttpAdapter().getInstance().ready();
  });
  afterAll(async () => app.close());
  beforeEach(() => { currentUser = { userId: 'u1', householdId: 'hh-A' }; jest.clearAllMocks(); });

  it('POST /auth/refresh rejects a missing token (400) and passes the raw token through', async () => {
    let res = await app.inject({ method: 'POST', url: '/auth/refresh', payload: { userId: 'u1' } });
    expect(res.statusCode).toBe(400);
    res = await app.inject({ method: 'POST', url: '/auth/refresh', payload: { userId: 'u1', refreshToken: 'RAW', family: 'f' } });
    expect(res.statusCode).toBe(200);
    expect(authService.refresh).toHaveBeenCalledWith('u1', 'RAW', 'f');
  });

  it('household-scoped route rejects a user without household (403)', async () => {
    currentUser = { userId: 'u1', householdId: null };
    const res = await app.inject({ method: 'GET', url: '/budgets?yearMonth=2026-09' });
    expect(res.statusCode).toBe(403);
    expect(budgetsService.findByMonth).not.toHaveBeenCalled();
  });

  it('account type must be bank or cash; numeric name/type are not coerced to strings (400)', async () => {
    let res = await app.inject({ method: 'POST', url: '/accounts', payload: { name: 'T', type: 'hacker', balancePaise: 0 } });
    expect(res.statusCode).toBe(400);
    res = await app.inject({ method: 'POST', url: '/accounts', payload: { name: 12345, type: 'bank', balancePaise: 0 } });
    expect(res.statusCode).toBe(400);
    res = await app.inject({ method: 'POST', url: '/accounts', payload: { name: 'Main', type: 'cash', balancePaise: 0 } });
    expect(res.statusCode).toBe(201);
  });

  it('household join/rename reject non-string values (400) and accept strings', async () => {
    let res = await app.inject({ method: 'POST', url: '/households/join', payload: { householdId: 12345 } });
    expect(res.statusCode).toBe(400);
    res = await app.inject({ method: 'PATCH', url: '/households/me', payload: { name: 12345 } });
    expect(res.statusCode).toBe(400);
    res = await app.inject({ method: 'PATCH', url: '/households/me', payload: { name: 'Home' } });
    expect(res.statusCode).toBeLessThan(300);
  });

  it('POST /auth/refresh rejects a numeric token (400)', async () => {
    const res = await app.inject({ method: 'POST', url: '/auth/refresh', payload: { userId: 'u1', refreshToken: 12345, family: 'f' } });
    expect(res.statusCode).toBe(400);
  });

  it('invalid yearMonth is 400', async () => {
    const res = await app.inject({ method: 'GET', url: '/budgets?yearMonth=2026-13' });
    expect(res.statusCode).toBe(400);
  });

  it('bulk budgets rejects fractional / unknown fields (400)', async () => {
    let res = await app.inject({ method: 'POST', url: '/budgets/bulk?yearMonth=2026-09', payload: [{ categoryId: 'c', amountPaise: 1.5 }] });
    expect(res.statusCode).toBe(400);
    res = await app.inject({ method: 'POST', url: '/budgets/bulk?yearMonth=2026-09', payload: [{ categoryId: 'c', amountPaise: 1, householdId: 'hh-B' }] });
    expect(res.statusCode).toBe(400);
    res = await app.inject({ method: 'POST', url: '/budgets/bulk?yearMonth=2026-09', payload: [{ categoryId: 'c', amountPaise: 100 }] });
    expect(res.statusCode).toBe(201);
    expect(budgetsService.upsertBulk).toHaveBeenCalledWith('hh-A', '2026-09', [expect.objectContaining({ categoryId: 'c', amountPaise: 100 })]);
  });
});
