import { Controller, Get, Module } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { FastifyAdapter, NestFastifyApplication } from '@nestjs/platform-fastify';
import { PrismaService } from '../src/database/prisma.service';
import { DatabaseModule } from '../src/database/database.module';
import http from 'http';

@Controller('shutdown-test')
class TestShutdownController {
  @Get('slow')
  async slow() {
    await new Promise((resolve) => setTimeout(resolve, 500));
    return { drained: true };
  }
}

@Module({
  imports: [DatabaseModule],
  controllers: [TestShutdownController],
})
class TestShutdownModule {}

describe('B1 — Graceful Shutdown & Request Draining', () => {
  let app: NestFastifyApplication;
  let prismaService: PrismaService;
  let disconnectSpy: jest.SpyInstance;
  let serverPort: number;

  beforeAll(async () => {
    app = await NestFactory.create<NestFastifyApplication>(
      TestShutdownModule,
      new FastifyAdapter(),
      { logger: false },
    );

    app.enableShutdownHooks();

    prismaService = app.get<PrismaService>(PrismaService);
    // Mock $connect and $disconnect to avoid needing live database connection during test
    jest.spyOn(prismaService, '$connect').mockResolvedValue(undefined);
    disconnectSpy = jest.spyOn(prismaService, '$disconnect').mockResolvedValue(undefined);

    await app.listen(0, '127.0.0.1');
    const address = app.getHttpServer().address();
    serverPort = typeof address === 'object' && address ? address.port : 3002;
  });

  it(
    'drains in-flight requests and calls Prisma $disconnect on app.close()',
    async () => {
      // 1. Launch a slow request that takes 400ms with Connection: close
      const requestPromise = new Promise<{ statusCode: number; body: any }>((resolve, reject) => {
        const req = http.get(
          `http://127.0.0.1:${serverPort}/shutdown-test/slow`,
          { headers: { Connection: 'close' } },
          (res) => {
            let rawData = '';
            res.on('data', (chunk) => {
              rawData += chunk;
            });
            res.on('end', () => {
              resolve({
                statusCode: res.statusCode || 0,
                body: JSON.parse(rawData),
              });
            });
          },
        );
        req.on('error', reject);
      });

      // 2. Wait 100ms so the request is actively in-flight
      await new Promise((resolve) => setTimeout(resolve, 100));

      // 3. Initiate graceful shutdown while request is still in-flight
      const closePromise = app.close();

      // 4. In-flight request must complete successfully without ECONNRESET
      const result = await requestPromise;
      expect(result.statusCode).toBe(200);
      expect(result.body).toEqual({ drained: true });

      // 5. Wait for shutdown to finish
      await closePromise;

      // 6. Verify Prisma $disconnect was called during module destruction
      expect(disconnectSpy).toHaveBeenCalledTimes(1);
    },
    15000,
  );

  it('registers SIGTERM and SIGINT listeners when enableShutdownHooks is called', async () => {
    const sigtermBefore = process.listeners('SIGTERM').length;
    const sigintBefore = process.listeners('SIGINT').length;

    const testApp = await NestFactory.create<NestFastifyApplication>(
      TestShutdownModule,
      new FastifyAdapter(),
      { logger: false },
    );
    testApp.enableShutdownHooks();

    const sigtermAfter = process.listeners('SIGTERM').length;
    const sigintAfter = process.listeners('SIGINT').length;

    expect(sigtermAfter).toBeGreaterThan(sigtermBefore);
    expect(sigintAfter).toBeGreaterThan(sigintBefore);

    await testApp.close();
  });
});


