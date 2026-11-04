---
name: nextjs-seo
description: SEO and discoverability for Next.js App Router - Metadata API (generateMetadata, metadataBase), titles and descriptions, canonical URLs, Open Graph and Twitter cards, dynamic OG images, sitemap.ts, robots.ts, JSON-LD structured data, redirects, hreflang/i18n, noindex rules, and rendering choices that affect crawling. Use this skill whenever the user adds or fixes page metadata, asks why Google is not indexing or showing the right title/image, sets up a sitemap or robots file, adds schema.org/JSON-LD, handles duplicate content or canonicals, migrates URLs, or wants better search and social sharing for a Next.js site.
---

# Next.js: SEO and Discoverability

Search engines and social scrapers read your HTML. The aim: every indexable page is server-rendered with a unique title, description, canonical URL and structured data; every non-indexable page says so explicitly.

## Principles (and why)
1. **Server-render what you want indexed.** Content that appears only after client-side fetch may be indexed late or incompletely. Server Components and static output are the SEO-safe default.
2. **One canonical URL per piece of content.** Duplicates (trailing slash, `?utm=`, http/https, www) split ranking signals; canonical tags and redirects consolidate them.
3. **Metadata is data, derived not hand-copied.** Titles/descriptions come from one resolver or the content itself, so they stay unique and consistent.
4. **Metadata resolvers must be cheap and cacheable.** Reading `cookies()`/`headers()` in metadata silently makes the route dynamic; fetches are deduped with page fetches, so share the query.
5. **Say what not to index.** Private, duplicate, search-result and staging pages get `noindex`, not just a hope.

## Rules
1. **[MUST]** Set `metadataBase` in the root layout (`new URL(process.env.NEXT_PUBLIC_SITE_URL)`) so relative canonical and OG URLs resolve to absolute ones.
2. **[MUST]** Every page has a unique `title` (about 50-60 chars) and `description` (about 140-160). Use a root `title.template` (`"%s | Brand"`) and `default`. Dynamic routes implement `generateMetadata` using the same cached query as the page, and call `notFound()` for missing items (returns a real 404).
3. **[MUST]** `alternates.canonical` on every indexable page, absolute or relative to `metadataBase`, without tracking params and matching your chosen slash/host convention.
4. **[MUST]** Open Graph and Twitter: `openGraph` (title, description, url, siteName, type, images 1200x630) and `twitter.card: "summary_large_image"`. Use `opengraph-image.tsx` (ImageResponse) or a static `opengraph-image.png` per route; thumbnails are not OG images.
5. **[MUST]** `app/sitemap.ts` lists every indexable URL (published content only, same publish predicate as the pages) with accurate `lastModified`; use `generateSitemaps` for > 50,000 URLs. `app/robots.ts` references the sitemap and disallows non-public paths (`/api/`, `/admin`, private app areas). Never ship `Disallow: /` to production; block staging via auth/`noindex`.
6. **[MUST]** `robots: { index: false, follow: false }` on private, duplicate, thin, thank-you, and filtered/search pages; note that robots.txt blocks crawling but does not remove indexed pages, `noindex` does (and the page must be crawlable for it to be seen).
7. **[MUST]** JSON-LD for the page type, serialized safely (escape `<` as `<`), rendered in a native `<script type="application/ld+json">` in a server component. Content must match what is visible on the page. Validate with Google's Rich Results Test and Schema Validator. Matrix and helpers: `references/structured-data.md`.
8. **[MUST]** Redirects for moved/removed URLs: `redirects()` in `next.config` (permanent 308/301) from old to new; avoid chains; keep a redirect map in version control during migrations.
9. **[SHOULD]** URL design: lowercase, hyphenated, short, stable slugs; no IDs-only URLs for content pages; pick one trailing-slash policy (`trailingSlash` config) and keep it.
10. **[SHOULD]** Semantic structure: one `<h1>`, ordered headings, descriptive link text, `alt` text, `lang`; internal linking via `<Link>` (crawlable `<a href>`), breadcrumb navigation.
11. **[SHOULD]** i18n: `alternates.languages` for hreflang (including `x-default`), locale in URL path, canonical per locale.
12. **[SHOULD]** Performance is SEO: Core Web Vitals feed ranking; see `nextjs-performance`.
13. **[SHOULD]** Pagination: self-canonical per page (`?page=2`), crawlable links to next/prev; do not canonical page 2+ to page 1.
14. **[SHOULD]** Track indexing: Google Search Console + Bing Webmaster Tools; submit sitemap; monitor coverage and Core Web Vitals reports.

## Pattern: metadata helper + page
```ts
// lib/seo/metadata.ts - pure and synchronous
import type { Metadata } from "next";
const SITE = process.env.NEXT_PUBLIC_SITE_URL ?? "http://localhost:3000";
export const absoluteUrl = (path: string) => new URL(path, SITE).toString();

export function buildMetadata(o: { title: string; description: string; path: string; image?: string; noindex?: boolean }): Metadata {
  const url = absoluteUrl(o.path);
  return {
    title: o.title,
    description: o.description,
    alternates: { canonical: url },
    openGraph: { title: o.title, description: o.description, url, type: "website", images: o.image ? [{ url: o.image, width: 1200, height: 630 }] : undefined },
    twitter: { card: "summary_large_image", title: o.title, description: o.description },
    robots: o.noindex ? { index: false, follow: false } : undefined,
  };
}
```
```tsx
// app/products/[slug]/page.tsx
export async function generateMetadata({ params }: { params: Promise<{ slug: string }> }): Promise<Metadata> {
  const { slug } = await params;
  const product = await getProduct(slug); // same cached query the page uses
  if (!product) return {};
  return buildMetadata({ title: product.seoTitle ?? product.name, description: product.seoDescription ?? product.summary, path: `/products/${slug}` });
}
```
Copy `assets/sitemap.ts`, `assets/robots.ts`, `assets/JsonLd.tsx` and adapt the `<placeholders>`.

## Workflow: new indexable route
1. Decide: indexable or not. 2. Slug and URL policy. 3. Metadata (title/description/canonical/OG). 4. JSON-LD type. 5. Add to sitemap (or ensure the generator includes it) and internal links/navigation. 6. Verify below.

## Pitfalls
- Missing `metadataBase`: OG images resolve to localhost and previews break.
- Same title/description on every page (template default left unchanged).
- Draft or `noindex` pages in the sitemap (contradictory signals).
- Canonical pointing to a redirecting or noindex URL.
- JSON-LD data not matching visible content (can cause manual action) or built with unescaped user data.
- Client-only rendering for primary content; infinite scroll with no crawlable pagination links.
- Social preview caching: scrapers cache OG data; re-scrape with the platform debugger after fixing.
- Search params creating infinite crawlable duplicates: canonicalize or `noindex` filter combinations.

## Verification checklist
- [ ] `curl -s <url> | grep -E "<title>|canonical|og:|ld\+json"` shows correct unique values (view-source, not DevTools DOM)
- [ ] `/sitemap.xml` and `/robots.txt` return 200, list only indexable URLs, reference each other
- [ ] Rich Results Test passes for each structured-data type used
- [ ] Unknown slugs return real 404; moved URLs 308/301 once
- [ ] Private/duplicate pages `noindex`; OG image 1200x630 renders in a social debugger
- [ ] Search Console shows sitemap processed with no critical errors

## Related skills
`nextjs-rendering-react` (static/dynamic effects on metadata), `nextjs-performance` (CWV), `nextjs-ui-accessibility` (semantic HTML).
