import { Test, TestingModule } from '@nestjs/testing';
import { PrismaService } from './prisma.service';
import { DatabaseModule } from './database.module';

describe('PrismaService & DatabaseModule (B1 graceful shutdown)', () => {
  let service: PrismaService;

  beforeEach(() => {
    service = new PrismaService();
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('calls $connect on onModuleInit', async () => {
    const connectSpy = jest.spyOn(service, '$connect').mockResolvedValueOnce(undefined);
    await service.onModuleInit();
    expect(connectSpy).toHaveBeenCalledTimes(1);
    connectSpy.mockRestore();
  });

  it('calls $disconnect on onModuleDestroy for graceful shutdown', async () => {
    const disconnectSpy = jest.spyOn(service, '$disconnect').mockResolvedValueOnce(undefined);
    await service.onModuleDestroy();
    expect(disconnectSpy).toHaveBeenCalledTimes(1);
    disconnectSpy.mockRestore();
  });

  it('provides both PrismaService and PRISMA token via DatabaseModule', async () => {
    const module: TestingModule = await Test.createTestingModule({
      imports: [DatabaseModule],
    })
      .overrideProvider(PrismaService)
      .useValue(service)
      .compile();

    const prismaService = module.get<PrismaService>(PrismaService);
    const prismaToken = module.get<PrismaService>('PRISMA');

    expect(prismaService).toBeDefined();
    expect(prismaToken).toBeDefined();
    expect(prismaService).toBe(prismaToken);
  });
});
