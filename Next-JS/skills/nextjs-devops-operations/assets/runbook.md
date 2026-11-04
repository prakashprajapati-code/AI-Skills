# Runbook: <Service / feature>

Owner: <team> | On-call: <channel> | SLO: <e.g. 99.5% of requests succeed over 30 days>

## Symptoms -> likely cause
- 5xx spike right after a deploy -> bad release or missing env var -> roll back first.
- `/api/health` failing -> app not booting (env validation, DB unreachable).
- Mostly 429 for real users -> shared IP behind a proxy, or limits too strict.
- Mostly 401/403 -> auth provider/secret change or clock skew.
- Slow pages (p95 up) -> DB slow queries, cold starts, third-party latency.

## Checks (in order)
1. Recent deploys/config changes (who, when, what).
2. Dashboard: error rate, latency, availability. Error tracker: top new issue.
3. `GET /api/health` and one write path smoke test.
4. Env present on the running instance (names only; never print values).
5. Dependencies: database, cache, email/SMS, auth provider status pages.

## Recovery
1. Stabilize: roll back to the previous release or turn the feature flag off.
2. Restore config/secrets from the secret store; redeploy.
3. Verify with the smoke test; watch dashboards for 15 minutes.
4. Fix forward with a regression test; schedule a blameless postmortem.

## Rollback
- Platform rollback to release `<tag>` (command/link: <...>).
- Database: migrations are backward compatible (expand/contract); do not drop columns in the same release.
- Restore previous env values if they changed.

## Escalation
<primary> -> <secondary> -> <vendor support>. Incident channel: <...>.
