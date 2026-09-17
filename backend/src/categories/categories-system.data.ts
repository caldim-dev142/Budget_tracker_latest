/**
 * System categories required by the borrow/lending and planning settlement flows.
 *
 * These 4 categories are INTERNAL — they are created with isSystem=true and are never
 * shown in the user-facing category picker. They are referenced programmatically by
 * the DAO layer when entries are created for:
 *   - Money lent out (receivables)
 *   - Borrowed money (planned bills)
 *   - Bill payment (when planned bill is marked paid)
 *   - Money returned back (when receivable is marked returned)
 *
 * IDs are scoped per household: `{householdId}-{suffix}`
 */
export interface SystemCategory {
  idSuffix: string;   // appended to householdId to form the full category id
  kind: string;
  name: string;
  isDeduction: boolean;
  sortOrder: number;
}

export const systemCategories: SystemCategory[] = [
  {
    idSuffix: 'lend-system-cat',
    kind: 'adjustment',
    name: 'Money Lent Out',
    isDeduction: true,
    sortOrder: 9990,
  },
  {
    idSuffix: 'borrow-system-cat',
    kind: 'adjustment',
    name: 'Borrowed Money',
    isDeduction: false,
    sortOrder: 9991,
  },
  {
    idSuffix: 'bill-pay-system-cat',
    kind: 'spending',
    name: 'Bill Payment',
    isDeduction: false,
    sortOrder: 9992,
  },
  {
    idSuffix: 'return-received-system-cat',
    kind: 'adjustment',
    name: 'Money Returned Back',
    isDeduction: false,
    sortOrder: 9993,
  },
];

/**
 * Build the full Prisma data objects for system categories for a given household.
 * Safe to pass directly to prisma.category.createMany({ skipDuplicates: true }).
 */
export function buildSystemCategoriesForHousehold(householdId: string) {
  return systemCategories.map((sc) => ({
    id: `${householdId}-${sc.idSuffix}`,
    householdId,
    kind: sc.kind,
    groupCode: null,
    name: sc.name,
    needOrWant: null,
    isDeduction: sc.isDeduction,
    isSystem: true,
    sortOrder: sc.sortOrder,
  }));
}
