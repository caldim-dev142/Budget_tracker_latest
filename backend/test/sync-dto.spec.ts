import 'reflect-metadata';
import { validate } from 'class-validator';
import { plainToInstance } from 'class-transformer';
import {
  SyncBatchDto,
  SyncCategoryDto,
  SyncCardTransactionDto,
  SyncPlannedBillDto,
} from '../src/sync/dto/sync-batch.dto';

describe('Phase 2 — SyncBatchDto class-validator Validation', () => {
  it('1. Valid sync batch payload passes validation with zero errors', async () => {
    const rawPayload = {
      categories: [
        {
          id: 'cat-1',
          kind: 'spending',
          name: 'Groceries',
          needOrWant: 'need',
          sortOrder: 1,
        },
      ],
      cardTransactions: [
        {
          id: 'txn-1',
          cardId: 'card-1',
          txnDate: '2026-09-15T10:00:00.000Z',
          description: 'Supermarket',
          amountPaise: 120000,
        },
      ],
      plannedBills: [
        {
          id: 'bill-1',
          name: 'Internet',
          amountPaise: 99900,
          dueDate: '2026-09-20T00:00:00.000Z',
          isPaid: false,
        },
      ],
    };

    const instance = plainToInstance(SyncBatchDto, rawPayload);
    const errors = await validate(instance);
    expect(errors).toHaveLength(0);
  });

  it('2. Rejects malformed txnDate with invalid date string format', async () => {
    const rawTxn = {
      id: 'txn-1',
      cardId: 'card-1',
      txnDate: 'invalid-date-not-iso',
      description: 'Test',
      amountPaise: 5000,
    };

    const instance = plainToInstance(SyncCardTransactionDto, rawTxn);
    const errors = await validate(instance);
    expect(errors.length).toBeGreaterThan(0);
    expect(errors[0].property).toBe('txnDate');
  });

  it('3. Rejects missing required id or name in planned bill', async () => {
    const rawBill = {
      amountPaise: 5000,
    };

    const instance = plainToInstance(SyncPlannedBillDto, rawBill);
    const errors = await validate(instance);
    const errorProperties = errors.map((e) => e.property);
    expect(errorProperties).toContain('id');
    expect(errorProperties).toContain('name');
  });

  it('4. Rejects nested invalid object inside SyncBatchDto', async () => {
    const rawPayload = {
      categories: [
        {
          id: 'cat-1',
          // missing required kind and name
        },
      ],
    };

    const instance = plainToInstance(SyncBatchDto, rawPayload);
    const errors = await validate(instance);
    expect(errors.length).toBeGreaterThan(0);
    expect(errors[0].property).toBe('categories');
  });
});
