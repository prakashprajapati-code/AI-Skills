// Server component. Native script tag so crawlers see it in the initial HTML.
// "<" is escaped so data can never close the script tag.
const serialize = (data: unknown) => JSON.stringify(data).replace(/</g, "\\u003c");

export function JsonLd({ data }: { data: Record<string, unknown> | Record<string, unknown>[] }) {
  return <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: serialize(data) }} />;
}
