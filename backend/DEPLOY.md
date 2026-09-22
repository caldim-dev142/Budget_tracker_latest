# BudgetIQ Backend — Deployment & Migration Guide

## 1. Automated Database Migrations (D8)
BudgetIQ automatically runs database migrations **before** application boot in production.

### NPM Lifecycle Hooks
- **`npm run predeploy`**: Runs `prisma migrate deploy` as a standalone pre-flight migration check.
- **`npm run prestart:prod`**: Runs `prisma migrate deploy` automatically before `start:prod` begins.
- **`npm run start:prod`**: Runs `prisma migrate deploy && node dist/main` to guarantee that all schema changes, foreign keys, and indexes are applied before the NestJS Fastify server starts accepting incoming traffic.

## 2. Production Startup Sequence
1. **Build Step**:
   ```bash
   npm ci
   npm run build
   ```
2. **Start Step**:
   ```bash
   npm run start:prod
   ```
   This executes:
   1. `prisma migrate deploy`: Applies pending migrations from `prisma/migrations/` sequentially. If any migration fails, startup halts with non-zero exit code, preventing the application from running against an incompatible schema.
   2. `node dist/main`: Starts Fastify server on the configured `PORT` (default 3001).

## 3. Database Connection & Pooling (B6)
- The production database connection is configured via `DATABASE_URL`.
- BudgetIQ requires Supabase **Session Mode** (port `5432`) with `connection_limit=10`.
- **Do not** use transaction-mode pooling (port `6543` / `pgbouncer=true`), as transaction mode swaps underlying connections per query and breaks Prisma interactive transactions (`$transaction(async (tx) => ...)`).

## 4. Graceful Shutdown (B1)
- The server responds to `SIGTERM` and `SIGINT` termination signals.
- In-flight requests drain completely before the Fastify server terminates.
- NestJS lifecycle invokes `PrismaService.onModuleDestroy()`, cleanly closing Prisma database connections via `$disconnect()`.

## 5. Health Check
- `GET /health` returns `{ "status": "ok", "service": "budget-tracker-backend", "timestamp": "..." }`.
- Use this endpoint for container/orchestrator liveness and readiness probes.
