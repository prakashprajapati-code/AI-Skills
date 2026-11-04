# Next.js (App Router) specifics

Read when the project has `next` in `package.json`. This complements `architecture-components.md` (client/server boundary), `security-privacy.md` (Server Functions, advisories) and `routing-navigation.md`.

Contents: 1. Know the version · 2. Rendering strategy · 3. Caching · 4. Data fetching and mutations · 5. Route files · 6. proxy.ts / middleware · 7. Metadata and SEO · 8. Images, fonts, scripts · 9. Env vars · 10. Pages Router projects · 11. Pitfalls

Facts in this file about Next.js 16 were checked against the Next.js 16 release post on 2026-11-04. Next.js moves fast, so confirm against the installed version and `nextjs.org/docs`.

## 1. Know the version
Read `next` in `package.json` and the `next.config.*`. Behavior differs a lot between 13, 14, 15 and 16. Do not paste examples from another major version.
- **15:** `params`, `searchParams`, `cookies()`, `headers()` became **async** (must be awaited). `fetch` is no longer cached by default.
- **16:** Turbopack is the default bundler; **Cache Components** (`cacheComponents: true`, the `'use cache'` directive) make caching explicit and replace the old PPR flag; **`proxy.ts` replaces `middleware.ts`** (Node.js runtime); `next lint` was removed (run ESLint directly); `revalidateTag` takes a cache-life profile as a second argument; parallel routes need an explicit `default.js`; React 19.2 and the React Compiler (opt-in) are supported. Node 20.9+ is required.
- Upgrade with the official codemod, then read the upgrade guide (see `migration-upgrades.md`).

## 2. Rendering strategy (decide per route)
| Need | Use |
|---|---|
| Mostly static content, changes rarely | Static rendering (default); revalidate on a schedule or on demand |
| Personalized per request (cookies, auth) | Dynamic rendering; keep the dynamic part small |
| Mix: static shell + dynamic holes | Cache Components / Partial Prerendering with `<Suspense>` boundaries (16+) |
| Highly interactive widget | Client Component (`'use client'`) leaf, rest stays on the server |
Reading `cookies()`, `headers()` or `searchParams` makes a route dynamic; do it as low in the tree as possible and wrap in `<Suspense>`.

## 3. Caching (the most common source of "stale data" bugs)
Know which cache layer you are touching: request memoization (same render), the data cache (`fetch`/`'use cache'`), the full-route cache, and the client router cache.
- **15+:** nothing is cached by default unless opted in. **16 with Cache Components:** put `'use cache'` at the top of an async function, component or file to cache it; the compiler derives cache keys from arguments and closed-over values.
- Never cache user-specific or request-specific data in a shared cache. Do not read `cookies()`/`headers()` inside a cached scope; read them outside and pass values in as arguments.
- Invalidate deliberately: `revalidateTag(tag, profile)` / `revalidatePath` / `updateTag` after mutations (check the installed version's signatures).
- If data is stale after a mutation, check: tag/path names match, the action actually ran on the server, and the client router cache was refreshed (`router.refresh()`).

```tsx
// Next 16 with cacheComponents: true
import { cacheLife, cacheTag } from 'next/cache';

export async function getProducts() {
  'use cache';
  cacheLife('hours');
  cacheTag('products');
  const res = await fetch(`${process.env.API_URL}/products`);
  if (!res.ok) throw new Error('products failed');
  return res.json();
}
```

## 4. Data fetching and mutations
- Fetch in **Server Components** by default (direct, no client waterfall, secrets stay on the server). Run independent requests in parallel (`Promise.all`), not sequentially.
- Stream slow parts with `loading.tsx` or a `<Suspense>` boundary so the shell is instant.
- Client-side interactive data (polling, infinite scroll, optimistic UI) still uses TanStack Query / SWR in Client Components, hydrated from server-prefetched data when useful.
- Mutations: Server Functions (`'use server'`) used as `<form action>` or called from event handlers, or Route Handlers for external clients. **Each is a public endpoint**: authenticate, authorize, validate input (Zod), return minimal data, handle errors by returning a typed result, not by leaking exceptions. See `security-privacy.md`.
- After a mutation, revalidate the affected tag/path, then `redirect()` if navigating (call `redirect` outside `try/catch`, it works by throwing).

## 5. Route files
- `page.tsx` (UI for a URL), `layout.tsx` (shared shell, persists across navigation), `loading.tsx` (Suspense fallback), `error.tsx` (client error boundary, must be `'use client'`), `global-error.tsx`, `not-found.tsx` (call `notFound()` for missing resources, with a correct 404 status), `route.ts` (HTTP handlers).
- Dynamic segments `[id]`, catch-all `[...slug]`, route groups `(group)`, parallel `@slot`, intercepting `(.)`.
- Use `generateStaticParams` for known dynamic routes that should be prebuilt.
- Use `next/link` for internal navigation (prefetches) and `redirect`/`useRouter` for programmatic moves.

## 6. proxy.ts (formerly middleware.ts)
- Runs before routes: redirects, rewrites, header setting, light auth gating, i18n locale routing, A/B bucketing.
- Keep it **fast and thin**. Do not do heavy data fetching or full authorization here; authorize again in the Server Component / Server Function / Route Handler that serves the data.
- A matcher config limits which paths run it; exclude `_next/static`, images and the favicon.
- On 15 and older the file is `middleware.ts` (edge runtime by default). On 16 rename to `proxy.ts` and the exported function to `proxy`.

## 7. Metadata and SEO
- Export `metadata` or `generateMetadata` from `layout`/`page` (title template, description, canonical, Open Graph, Twitter, `robots`). Do not hand-write `<head>` tags.
- Provide `app/sitemap.ts`, `app/robots.ts`, and `opengraph-image`/icons as files. See `i18n-seo-analytics.md`.
- Each indexable page needs one `<h1>`, a unique title and description, and a canonical URL.

## 8. Images, fonts, scripts
- `next/image` with real `width`/`height` (or `fill` + sized parent), `sizes` for responsive images, `priority` only for the LCP image. Remote hosts must be allowed via `images.remotePatterns` (the old `images.domains` is deprecated).
- `next/font` self-hosts fonts and removes layout shift.
- `next/script` with a loading `strategy` for third-party scripts (`afterInteractive`, `lazyOnload`); mind your CSP.

## 9. Env vars
- Only `NEXT_PUBLIC_*` reaches the browser and is inlined **at build time**, so it is public and cannot change without a rebuild. Everything else stays server-side.
- Validate env at startup in one module (`env.ts` with Zod). Never read `process.env` all over the code.

## 10. Pages Router projects
If `pages/` is used (not `app/`): `getServerSideProps` / `getStaticProps` + `revalidate`, `_app.tsx`, `_document.tsx`, API routes in `pages/api`. Do not mix in App Router patterns or move a project to App Router as a side effect of another task; migration is its own planned task.

## 11. Pitfalls checklist
- Hydration mismatch: dates, `Math.random`, `window`, locale formatting differing between server and client.
- `'use client'` placed too high (whole page becomes client JS). Push it to leaves.
- Passing non-serializable props (functions, class instances) from server to client components.
- Importing a server-only module into a client file (use the `server-only` package so it fails the build).
- Forgetting to `await params` / `searchParams` / `cookies()` (15+).
- Caching personalized data; stale data after mutation; `redirect()` inside `try/catch`.
- Leaking secrets through `NEXT_PUBLIC_` variables or by serializing whole DB rows into props.
- Unpatched React/Next on a server-rendering app (see `security-privacy.md`, advisories).
