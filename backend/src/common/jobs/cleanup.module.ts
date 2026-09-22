import { Module } from '@nestjs/common';
import { DatabaseModule } from '../../database/database.module';
import { CleanupService } from './cleanup.service';

@Module({
  imports: [DatabaseModule],
  providers: [CleanupService],
  exports: [CleanupService],
})
export class CleanupModule {}
