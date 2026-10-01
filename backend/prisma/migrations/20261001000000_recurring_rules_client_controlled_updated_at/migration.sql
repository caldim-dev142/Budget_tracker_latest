-- Migration: 20261001000000_recurring_rules_client_controlled_updated_at
-- No DDL changes. Documents that recurring_rules.updated_at is now
-- client-controlled for last-write-wins (LWW) sync.
-- The @updatedAt Prisma directive was removed from the schema; the column
-- definition itself is unchanged. The application layer now supplies the
-- correct updated_at value on every upsert.
--
-- The DEFAULT NOW() on the column remains as a safety net for raw SQL inserts.

-- No SQL statements needed. This is a Prisma schema behaviour change only.
SELECT 1; -- Prisma requires at least one statement.
