import { randomUUID } from 'crypto';

/**
 * Request ID validation & generation
 * Enforces a max length of 100 characters and safe alphanumeric/hyphen/underscore
 * characters to prevent oversized or spoofed headers from polluting logs.
 */
export const MAX_REQUEST_ID_LENGTH = 100;
export const SAFE_REQUEST_ID_REGEX = /^[a-zA-Z0-9_-]+$/;

export function generateRequestId(req: any): string {
  const incomingId = (req?.headers?.['x-request-id'] || req?.headers?.['request-id']) as string | undefined;
  if (
    typeof incomingId === 'string' &&
    incomingId.length > 0 &&
    incomingId.length <= MAX_REQUEST_ID_LENGTH &&
    SAFE_REQUEST_ID_REGEX.test(incomingId)
  ) {
    return incomingId;
  }
  return randomUUID();
}
