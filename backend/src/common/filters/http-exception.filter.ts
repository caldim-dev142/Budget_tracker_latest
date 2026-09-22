import {
  ExceptionFilter,
  Catch,
  ArgumentsHost,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { FastifyReply, FastifyRequest } from 'fastify';
import * as Sentry from '@sentry/nestjs';

/**
 * Phase 5 — Global Structured Exception Filter
 *
 * Ensures all API errors (validation, 404, 403, 500) return a consistent JSON schema:
 * {
 *   statusCode: number,
 *   timestamp: string,
 *   path: string,
 *   method: string,
 *   error: string,
 *   message: string | string[]
 * }
 */
@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger('HttpExceptionFilter');

  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<FastifyReply>();
    const request = ctx.getRequest<FastifyRequest>();

    let status = HttpStatus.INTERNAL_SERVER_ERROR;
    let message: any = 'Internal server error';
    let error = 'Internal Server Error';

    if (exception instanceof HttpException) {
      status = exception.getStatus();
      const res = exception.getResponse();
      if (typeof res === 'string') {
        message = res;
        error = exception.name;
      } else if (typeof res === 'object' && res !== null) {
        message = (res as any).message ?? message;
        error = (res as any).error ?? exception.name;
      }
    } else if (exception instanceof Error) {
      this.logger.error(`Unhandled error at ${request?.method} ${request?.url}: ${exception.message}`, exception.stack);
      if (process.env.NODE_ENV !== 'production') {
        message = exception.message;
      }
    }

    // Capture 5xx server errors and unhandled exceptions in Sentry.
    // Client errors (4xx validation, 401, 403, 404) are ignored to avoid noise.
    if (status >= 500 && process.env.SENTRY_DSN) {
      try {
        Sentry.captureException(exception);
      } catch (err) {
        // Fail-safe: Sentry error capture failure must never disrupt the response flow or throw.
        this.logger.warn(`Failed to capture exception in Sentry: ${(err as Error)?.message}`);
      }
    }

    const requestId =
      (request as any)?.id ||
      (request?.headers && (request.headers['x-request-id'] || request.headers['request-id'])) ||
      '';

    const payload = {
      statusCode: status,
      timestamp: new Date().toISOString(),
      path: request?.url || '',
      method: request?.method || '',
      requestId,
      error,
      message,
    };

    response.status(status).send(payload);
  }
}
