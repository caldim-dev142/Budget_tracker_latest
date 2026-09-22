import { generateRequestId, MAX_REQUEST_ID_LENGTH } from './request-id.util';

describe('generateRequestId (Request ID hardening)', () => {
  const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

  it('accepts a valid client-supplied x-request-id within length limit', () => {
    const req = { headers: { 'x-request-id': 'req-client-123_abc-XYZ' } };
    const id = generateRequestId(req);
    expect(id).toBe('req-client-123_abc-XYZ');
  });

  it('accepts a valid client-supplied request-id within length limit', () => {
    const req = { headers: { 'request-id': 'req-fallback-456' } };
    const id = generateRequestId(req);
    expect(id).toBe('req-fallback-456');
  });

  it('accepts a client-supplied request ID exactly at the 100 char limit', () => {
    const maxLenId = 'a'.repeat(MAX_REQUEST_ID_LENGTH);
    const req = { headers: { 'x-request-id': maxLenId } };
    const id = generateRequestId(req);
    expect(id).toBe(maxLenId);
  });

  it('rejects an oversized request ID (> 100 chars) and generates a new UUID', () => {
    const oversizedId = 'a'.repeat(MAX_REQUEST_ID_LENGTH + 1);
    const req = { headers: { 'x-request-id': oversizedId } };
    const id = generateRequestId(req);
    expect(id).not.toBe(oversizedId);
    expect(id).toMatch(UUID_REGEX);
  });

  it('rejects request IDs containing invalid/spoofed characters and generates a new UUID', () => {
    const malicious = [
      '<script>alert(1)</script>',
      'id with spaces',
      'id;injection',
      'id\nnewline',
      'id"quote',
      'id`tick`',
    ];

    for (const badId of malicious) {
      const req = { headers: { 'x-request-id': badId } };
      const id = generateRequestId(req);
      expect(id).not.toBe(badId);
      expect(id).toMatch(UUID_REGEX);
    }
  });

  it('generates a new UUID when no request ID header is supplied', () => {
    const req = { headers: {} };
    const id = generateRequestId(req);
    expect(id).toMatch(UUID_REGEX);
  });

  it('generates a new UUID when req or headers is undefined', () => {
    const id1 = generateRequestId(null);
    const id2 = generateRequestId({});
    expect(id1).toMatch(UUID_REGEX);
    expect(id2).toMatch(UUID_REGEX);
  });
});
