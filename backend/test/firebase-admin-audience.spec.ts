import { UnauthorizedException } from '@nestjs/common';

/**
 * Regression tests for the Google ID-token audience bypass (security audit
 * finding S1, 2026-09-18).
 *
 * Before the fix, the direct-Google fallback called
 *   googleClient.verifyIdToken({ idToken })
 * with NO `audience`. google-auth-library skips the `aud` claim check entirely
 * when audience is omitted, so an ID token minted for ANY unrelated OAuth
 * client was accepted and its `email` trusted as the caller's identity —
 * allowing takeover of the BudgetIQ household belonging to that email.
 *
 * NOTE: the pre-existing auth.security.spec.ts mocks FirebaseAdminService
 * wholesale, so it could never have caught this. These tests drive the REAL
 * service and assert on how the underlying libraries are called.
 */

const mockVerifyIdToken = jest.fn();
const mockGetAuthVerifyIdToken = jest.fn();

jest.mock('google-auth-library', () => ({
  OAuth2Client: jest.fn(() => ({ verifyIdToken: mockVerifyIdToken })),
}));

jest.mock('firebase-admin/app', () => ({
  initializeApp: jest.fn(),
  cert: jest.fn(),
  getApps: jest.fn(() => [{ name: 'DEFAULT' }]),
}));

jest.mock('firebase-admin/auth', () => ({
  getAuth: jest.fn(() => ({ verifyIdToken: mockGetAuthVerifyIdToken })),
}));

import { FirebaseAdminService } from '../src/auth/firebase-admin.service';

/** Minimal ConfigService stand-in backed by a plain record. */
const configOf = (values: Record<string, string | undefined>) =>
  ({
    get: (key: string, fallback?: string) => values[key] ?? fallback,
  }) as any;

const OUR_CLIENT_ID = '812371931220-ourclient.apps.googleusercontent.com';
const ATTACKER_CLIENT_ID = '999999999999-attacker.apps.googleusercontent.com';

const buildService = (values: Record<string, string | undefined>) => {
  const service = new FirebaseAdminService(configOf(values));
  service.onModuleInit();
  return service;
};

describe('FirebaseAdminService — Google ID token audience pinning (S1)', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    // Force the Firebase path to fall through to the Google fallback, which is
    // exactly the condition that made the bypass reachable in production.
    mockGetAuthVerifyIdToken.mockRejectedValue(new Error('firebase unavailable'));
  });

  it('1. passes an explicit audience allow-list to google-auth-library', async () => {
    const service = buildService({
      FIREBASE_PROJECT_ID: 'budget-tracker-test',
      GOOGLE_OAUTH_CLIENT_IDS: OUR_CLIENT_ID,
    });

    mockVerifyIdToken.mockResolvedValue({
      getPayload: () => ({
        sub: 'google-uid-1',
        aud: OUR_CLIENT_ID,
        email: 'real.user@example.com',
        email_verified: true,
      }),
    });

    await service.verifyIdToken('a-valid-token');

    // The core assertion: audience must be supplied, or the aud check is skipped.
    expect(mockVerifyIdToken).toHaveBeenCalledWith(
      expect.objectContaining({ audience: [OUR_CLIENT_ID] }),
    );
  });

  it('2. rejects a token minted for a different OAuth client (the takeover vector)', async () => {
    const service = buildService({
      FIREBASE_PROJECT_ID: 'budget-tracker-test',
      GOOGLE_OAUTH_CLIENT_IDS: OUR_CLIENT_ID,
    });

    // Simulate a library that returned a payload whose aud is NOT ours.
    mockVerifyIdToken.mockResolvedValue({
      getPayload: () => ({
        sub: 'attacker-uid',
        aud: ATTACKER_CLIENT_ID,
        email: 'victim@example.com',
        email_verified: true,
      }),
    });

    await expect(service.verifyIdToken('foreign-client-token')).rejects.toThrow(
      UnauthorizedException,
    );
  });

  it('3. disables the fallback entirely when no allow-list is configured (fail closed)', async () => {
    const service = buildService({
      FIREBASE_PROJECT_ID: 'budget-tracker-test',
      GOOGLE_OAUTH_CLIENT_IDS: undefined,
    });

    // Even if the library would happily verify, we must never reach it.
    mockVerifyIdToken.mockResolvedValue({
      getPayload: () => ({
        sub: 'any-uid',
        aud: ATTACKER_CLIENT_ID,
        email: 'victim@example.com',
        email_verified: true,
      }),
    });

    await expect(service.verifyIdToken('any-token')).rejects.toThrow(UnauthorizedException);
    expect(mockVerifyIdToken).not.toHaveBeenCalled();
  });

  it('4. rejects a Google account whose email is not verified', async () => {
    const service = buildService({
      FIREBASE_PROJECT_ID: 'budget-tracker-test',
      GOOGLE_OAUTH_CLIENT_IDS: OUR_CLIENT_ID,
    });

    mockVerifyIdToken.mockResolvedValue({
      getPayload: () => ({
        sub: 'unverified-uid',
        aud: OUR_CLIENT_ID,
        email: 'unverified@example.com',
        email_verified: false,
      }),
    });

    await expect(service.verifyIdToken('unverified-email-token')).rejects.toThrow(
      UnauthorizedException,
    );
  });

  it('5. fails closed when FIREBASE_PROJECT_ID is not configured', async () => {
    const service = buildService({
      FIREBASE_PROJECT_ID: undefined,
      GOOGLE_OAUTH_CLIENT_IDS: OUR_CLIENT_ID,
    });

    // Firebase itself verifies fine here — the project id is what is missing,
    // so we must not fall back to a baked-in default constant.
    mockGetAuthVerifyIdToken.mockResolvedValue({
      aud: 'budget-tracker-d034f',
      email: 'user@example.com',
      sub: 'uid',
    });

    await expect(service.verifyIdToken('token')).rejects.toThrow(UnauthorizedException);
  });

  it('6. still accepts a correctly-audienced Firebase token', async () => {
    const service = buildService({
      FIREBASE_PROJECT_ID: 'budget-tracker-test',
      GOOGLE_OAUTH_CLIENT_IDS: OUR_CLIENT_ID,
    });

    mockGetAuthVerifyIdToken.mockResolvedValue({
      aud: 'budget-tracker-test',
      email: 'legit@example.com',
      sub: 'firebase-uid',
    });

    const decoded = await service.verifyIdToken('good-firebase-token');
    expect(decoded.email).toBe('legit@example.com');
    // The Google fallback must not run when Firebase already succeeded.
    expect(mockVerifyIdToken).not.toHaveBeenCalled();
  });
});
