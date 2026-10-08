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
      requestOtp: jest.fn(),
      verifyOtp: jest.fn(),
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

  describe('OTP endpoints', () => {
    it('delegates requestOtp to AuthService', async () => {
      const dto = { email: 'user@example.com' };
      (mockAuthService.requestOtp as jest.Mock).mockResolvedValueOnce({
        success: true,
        message: 'Verification code sent to your email.',
      });

      const res = await controller.requestOtp(dto);
      expect(mockAuthService.requestOtp).toHaveBeenCalledWith(dto);
      expect(res.success).toBe(true);
    });

    it('delegates verifyOtp to AuthService', async () => {
      const dto = { email: 'user@example.com', otp: '123456' };
      (mockAuthService.verifyOtp as jest.Mock).mockResolvedValueOnce({
        accessToken: 'jwt-access',
        refreshToken: 'jwt-refresh',
        refreshTokenFamily: 'family-1',
        user: { id: 'u-1', email: 'user@example.com', displayName: 'User', householdId: 'h-1' },
      });

      const res = await controller.verifyOtp(dto);
      expect(mockAuthService.verifyOtp).toHaveBeenCalledWith(dto);
      expect(res.accessToken).toBe('jwt-access');
    });
  });
});
