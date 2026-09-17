import { envValidationSchema, isPlaceholderSecret } from '../src/config/env.validation';

const base = {
  DATABASE_URL: 'postgresql://u:p@localhost:5432/db',
};
const strongA = 'a3f9c1e07b5d4e2f8a6b9c0d1e2f3a4b5c6d7e8f90112233';
const strongB = 'b7e2d4c6a8f0e1d3c5b7a9f1e3d5c7b9a1f3e5d7c9b1a3f5';

function validate(env: Record<string, string>) {
  return envValidationSchema.validate(env, { allowUnknown: true, abortEarly: false });
}

describe('Environment validation — JWT secrets (DEF-DEP-03)', () => {
  it('rejects the .env.example placeholder secrets in production', () => {
    const { error } = validate({
      ...base,
      NODE_ENV: 'production',
      JWT_ACCESS_SECRET: 'REPLACE_WITH_RANDOM_HEX_MIN_32_CHARS',
      JWT_REFRESH_SECRET: 'REPLACE_WITH_DIFFERENT_RANDOM_HEX_MIN_32_CHARS',
    });
    expect(error).toBeDefined();
    expect(error!.message).toMatch(/placeholder/);
  });

  it('rejects identical access and refresh secrets in production', () => {
    const { error } = validate({ ...base, NODE_ENV: 'production', JWT_ACCESS_SECRET: strongA, JWT_REFRESH_SECRET: strongA });
    expect(error).toBeDefined();
    expect(error!.message).toMatch(/must differ/);
  });

  it('rejects missing or short secrets in production', () => {
    expect(validate({ ...base, NODE_ENV: 'production', JWT_REFRESH_SECRET: strongB }).error).toBeDefined();
    expect(validate({ ...base, NODE_ENV: 'production', JWT_ACCESS_SECRET: 'short', JWT_REFRESH_SECRET: strongB }).error).toBeDefined();
  });

  it('accepts strong distinct secrets in production', () => {
    expect(validate({ ...base, NODE_ENV: 'production', JWT_ACCESS_SECRET: strongA, JWT_REFRESH_SECRET: strongB }).error).toBeUndefined();
  });

  it('keeps local/development behaviour unchanged (min length 32 only)', () => {
    expect(validate({ ...base, NODE_ENV: 'local', JWT_ACCESS_SECRET: 'REPLACE_WITH_RANDOM_HEX_MIN_32_CHARS', JWT_REFRESH_SECRET: 'REPLACE_WITH_DIFFERENT_RANDOM_HEX_MIN_32_CHARS' }).error).toBeUndefined();
    expect(validate({ ...base, JWT_ACCESS_SECRET: 'short', JWT_REFRESH_SECRET: strongB }).error).toBeDefined();
  });

  it('detects placeholder markers', () => {
    expect(isPlaceholderSecret('REPLACE_WITH_anything_long_enough_to_pass_min_len')).toBe(true);
    expect(isPlaceholderSecret(strongA)).toBe(false);
  });
});
