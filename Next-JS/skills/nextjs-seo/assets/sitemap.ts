// app/sitemap.ts - list only indexable, published URLs.
import type { MetadataRoute } from "next";
import { getPublishedProducts } from "@/features/<domain>/server/queries"; // <same publish predicate the pages use>

const SITE = process.env.NEXT_PUBLIC_SITE_URL ?? "http://localhost:3000";

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const staticRoutes = ["", "/about", "/contact"].map((path) => ({
    url: `${SITE}${path}`,
    lastModified: new Date(), // replace with real content dates when known
  }));

  const items = await getPublishedProducts();
  const dynamicRoutes = items.map((item) => ({
    url: `${SITE}/products/${item.slug}`,
    lastModified: item.updatedAt,
  }));

  return [...staticRoutes, ...dynamicRoutes];
}
