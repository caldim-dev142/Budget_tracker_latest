-- DEF-SYNC-07: record when a month was last closed or reopened so devices can order status changes.
ALTER TABLE "month_snapshots" ADD COLUMN IF NOT EXISTS "status_changed_at" TIMESTAMPTZ(6);

-- Existing closed months: the close time is the last status change.
UPDATE "month_snapshots" SET "status_changed_at" = "closed_at"
WHERE "status" = 'closed' AND "status_changed_at" IS NULL;
