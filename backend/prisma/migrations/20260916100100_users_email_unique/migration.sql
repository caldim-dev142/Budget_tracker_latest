-- DEF-AUTH-04: users.email must be unique (docs/DATABASE_SCHEMA.md: "NOT NULL, UNIQUE").
-- Fails loudly (instead of silently skipping) if duplicate rows already exist; such accounts must be
-- reviewed and merged manually before this migration can be applied.
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM "users" GROUP BY "email" HAVING COUNT(*) > 1) THEN
    RAISE EXCEPTION 'users.email has duplicate values. Resolve duplicate accounts before applying migration 20260916100100_users_email_unique.';
  END IF;
END $$;

CREATE UNIQUE INDEX "users_email_key" ON "users"("email");
