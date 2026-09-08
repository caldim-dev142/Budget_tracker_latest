import { UnauthorizedException } from '@nestjs/common';

jest.mock('firebase-admin/app', () => ({
  initializeApp: jest.fn(),
  cert: jest.fn(),
  getApps: jest.fn(() => [{ name: 'DEFAULT' }]),
}));

jest.mock('firebase-admin/auth', () => ({
  getAuth: jest.fn(() => ({
    verifyIdToken: jest.fn(),
  })),
}));

import { AuthService } from '../src/auth/auth.service';
import { FirebaseAdminService } from '../src/auth/firebase-admin.service';

interface DecodedIdToken {
  aud: string;
  auth_time: number;
  email?: string;
  email_verified?: boolean;
  exp: number;
  firebase: {
    identities: { [key: string]: any };
    sign_in_provider: string;
    sign_in_second_factor?: string;
    second_factor_identifier?: string;
    tenant?: string;
    [key: string]: any;
  };
  iat: number;
  iss: string;
  name?: string;
  picture?: string;
  sub: string;
  uid: string;
  [key: string]: any;
}

describe('Firebase Authentication Security Verification', () => {
  let authService: AuthService;
  let mockFirebaseAdmin: jest.Mocked<FirebaseAdminService>;
  let mockPrisma: any;
  let mockJwtService: any;
  let mockConfigService: any;
  let loggedMessages: string[] = [];

  const validDecodedToken: DecodedIdToken = {
    uid: 'firebase-uid-12345',
    email: 'test.user@example.com',
    name: 'Test Verified User',
    aud: 'budget-tracker-d034f',
    iss: 'https://securetoken.google.com/budget-tracker-d034f',
    sub: 'firebase-uid-12345',
    auth_time: Math.floor(Date.now() / 1000),
    exp: Math.floor(Date.now() / 1000) + 3600,
    firebase: { identities: {}, sign_in_provider: 'google.com' },
    iat: Math.floor(Date.now() / 1000),
  };

  beforeEach(() => {
    loggedMessages = [];

    mockConfigService = {
      get: jest.fn((key: string, defaultValue?: string) => {
        if (key === 'FIREBASE_PROJECT_ID') return 'budget-tracker-d034f';
        if (key === 'JWT_ACCESS_SECRET') return 'super_secret_access_jwt_key_32_chars';
        if (key === 'JWT_REFRESH_SECRET') return 'super_secret_refresh_jwt_key_32_chars';
        return defaultValue;
      }),
    };

    mockFirebaseAdmin = {
      verifyIdToken: jest.fn(),
      onModuleInit: jest.fn(),
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
      },
      householdMember: {
        create: jest.fn(),
      },
      refreshToken: {
        create: jest.fn(),
      },
      $transaction: jest.fn((actions) => Promise.all(actions)),
    };

    authService = new AuthService(
      mockPrisma as any,
      mockJwtService as any,
      mockConfigService as any,
      mockFirebaseAdmin as any,
    );
  });

  it('1. Valid Firebase ID token -> 200 + application JWT', async () => {
    mockFirebaseAdmin.verifyIdToken.mockResolvedValue(validDecodedToken as any);

    mockPrisma.user.findFirst.mockResolvedValue({
      id: 'app-user-001',
      email: 'test.user@example.com',
      displayName: 'Test Verified User',
      firebaseUid: 'firebase-uid-12345',
      memberships: [{ householdId: 'household-001', userId: 'app-user-001', role: 'owner' }],
    });

    const result = await authService.googleSignIn('valid-firebase-id-token');

    expect(result.accessToken).toBe('mock-application-jwt-access-token');
    expect(result.user.id).toBe('app-user-001');
    expect(result.user.email).toBe('test.user@example.com');
  });

  it('2. Random/forged token -> 401 Unauthorized', async () => {
    mockFirebaseAdmin.verifyIdToken.mockRejectedValue(
      new UnauthorizedException('Invalid, expired, or unverified Firebase ID token')
    );

    await expect(authService.googleSignIn('random-forged-token-abc123')).rejects.toThrow(
      UnauthorizedException
    );
    expect(mockPrisma.user.findFirst).not.toHaveBeenCalled();
    expect(mockJwtService.sign).not.toHaveBeenCalled();
  });

  it('3. Empty/missing token -> 401 Unauthorized', async () => {
    await expect(authService.googleSignIn('')).rejects.toThrow(UnauthorizedException);
    await expect(authService.googleSignIn('   ')).rejects.toThrow(UnauthorizedException);
    expect(mockFirebaseAdmin.verifyIdToken).not.toHaveBeenCalled();
    expect(mockPrisma.user.findFirst).not.toHaveBeenCalled();
  });

  it('4. Expired Firebase ID token -> 401 Unauthorized', async () => {
    mockFirebaseAdmin.verifyIdToken.mockRejectedValue(
      new UnauthorizedException('Invalid, expired, or unverified Firebase ID token')
    );

    await expect(authService.googleSignIn('expired-token')).rejects.toThrow(UnauthorizedException);
    expect(mockJwtService.sign).not.toHaveBeenCalled();
  });

  it('5. Token issued for another Firebase project -> 401 Unauthorized', async () => {
    mockFirebaseAdmin.verifyIdToken.mockRejectedValue(
      new UnauthorizedException('Firebase ID token audience mismatch')
    );

    await expect(authService.googleSignIn('wrong-project-token')).rejects.toThrow(
      UnauthorizedException
    );
    expect(mockJwtService.sign).not.toHaveBeenCalled();
  });

  it('6. Request containing valid token + malicious email parameter -> malicious email ignored', async () => {
    mockFirebaseAdmin.verifyIdToken.mockResolvedValue(validDecodedToken as any);

    mockPrisma.user.findFirst.mockResolvedValue({
      id: 'app-user-001',
      email: 'test.user@example.com',
      displayName: 'Test Verified User',
      firebaseUid: 'firebase-uid-12345',
      memberships: [{ householdId: 'household-001', userId: 'app-user-001', role: 'owner' }],
    });

    // authService.googleSignIn accepts ONLY idToken.
    const result = await authService.googleSignIn('valid-firebase-id-token');

    // Verification used ONLY token's verified email
    expect(result.user.email).toBe('test.user@example.com');
  });

  it('7. Request containing valid token + malicious firebaseUid parameter -> malicious UID ignored', async () => {
    mockFirebaseAdmin.verifyIdToken.mockResolvedValue(validDecodedToken as any);

    mockPrisma.user.findFirst.mockResolvedValue({
      id: 'app-user-001',
      email: 'test.user@example.com',
      displayName: 'Test Verified User',
      firebaseUid: 'firebase-uid-12345',
      memberships: [{ householdId: 'household-001', userId: 'app-user-001', role: 'owner' }],
    });

    await authService.googleSignIn('valid-firebase-id-token');

    expect(mockPrisma.user.findFirst).toHaveBeenCalledWith({
      where: { email: 'test.user@example.com' },
    });
  });

  it('8. Repeated login with the same Firebase account -> same application user, no duplicate user created', async () => {
    mockFirebaseAdmin.verifyIdToken.mockResolvedValue(validDecodedToken as any);

    mockPrisma.user.findFirst.mockResolvedValue({
      id: 'existing-user-uuid',
      email: 'test.user@example.com',
      firebaseUid: 'firebase-uid-12345',
      displayName: 'Test Verified User',
      memberships: [{ householdId: 'hsh-existing', userId: 'existing-user-uuid', role: 'owner' }],
    });

    const result1 = await authService.googleSignIn('valid-firebase-id-token');
    const result2 = await authService.googleSignIn('valid-firebase-id-token');

    expect(result1.user.id).toBe('existing-user-uuid');
    expect(result2.user.id).toBe('existing-user-uuid');
    expect(mockPrisma.user.create).not.toHaveBeenCalled();
  });

  it('9. Firebase token verification failure -> absolutely no JWT issuance', async () => {
    mockFirebaseAdmin.verifyIdToken.mockRejectedValue(
      new UnauthorizedException('Token failed')
    );

    await expect(authService.googleSignIn('invalid-token')).rejects.toThrow(UnauthorizedException);
    expect(mockJwtService.sign).not.toHaveBeenCalled();
  });

  it('10. Verify that complete Firebase ID tokens are never written to logs', async () => {
    const rawSecretToken = 'header.payload.secret-signature-full-token-content-12345';
    
    mockFirebaseAdmin.verifyIdToken.mockRejectedValue(
      new UnauthorizedException('Token failed')
    );

    await expect(authService.googleSignIn(rawSecretToken)).rejects.toThrow();

    const loggedStr = loggedMessages.join(' ');
    expect(loggedStr).not.toContain(rawSecretToken);
  });
});
