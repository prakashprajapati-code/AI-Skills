---
name: nextjs-rendering-react
description: Rendering strategy and React patterns for Next.js App Router - Server Components vs Client Components, "use client" boundaries, SSR vs SSG vs ISR vs dynamic rendering, streaming and Suspense, caching and revalidation (fetch cache, unstable_cache, use cache, revalidateTag, revalidatePath), composition patterns, hydration errors, React 19 hooks, and core React patterns (useEffect rules, useMemo/useCallback and the React Compiler, useReducer, useRef, useTransition, keys, controlled inputs, context, custom hooks, portals, error boundaries, client state libraries). Use this skill whenever the user decides between server and client components, sees "window is not defined", hydration mismatch, a page that is unexpectedly dynamic or stale, asks how caching or revalidation works, adds "use client", designs data fetching for a page, or writes or reviews hooks and Client Component logic.
---

# Next.js: Rendering and React Patterns

Decide *where* code runs (server or browser) and *when* it runs (build time, request time, on a schedule). Most Next.js bugs and performance problems are a wrong answer to one of those two questions.

Caching APIs changed between Next 14, 15 and 16 (fetch no longer cached by default in 15; `use cache` / Cache Components arrive in 16; `params`, `cookies()`, `headers()` are async from 15). Check the installed version and the official docs for the exact API before writing cache code. Details by version: `references/caching.md`.

## Principles (and why)
1. **Server Components by default.** They ship no JS, can read data directly and keep secrets safe. Opt into the client only for interactivity.
2. **Push `"use client"` to the leaves.** The directive makes the file *and everything it imports* client code. A small `<LikeButton>` is a client leaf; the page around it stays on the server.
3. **Static first, dynamic by need.** Static output is the fastest and cheapest; request-time APIs (`cookies`, `headers`, `searchParams`, uncached fetch) opt a route into dynamic rendering. Know which you are choosing.
4. **Stream the slow part.** Wrap slow data in `<Suspense>` so the shell paints immediately.
5. **Data flows down, events flow up.** Fetch in the server component that needs the data, pass serializable props to client children.

## Server or client? Decision rules
Use a **Server Component** when it: fetches data, reads secrets/env, touches DB/filesystem, renders static markup, or imports heavy libraries (markdown, syntax highlighting).
Use a **Client Component** only when it needs: state/effects (`useState`, `useEffect`), event handlers, browser APIs (`window`, `localStorage`, `IntersectionObserver`), or client-only libraries.

Composition trick: a client component can render server components passed as `children`/props. Do not import a server component into a client file; pass it in from a parent server component.

## Rules
1. **[MUST]** Add `"use client"` only where hooks, handlers or browser APIs are used; never on layouts, pages or barrel files without reason.
2. **[MUST]** Props from server to client components must be serializable (plain objects, arrays, strings, numbers, dates as ISO strings). No functions, class instances, or ORM models.
3. **[MUST]** Never import server-only code (DB client, secrets) into client files; mark such modules with `import "server-only"`.
4. **[MUST]** Be explicit about caching per data source: choose static, time-based revalidate, tag-based revalidate, or no-store, and write the reason as a one-line comment. Never rely on defaults you have not verified for your version.
5. **[MUST]** After a mutation, revalidate what changed (`revalidateTag` / `revalidatePath`, or `updateTag` in Next 16 actions) so users do not see stale data.
6. **[MUST]** Await `params`, `searchParams`, `cookies()` and `headers()` (Next 15+). Reading them makes the route dynamic; read them only where needed, and keep it out of components that should be static.
7. **[MUST]** Avoid hydration mismatches: render identical markup on server and first client render. No `Date.now()`, `Math.random()`, `window` checks or locale-dependent formatting in render; move them into `useEffect`, or use `suppressHydrationWarning` only on a single known-different node (like a timestamp).
8. **[SHOULD]** Fetch in parallel: start independent promises together (`Promise.all`) rather than awaiting in sequence (waterfalls). Use `React.cache` to dedupe the same query across components in one request.
9. **[SHOULD]** Put `loading.tsx` and `<Suspense>` boundaries around slow sections; add `error.tsx` per route segment that can fail.
10. **[SHOULD]** Use `generateStaticParams` for known dynamic routes (pre-render at build) and decide `dynamicParams` for unknown ones.
11. **[SHOULD]** Keep client state minimal: derive instead of syncing, lift only as high as needed, prefer URL state (`searchParams`) for filters/pagination so pages are shareable and server-rendered.
12. **[SHOULD]** Use React 19 form primitives (`useActionState`, `useFormStatus`, `useOptimistic`) for forms backed by server actions instead of hand-rolled loading flags.
13. **[SHOULD]** Third-party client libraries that break on the server: wrap in a client component and load with `next/dynamic` (`ssr: false` only inside a client component).

