import { Module } from '@nestjs/common';
import { SavingService } from './saving.service';
import { SavingController } from './saving.controller';

@Module({
  controllers: [SavingController],
  providers: [SavingService],
  exports: [SavingService],
})
export class SavingModule {}
