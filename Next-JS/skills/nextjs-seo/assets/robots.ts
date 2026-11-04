// app/robots.ts
import type { MetadataRoute } from "next";

const SITE = process.env.NEXT_PUBLIC_SITE_URL ?? "http://localhost:3000";
const isProduction = process.env.NEXT_PUBLIC_ENV === "production"; // <set per environment>

export default function robots(): MetadataRoute.Robots {
  if (!isProduction) {
    // Staging/preview: block crawlers (also protect with auth or a noindex header).
    return { rules: { userAgent: "*", disallow: "/" } };
  }
  return {
    rules: { userAgent: "*", allow: "/", disallow: ["/api/", "/admin/"] },
    sitemap: `${SITE}/sitemap.xml`,
  };
}