14. **[MUST]** Do not use `useEffect` to derive state, handle user events, or fetch data a Server Component could fetch; always clean up subscriptions/timers and list every dependency. Details: `references/react-patterns.md`.
15. **[MUST]** List items need stable unique `key`s (ids, not random values or indexes for dynamic lists); never define a component inside another component; never mutate state or props.
16. **[SHOULD]** Measure before memoizing (`useMemo`, `useCallback`, `memo`); with the React Compiler enabled, drop speed-only manual memoization. Fix state placement and composition first.
17. **[SHOULD]** State placement order: derive -> URL -> local -> lifted -> context -> store library; server data on the client via TanStack Query/SWR, not copied into `useState`.

## Choosing a rendering mode
| Need | Choose |
|---|---|
| Content same for everyone, changes rarely (marketing, docs) | Static (SSG), `generateStaticParams` |
| Mostly static but updates periodically | ISR: `revalidate` seconds, or on-demand `revalidateTag` |
| Per-user or per-request data (dashboard, cart) | Dynamic SSR, with `Suspense` streaming |
| Static shell + small dynamic region | Partial prerendering / Cache Components (Next 16, check docs for your version) |
| Purely interactive widget | Client Component fetching via server action or route handler |

## Typical page shape
```tsx
// app/products/[slug]/page.tsx (Server Component)
import { Suspense } from "react";
import { notFound } from "next/navigation";
import { getProduct } from "@/features/products/server/queries";
import { ProductReviews } from "@/features/products/components/ProductReviews";
import { AddToCart } from "@/features/cart/components/AddToCart"; // "use client" leaf

export default async function Page({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const product = await getProduct(slug);
  if (!product) notFound();
  return (
    <>
      <h1>{product.name}</h1>
      <AddToCart productId={product.id} />
      <Suspense fallback={<p>Loading reviews...</p>}>
        <ProductReviews productId={product.id} /> {/* slow, streams in */}
      </Suspense>
    </>
  );
}
```

## React patterns (hooks, effects, state, refs, boundaries)
Full guidance with examples is in `references/react-patterns.md`; read it when writing or reviewing Client Component logic. It covers: hooks cheat sheet (`useReducer`, `useRef`, `useMemo`, `useCallback`, `useTransition`, `useDeferredValue`, `use()`, `useSyncExternalStore`, `useId`, `useLayoutEffect`), effect rules and Strict Mode, memoization and the React Compiler, keys, controlled vs uncontrolled forms, state libraries (Zustand/Redux/TanStack Query/React Hook Form), context, custom hooks, refs (`ref` as a prop in React 19), portals, error boundaries, client code splitting, and React 19 additions.
This skill targets Next.js. For plain React apps (Vite, CRA, Remix) the hook and component rules still apply; the server/client and caching rules do not.

## Pitfalls
- A route unexpectedly dynamic: something read `cookies()`, `headers()`, `searchParams`, or used `no-store`. Check the build output (`ƒ` dynamic vs `○`/`●` static) and trace which call did it.
- Stale data after a mutation: forgot to revalidate, or the data is cached in a layer you did not invalidate (fetch cache, data cache, client router cache).
- "window is not defined": browser API in a server-rendered path. Use `useEffect`, or a client-only dynamic import.
- Context providers: put them in a small client `Providers` component wrapping `children` in the root layout; do not make the layout itself a client component.
- Passing huge objects to client components bloats the HTML (it is serialized into the page). Pass only the fields needed.
- `useEffect` for data fetching that could be a server component or server action.
- Effects that sync derived state, missing cleanup, or silenced `exhaustive-deps`: see `references/react-patterns.md` section 2.
- Index or random `key`s causing lost input state or remounts.
- A module-level client store (Zustand/Redux) used during SSR shares state across users: create it per provider/request.

## Verification checklist
- [ ] Each `"use client"` file justified by hooks/handlers/browser APIs, kept small
- [ ] Build output shows the expected static/dynamic mode per route
- [ ] Caching choice explicit and commented; mutations revalidate affected data
- [ ] No hydration warnings in the browser console; no waterfalls on the main data path
- [ ] Effects justified (external sync only), with cleanup and full dependencies; keys stable; no component defined inside a component
- [ ] Slow sections streamed with Suspense; error and loading UI exist for risky routes

## Related skills
`nextjs-data-backend` (actions, queries), `nextjs-performance` (bundles, streaming budgets), `nextjs-architecture` (where server/client code lives). Version-specific caching notes: `references/caching.md`. React hooks/effects/state patterns: `references/react-patterns.md`. Also `nextjs-testing-quality` (hook and component tests).
