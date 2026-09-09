import { NestFactory } from '@nestjs/core';
import {
  FastifyAdapter,
  NestFastifyApplication,
} from '@nestjs/platform-fastify';
import { ValidationPipe } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create<NestFastifyApplication>(
    AppModule,
    new FastifyAdapter({ logger: process.env.NODE_ENV === 'development' }),
  );

  // Global validation pipe (doc 06 §2.3 DTOs)
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,       // Strip unknown fields
      forbidNonWhitelisted: true,
      transform: true,        // Auto-transform types
      transformOptions: { enableImplicitConversion: true },
    }),
  );

  // Security headers and Content-Type handling
  const fastifyInstance = app.getHttpAdapter().getInstance();

  fastifyInstance.addHook('onRequest', (request: any, reply: any, done: () => void) => {
    reply.header('X-Content-Type-Options', 'nosniff');
    reply.header('X-Frame-Options', 'SAMEORIGIN');
    reply.header('X-XSS-Protection', '1; mode=block');
    reply.header('Referrer-Policy', 'strict-origin-when-cross-origin');

    // Default missing content-type on requests so Fastify doesn't reject with 415 Unsupported Media Type: undefined
    if (!request.headers['content-type']) {
      request.headers['content-type'] = 'application/json';
    }
    done();
  });

  // CORS - allow mobile apps and web clients
  app.enableCors({
    origin: true,
    credentials: true,
  });

  // Swagger API docs (dev only)
  if (process.env.NODE_ENV !== 'production') {
    const config = new DocumentBuilder()
      .setTitle('Budget Tracker API')
      .setDescription('Personal/family budget tracker — INR, six-layer waterfall')
      .setVersion('1.0')
      .addBearerAuth()
      .build();
    const document = SwaggerModule.createDocument(app, config);
    SwaggerModule.setup('api/docs', app, document);
  }

  const port = parseInt(process.env.PORT ?? '3000', 10);
  await app.listen(port, '0.0.0.0');
  console.log(`Budget Tracker API running on http://localhost:${port}`);
  if (process.env.NODE_ENV !== 'production') {
    console.log(`Swagger docs: http://localhost:${port}/api/docs`);
  }
}

bootstrap();
