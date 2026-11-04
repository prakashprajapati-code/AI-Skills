# Security headers and CSP

## Baseline headers
See `assets/security-headers.ts`. Notes:
- **HSTS**: only after the whole site (and subdomains if `includeSubDomains`) is HTTPS. Start with a short `max-age`, then raise.
- **Frame protection**: prefer CSP `frame-ancestors 'none'` (or `'self'`); keep `X-Frame-Options: DENY` for old browsers.
- **Permissions-Policy**: disable features you do not use (`camera=(), microphone=(), geolocation=()`).
- **Referrer-Policy**: `strict-origin-when-cross-origin`.

## CSP rollout
1. Ship `Content-Security-Policy-Report-Only` with a reporting endpoint; collect violations for a week.
2. Build the allow-list from real needs: scripts, styles, images, fonts, frames, connect (APIs, analytics).
3. Switch to enforcing `Content-Security-Policy`.
4. Remove `'unsafe-inline'` for scripts by using nonces (generated per request in middleware/proxy and passed to `<Script nonce>` / inline scripts). Nonces require dynamic rendering of pages that use them: weigh against static performance. Alternative: hash-based or `strict-dynamic`.

Starter (tighten per project):
```
default-src 'self';
script-src 'self' 'nonce-<random>' 'strict-dynamic';
style-src 'self' 'unsafe-inline';
img-src 'self' data: https:;
font-src 'self';
connect-src 'self';
frame-ancestors 'none';
base-uri 'self';
form-action 'self';
object-src 'none';
```
Third parties need explicit entries (e.g. reCAPTCHA: `script-src https://www.google.com https://www.gstatic.com`, `frame-src https://www.google.com`; analytics hosts under `connect-src`/`script-src`).

## Nonce in Next.js (sketch)
Generate in `middleware.ts` (named `proxy.ts` from Next 16): create a random nonce, set it on the CSP header and an `x-nonce` request header; read `(await headers()).get("x-nonce")` in the root layout to pass to scripts. Next.js applies the nonce to its own scripts when the CSP header is present on the request. Check the official CSP guide for your version.

## Verify
`curl -sI https://your-site | grep -i -E "content-security|strict-transport|x-content|referrer|permissions"` and browser console for CSP violation reports.
