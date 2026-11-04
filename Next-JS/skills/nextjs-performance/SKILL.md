---
name: nextjs-performance
description: Performance and Core Web Vitals for Next.js - LCP, CLS, INP, next/image, next/font, bundle size and code splitting, third-party scripts, streaming and loading states, caching headers, static vs dynamic cost, and diagnosing slow pages with Lighthouse and the bundle analyzer. Use this skill whenever the user says a page is slow, asks about Lighthouse, Web Vitals, bundle size, image or font optimization, layout shift, slow server response (TTFB), loading skeletons, or wants performance budgets and monitoring for a Next.js app.
---

# Next.js: Performance and Core Web Vitals

Measure first, change one thing, measure again. Most wins come from sending less JavaScript, loading the right image sooner, reserving space for things, and not blocking the first paint on slow data.

## Targets (75th percentile, real users)
LCP < 2.5 s, INP < 200 ms, CLS < 0.1, TTFB < 0.8 s. Suggested JS budget: < 200 KB compressed per route (first load). Treat them as regression budgets in CI, not one-off goals.

## Principles (and why)
1. **Lab data finds, field data decides.** Lighthouse reproduces a problem; real-user data (Vercel/Speed Insights, CrUX, `web-vitals`) tells you whether it matters.
2. **The fastest code is code not shipped.** Server Components, fewer client libraries, and lazy loading beat micro-optimizations.
3. **Reserve space, then fill it.** Explicit dimensions prevent layout shift; skeletons match final size.
4. **Prioritize the LCP element.** One image or text block is the largest paint; make it discoverable and early.
5. **Do not block the shell on slow data.** Stream with Suspense.

## Rules
### Images (`references/images-fonts-scripts.md`)
1. **[MUST]** Use `next/image` with explicit `width`/`height` (or `fill` + sized parent) and a meaningful `sizes` attribute for responsive images; right-size sources (do not serve 4000 px for a 400 px slot).
2. **[MUST]** `priority` (or `fetchPriority="high"`) only on the LCP image (usually one per page); everything else lazy by default. Never lazy-load the hero.
3. **[SHOULD]** Modern formats (AVIF/WebP via `images.formats`), `placeholder="blur"` for large images; configure `images.remotePatterns` narrowly for remote hosts.

### Fonts and CSS
4. **[MUST]** Fonts via `next/font` (self-hosted, `display: swap`, subsets, CSS variable). No render-blocking `<link>` to font CDNs. Limit weights/families.
5. **[SHOULD]** Keep CSS small: Tailwind purges unused classes; avoid giant global stylesheets and CSS-in-JS runtime in server-rendered trees.

### JavaScript
6. **[MUST]** Keep `"use client"` at leaves (see `nextjs-rendering-react`). Heavy libraries (charts, editors, maps, markdown) load via `next/dynamic` where first paint does not need them.
7. **[MUST]** Third-party scripts through `next/script` with the right strategy: `afterInteractive` (default), `lazyOnload` for chat/analytics widgets, `worker` (experimental) where supported. Audit each tag; marketing tags are the usual INP killer.
8. **[SHOULD]** Check the bundle with `@next/bundle-analyzer` (or `next experimental-analyze` on newer versions) before and after large changes; replace heavy deps (moment -> date-fns/Intl, lodash full -> per-method imports, icon packs -> per-icon imports); set `optimizePackageImports` for big barrels.
9. **[SHOULD]** Avoid long main-thread tasks: debounce handlers, memoize only measured hot paths, virtualize long lists, use `startTransition` for non-urgent updates (INP).

### Server, data and caching
10. **[MUST]** Prefer static/ISR for public pages; make dynamic routes fast by parallelizing fetches (`Promise.all`), deduping with `React.cache`, indexing DB queries, and caching with tags (`../nextjs-rendering-react/references/caching.md`).
11. **[MUST]** Use `loading.tsx` and `<Suspense>` so slow sections stream in; skeleton dimensions match final content to avoid CLS.
12. **[SHOULD]** Cache headers: hashed `_next/static` assets are immutable by default; set `Cache-Control` for your own API/static files (`public, max-age=..., stale-while-revalidate`); put a CDN in front.
13. **[SHOULD]** Place compute near data (region of the DB), avoid chatty client -> API -> DB waterfalls, enable compression, keep response payloads lean (select fewer fields).
14. **[SHOULD]** Prefetching: `<Link>` prefetches in view in production; disable (`prefetch={false}`) on huge link lists to save bandwidth.

## React rendering performance (client)
1. **[SHOULD]** Profile with React DevTools Profiler ("Highlight updates") and look for components re-rendering with unchanged props before changing code.
2. **[SHOULD]** Fix in this order: move state down / lift content up via `children`; split context; defer with `useTransition` / `useDeferredValue`; virtualize long lists (`@tanstack/react-virtual`); only then `memo`/`useMemo`/`useCallback` (or enable the React Compiler and remove speed-only manual memoization).
3. **[MUST]** Do not pass new inline objects/arrays/functions to `memo` children or effect dependencies when it defeats memoization; keep `key`s stable so rows do not remount.
4. **[SHOULD]** Avoid effects that set state right after render (extra render pass); derive during render.
5. INP: keep handlers short, yield long work (`startTransition`, `scheduler.yield`, web worker), avoid synchronous heavy work on input.
Details and examples: `../nextjs-rendering-react/references/react-patterns.md` sections 3 and 4.

## Diagnosis workflow
1. Reproduce on a production build: `npm run build && npm start` (dev mode is not representative).
2. Lighthouse (mobile preset, throttled) on home, listing, detail, and the heaviest authenticated page. Save the baseline numbers.
3. Identify the bottleneck type:
   - Slow LCP -> image not prioritized/oversized, slow TTFB, render-blocking font/CSS, client-side data fetch for hero content.
   - High CLS -> images without dimensions, late-injected banners, font swap shifts (use `next/font` size-adjust), skeleton size mismatch.
   - Poor INP -> long tasks from big client trees, third-party scripts, expensive re-renders.
   - Large bundle -> run analyzer, look for accidental client imports of server libs, duplicate deps, unneeded polyfills.
   - Slow TTFB -> dynamic route doing sequential queries, cold serverless starts, far-away DB.
4. Fix the largest one, rebuild, re-measure, record the delta in the PR.
5. Add monitoring: `useReportWebVitals` or hosting analytics, plus Lighthouse CI budgets on PRs once stable.

## Pitfalls
- Optimizing in dev mode. Always measure a production build.
- `priority` on many images defeats prioritization.
- A client component at the top of the tree (analytics provider, theme provider) pulling large libs into every route.
- Remote images without `sizes`: browser downloads the largest variant.
- Layout shift from cookie banners and late chat widgets: reserve space or overlay with fixed positioning.
- `export const dynamic = "force-dynamic"` added "to fix staleness", silently removing static speed for the whole route.

## Verification checklist
- [ ] Production-build Lighthouse before/after recorded for key routes
- [ ] LCP image prioritized and sized; all images have dimensions
- [ ] Fonts via `next/font`; third-party scripts deferred
- [ ] Bundle analyzed after large changes; heavy components dynamically imported
- [ ] Slow data streamed with Suspense; skeletons match final size
- [ ] Budgets/monitoring in place (CI Lighthouse or real-user Web Vitals)

## Related skills
`nextjs-rendering-react` (static vs dynamic, streaming), `nextjs-ui-accessibility` (layout stability, reduced motion), `nextjs-devops-operations` (CDN/caching, monitoring).
