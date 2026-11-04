// lib/env.ts - the only place that reads process.env. Fails fast on missing/invalid config.
import "server-only";
import { z } from "zod";

const schema = z.object({
  NODE_ENV: z.enum(["development", "test", "production"]).default("development"),
  DATABASE_URL: z.string().url(),
  SESSION_SECRET: z.string().min(32),
  // add: SMTP_*, third-party API keys, etc.
});

export const env = schema.parse(process.env);

// Public values (inlined at build time) live in a separate client-safe module:
// export const publicEnv = { siteUrl: process.env.NEXT_PUBLIC_SITE_URL ?? "http://localhost:3000" };
