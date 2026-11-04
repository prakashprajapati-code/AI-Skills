# Caching and revalidation cheat sheet

Always confirm against the docs for the installed version (`npm ls next`). This sheet gives the mental model; APIs shift between majors.

## Layers (think in this order)
1. **Request memoization**: identical `fetch` GETs, or functions wrapped in `React.cache`, run once per render pass.
2. **Data cache**: persisted results of `fetch` (with `next: { revalidate, tags }`), `unstable_cache`, or `"use cache"` functions.
3. **Full route cache**: rendered HTML/RSC payload of static routes, built at build time or on revalidation.
4. **Client router cache**: browser-side cache of visited route segments; invalidated by `router.refresh()` and by server actions that revalidate.

## By version (high level)
| Next | Fetch default | Notes |
|---|---|---|
| 14 | cached (`force-cache`) | opt out with `cache: "no-store"` or `export const dynamic = "force-dynamic"` |
| 15 | **not** cached | opt in per fetch (`cache: "force-cache"`, `next.revalidate`) or per route (`export const revalidate`, `dynamic`); `params`, `searchParams`, `cookies()`, `headers()` are async |
| 16 | not cached; Cache Components (`"use cache"`, `cacheLife`, `cacheTag`) opt-in via config | `updateTag` for read-your-writes in server actions; `revalidateTag` takes a cache-life profile argument; `middleware` renamed `proxy` |

## Patterns
```ts
// time-based
const res = await fetch(url, { next: { revalidate: 3600, tags: ["products"] } });

// DB query cached with tags (Next 14/15)
import { unstable_cache } from "next/cache";
export const getProducts = unstable_cache(async () => db.product.findMany(), ["products"], { revalidate: 3600, tags: ["products"] });

// invalidate after a mutation (server action or route handler)
import { revalidateTag, revalidatePath } from "next/cache";
revalidateTag("products");          // signature differs in Next 16: check docs
revalidatePath("/products");

// dedupe within one request
import { cache } from "react";
export const getUser = cache(async (id: string) => db.user.findUnique({ where: { id } }));
```

## Choosing a policy
| Data | Policy |
|---|---|
| Never changes between deploys | static, no revalidate |
| Edited by staff, can be minutes old | tag + on-demand revalidate on save (best), or `revalidate: 60-300` |
| Per user / personalized | no-store (dynamic) and stream |
| Third-party API with rate limits | time-based revalidate + error fallback |

## Debugging stale or over-dynamic pages
1. `next build` output: `○` static, `●` SSG with params, `ƒ` dynamic. Find the route's symbol.
2. Search the route and its layouts for `cookies(`, `headers(`, `searchParams`, `no-store`, `force-dynamic`.
3. After mutation, confirm the exact tag/path you revalidate matches the one you fetched with.
4. In dev, caching behaves differently; verify with `next build && next start`.
