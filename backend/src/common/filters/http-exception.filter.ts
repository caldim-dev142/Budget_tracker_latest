import {
  ExceptionFilter,
  Catch,
  ArgumentsHost,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { FastifyReply, FastifyRequest } from 'fastify';

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

    const payload = {
      statusCode: status,
      timestamp: new Date().toISOString(),
      path: request?.url || '',
      method: request?.method || '',
      error,
      message,
    };

    response.status(status).send(payload);
  }
}
