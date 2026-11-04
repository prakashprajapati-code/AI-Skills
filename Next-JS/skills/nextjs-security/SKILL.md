---
name: nextjs-security
description: Security for Next.js applications - authentication and sessions, authorization (RBAC, ownership checks, IDOR), input validation, XSS/CSRF/SSRF/injection, secrets and environment variables, security headers and CSP, rate limiting, CAPTCHA/honeypots, file uploads, middleware/proxy limits, and dependency risk. Use this skill whenever the user adds login or roles, protects a route, API or server action, handles user input, files, cookies or tokens, sets headers/CSP/CORS, rate limits an endpoint, stores secrets, or asks "is this secure?" or for a security review of a Next.js project.
---

# Next.js: Security

Assume every request is hostile and every client-side check is cosmetic. Security in Next.js fails most often at one place: an endpoint (route handler or server action) that does the work without re-checking who is calling and what they may touch.

## Principles (and why)
1. **Authorize at the data access point.** Hiding a button or protecting a page in middleware is not enough; Server Actions and Route Handlers are directly callable. Check in the function that touches the data.
2. **Deny by default.** New endpoints require explicit auth and permission; public ones are an explicit exception.
3. **Validate on the server, escape at the sink.** Validate shape/size at the boundary; encode at the place data enters HTML, SQL, shell, email, JSON-LD.
4. **Defense in depth.** Layer cheap controls (headers, rate limits, validation, least privilege) so one miss is not a breach.
5. **Fail closed, speak generically.** Clients get generic errors; details go to logs. Security-sensitive messages must not reveal whether an account exists.
6. **Secrets never reach the client.** Only `NEXT_PUBLIC_*` is bundled to the browser.

## Rules: authentication and authorization
1. **[MUST]** Use a proven auth library or provider (Auth.js, Clerk, Better Auth, Lucia-style patterns, your IdP). Do not hand-roll password hashing, session signing or token formats.
2. **[MUST]** Sessions: HttpOnly, Secure, SameSite=Lax (or Strict) cookies; rotate on login and privilege change; short idle expiry plus absolute expiry; server-side revocation for sensitive apps.
3. **[MUST]** Passwords (if you store them): argon2id or bcrypt with a proper cost, never fast hashes; constant-time compare; breached-password check; rate-limit login and reset.
4. **[MUST]** Centralize checks: `requireUser()` and `can(user, action, resource)` helpers called inside every action, handler, and server-side data function. Middleware/proxy is for coarse redirects only. Since middleware can be bypassed or misconfigured (CVE-2025-29927 showed header-based bypass in older versions), never make it your only gate.
5. **[MUST]** Prevent IDOR: every query that takes an ID also scopes by the owner/tenant (`where: { id, orgId: user.orgId }`). Multi-tenant apps put `tenantId` in every table and every query.
6. **[MUST]** Use a Data Access Layer (DAL): server-only functions that check the session and return DTOs, so components cannot fetch data without the check.
7. **[SHOULD]** RBAC roles from a closed list; permissions checked as capabilities (`invoice:delete`), not scattered role string comparisons.
8. **[SHOULD]** Re-authenticate for sensitive operations (change email/password, delete account, payouts); support MFA for admin roles.

## Rules: input, output and injection
1. **[MUST]** Validate all inputs with Zod: body, `FormData`, `params`, `searchParams`, headers; cap string/array sizes.
2. **[MUST]** Database: parameterized queries only (ORM or tagged templates). Never concatenate user input into SQL; allow-list dynamic column/sort names.
3. **[MUST]** XSS: React escapes by default; the risk is `dangerouslySetInnerHTML`, unsanitized markdown/HTML, `href`/`src` with `javascript:` URLs, and JSON-LD. Sanitize HTML with a vetted library (DOMPurify/sanitize-html) and escape `<` as `<` in JSON inside script tags. Validate URL schemes (`https:`, `mailto:`) before rendering user links.
4. **[MUST]** SSRF: when the server fetches a user-provided URL, allow-list hosts/schemes, block private/link-local IP ranges, disable redirects or re-check, set timeouts and size caps.
5. **[MUST]** Open redirects: validate `next`/`returnTo` params are same-origin relative paths.
6. **[MUST]** Email: escape interpolated values, strip CR/LF from headers/subjects, set `replyTo` rather than `from` to user input, never log bodies.
7. **[SHOULD]** CSRF: Server Actions check `Origin` against `Host` by default and require POST; keep cookies `SameSite`; for cookie-authenticated Route Handlers that mutate, add CSRF tokens or verify `Origin`. Configure `serverActions.allowedOrigins` only for known proxies.
8. **[SHOULD]** File uploads: allow-list extension and sniffed MIME, size cap, randomized names, store in object storage or outside the web root, scan if feasible, never serve user HTML/SVG inline from your origin.

