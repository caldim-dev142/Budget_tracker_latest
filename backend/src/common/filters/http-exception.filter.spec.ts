import { HttpException, HttpStatus } from '@nestjs/common';
import { ArgumentsHost } from '@nestjs/common';
import * as Sentry from '@sentry/nestjs';
import { HttpExceptionFilter } from './http-exception.filter';

jest.mock('@sentry/nestjs', () => ({
  captureException: jest.fn(),
}));

describe('HttpExceptionFilter (with Sentry error tracking)', () => {
  let filter: HttpExceptionFilter;
  let mockResponse: { status: jest.Mock; send: jest.Mock };
  let mockRequest: { method: string; url: string };
  let mockHost: ArgumentsHost;
  const originalDsn = process.env.SENTRY_DSN;

  beforeEach(() => {
    jest.clearAllMocks();
    filter = new HttpExceptionFilter();

    mockResponse = {
      status: jest.fn().mockReturnThis(),
      send: jest.fn(),
    };

    mockRequest = {
      method: 'GET',
      url: '/test-endpoint',
    };

    mockHost = {
      switchToHttp: () => ({
        getResponse: () => mockResponse,
        getRequest: () => mockRequest,
      }),
    } as unknown as ArgumentsHost;
  });

  afterEach(() => {
    process.env.SENTRY_DSN = originalDsn;
  });

  it('does not send client 4xx errors to Sentry', () => {
    process.env.SENTRY_DSN = 'https://mock@sentry.io/123';
    const exception = new HttpException('Bad Request', HttpStatus.BAD_REQUEST);

    filter.catch(exception, mockHost);

    expect(Sentry.captureException).not.toHaveBeenCalled();
    expect(mockResponse.status).toHaveBeenCalledWith(400);
    expect(mockResponse.send).toHaveBeenCalledWith(
      expect.objectContaining({
        statusCode: 400,
        message: 'Bad Request',
        error: 'HttpException',
      }),
    );
  });

  it('reports 500 errors to Sentry when SENTRY_DSN is configured', () => {
    process.env.SENTRY_DSN = 'https://mock@sentry.io/123';
    const exception = new Error('Database connection failed');

    filter.catch(exception, mockHost);

    expect(Sentry.captureException).toHaveBeenCalledWith(exception);
    expect(mockResponse.status).toHaveBeenCalledWith(500);
    expect(mockResponse.send).toHaveBeenCalledWith(
      expect.objectContaining({
        statusCode: 500,
        error: 'Internal Server Error',
      }),
    );
  });

  it('no-ops without reporting to Sentry when SENTRY_DSN is unset', () => {
    delete process.env.SENTRY_DSN;
    const exception = new Error('Database connection failed');

    filter.catch(exception, mockHost);

    expect(Sentry.captureException).not.toHaveBeenCalled();
    expect(mockResponse.status).toHaveBeenCalledWith(500);
    expect(mockResponse.send).toHaveBeenCalledWith(
      expect.objectContaining({
        statusCode: 500,
        error: 'Internal Server Error',
      }),
    );
  });

  it('is fail-safe if Sentry.captureException throws an error', () => {
    process.env.SENTRY_DSN = 'https://mock@sentry.io/123';
    (Sentry.captureException as jest.Mock).mockImplementationOnce(() => {
      throw new Error('Sentry network timeout');
    });

    const exception = new Error('Fatal crash');

    expect(() => filter.catch(exception, mockHost)).not.toThrow();
    expect(mockResponse.status).toHaveBeenCalledWith(500);
    expect(mockResponse.send).toHaveBeenCalledWith(
      expect.objectContaining({
        statusCode: 500,
        error: 'Internal Server Error',
      }),
    );
  });

  describe('requestId propagation in error payload', () => {
    it('includes request.id in error payload when present', () => {
      (mockRequest as any).id = 'req-fastify-999';
      const exception = new HttpException('Forbidden', HttpStatus.FORBIDDEN);

      filter.catch(exception, mockHost);

      expect(mockResponse.send).toHaveBeenCalledWith(
        expect.objectContaining({
          statusCode: 403,
          requestId: 'req-fastify-999',
        }),
      );
    });

    it('falls back to x-request-id header when request.id is missing', () => {
      delete (mockRequest as any).id;
      (mockRequest as any).headers = { 'x-request-id': 'req-header-888' };
      const exception = new HttpException('Not Found', HttpStatus.NOT_FOUND);

      filter.catch(exception, mockHost);

      expect(mockResponse.send).toHaveBeenCalledWith(
        expect.objectContaining({
          statusCode: 404,
          requestId: 'req-header-888',
        }),
      );
    });

    it('defaults requestId to empty string when neither is present', () => {
      delete (mockRequest as any).id;
      delete (mockRequest as any).headers;
      const exception = new HttpException('Bad Request', HttpStatus.BAD_REQUEST);

      filter.catch(exception, mockHost);

      expect(mockResponse.send).toHaveBeenCalledWith(
        expect.objectContaining({
          statusCode: 400,
          requestId: '',
        }),
      );
    });
  });
});
