import { NotFoundException, ForbiddenException } from '@nestjs/common';
import { CardsService } from './cards.service';

describe('CardsService', () => {
  let service: CardsService;
  let prismaMock: any;

  const householdId = 'household-123';
  const otherHouseholdId = 'household-999';
  const cardId = 'card-xyz';

  beforeEach(() => {
    prismaMock = {
      creditCard: {
        findMany: jest.fn(),
        create: jest.fn(),
        findUnique: jest.fn(),
      },
      cardTransaction: {
        create: jest.fn(),
      },
    };

    service = new CardsService(prismaMock);
  });

  describe('findAll', () => {
    it('scopes query to householdId and isActive: true, including transactions', async () => {
      prismaMock.creditCard.findMany.mockResolvedValue([
        {
          id: 'card-1',
          householdId,
          name: 'HDFC Regalia',
          previousOutstandingPaise: BigInt(50000), // ₹500
          isActive: true,
          transactions: [
            { id: 'txn-1', cardId: 'card-1', amountPaise: BigInt(20000), description: 'Dinner' }, // +₹200 (spend)
            { id: 'txn-2', cardId: 'card-1', amountPaise: BigInt(15000), description: 'Groceries' }, // +₹150 (spend)
            { id: 'txn-3', cardId: 'card-1', amountPaise: BigInt(-30000), description: 'Bill payment' }, // -₹300 (pay)
          ],
        },
        {
          id: 'card-2',
          householdId,
          name: 'ICICI Amazon Pay',
          previousOutstandingPaise: BigInt(10000), // ₹100
          isActive: true,
          transactions: [], // No transactions this month
        },
      ]);

      const cards = await service.findAll(householdId);

      expect(prismaMock.creditCard.findMany).toHaveBeenCalledTimes(1);
      expect(prismaMock.creditCard.findMany).toHaveBeenCalledWith({
        where: { householdId, isActive: true },
        include: { transactions: true },
      });

      expect(cards).toHaveLength(2);

      // Card 1: prev=50000, spend=35000, pay=-30000 => outstanding=55000, delta=5000
      const card1 = cards[0];
      expect(card1.id).toBe('card-1');
      expect(card1.name).toBe('HDFC Regalia');
      expect(card1.previousOutstandingPaise).toBe(50000);
      expect(card1.currentOutstandingPaise).toBe(55000);
      expect(card1.monthDeltaPaise).toBe(5000);
      expect(card1.transactions).toHaveLength(3);
      expect(card1.transactions[0].amountPaise).toBe(20000);
      expect(typeof card1.transactions[0].amountPaise).toBe('number');
      expect(card1.transactions[1].amountPaise).toBe(15000);
      expect(card1.transactions[2].amountPaise).toBe(-30000);

      // Card 2: prev=10000, no txns => outstanding=10000, delta=0
      const card2 = cards[1];
      expect(card2.id).toBe('card-2');
      expect(card2.name).toBe('ICICI Amazon Pay');
      expect(card2.previousOutstandingPaise).toBe(10000);
      expect(card2.currentOutstandingPaise).toBe(10000);
      expect(card2.monthDeltaPaise).toBe(0);
      expect(card2.transactions).toEqual([]);
    });

    it('returns an empty array when no active cards exist for the household', async () => {
      prismaMock.creditCard.findMany.mockResolvedValue([]);

      const cards = await service.findAll(householdId);

      expect(prismaMock.creditCard.findMany).toHaveBeenCalledWith({
        where: { householdId, isActive: true },
        include: { transactions: true },
      });
      expect(cards).toEqual([]);
    });

    it('correctly handles payments exceeding spending and previous balance', async () => {
      prismaMock.creditCard.findMany.mockResolvedValue([
        {
          id: 'card-credit',
          householdId,
          name: 'Overpaid Card',
          previousOutstandingPaise: 20000,
          isActive: true,
          transactions: [
            { id: 'txn-overpay', cardId: 'card-credit', amountPaise: -50000, description: 'Refund' },
          ],
        },
      ]);

      const cards = await service.findAll(householdId);

      // prev=20000, pay=-50000 => outstanding = -30000, delta = -50000
      expect(cards[0].previousOutstandingPaise).toBe(20000);
      expect(cards[0].currentOutstandingPaise).toBe(-30000);
      expect(cards[0].monthDeltaPaise).toBe(-50000);
    });
  });

  describe('createCard', () => {
    it('creates a credit card scoped to householdId and rounds previousOutstandingPaise', async () => {
      const createdRecord = {
        id: 'new-card-1',
        householdId,
        name: 'Axis Bank Card',
        previousOutstandingPaise: 45679,
      };
      prismaMock.creditCard.create.mockResolvedValue(createdRecord);

      const result = await service.createCard(householdId, 'Axis Bank Card', 45678.6);

      expect(prismaMock.creditCard.create).toHaveBeenCalledTimes(1);
      expect(prismaMock.creditCard.create).toHaveBeenCalledWith({
        data: {
          householdId,
          name: 'Axis Bank Card',
          previousOutstandingPaise: 45679, // Math.round(45678.6)
        },
      });
      expect(result).toEqual(createdRecord);
    });

    it('handles zero previous outstanding amount', async () => {
      const createdRecord = {
        id: 'new-card-2',
        householdId,
        name: 'Clean Card',
        previousOutstandingPaise: 0,
      };
      prismaMock.creditCard.create.mockResolvedValue(createdRecord);

      const result = await service.createCard(householdId, 'Clean Card', 0);

      expect(prismaMock.creditCard.create).toHaveBeenCalledWith({
        data: {
          householdId,
          name: 'Clean Card',
          previousOutstandingPaise: 0,
        },
      });
      expect(result).toEqual(createdRecord);
    });
  });

  describe('addTransaction', () => {
    it('adds a transaction to a card belonging to the household, rounding amountPaise', async () => {
      prismaMock.creditCard.findUnique.mockResolvedValue({
        id: cardId,
        householdId,
        name: 'HDFC Regalia',
      });

      const createdTxn = {
        id: 'txn-new',
        cardId,
        description: 'Fuel',
        amountPaise: 250000,
        txnDate: new Date(),
      };
      prismaMock.cardTransaction.create.mockResolvedValue(createdTxn);

      const result = await service.addTransaction(householdId, cardId, 'Fuel', 250000.4);

      expect(prismaMock.creditCard.findUnique).toHaveBeenCalledWith({ where: { id: cardId } });
      expect(prismaMock.cardTransaction.create).toHaveBeenCalledWith({
        data: {
          cardId,
          description: 'Fuel',
          amountPaise: 250000, // Math.round(250000.4)
          txnDate: expect.any(Date),
        },
      });
      expect(result).toEqual(createdTxn);
    });

    it('throws NotFoundException when the credit card does not exist', async () => {
      prismaMock.creditCard.findUnique.mockResolvedValue(null);

      await expect(
        service.addTransaction(householdId, 'non-existent-card', 'Coffee', 15000),
      ).rejects.toThrow(new NotFoundException('Credit card not found.'));

      expect(prismaMock.cardTransaction.create).not.toHaveBeenCalled();
    });

    it('throws ForbiddenException when card belongs to a different household (cross-tenant rejection)', async () => {
      prismaMock.creditCard.findUnique.mockResolvedValue({
        id: cardId,
        householdId: otherHouseholdId,
        name: 'Other Household Card',
      });

      await expect(
        service.addTransaction(householdId, cardId, 'Unauthorized Charge', 50000),
      ).rejects.toThrow(ForbiddenException);

      expect(prismaMock.cardTransaction.create).not.toHaveBeenCalled();
    });
  });
});
