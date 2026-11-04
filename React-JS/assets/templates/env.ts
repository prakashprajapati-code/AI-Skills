// Single place that reads and validates environment variables. Nobody else touches import.meta.env / process.env.
// Everything here is PUBLIC (inlined into the browser bundle). Never add secrets.
import { z } from 'zod';

const schema = z.object({
  API_URL: z.string().url(),
  APP_ENV: z.enum(['development', 'staging', 'production']).default('development'),
  SENTRY_DSN: z.string().url().optional(),
});

// Vite: map VITE_* names. For Next.js use process.env.NEXT_PUBLIC_* (must be referenced statically).
export const env = schema.parse({
  API_URL: import.meta.env.VITE_API_URL,
  APP_ENV: import.meta.env.VITE_APP_ENV,
  SENTRY_DSN: import.meta.env.VITE_SENTRY_DSN,
});
