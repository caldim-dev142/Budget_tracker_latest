import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { ThrottlerModule } from '@nestjs/throttler';
import { ScheduleModule } from '@nestjs/schedule';
import Joi from 'joi';

import { DatabaseModule } from './database/database.module';
import { AuthModule } from './auth/auth.module';
import { HouseholdsModule } from './households/households.module';
import { UsersModule } from './users/users.module';
import { CategoriesModule } from './categories/categories.module';
import { EntriesModule } from './entries/entries.module';
import { BudgetsModule } from './budgets/budgets.module';
import { ProtectionModule } from './protection/protection.module';
import { SavingModule } from './saving/saving.module';
import { CardsModule } from './cards/cards.module';
import { AccountsModule } from './accounts/accounts.module';
import { PlanningModule } from './planning/planning.module';
import { MonthsModule } from './months/months.module';
import { ReportsModule } from './reports/reports.module';
import { SyncModule } from './sync/sync.module';
import { EngineModule } from './engine/engine.module';

@Module({
  imports: [
    // Config — Joi-validated env vars (doc 16 §1)
    ConfigModule.forRoot({
      isGlobal: true,
      validationSchema: Joi.object({
        NODE_ENV: Joi.string()
          .valid('local', 'development', 'staging', 'production')
          .default('local'),
        PORT: Joi.number().default(3000),
        DATABASE_URL: Joi.string().uri().required(),
        JWT_ACCESS_SECRET: Joi.string().min(32).required(),
        JWT_REFRESH_SECRET: Joi.string().min(32).required(),
        JWT_ACCESS_EXPIRY: Joi.string().default('15m'),
        JWT_REFRESH_EXPIRY: Joi.string().default('30d'),
        CORS_ORIGINS: Joi.string().default('http://localhost:3000'),
        REDIS_URL: Joi.string().optional(),
        SENTRY_DSN: Joi.string().optional(),
      }),
    }),

    // Rate limiting — 100 req/min global (doc 12 §7)
    ThrottlerModule.forRoot([{ ttl: 60000, limit: 100 }]),

    // Cron scheduler for month-close job (doc 06 §4)
    ScheduleModule.forRoot(),

    // Feature modules
    DatabaseModule,
    AuthModule,
    HouseholdsModule,
    UsersModule,
    CategoriesModule,
    EntriesModule,
    BudgetsModule,
    ProtectionModule,
    SavingModule,
    CardsModule,
    AccountsModule,
    PlanningModule,
    MonthsModule,
    ReportsModule,
    SyncModule,
    EngineModule,
  ],
})
export class AppModule {}
