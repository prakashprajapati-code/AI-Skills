---
name: nextjs-devops-operations
description: DevOps and production operations for Next.js - environment configuration and validation, CI/CD pipelines (GitHub Actions), Docker and standalone output, deployment targets (Vercel, containers, Node), preview environments, health checks, structured logging, error tracking, monitoring and alerts, database migrations in deploys, rollback, runbooks and releases. Use this skill whenever the user sets up or fixes CI/CD, Docker, deployment, environment variables or secrets, asks about logging, Sentry, monitoring, uptime, health endpoints, rollbacks, release process, or "how do I take this Next.js app to production".
---

# Next.js: DevOps and Production Operations

Production readiness means: the same build runs everywhere, configuration comes from the environment, every change passes automated checks, you can see what the app is doing, and you can undo a bad release in minutes.

## Principles (and why)
1. **Build once, configure per environment.** One artifact promoted from preview -> staging -> production; differences live in env vars. Rebuilding per environment hides "works on staging" bugs.
2. **Fail fast on bad config.** Validate env at startup/build (`lib/env.ts` with Zod) so a missing secret stops the deploy, not the first user.
3. **Everything automated is repeatable.** Deploys, migrations, and checks run from CI, not from a laptop.
4. **You cannot fix what you cannot see.** Logs, errors, metrics and a health check exist before the first incident.
5. **Every release has an undo.** Rollback is rehearsed, and database changes are backward compatible so rollback is possible.

## Rules
### Environments and configuration
1. **[MUST]** `.env.example` committed (names, no values); real values in the platform secret store; `.env*` git-ignored. Document each variable (purpose, public/secret, per-env).
2. **[MUST]** Validate env with Zod in one server-only module; separate public (`NEXT_PUBLIC_*`, inlined at **build** time) from server runtime vars. Remember: changing a `NEXT_PUBLIC_` value requires a rebuild.
3. **[MUST]** Separate environments (dev, preview, staging, production) with separate credentials and databases; production data never in lower environments without scrubbing.
4. **[SHOULD]** Pin Node via `.nvmrc`/`engines`, commit the lockfile, use `npm ci`.

### CI/CD
5. **[MUST]** CI on every PR: install, `tsc --noEmit`, lint, tests, build (template `assets/ci-workflow.yml`); `main` protected, required checks, no direct pushes.
6. **[MUST]** CD from `main` (or tags) to production via the pipeline/platform; preview deployments per PR for review and E2E smoke tests. Use least-privilege deploy tokens in CI secrets; `permissions: contents: read` by default.
7. **[SHOULD]** Cache dependencies and `.next/cache` between CI runs; run E2E against the preview URL; add `npm audit` and dependency updates (Dependabot/Renovate).
8. **[SHOULD]** Database migrations run as an explicit deploy step *before* the new app version (expand/contract so old and new code both work), never on app boot in multi-instance setups without locking.

### Deployment targets
9. **[SHOULD]** Pick deliberately: **Vercel** (zero-config, previews, edge/ISR support), **container** (`output: "standalone"`, Docker; works on any cloud/Kubernetes/Fly/Render/ECS), **Node server** (`next start` behind a reverse proxy), **static export** (`output: "export"`, only if no server features). Features such as ISR, image optimization, middleware/proxy, and `after()` behave differently by host: check the host's Next.js support before relying on them.
10. **[SHOULD]** Containers: multi-stage build, non-root user, `output: "standalone"` to shrink the image, `HEALTHCHECK`, handle `SIGTERM` for graceful shutdown; multi-instance deployments need a shared cache handler (Redis) for ISR/data cache consistency, and a shared rate-limit store. Template: `assets/Dockerfile`.
11. **[SHOULD]** CDN in front; long-lived immutable caching for `_next/static`; set `Cache-Control` deliberately for your own endpoints.

### Observability
12. **[MUST]** Health endpoint (`assets/health-route.ts`): liveness is cheap and dependency-free; add a separate readiness check (DB ping) if the platform supports it. Uptime monitor alerts on failures.
13. **[MUST]** Structured logs (JSON: level, message, requestId, route, userId-not-PII) to stdout; collected by the platform; never log secrets, tokens, request bodies or PII. Use `instrumentation.ts` to initialize tracing/error tracking.
14. **[SHOULD]** Error tracking (Sentry or equivalent) with source maps uploaded in CI, release tags, and alerts routed to an owner; track Web Vitals (`nextjs-performance`).
15. **[SHOULD]** Metrics and alerts on what users feel: error rate, p95 latency, availability, job failures; alert on symptoms, link each alert to a runbook.
16. **[SHOULD]** OpenTelemetry via `@vercel/otel` or the Node SDK in `instrumentation.ts` for traces across API/DB calls.

### Releases and rollback
17. **[MUST]** Rollback plan for every release: redeploy previous artifact/tag (Vercel instant rollback, `docker run` previous tag, `helm rollback`), plus config rollback. Feature flags for risky changes so rollback is a toggle.
18. **[SHOULD]** Semver tags and release notes (Conventional Commits + changesets/release-please); deploy small and often; post-deploy smoke test (home, a dynamic route, health, one write path).
19. **[SHOULD]** Runbook per service (`assets/runbook.md`): symptoms, checks, recovery, rollback, owners, SLOs; blameless postmortem after incidents.
20. **[SHOULD]** Backups: automated database backups with a tested restore; document RPO/RTO.

## Workflow: first production deploy
1. Env validated and documented; secrets in store. 2. CI green and required. 3. Build artifact (platform or Docker). 4. Staging deploy + smoke tests. 5. Migrations (backward compatible). 6. Production deploy. 7. Smoke test + dashboards watched for 15 minutes. 8. Tag release, note rollback target.

## Workflow: incident
Stabilize first (rollback or flag off), communicate, gather evidence (logs, error tracker, recent deploys), fix forward with a test, then write the postmortem and add the missing alert or check.

## Pitfalls
- Env var set on the platform but missing at **build** time for `NEXT_PUBLIC_*` (value undefined in bundle).
- In-memory rate limits, caches and sessions in multi-instance/serverless deployments.
- Running migrations and app start concurrently from several replicas.
- Source maps not uploaded, so production stack traces are unreadable (and never expose public source maps unintentionally).
- Alert fatigue: dozens of noisy alerts nobody owns.
- `next start` in a container behind a proxy without `X-Forwarded-*` handling or a trusted proxy configuration.
- Image optimization/ISR assumed available on a host that does not support it.

## Verification checklist
- [ ] `.env.example` complete; env validated at startup; secrets only in the secret store
- [ ] CI: `tsc`, lint, tests, build required on `main`; preview deploys per PR
- [ ] Health endpoint, uptime check, error tracking with source maps, structured logs without PII
- [ ] Migrations backward compatible and run from the pipeline
- [ ] Rollback tested once; runbook and owners documented; post-deploy smoke test defined

## Related skills
`nextjs-security` (secrets, headers), `nextjs-testing-quality` (CI checks), `nextjs-performance` (CDN, web vitals monitoring).
