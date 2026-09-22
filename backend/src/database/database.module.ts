import { Module, Global } from '@nestjs/common';
import { PrismaService } from './prisma.service';

@Global()
@Module({
  providers: [
    PrismaService,
    {
      provide: 'PRISMA',
      useExisting: PrismaService,
    },
  ],
  exports: [PrismaService, 'PRISMA'],
})
export class DatabaseModule {}

