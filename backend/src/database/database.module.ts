import { Module, Global } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

const prismaProvider = {
  provide: 'PRISMA',
  useFactory: async () => {
    const prisma = new PrismaClient({
      log:
        process.env.NODE_ENV === 'development'
          ? ['query', 'info', 'warn', 'error']
          : ['error'],
    });
    await prisma.$connect();
    return prisma;
  },
};

@Global()
@Module({
  providers: [prismaProvider],
  exports: ['PRISMA'],
})
export class DatabaseModule {}
