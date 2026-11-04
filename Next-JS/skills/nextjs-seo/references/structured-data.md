# Structured data (JSON-LD)

## Which type for which page
| Page | Types |
|---|---|
| Every page (root layout) | `Organization` (name, url, logo, sameAs), `WebSite` (name, url; add `SearchAction` only if a real site search exists) |
| Any nested page | `BreadcrumbList` matching visible breadcrumbs |
| Article / blog | `Article`/`BlogPosting` (headline, datePublished, dateModified, author, image) |
| Product page | `Product` (name, image, description, brand, sku; `offers` only with real price/availability) |
| FAQ section | `FAQPage` (only if visible Q&A on the page; note Google limits rich results for FAQs) |
| Local business | `LocalBusiness` subtype (address, openingHours, geo, telephone) |
| Event / Job / Recipe / Video | `Event`, `JobPosting`, `Recipe`, `VideoObject` as applicable |

Rules: markup must match visible content; no ratings/reviews you do not actually display; one canonical entity per concept; use absolute URLs.

## Safe serializer and component
```tsx
// lib/seo/JsonLd.tsx (server component)
const serialize = (data: unknown) => JSON.stringify(data).replace(/</g, "\\u003c");
export function JsonLd({ data }: { data: Record<string, unknown> | Record<string, unknown>[] }) {
  return <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: serialize(data) }} />;
}
```
Use a native `<script>`, not `next/script`, so it is in the initial HTML.

## Helpers
```ts
export const breadcrumbJsonLd = (items: { name: string; url: string }[]) => ({
  "@context": "https://schema.org",
  "@type": "BreadcrumbList",
  itemListElement: items.map((it, i) => ({ "@type": "ListItem", position: i + 1, name: it.name, item: it.url })),
});

export const organizationJsonLd = (o: { name: string; url: string; logo: string; sameAs?: string[] }) => ({
  "@context": "https://schema.org", "@type": "Organization", name: o.name, url: o.url, logo: o.logo, sameAs: o.sameAs,
});
```

## Validation
- Google Rich Results Test and Schema Markup Validator on a live or tunneled URL.
- Search Console "Enhancements" reports after deploy.
- Add a unit test that serializes your builders and asserts required keys and that `<` is escaped.

## Dynamic OG image
```tsx
// app/products/[slug]/opengraph-image.tsx
import { ImageResponse } from "next/og";
export const size = { width: 1200, height: 630 };
export const contentType = "image/png";
export default async function Image({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const product = await getProduct(slug);
  return new ImageResponse(<div style={{ display: "flex", fontSize: 64, width: "100%", height: "100%", alignItems: "center", justifyContent: "center" }}>{product?.name}</div>, size);
}
```
