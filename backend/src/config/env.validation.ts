import Joi from 'joi';

/**
 * Known template / documentation JWT secret values. These are public (they appear in
 * .env.example and docs) and must never be accepted when NODE_ENV=production.
 */
export const KNOWN_PLACEHOLDER_SECRETS: readonly string[] = [
  'REPLACE_WITH_RANDOM_HEX_MIN_32_CHARS',
  'REPLACE_WITH_DIFFERENT_RANDOM_HEX_MIN_32_CHARS',
  'your-super-secure-jwt-secret-key-change-me',
];

/** Substrings that identify an unfilled template value. */
const PLACEHOLDER_MARKERS = ['REPLACE_WITH', 'your-super-secure', 'CHANGE_ME', 'changeme'];

export function isPlaceholderSecret(value: string | undefined | null): boolean {
  if (!value) return true;
  const v = value.trim();
  if (KNOWN_PLACEHOLDER_SECRETS.includes(v)) return true;
  return PLACEHOLDER_MARKERS.some((m) => v.toLowerCase().includes(m.toLowerCase()));
}

const productionSecret = Joi.string()
  .min(32)
  .required()
  .custom((value: string, helpers) => {
    if (isPlaceholderSecret(value)) {
      return helpers.message({
        custom: '{{#label}} is a template/placeholder value and is not allowed when NODE_ENV=production',
      });
    }
    return value;
  });

export const envValidationSchema = Joi.object({
  NODE_ENV: Joi.string()
    .valid('local', 'development', 'staging', 'production')
    .default('local'),
  PORT: Joi.number().default(3000),
  DATABASE_URL: Joi.string().uri().required(),
  JWT_ACCESS_SECRET: Joi.when('NODE_ENV', {
    is: 'production',
    then: productionSecret,
    otherwise: Joi.string().min(32).required(),
  }),
  JWT_REFRESH_SECRET: Joi.when('NODE_ENV', {
    is: 'production',
    then: productionSecret.invalid(Joi.ref('JWT_ACCESS_SECRET')).messages({
      'any.invalid': 'JWT_REFRESH_SECRET must differ from JWT_ACCESS_SECRET when NODE_ENV=production',
    }),
    otherwise: Joi.string().min(32).required(),
  }),
  JWT_ACCESS_EXPIRY: Joi.string().default('15m'),
  JWT_REFRESH_EXPIRY: Joi.string().default('30d'),
  CORS_ORIGINS: Joi.string().default('http://localhost:3000'),
  REDIS_URL: Joi.string().optional(),
  SENTRY_DSN: Joi.string().optional(),

  // ─── Security switches (each independent — see main.ts) ─────────────────────
  // Opt-in wildcard CORS for LAN development. Ignored in production.
  CORS_ALLOW_ALL: Joi.string().valid('true', 'false').default('false'),
  // Explicit Swagger switch; defaults to on outside production, off in production.
  ENABLE_SWAGGER: Joi.string().valid('true', 'false').optional(),
  // Set true ONLY when running behind a reverse proxy you control, so the
  // throttler reads the real client IP from X-Forwarded-For.
  TRUST_PROXY: Joi.string().valid('true', 'false').default('false'),

  // ─── Firebase / Google Sign-In ──────────────────────────────────────────────
  // Optional so local development without Google Sign-In still boots, but the
  // auth service fails closed at verification time when they are absent.
  FIREBASE_PROJECT_ID: Joi.string().optional(),
  FIREBASE_CLIENT_EMAIL: Joi.string().optional(),
  FIREBASE_PRIVATE_KEY: Joi.string().optional(),

  // Comma-separated OAuth client IDs accepted by the direct-Google ID token
  // fallback. When empty, that fallback is disabled entirely (fail closed) —
  // never verify a Google ID token without pinning its audience.
  GOOGLE_OAUTH_CLIENT_IDS: Joi.string().optional().allow(''),
});
