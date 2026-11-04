# Images, fonts and scripts: snippets

## Images
```tsx
import Image from "next/image";

// Known size, above the fold: LCP candidate
<Image src="/hero.jpg" alt="Descriptive alt" width={1600} height={900} priority sizes="100vw" />

// Fluid card image
<div className="relative aspect-[4/3]">
  <Image src={item.image} alt={item.name} fill sizes="(min-width: 1024px) 33vw, (min-width: 640px) 50vw, 100vw" className="object-cover" />
</div>
```
```ts
// next.config.ts
images: {
  formats: ["image/avif", "image/webp"],
  remotePatterns: [{ protocol: "https", hostname: "images.example.com" }], // narrow, no wildcards
},
```
- Decorative images: `alt=""`. Informative images: describe purpose.
- Always supply `sizes` for `fill` and responsive images, or the browser assumes 100vw.

## Fonts
```tsx
// app/layout.tsx
import { Inter } from "next/font/google";
const inter = Inter({ subsets: ["latin"], display: "swap", variable: "--font-sans" });
export default function RootLayout({ children }: { children: React.ReactNode }) {
  return <html lang="en" className={inter.variable}><body className="font-sans">{children}</body></html>;
}
```
Local fonts: `next/font/local` with `src` and `display: "swap"`. Use variable fonts to cut file count.

## Third-party scripts
```tsx
import Script from "next/script";
<Script src="https://example.com/widget.js" strategy="lazyOnload" />
// analytics: afterInteractive; critical-before-hydration only: beforeInteractive (root layout only, rare)
```
Audit quarterly: each tag has an owner, a reason, and a measured cost.

## Dynamic import
```tsx
import dynamic from "next/dynamic";
const Chart = dynamic(() => import("@/features/reports/components/Chart"), { loading: () => <div className="h-64 animate-pulse rounded bg-muted" /> });
// ssr: false is allowed only inside a Client Component
```

## Web Vitals reporting
```tsx
"use client";
import { useReportWebVitals } from "next/web-vitals";
export function WebVitals() {
  useReportWebVitals((metric) => { navigator.sendBeacon("/api/vitals", JSON.stringify(metric)); });
  return null;
}
```
Mount once in the root layout; aggregate by route and percentile.

## Bundle analyzer
`npm i -D @next/bundle-analyzer`, wrap config: `withBundleAnalyzer({ enabled: process.env.ANALYZE === "true" })(nextConfig)`, run `ANALYZE=true npm run build`. Look for duplicated packages, server-only libs in client chunks, and large barrels.
