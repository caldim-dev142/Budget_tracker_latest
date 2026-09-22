import { CategoriesService } from './categories.service';
import { seedCategories } from './categories-seed.data';

describe('CategoriesService', () => {
  let service: CategoriesService;
  let prismaMock: any;

  const householdId = 'household-123';

  beforeEach(() => {
    prismaMock = {
      category: {
        count: jest.fn(),
        findMany: jest.fn(),
        createMany: jest.fn(),
      },
    };

    service = new CategoriesService(prismaMock);
  });

  describe('findAll', () => {
    it('automatically seeds household categories when count is 0, then returns categories', async () => {
      prismaMock.category.count.mockResolvedValue(0);
      prismaMock.category.createMany.mockResolvedValue({ count: seedCategories.length });

      const mockCategories = [
        {
          id: `${householdId}-inc-01`,
          householdId,
          name: 'Person 1 Salary & Allowance',
          kind: 'income',
          sortOrder: 1,
          archivedAt: null,
        },
      ];
      prismaMock.category.findMany.mockResolvedValue(mockCategories);

      const result = await service.findAll(householdId);

      expect(prismaMock.category.count).toHaveBeenCalledWith({ where: { householdId } });
      expect(prismaMock.category.createMany).toHaveBeenCalledTimes(1);
      expect(prismaMock.category.createMany).toHaveBeenCalledWith({
        data: expect.arrayContaining([
          expect.objectContaining({
            id: `${householdId}-inc-01`,
            householdId,
            kind: 'income',
            name: 'Person 1 Salary & Allowance',
          }),
        ]),
        skipDuplicates: true,
      });

      expect(prismaMock.category.findMany).toHaveBeenCalledWith({
        where: { householdId, archivedAt: null },
        orderBy: { sortOrder: 'asc' },
      });
      expect(result).toEqual(mockCategories);
    });

    it('does not re-seed when categories already exist (count > 0), returning existing categories', async () => {
      prismaMock.category.count.mockResolvedValue(45);

      const existingCategories = [
        {
          id: `${householdId}-spd-01`,
          householdId,
          name: 'Groceries',
          kind: 'spending',
          sortOrder: 1,
          archivedAt: null,
        },
      ];
      prismaMock.category.findMany.mockResolvedValue(existingCategories);

      const result = await service.findAll(householdId);

      expect(prismaMock.category.count).toHaveBeenCalledWith({ where: { householdId } });
      expect(prismaMock.category.createMany).not.toHaveBeenCalled();
      expect(prismaMock.category.findMany).toHaveBeenCalledWith({
        where: { householdId, archivedAt: null },
        orderBy: { sortOrder: 'asc' },
      });
      expect(result).toEqual(existingCategories);
    });
  });

  describe('seedHouseholdCategories', () => {
    it('maps all seedCategories with prefixed IDs and householdId, calling createMany with skipDuplicates', async () => {
      prismaMock.category.createMany.mockResolvedValue({ count: seedCategories.length });

      await service.seedHouseholdCategories(householdId);

      expect(prismaMock.category.createMany).toHaveBeenCalledTimes(1);

      const callArgs = prismaMock.category.createMany.mock.calls[0][0];
      expect(callArgs.skipDuplicates).toBe(true);
      expect(callArgs.data).toHaveLength(seedCategories.length);

      // Verify the first seed category mapping
      const firstSeed = seedCategories[0];
      const firstMapped = callArgs.data[0];
      expect(firstMapped).toEqual({
        id: `${householdId}-${firstSeed.id}`,
        householdId,
        kind: firstSeed.kind,
        groupCode: firstSeed.groupCode ?? null,
        name: firstSeed.name,
        needOrWant: firstSeed.needOrWant ?? null,
        isDeduction: firstSeed.isDeduction,
        isSystem: firstSeed.isSystem,
        sortOrder: firstSeed.sortOrder,
      });
    });
  });
});
