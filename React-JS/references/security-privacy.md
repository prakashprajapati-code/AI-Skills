# Security and privacy

Contents: Core rules · Server Components and Server Functions · Known critical advisories · Authentication, sessions and requests · Browser hardening · Supply chain · Logging and privacy. Uploads, payments and auth screens: `advanced-features.md`.

Read when handling user input, authentication, URLs, tokens, HTML rendering, or adding dependencies.

The browser is a hostile environment: anyone can read the bundle, edit the DOM and call your API directly. Design as if the client is untrusted.

- Treat user input, URL parameters and API responses as untrusted data. Validate and encode at the boundary where they are used.
- Prevent XSS. React escapes text by default, so avoid bypassing it: do not use `dangerouslySetInnerHTML`, `innerHTML`, `document.write` or `eval` with untrusted content.
- If rendering user-controlled HTML is truly required (rich text, markdown), sanitize it with a maintained sanitizer such as DOMPurify, configured with an allowlist, immediately before rendering.
- Validate untrusted navigation targets (`href`, `window.location`, redirects after login). Allow only expected schemes (`https:`, `mailto:`) and known paths; `javascript:` URLs and open redirects are classic attack vectors. Add `rel="noopener noreferrer"` to links that open new tabs.
- Never rely on client-side checks for authorization. Hiding a button or route is a usability feature; the backend must enforce access on every request.
- Follow secure authentication and session patterns. Prefer the project's existing approach, typically `HttpOnly`, `Secure`, `SameSite` cookies over tokens in `localStorage`, which any XSS can read. Do not invent custom crypto or auth flows.
- Do not leak tokens or sensitive data into logs, error messages, URLs (query strings end up in history, referrers and server logs) or analytics events. Strip or mask PII before sending telemetry.
- Check dependencies and the supply chain: run the project's audit (`npm audit`, `pnpm audit`, or equivalent), prefer well-maintained packages with a clear owner, pin versions via the lockfile, and avoid packages for trivial functionality. Note Content Security Policy requirements (inline scripts and styles, third-party origins) before adding scripts, and do not weaken an existing CSP to make something work.
- Never commit secrets (keys, `.env` files with real values). If you spot one already committed, tell the user; do not silently rewrite history.

---

# Current security patterns for production React

## Server Components and Server Functions
If the project runs React Server Components (Next.js App Router, React Router framework mode, or anything that depends on `react-server-dom-*` packages), treat the server side as a public API surface.

- Every Server Function is a public HTTP endpoint, even if only one button calls it. Inside each one: authenticate the caller, authorize the specific action and resource, and validate all arguments with a schema. Never trust closure values or "hidden" ids that came from the client.
- Return minimal data. Do not pass whole database rows, user objects or internal fields into client components; map to a view model first.
- Keep secrets and server-only code behind the `server-only` package, and keep them out of `NEXT_PUBLIC_*`/`VITE_*` variables.
- Do not make server-side requests to URLs supplied by the user without an allowlist (SSRF).

## Known critical advisories (verify, do not trust this list to be current)
Advisories change after this file was written (last checked 2026-10-27). Run `npm audit` (or the project's equivalent) and read the current React and Next.js security pages before declaring a project safe.

- **React2Shell, CVE-2025-55182** (Next.js tracking id CVE-2025-66478, December 2025): a critical, CVSS 10.0 remote code execution in the React Server Components protocol, triggered by crafted requests to unpatched servers. Next.js 15.x and 16.x App Router apps were affected (patched lines include 15.0.5, 15.1.9, 15.2.6, 15.3.6, 15.4.8, 15.5.7 and 16.0.7). Pages Router and Edge Runtime were stated as not affected. The Next.js advisory says there is no workaround, so upgrade is required, and secrets should be rotated if the app was online and unpatched during the exposure window.
- **CVE-2026-23864**: a denial-of-service issue in `react-server-dom-webpack`, `react-server-dom-turbopack` and `react-server-dom-parcel`, with patched releases reported as 19.0.4, 19.1.5 and 19.2.4. This comes from a third-party summary of the advisory, so confirm the exact ranges against React's own announcement.
- If the project uses Server Components, confirm the installed `react`, `react-dom`, `react-server-dom-*` and `next` versions are on patched releases. Use the vendor's fixer tool or a deliberate version bump, then redeploy. Client-only apps that ship no server-side React code do not run this server component code, but still audit their dependencies.

## Authentication, sessions and requests
- Prefer a backend-for-frontend or cookie session with `HttpOnly`, `Secure`, `SameSite=Lax` or `Strict`. Avoid storing access or refresh tokens in `localStorage`; any XSS then steals them.
- With cookie auth, protect state-changing requests from CSRF: `SameSite` plus a CSRF token or origin check on the server. Server Functions need the same thought.
- Configure CORS with explicit origins. Never combine `*` with credentials.
- Refresh tokens in a single-flight flow and discard them on logout. Do not put tokens in URLs.

## Browser hardening
- Ship a Content Security Policy, ideally nonce-based, without `unsafe-inline` or `unsafe-eval` for scripts. Consider Trusted Types for DOM sinks.
- Send standard headers: `Strict-Transport-Security`, `X-Content-Type-Options: nosniff`, `Referrer-Policy`, `Permissions-Policy`, and `frame-ancestors` (or `X-Frame-Options`) to prevent clickjacking.
- Use Subresource Integrity for third-party scripts you cannot avoid, and keep third-party scripts to a minimum.
- Verify the `origin` and shape of every `postMessage` before acting on it.
- For uploads: validate type, size and content on the server, never trust the file extension or `Content-Type` from the client, and serve uploads from a separate origin or with safe headers.

## Supply chain
- Commit lockfiles and install from them (`npm ci`). Enable automated updates (Dependabot or Renovate) and review the diffs of major bumps.
- Prefer maintained packages with provenance; run `npm audit signatures` where supported. Be cautious with new packages that are days old, have few users or have install scripts. Use `--ignore-scripts` when installing something you have not vetted.
- Pin build-critical tools that change behavior (for example the React Compiler plugin) to exact versions.

## Logging and privacy
- Redact tokens, passwords, emails and other personal data from client and server logs, error reports and analytics. Check source-map and error-tracker settings so they do not capture form values.
- Respect consent requirements before loading analytics or marketing scripts.

Primary sources to check: the React blog security posts at react.dev, the Next.js security advisories at nextjs.org/blog, and the CVE records.

Report real findings plainly. If you are unsure whether something is exploitable, say what the risk would be rather than claiming it is safe.
