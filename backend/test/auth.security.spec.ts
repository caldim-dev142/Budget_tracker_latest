import {
  UnauthorizedException,
  BadRequestException,
  NotFoundException,
  ConflictException,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import { createHash } from 'crypto';
import { AuthService } from '../src/auth/auth.service';
import { EmailService } from '../src/email/email.service';

describe('Passwordless Email OTP Authentication Security Verification', () => {
  let authService: AuthService;
  let mockEmailService: jest.Mocked<EmailService>;
  let mockPrisma: any;
  let mockJwtService: any;
  let mockConfigService: any;

  beforeEach(() => {
    mockConfigService = {
      get: jest.fn((key: string, defaultValue?: string) => {
        if (key === 'JWT_ACCESS_SECRET') return 'super_secret_access_jwt_key_32_chars';
        if (key === 'JWT_REFRESH_SECRET') return 'super_secret_refresh_jwt_key_32_chars';
        return defaultValue;
      }),
    };

    mockEmailService = {
      sendOtpEmail: jest.fn().mockResolvedValue(undefined),
      verifySmtpConnection: jest.fn().mockResolvedValue({ success: true, message: 'OK' }),
    } as any;

    mockJwtService = {
      sign: jest.fn(() => 'mock-application-jwt-access-token'),
    };

    mockPrisma = {
      user: {
        findFirst: jest.fn(),
        create: jest.fn(),
        update: jest.fn(),
      },
      household: {
        create: jest.fn(),
        upsert: jest.fn(),
      },
      category: {
        createMany: jest.fn().mockResolvedValue({ count: 10 }),
      },
      emailOtp: {
        findFirst: jest.fn(),
        count: jest.fn().mockResolvedValue(0),
        create: jest.fn(),
        update: jest.fn(),
        updateMany: jest.fn(),
      },
      refreshToken: {
        create: jest.fn(),
        findUnique: jest.fn(),
        update: jest.fn(),
        delete: jest.fn(),
        deleteMany: jest.fn(),
      },
      $transaction: jest.fn(async (cb) => cb(mockPrisma)),
    };

    authService = new AuthService(
      mockPrisma as any,
      mockJwtService as any,
      mockConfigService as any,
      mockEmailService as any,
    );
  });

  describe('1. Request OTP (requestOtp)', () => {
    it('1.1. Existing user -> generates OTP, stores SHA-256 hash with 5m expiry, sends email', async () => {
      mockPrisma.user.findFirst.mockResolvedValue({
        id: 'user-001',
        email: 'test.user@example.com',
        displayName: 'Test User',
        household_id: 'hsh-001',
      });

      const res = await authService.requestOtp({ email: 'test.user@example.com' });

      expect(res.success).toBe(true);
      expect(mockEmailService.sendOtpEmail).toHaveBeenCalledWith('test.user@example.com', expect.stringMatching(/^\d{6}$/));
      expect(mockPrisma.emailOtp.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            email: 'test.user@example.com',
            otpHash: expect.any(String),
            attempts: 0,
            expiresAt: expect.any(Date),
          }),
        }),
      );

      // Verify plaintext OTP is NEVER stored in database
      const createdData = mockPrisma.emailOtp.create.mock.calls[0][0].data;
      expect(createdData.otp).toBeUndefined();
      expect(createdData.otpHash.length).toBe(64); // SHA-256 hex length
    });

    it('1.2. Unknown email on sign in (no displayName) -> 404 NotFoundException', async () => {
      mockPrisma.user.findFirst.mockResolvedValue(null);

      await expect(
        authService.requestOtp({ email: 'unknown@example.com' }),
      ).rejects.toThrow(NotFoundException);

      expect(mockEmailService.sendOtpEmail).not.toHaveBeenCalled();
      expect(mockPrisma.emailOtp.create).not.toHaveBeenCalled();
    });

    it('1.3. Existing email on register (displayName provided) -> 409 ConflictException', async () => {
      mockPrisma.user.findFirst.mockResolvedValue({
        id: 'existing-user',
        email: 'existing@example.com',
        displayName: 'Existing User',
      });

      await expect(
        authService.requestOtp({ email: 'existing@example.com', displayName: 'New Name' }),
      ).rejects.toThrow(ConflictException);

      expect(mockEmailService.sendOtpEmail).not.toHaveBeenCalled();
    });

    it('1.4. Resend within 30s -> 429 Rate limited', async () => {
      mockPrisma.user.findFirst.mockResolvedValue({ id: 'u1', email: 'test@example.com' });
      mockPrisma.emailOtp.findFirst.mockResolvedValue({ id: 'recent-otp', createdAt: new Date() });

      await expect(
        authService.requestOtp({ email: 'test@example.com' }),
      ).rejects.toThrow(HttpException);

      expect(mockEmailService.sendOtpEmail).not.toHaveBeenCalled();
    });

    it('1.5. More than 5 requests in 10m -> 429 Rate limited', async () => {
      mockPrisma.user.findFirst.mockResolvedValue({ id: 'u1', email: 'test@example.com' });
      mockPrisma.emailOtp.findFirst.mockResolvedValue(null);
      mockPrisma.emailOtp.count.mockResolvedValue(5);

      await expect(
        authService.requestOtp({ email: 'test@example.com' }),
      ).rejects.toThrow(HttpException);

      expect(mockEmailService.sendOtpEmail).not.toHaveBeenCalled();
    });
  });

  describe('2. Verify OTP (verifyOtp)', () => {
    const rawOtp = '654321';
    const rawOtpHash = createHash('sha256').update(rawOtp).digest('hex');

    it('2.1. Valid OTP for existing user -> 200 + tokens + marks OTP as used', async () => {
      mockPrisma.emailOtp.findFirst.mockResolvedValue({
        id: 'otp-rec-1',
        email: 'test@example.com',
        otpHash: rawOtpHash,
        attempts: 0,
        expiresAt: new Date(Date.now() + 3 * 60 * 1000),
        usedAt: null,
      });

      mockPrisma.user.findFirst.mockResolvedValue({
        id: 'user-001',
        email: 'test@example.com',
        displayName: 'Test User',
        household_id: 'household-001',
      });

      const result = await authService.verifyOtp({
        email: 'test@example.com',
        otp: rawOtp,
      });

      expect(result.accessToken).toBe('mock-application-jwt-access-token');
      expect(result.user.id).toBe('user-001');
      expect(result.user.email).toBe('test@example.com');
      expect(mockPrisma.emailOtp.update).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { id: 'otp-rec-1' },
          data: expect.objectContaining({ usedAt: expect.any(Date) }),
        }),
      );
    });

    it('2.2. Valid OTP for new user -> creates user + household + seeds categories + returns tokens', async () => {
      mockPrisma.emailOtp.findFirst.mockResolvedValue({
        id: 'otp-rec-new',
        email: 'newuser@example.com',
        otpHash: rawOtpHash,
        displayName: 'Alice Smith',
        householdName: "Alice's Family",
        attempts: 0,
        expiresAt: new Date(Date.now() + 3 * 60 * 1000),
        usedAt: null,
      });

      mockPrisma.user.findFirst.mockResolvedValue(null);
      mockPrisma.user.create.mockImplementation(({ data }: any) => ({ ...data, id: 'new-user-id' }));

      const result = await authService.verifyOtp({
        email: 'newuser@example.com',
        otp: rawOtp,
      });

      expect(result.accessToken).toBe('mock-application-jwt-access-token');
      expect(mockPrisma.household.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            name: "Alice's Family",
          }),
        }),
      );
      expect(mockPrisma.user.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            email: 'newuser@example.com',
            displayName: 'Alice Smith',
            auth_provider: 'email_otp',
          }),
        }),
      );
      expect(mockPrisma.category.createMany).toHaveBeenCalled();
    });

    it('2.3. Incorrect OTP -> 401 Unauthorized + increments attempts count', async () => {
      mockPrisma.emailOtp.findFirst.mockResolvedValue({
        id: 'otp-rec-1',
        email: 'test@example.com',
        otpHash: rawOtpHash,
        attempts: 0,
        expiresAt: new Date(Date.now() + 3 * 60 * 1000),
        usedAt: null,
      });

      await expect(
        authService.verifyOtp({ email: 'test@example.com', otp: '000000' }),
      ).rejects.toThrow(UnauthorizedException);

      expect(mockPrisma.emailOtp.update).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { id: 'otp-rec-1' },
          data: { attempts: { increment: 1 } },
        }),
      );
      expect(mockJwtService.sign).not.toHaveBeenCalled();
    });

    it('2.4. Expired OTP -> 400 BadRequestException', async () => {
      mockPrisma.emailOtp.findFirst.mockResolvedValue({
        id: 'otp-rec-1',
        email: 'test@example.com',
        otpHash: rawOtpHash,
        attempts: 0,
        expiresAt: new Date(Date.now() - 1000), // Expired
        usedAt: null,
      });

      await expect(
        authService.verifyOtp({ email: 'test@example.com', otp: rawOtp }),
      ).rejects.toThrow(BadRequestException);
    });

    it('2.5. Already used OTP -> 400 BadRequestException', async () => {
      mockPrisma.emailOtp.findFirst.mockResolvedValue({
        id: 'otp-rec-1',
        email: 'test@example.com',
        otpHash: rawOtpHash,
        attempts: 0,
        expiresAt: new Date(Date.now() + 3 * 60 * 1000),
        usedAt: new Date(Date.now() - 60000), // Already consumed
      });

      await expect(
        authService.verifyOtp({ email: 'test@example.com', otp: rawOtp }),
      ).rejects.toThrow(BadRequestException);
    });

    it('2.6. Max attempts exceeded (5 attempts) -> 400 BadRequestException lockout', async () => {
      mockPrisma.emailOtp.findFirst.mockResolvedValue({
        id: 'otp-rec-1',
        email: 'test@example.com',
        otpHash: rawOtpHash,
        attempts: 5,
        expiresAt: new Date(Date.now() + 3 * 60 * 1000),
        usedAt: null,
      });

      await expect(
        authService.verifyOtp({ email: 'test@example.com', otp: rawOtp }),
      ).rejects.toThrow(BadRequestException);
    });
  });
});
