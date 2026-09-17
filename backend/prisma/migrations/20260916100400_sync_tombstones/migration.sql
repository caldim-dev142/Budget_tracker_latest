-- DEF-SYNC-01: deletion tombstones for entities that devices hard-delete.
CREATE TABLE "sync_tombstones" (
    "id" TEXT NOT NULL,
    "household_id" TEXT NOT NULL,
    "entity" TEXT NOT NULL,
    "entity_id" TEXT NOT NULL,
    "deleted_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "sync_tombstones_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "sync_tombstones_entity_entity_id_key" ON "sync_tombstones"("entity", "entity_id");
CREATE INDEX "sync_tombstones_household_id_idx" ON "sync_tombstones"("household_id");
