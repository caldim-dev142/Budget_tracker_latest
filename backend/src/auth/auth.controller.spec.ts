jest.mock('firebase-admin/app', () => ({
  initializeApp: jest.fn(),
  cert: jest.fn(),
  getApps: jest.fn(() => [{}]),
}));
jest.mock('firebase-admin/auth', () => ({
  getAuth: jest.fn(() => ({ verifyIdToken: jest.fn() })),
}));

import { HttpStatus } from '@nestjs/common';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';

describe('AuthController — Health & DB Readiness Check (B5)', () => {
  let controller: AuthController;
  let mockAuthService: Partial<AuthService>;
  let mockPrisma: { $queryRaw: jest.Mock };
  let mockResponse: { status: jest.Mock };

  beforeEach(() => {
    mockAuthService = {
      register: jest.fn(),
      login: jest.fn(),
      refresh: jest.fn(),
      logout: jest.fn(),
      googleSignIn: jest.fn(),
    };

    mockPrisma = {
      $queryRaw: jest.fn(),
    };

    mockResponse = {
      status: jest.fn().mockReturnThis(),
    };

    controller = new AuthController(
      mockAuthService as AuthService,
      mockPrisma as any,
    );
  });

  describe('health', () => {
    it('returns status ok and db ok when database is reachable', async () => {
      mockPrisma.$queryRaw.mockResolvedValueOnce([{ 1: 1 }]);

      const result = await controller.health(mockResponse as any);

      expect(mockPrisma.$queryRaw).toHaveBeenCalled();
      expect(mockResponse.status).not.toHaveBeenCalledWith(HttpStatus.SERVICE_UNAVAILABLE);
      expect(result).toEqual({
        status: 'ok',
        db: 'ok',
        service: 'budget-tracker-backend',
        timestamp: expect.any(String),
      });
    });

    it('returns HTTP 503 and db unreachable without leaking error details when database is down', async () => {
      const rawDbError = new Error('FATAL: password authentication failed for user "postgres"');
      mockPrisma.$queryRaw.mockRejectedValueOnce(rawDbError);

      const result = await controller.health(mockResponse as any);

      expect(mockPrisma.$queryRaw).toHaveBeenCalled();
      expect(mockResponse.status).toHaveBeenCalledWith(HttpStatus.SERVICE_UNAVAILABLE);
      expect(result).toEqual({
        status: 'error',
        db: 'unreachable',
        timestamp: expect.any(String),
      });

      // Verify zero leak of internal database error messages
      expect(JSON.stringify(result)).not.toContain('FATAL');
      expect(JSON.stringify(result)).not.toContain('postgres');
    });

    it('handles undefined res gracefully when database check fails', async () => {
      mockPrisma.$queryRaw.mockRejectedValueOnce(new Error('Connection timeout'));

      const result = await controller.health();

      expect(result).toEqual({
        status: 'error',
        db: 'unreachable',
        timestamp: expect.any(String),
      });
    });
  });
});
