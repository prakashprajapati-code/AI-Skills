# Security checklist and probe matrix

## Pre-launch pass
**Auth**
- [ ] Auth via maintained library/provider; no custom crypto
- [ ] Cookies HttpOnly + Secure + SameSite; session expiry and revocation defined
- [ ] Login/signup/reset rate-limited; generic errors; no account enumeration
- [ ] Admin routes require role *and* MFA where feasible

**Authorization**
- [ ] Every action/handler calls `requireUser()` + `can()` inside the function
- [ ] DAL functions scope by owner/tenant; no raw `findUnique({ id })` on user-supplied IDs
- [ ] Roles/permissions closed lists; default deny

**Input / output**
- [ ] Zod on body, FormData, params, searchParams; size caps
- [ ] No string-built SQL; dynamic identifiers allow-listed
- [ ] `dangerouslySetInnerHTML` only with sanitized content; JSON-LD escapes `<`
- [ ] User-supplied URLs scheme-checked (render) and host-allow-listed (server fetch)
- [ ] Redirect targets validated as same-origin paths

**Secrets / config**
- [ ] No secrets in repo, logs, client bundle (`grep -r "NEXT_PUBLIC_" .env*` review)
- [ ] `server-only` on modules reading secrets
- [ ] Secret rotation procedure exists

**Platform**
- [ ] Security headers present (check with securityheaders.com or curl -I)
- [ ] CSP in Report-Only or enforced; reporting endpoint decided
- [ ] HTTPS everywhere, HSTS on
- [ ] Dependabot/Renovate + `npm audit` in CI; Next.js on a patched version

## Probe matrix (run for each mutating endpoint)
| Probe | Expected |
|---|---|
| No session | 401 (or redirect for pages) |
| Session of another user, target ID of first user | 403/404, no data |
| Valid session, lacking role | 403 |
| Malformed JSON / wrong types | 400, generic message |
| Oversize body / string | 400/413 |
| Burst of N requests | 429 after limit |
| Replay of same one-time action (payment, invite) | Idempotent or 409 |
| Extra unexpected fields | Ignored/stripped, never persisted |

## Account-enumeration-safe messages
- Login: "Invalid email or password."
- Reset: "If that email exists, we sent a link." (same timing and response either way)

## Incident basics
Rotate exposed secrets first, invalidate sessions if needed, preserve logs, then fix root cause and add a regression test or probe.
