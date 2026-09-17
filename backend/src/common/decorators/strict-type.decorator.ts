import { Transform } from 'class-transformer';

/**
 * Keeps the raw request value for this property so the global `enableImplicitConversion`
 * cannot silently turn e.g. a number into a string before validation runs.
 * Use on string fields where a type-confused value must be rejected with 400.
 */
export const KeepRawValue = (): PropertyDecorator => Transform(({ obj, key }) => obj[key]);
