# Troubleshooting table

| Symptom | Likely cause | Fix |
|---|---|---|
| Hydration mismatch warning | Server and client render differ: `Date`, `Math.random`, `window`, locale format, invalid HTML nesting (`<p>` in `<p>`, `<div>` in `<p>`), browser extension | Move non-deterministic work to `useEffect`; fix nesting; `suppressHydrationWarning` on the single node (or `<html>` for theme class) |
| "window/document is not defined" | Browser API in server-rendered path | Guard in `useEffect`; client-only component via `next/dynamic` inside a client component |
| "You're importing a component that needs useState... Server Component" | Hook in a file without `"use client"` | Add `"use client"` to the smallest leaf that needs it |
| "Functions cannot be passed directly to Client Components" | Passing a function/class prop across boundary | Pass data; use a server action (`"use server"`) for callbacks |
| Route unexpectedly dynamic (`ƒ`) | `cookies()`, `headers()`, `searchParams`, `no-store`, `force-dynamic` in the tree | Find and isolate in a Suspense'd child, or accept dynamic deliberately |
| Stale data after mutation | No `revalidateTag/Path`, wrong tag, client router cache | Revalidate matching tag/path; `router.refresh()`; verify with `build && start` |
| `params` should be awaited | Next 15+ async request APIs | `const { id } = await params;` run the codemod |
| Metadata empty or localhost URLs in OG | Missing `metadataBase` or `generateMetadata` returned `{}` | Set `metadataBase` from `NEXT_PUBLIC_SITE_URL`; check early returns |
| Sitemap/robots 404 | File not at `app/` root or not exporting default function | Place `app/sitemap.ts`/`robots.ts`; check build output |
| Env var `undefined` in browser | Missing `NEXT_PUBLIC_` prefix or not set at build time | Prefix (if public) and set at build; restart dev server |
| Env var `undefined` on server in prod | Not set in the runtime environment; set only at build | Provide at runtime in the platform; validate with the env module at boot |
| `Module not found: server-only` / client bundle error | Server module imported from a client file | Move logic behind an action/handler; split file |
| Image error: hostname not configured | Remote host not in `images.remotePatterns` | Add the narrow pattern; restart |
| Build OOM or very slow | Huge static generation, large deps, source maps | Reduce `generateStaticParams`, use ISR, raise Node memory, check analyzer |
| Works locally, fails on deploy | Case-sensitive filenames, Node version, missing env, filesystem writes | Match Node version (`.nvmrc`), fix casing, write to object storage |
| Tests: "cannot find module '@/...'" | Vitest alias missing | Add alias in `vitest.config.ts` (see template) |
| Tests: `next/navigation` errors | Router not mounted in unit test | `vi.mock("next/navigation")` |
| Async Server Component fails in unit test | Not supported by most test renderers | Test its logic as functions; cover with Playwright |
| ESLint: config not found after upgrade | Flat config migration (`eslint.config.mjs`), `next lint` removed in 16 | Use generated flat config; script `eslint .` |
| Form returns 400/403/429 unexpectedly | Validation/CAPTCHA/rate limit | Read server log, probe each guard in turn |
| Theme flash on reload | Theme applied in `useEffect` | Inline pre-paint script or `next-themes`; `suppressHydrationWarning` on `<html>` |

## Reproduce-minimally recipe
1. `rm -rf .next node_modules/.cache && npm ci`
2. `npx tsc --noEmit && npx eslint . && npm run build`
3. `npm start` and test the failing route; check server logs and browser console.
4. Bisect with `git bisect` or by stripping the route to the minimum; write a failing test; fix; keep the test.