## Rules: secrets, headers, abuse
1. **[MUST]** Secrets in the platform's secret store; `.env*` git-ignored; `.env.example` shows names only. Read via a validated `env` module; secret modules use `import "server-only"`. Never log secrets or tokens; rotate if ever committed.
2. **[MUST]** `NEXT_PUBLIC_` values are public by definition. Never prefix a secret.
3. **[MUST]** Rate-limit login, signup, password reset, contact/enquiry forms, search and expensive endpoints. Key by IP *and* account where relevant. In-memory limiters are per-process: use Redis/Upstash or an edge/WAF limiter in multi-instance or serverless production. Template: `assets/rate-limit.ts`.
4. **[SHOULD]** Bot defense for public forms: honeypot field + CAPTCHA (reCAPTCHA v3/hCaptcha/Turnstile) with server-side verification of score/action.
5. **[SHOULD]** Security headers (template `assets/security-headers.ts`): `X-Content-Type-Options`, `Referrer-Policy`, `Permissions-Policy`, HSTS (HTTPS only), frame protection via CSP `frame-ancestors` or `X-Frame-Options`. Add a CSP: start with `Content-Security-Policy-Report-Only`, use nonces for inline scripts (needs dynamic rendering) or hash-based allow-lists. Details: `references/headers-and-csp.md`.
6. **[SHOULD]** CORS: same-origin by default; if you add CORS, name specific origins; never `*` with credentials.
7. **[SHOULD]** Dependencies: `npm audit` in CI, Dependabot/Renovate, lockfile committed, review install scripts, keep Next.js patched (security releases matter).
8. **[SHOULD]** Logging: structured, no PII/tokens; audit-log security events (login, role change, deletes).

## Workflow: security review of a route/action
1. Who can call it? (anonymous / user / role) - is that enforced *in the function*?
2. What can they touch? (ownership/tenant scoped queries)
3. What do they send? (schema, size caps)
4. What do they get back? (DTO, no secrets, generic errors)
5. How can it be abused? (rate limit, replay, enumeration)
Use `references/security-checklist.md` for a full pass and probe matrix.

## Pitfalls
- Trusting `x-forwarded-for` without a controlled proxy: attackers rotate it to bypass limits.
- Checking auth in a layout only: layouts do not re-render on every navigation/partial render, and actions bypass them entirely.
- Returning different errors for "no such user" vs "wrong password" (account enumeration).
- Passing secrets or full DB rows from server to client components (serialized into HTML).
- CSP with `'unsafe-inline'` + `'unsafe-eval'` everywhere (offers little protection) - work toward nonces.
- Storing JWTs in localStorage (XSS-readable); prefer HttpOnly cookies.

## Verification checklist
- [ ] Every action/handler authenticates and authorizes inside itself; queries scoped by owner/tenant
- [ ] Inputs validated and capped; outputs are DTOs; errors generic
- [ ] Rate limits on auth and public forms; bot defense where needed
- [ ] Secrets only server-side; `.env` ignored; headers/CSP set (or Report-Only in progress)
- [ ] `npm audit` clean or triaged; probe matrix run (bad/missing session, other user's ID, oversize body, burst requests)

## Related skills
`nextjs-data-backend` (pipeline order, transactions), `nextjs-devops-operations` (secrets in CI/CD, logging), `nextjs-typescript-conventions` (env module).
