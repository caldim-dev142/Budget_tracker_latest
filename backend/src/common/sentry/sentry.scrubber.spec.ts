import { scrubSentryEvent, sanitizeString } from './sentry.scrubber';

describe('Sentry Scrubber — Data & Financial Privacy Protection', () => {
  describe('sanitizeString', () => {
    it('redacts Bearer tokens and standalone JWTs', () => {
      const raw = 'Failed with token Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.e30.t-ID and eyJhbGciOiJIUzI1NiJ9.abc.xyz';
      const clean = sanitizeString(raw);
      expect(clean).toBe('Failed with token Bearer [REDACTED_TOKEN] and [REDACTED_TOKEN]');
    });

    it('redacts email addresses', () => {
      const raw = 'User john.doe@example.com encountered an error';
      const clean = sanitizeString(raw);
      expect(clean).toBe('User [REDACTED_EMAIL] encountered an error');
    });

    it('redacts credit card numbers (13 to 19 digits)', () => {
      const raw = 'Card transaction failed on card 4111 2222 3333 4444 or 4111222233334444';
      const clean = sanitizeString(raw);
      expect(clean).toBe('Card transaction failed on card [REDACTED_CARD] or [REDACTED_CARD]');
    });

    it('redacts UUIDs (household IDs, user IDs)', () => {
      const raw = 'Failed for household a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11 and user 123e4567-e89b-12d3-a456-426614174000';
      const clean = sanitizeString(raw);
      expect(clean).toBe('Failed for household [REDACTED_ID] and user [REDACTED_ID]');
    });

    it('redacts explicit financial values in error messages', () => {
      const raw = 'Validation error: amountPaise: 50000 and balance = 1200000 and budget: 75000';
      const clean = sanitizeString(raw);
      expect(clean).toBe('Validation error: amountPaise: [REDACTED_FINANCIAL] and balance = [REDACTED_FINANCIAL] and budget: [REDACTED_FINANCIAL]');
    });
  });

  describe('scrubSentryEvent', () => {
    it('completely strips request payload (data), cookies, and query strings', () => {
      const event = {
        request: {
          url: 'http://localhost:3000/sync/batch',
          method: 'POST',
          data: {
            entries: [{ id: 'e-1', amountPaise: 50000 }],
            accounts: [{ id: 'a-1', currentBalancePaise: 250000 }],
          },
          cookies: { session: 'secret-session-id' },
          query_string: 'token=super-secret&amount=1000',
          headers: {
            'content-type': 'application/json',
            'user-agent': 'Dart/3.3',
            authorization: 'Bearer secret-jwt-token',
            cookie: 'session=123',
            'x-access-token': 'token-xyz',
          },
        },
      };

      const scrubbed = scrubSentryEvent(event);

      expect(scrubbed.request.data).toBeUndefined();
      expect(scrubbed.request.cookies).toBeUndefined();
      expect(scrubbed.request.query_string).toBeUndefined();

      // Only safe headers allowed
      expect(scrubbed.request.headers).toEqual({
        'content-type': 'application/json',
        'user-agent': 'Dart/3.3',
      });
      expect(scrubbed.request.headers.authorization).toBeUndefined();
      expect(scrubbed.request.headers.cookie).toBeUndefined();
      expect(scrubbed.request.headers['x-access-token']).toBeUndefined();
    });

    it('removes IP address, email, and username from user context and redacts user.id', () => {
      const event = {
        user: {
          id: 'user-12345',
          ip_address: '192.168.1.1',
          email: 'user@example.test',
          username: 'testuser',
        },
      };

      const scrubbed = scrubSentryEvent(event);

      expect(scrubbed.user.ip_address).toBeUndefined();
      expect(scrubbed.user.email).toBeUndefined();
      expect(scrubbed.user.username).toBeUndefined();
      expect(scrubbed.user.id).toBe('[REDACTED_ID]');
    });

    it('sanitizes messages and exception values', () => {
      const event = {
        message: 'Error processing user@test.com for household 12345678-1234-1234-1234-123456789abc',
        exception: {
          values: [
            {
              type: 'InternalServerError',
              value: 'Failed to update balance: 50000 with token Bearer eyJhbGciOi.abc.xyz',
            },
          ],
        },
      };

      const scrubbed = scrubSentryEvent(event);

      expect(scrubbed.message).toBe('Error processing [REDACTED_EMAIL] for household [REDACTED_ID]');
      expect(scrubbed.exception.values[0].value).toBe(
        'Failed to update balance: [REDACTED_FINANCIAL] with token Bearer [REDACTED_TOKEN]',
      );
    });

    it('redacts sensitive keys in extra and breadcrumbs', () => {
      const event = {
        extra: {
          accountBalance: 50000,
          userToken: 'secret-token',
          safeKey: 'normal-value',
        },
        breadcrumbs: [
          {
            message: 'User requested with email user@test.com',
            data: {
              paiseAmount: 100000,
              route: '/entries',
            },
          },
        ],
      };

      const scrubbed = scrubSentryEvent(event);

      expect(scrubbed.extra.accountBalance).toBe('[REDACTED]');
      expect(scrubbed.extra.userToken).toBe('[REDACTED]');
      expect(scrubbed.extra.safeKey).toBe('normal-value');

      expect(scrubbed.breadcrumbs[0].message).toBe('User requested with email [REDACTED_EMAIL]');
      expect(scrubbed.breadcrumbs[0].data.paiseAmount).toBe('[REDACTED]');
      expect(scrubbed.breadcrumbs[0].data.route).toBe('/entries');
    });

    it('returns null fail-safe if an unexpected error occurs during scrubbing', () => {
      // Pass an object with a throwing getter
      const maliciousEvent = {
        get request() {
          throw new Error('Explosion');
        },
      };

      const result = scrubSentryEvent(maliciousEvent);
      expect(result).toBeNull();
    });
  });
});
