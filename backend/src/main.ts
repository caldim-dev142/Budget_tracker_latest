import 'dotenv/config';
import './common/bigint-json';
import { NestFactory } from '@nestjs/core';
import {
  FastifyAdapter,
  NestFastifyApplication,
} from '@nestjs/platform-fastify';
import { ValidationPipe } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { parse as parseQueryString } from 'querystring';
import { AppModule } from './app.module';
import { HttpExceptionFilter } from './common/filters/http-exception.filter';

async function bootstrap() {
  const app = await NestFactory.create<NestFastifyApplication>(
    AppModule,
    new FastifyAdapter({ logger: process.env.NODE_ENV === 'development' }),
    // Body parsers are registered explicitly below (Nest's automatic JSON parser would collide
    // with the empty-body-tolerant parser and abort bootstrap with FST_ERR_CTP_ALREADY_PRESENT).
    { bodyParser: false },
  );

  // Global exception filter for structured JSON error responses
  app.useGlobalFilters(new HttpExceptionFilter());

  // Global validation pipe (doc 06 §2.3 DTOs)
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,       // Strip unknown fields
      forbidNonWhitelisted: true,
      transform: true,        // Auto-transform types
      transformOptions: { enableImplicitConversion: true },
    }),
  );

  // Security headers, health check, and Content-Type handling
  const fastifyInstance = app.getHttpAdapter().getInstance();

  // JSON body parser that accepts an empty body. Endpoints such as DELETE /users/me,
  // DELETE /households/me, DELETE /households/members/:id and POST /months/reopen take no body,
  // but clients (and the onRequest hook below) send `Content-Type: application/json`.
  // Fastify's default parser rejects that combination with a 500. Non-empty bodies keep using
  // Fastify's default (prototype-poisoning-safe) JSON parser, so malformed JSON is still a 400.
  const defaultJsonParser = fastifyInstance.getDefaultJsonParser('error', 'error');
  const { bodyLimit } = fastifyInstance.initialConfig;
  fastifyInstance.removeContentTypeParser('application/json');
  fastifyInstance.addContentTypeParser(
    'application/json',
    { parseAs: 'string', bodyLimit },
    (request: any, body: string, done: (err: Error | null, body?: unknown) => void) => {
      if (typeof body !== 'string' || body.trim().length === 0) {
        done(null, {});
        return;
      }
      defaultJsonParser(request, body, done);
    },
  );

  // Same urlencoded handling Nest registers by default (kept for parity now that bodyParser is false).
  fastifyInstance.addContentTypeParser(
    'application/x-www-form-urlencoded',
    { parseAs: 'string', bodyLimit },
    (_request: any, body: string, done: (err: Error | null, body?: unknown) => void) => {
      done(null, parseQueryString(body));
    },
  );

  fastifyInstance.get('/health', async () => {
    return {
      status: 'ok',
      service: 'budget-tracker-backend',
      timestamp: new Date().toISOString(),
    };
  });

  fastifyInstance.addHook('onRequest', (request: any, reply: any, done: () => void) => {
    request.rawStartTime = Date.now();
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

  fastifyInstance.addHook('onResponse', (request: any, reply: any, done: () => void) => {
    const duration = Date.now() - (request.rawStartTime || Date.now());
    if (request.url !== '/health') {
      console.log(`[HTTP] ${request.method} ${request.url} ${reply.statusCode} - ${duration}ms`);
    }
    done();
  });

  // CORS — permissive in development (LAN mobile/web clients), restricted in production.
  // Set CORS_ORIGINS env var to a comma-separated list of allowed origins for production.
  const corsOrigins = process.env.CORS_ORIGINS;
  const isProduction = process.env.NODE_ENV === 'production';

  app.enableCors({
    origin: isProduction
      ? (corsOrigins ? corsOrigins.split(',').map((o) => o.trim()) : false)
      : true, // allow all origins in local/development for LAN mobile access
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

  const configService = app.get(ConfigService);
  const port = configService.get<number>('PORT') ?? parseInt(process.env.PORT ?? '3001', 10);
  await app.listen(port, '0.0.0.0');
  console.log(`Budget Tracker API running on http://0.0.0.0:${port}`);
  if (process.env.NODE_ENV !== 'production') {
    console.log(`Swagger docs: http://localhost:${port}/api/docs`);
  }
}

bootstrap().catch((err) => {
  console.error('Fatal bootstrap error:', err);
  process.exit(1);
});
