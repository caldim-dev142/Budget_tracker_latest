import { Module } from '@nestjs/common';
import { MonthsService } from './months.service';
import { MonthsController } from './months.controller';
import { EngineModule } from '../engine/engine.module';

@Module({
  imports: [EngineModule],
  controllers: [MonthsController],
  providers: [MonthsService],
  exports: [MonthsService],
})
export class MonthsModule {}
