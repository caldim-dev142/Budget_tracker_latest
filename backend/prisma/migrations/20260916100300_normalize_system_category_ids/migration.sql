-- DEF-FIN-02: Flutter system category ids ('lend-system-cat-{householdId}') were previously
-- prefixed by the server into '{householdId}-lend-system-cat-{householdId}' and auto-created as
-- ordinary (is_deduction = false) categories. Re-point those rows to the canonical backend system
-- categories '{householdId}-{suffix}-system-cat' (backend/src/categories/categories-system.data.ts).

-- 1. Make sure the canonical system category exists for every affected household.
WITH d("suffix", "kind", "name", "is_deduction", "sort_order") AS (VALUES
  ('lend', 'adjustment', 'Money Lent Out', true, 9990),
  ('borrow', 'adjustment', 'Borrowed Money', false, 9991),
  ('bill-pay', 'spending', 'Bill Payment', false, 9992),
  ('return-received', 'adjustment', 'Money Returned Back', false, 9993))
INSERT INTO "categories" ("id", "household_id", "kind", "name", "is_deduction", "is_system", "sort_order")
SELECT DISTINCT r."household_id" || '-' || d."suffix" || '-system-cat', r."household_id", d."kind", d."name", d."is_deduction", true, d."sort_order"
FROM (
  SELECT "household_id", "category_id" FROM "entries"
  UNION SELECT "household_id", "category_id" FROM "budgets"
) r
JOIN d
  ON r."category_id" = r."household_id" || '-' || d."suffix" || '-system-cat-' || r."household_id"
ON CONFLICT ("id") DO NOTHING;

-- 2. Re-point entries and budgets.
WITH d("suffix", "kind", "name", "is_deduction", "sort_order") AS (VALUES
  ('lend', 'adjustment', 'Money Lent Out', true, 9990),
  ('borrow', 'adjustment', 'Borrowed Money', false, 9991),
  ('bill-pay', 'spending', 'Bill Payment', false, 9992),
  ('return-received', 'adjustment', 'Money Returned Back', false, 9993))
UPDATE "entries" e
SET "category_id" = e."household_id" || '-' || d."suffix" || '-system-cat'
FROM d
WHERE e."category_id" = e."household_id" || '-' || d."suffix" || '-system-cat-' || e."household_id";

WITH d("suffix", "kind", "name", "is_deduction", "sort_order") AS (VALUES
  ('lend', 'adjustment', 'Money Lent Out', true, 9990),
  ('borrow', 'adjustment', 'Borrowed Money', false, 9991),
  ('bill-pay', 'spending', 'Bill Payment', false, 9992),
  ('return-received', 'adjustment', 'Money Returned Back', false, 9993))
UPDATE "budgets" b
SET "category_id" = b."household_id" || '-' || d."suffix" || '-system-cat'
FROM d
WHERE b."category_id" = b."household_id" || '-' || d."suffix" || '-system-cat-' || b."household_id";

-- 3. Remove the now-unreferenced alias categories (never referenced rows only).
WITH d("suffix", "kind", "name", "is_deduction", "sort_order") AS (VALUES
  ('lend', 'adjustment', 'Money Lent Out', true, 9990),
  ('borrow', 'adjustment', 'Borrowed Money', false, 9991),
  ('bill-pay', 'spending', 'Bill Payment', false, 9992),
  ('return-received', 'adjustment', 'Money Returned Back', false, 9993))
DELETE FROM "categories" c
USING d
WHERE (c."id" = c."household_id" || '-' || d."suffix" || '-system-cat-' || c."household_id"
       OR c."id" = d."suffix" || '-system-cat-' || c."household_id")
  AND NOT EXISTS (SELECT 1 FROM "entries" e WHERE e."category_id" = c."id")
  AND NOT EXISTS (SELECT 1 FROM "budgets" b WHERE b."category_id" = c."id");
