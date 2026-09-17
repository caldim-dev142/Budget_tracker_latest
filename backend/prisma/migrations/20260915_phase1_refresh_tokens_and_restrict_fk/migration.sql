ALTER TABLE "budgets" DROP CONSTRAINT IF EXISTS "budgets_category_id_fkey";
ALTER TABLE "entries" DROP CONSTRAINT IF EXISTS "entries_category_id_fkey";
CREATE TABLE IF NOT EXISTS "refresh_tokens" ("id" TEXT NOT NULL, "user_id" TEXT NOT NULL, "token_hash" TEXT NOT NULL, "family" TEXT NOT NULL, "used_at" TIMESTAMPTZ(6), "expires_at" TIMESTAMPTZ(6) NOT NULL, "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP, CONSTRAINT "refresh_tokens_pkey" PRIMARY KEY ("id"));
CREATE UNIQUE INDEX IF NOT EXISTS "refresh_tokens_token_hash_key" ON "refresh_tokens"("token_hash");
CREATE INDEX IF NOT EXISTS "refresh_tokens_user_id_idx" ON "refresh_tokens"("user_id");
CREATE INDEX IF NOT EXISTS "refresh_tokens_family_idx" ON "refresh_tokens"("family");
ALTER TABLE "entries" ADD CONSTRAINT "entries_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "categories"("id") ON DELETE RESTRICT ON UPDATE NO ACTION;
ALTER TABLE "budgets" ADD CONSTRAINT "budgets_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "categories"("id") ON DELETE RESTRICT ON UPDATE NO ACTION;
ALTER TABLE "refresh_tokens" ADD CONSTRAINT "refresh_tokens_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;