-- DEF-FIN-01: approved adjustment sign rule (docs/FINANCIAL_WATERFALL_ENGINE.md §4, 4 add / 2 subtract).
-- The backend seed created "Lending/Return(-)" (adj-05) and "Others(Outflow)" (adj-06) with
-- is_deduction = false. Correct the metadata of those seeded categories only.
-- NOTE: month snapshots that were already closed are NOT recalculated by this migration.
UPDATE "categories"
SET "is_deduction" = true
WHERE "kind" = 'adjustment'
  AND "is_system" = false
  AND "is_deduction" = false
  AND "id" ~ '-adj-0[56]$';
