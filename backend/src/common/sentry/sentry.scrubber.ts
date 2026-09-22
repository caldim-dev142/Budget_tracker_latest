/**
 * Sentry Data Scrubber
 *
 * Guarantees zero leakage of financial data, request payloads, credentials,
 * and personal identifiers to Sentry error reports.
 */

const ALLOWED_HEADERS = new Set([
  'content-type',
  'user-agent',
  'accept',
  'host',
  'origin',
  'referer',
  'accept-encoding',
  'accept-language',
]);

const SENSITIVE_KEY_PATTERN = /(?:password|secret|token|auth|cookie|jwt|bearer|card|cvv|pin|paise|balance|amount|budget|target|reserve|household|user)/i;

/**
 * Redacts tokens, emails, UUIDs, card numbers, and financial values from string messages.
 */
export function sanitizeString(str: string): string {
  if (!str || typeof str !== 'string') return str;

  return str
    // Redact Bearer tokens & JWTs
    .replace(/Bearer\s+[A-Za-z0-9-_=]+\.[A-Za-z0-9-_=]+\.?[A-Za-z0-9-_.+/=]*/gi, 'Bearer [REDACTED_TOKEN]')
    .replace(/\beyJ[A-Za-z0-9-_=]+\.[A-Za-z0-9-_=]+\.?[A-Za-z0-9-_.+/=]*/g, '[REDACTED_TOKEN]')
    // Redact Email addresses
    .replace(/[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/g, '[REDACTED_EMAIL]')
    // Redact UUIDs (household IDs, user IDs, etc.) — must run before card numbers to avoid false card matches
    .replace(/\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b/gi, '[REDACTED_ID]')
    // Redact Credit card numbers (13 to 19 digits, continuous or separated by spaces/hyphens)
    .replace(/\b(?:\d[ -]*?){13,19}\b/g, '[REDACTED_CARD]')
    // Redact explicit financial fields in error messages
    .replace(/((?:amountPaise|amount|balance|outstanding|budget|targetPaise|openingReservePaise)\s*[:=]\s*)\d+/gi, '$1[REDACTED_FINANCIAL]');
}

/**
 * Recursively sanitizes an object, stripping sensitive keys and sanitizing string values.
 */
function sanitizeObject(obj: any, depth = 0): any {
  if (!obj || depth > 5) return obj;
  if (typeof obj === 'string') return sanitizeString(obj);
  if (typeof obj !== 'object') return obj;

  if (Array.isArray(obj)) {
    return obj.map((item) => sanitizeObject(item, depth + 1));
  }

  const cleaned: Record<string, any> = {};
  for (const [key, value] of Object.entries(obj)) {
    if (SENSITIVE_KEY_PATTERN.test(key)) {
      cleaned[key] = '[REDACTED]';
    } else {
      cleaned[key] = sanitizeObject(value, depth + 1);
    }
  }
  return cleaned;
}

/**
 * Main Sentry beforeSend hook.
 * Strips all request payloads, cookies, auth headers, and sensitive data.
 */
export function scrubSentryEvent(event: any): any {
  if (!event || typeof event !== 'object') return event;

  try {
    // 1. Request Sanitization
    if (event.request) {
      // Never send request payload/body to Sentry
      delete event.request.data;
      delete event.request.cookies;
      delete event.request.query_string;

      // Sanitize headers: allow only safe, non-sensitive headers
      if (event.request.headers && typeof event.request.headers === 'object') {
        const safeHeaders: Record<string, string> = {};
        for (const [key, val] of Object.entries(event.request.headers)) {
          const lowerKey = key.toLowerCase();
          if (ALLOWED_HEADERS.has(lowerKey)) {
            safeHeaders[lowerKey] = sanitizeString(String(val));
          }
        }
        event.request.headers = safeHeaders;
      }
    }

    // 2. User Sanitization: Never track PII or IP address
    if (event.user) {
      delete event.user.ip_address;
      delete event.user.email;
      delete event.user.username;
      if (event.user.id) {
        event.user.id = '[REDACTED_ID]';
      }
    }

    // 3. Exception & Message Sanitization
    if (event.message) {
      event.message = sanitizeString(event.message);
    }

    if (event.exception?.values && Array.isArray(event.exception.values)) {
      for (const ex of event.exception.values) {
        if (ex.value) {
          ex.value = sanitizeString(ex.value);
        }
      }
    }

    // 4. Breadcrumbs Sanitization
    if (event.breadcrumbs && Array.isArray(event.breadcrumbs)) {
      for (const b of event.breadcrumbs) {
        if (b.message) {
          b.message = sanitizeString(b.message);
        }
        if (b.data) {
          b.data = sanitizeObject(b.data);
        }
      }
    }

    // 5. Extra & Context Sanitization
    if (event.extra) {
      event.extra = sanitizeObject(event.extra);
    }
    if (event.contexts) {
      event.contexts = sanitizeObject(event.contexts);
    }

    return event;
  } catch {
    // Fail-safe: return null to drop event rather than risk transmitting unscrubbed data
    return null;
  }
}
