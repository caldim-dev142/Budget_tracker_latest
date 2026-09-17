/**
 * Money columns are stored as BIGINT paise (Prisma `BigInt`). JSON has no bigint type, so API
 * responses serialise them as JSON numbers. Values are bounded by API validation to
 * Number.MAX_SAFE_INTEGER, so the conversion is exact for every value the API accepts.
 */
declare global {
  interface BigInt {
    toJSON(): number;
  }
}

if (typeof (BigInt.prototype as any).toJSON !== 'function') {
  Object.defineProperty(BigInt.prototype, 'toJSON', {
    value: function toJSON(this: bigint) {
      return Number(this);
    },
    writable: true,
    configurable: true,
  });
}

export {};
