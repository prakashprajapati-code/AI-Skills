# Performance and rendering

Read when a screen is slow, re-renders too much, handles big lists, or when bundle size matters.

Guessing at performance problems usually adds complexity without fixing anything. Measure first, change one thing, measure again.

- Measure before optimizing. Establish what is slow and by how much, so you can show the change helped.
- Find bottlenecks with real tools: React DevTools Profiler (why a component rendered, how long), browser Performance panel and Lighthouse, and a bundle analyzer for size.
- Avoid unnecessary work: renders caused by state living too high or by new object/function props every render, expensive calculations repeated each render, and duplicate network requests (share them through the data-fetching cache).
- Use memoization only when justified. `useMemo`, `useCallback` and `React.memo` have a cost and add dependency bugs. Use them when the profiler shows a costly re-render or calculation, or when a stable reference is genuinely needed (a dependency of an effect, a memoized child). Check whether the project uses React Compiler (stable since v1.0) before hand-memoizing: if enabled, write plain code and let it memoize; leave existing manual memoization alone unless tests cover removing it. See `architecture-components.md` for adoption notes.
- Use React 19 concurrency features where they fit: `startTransition` / `useTransition` for non-urgent updates (filtering a big list while typing), `useDeferredValue` for expensive derived views, and `<Activity>` (19.2) to keep hidden screens' state without paying for their effects. In Chrome DevTools, React 19.2 adds Performance Tracks that show scheduler and component work.
- Split code and lazy-load suitable routes and heavy features (`React.lazy` + `Suspense`, dynamic `import()`): charts, editors, admin screens, modals that rarely open. Do not lazy-load tiny or above-the-fold components.
- Optimize assets and bundle size: compress and size images properly (modern formats, `width`/`height` to avoid layout shift, `loading="lazy"` below the fold), subset and preload fonts, import only what you use from large libraries, and watch for accidental whole-library imports.
- Virtualize genuinely large lists (hundreds to thousands of rows) with the project's virtualization library or a well-known one such as `react-window`. Do not virtualize short lists; it complicates accessibility and find-in-page.
- Respect framework-specific rendering, hydration and caching behavior (SSR/RSC, Next.js caching, route-level data loaders). Do not apply client-only advice to server-rendered code, and avoid causing hydration mismatches with values that differ between server and client (dates, random IDs, `window` access).

Report the before/after numbers, or say plainly that you could not measure.

See also: `tooling-ci.md` (bundle analysis and budgets), `error-handling-observability.md` (Web Vitals reporting), `styling-theming.md` (layout shift, animation cost), `nextjs-app-router.md` (rendering strategy and caching), `advanced-features.md` (virtualization, workers).
