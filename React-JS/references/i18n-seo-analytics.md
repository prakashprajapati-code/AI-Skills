# Internationalization, SEO and analytics

Read when adding user-facing text, locales, meta tags, social previews, sitemaps, analytics or consent.

Contents: 1. i18n · 2. Formatting · 3. RTL · 4. SEO for React apps · 5. Social sharing · 6. Analytics and consent · 7. Testing

## 1. i18n (internationalization)
- If the project already has an i18n library (`react-i18next`, `react-intl` / FormatJS, `next-intl`, `lingui`, `@formatjs/*`), use it. If the app is single-language and the task does not ask for i18n, do not add it, but also do not concatenate sentences from fragments, so translation stays possible later.
- **No hard-coded UI strings** in i18n-enabled code. Use message keys (`t('orders.empty.title')`) with a clear key hierarchy, or ICU message strings.
- **Never build sentences by concatenation.** Word order differs between languages. Use placeholders: `"greeting": "Hello, {name}!"`.
- **Plurals and gender:** use ICU plural rules (`{count, plural, one {# item} other {# items}}`), not `count === 1 ? ... : ...`. Some languages have 3 to 6 plural forms.
- Rich text in messages: use the library's component interpolation (`<Trans>` / `<FormattedMessage values={{ b: chunks => <b>{chunks}</b> }}>`), not `dangerouslySetInnerHTML`.
- Keep translation files in one folder per locale (`locales/en/orders.json`) split by feature/namespace; lazy-load locales not in use.
- Detect locale in order: user setting, URL segment (`/fr/...`), `Accept-Language`, default. Persist the choice. Put the locale in the URL for SEO.
- Set `<html lang="xx">` and update it on locale change. Mark foreign phrases with `lang`.
- Missing-key behavior: fall back to the default locale and log in development; fail the CI check for missing keys if tooling exists.
- Text expands: German and Finnish are often 30%+ longer than English. Never fix widths on labels and buttons. Test with pseudo-locale or long strings.

## 2. Formatting
Use `Intl` (or the library wrappers), never manual formatting:
- Dates/times: `Intl.DateTimeFormat(locale, { dateStyle: 'medium' })`; store and transmit **UTC ISO 8601**, format at the edge. Show the time zone when it matters.
- Numbers/currency: `Intl.NumberFormat(locale, { style: 'currency', currency })`. Keep money as integer minor units or a decimal library, never floats.
- Lists, relative time, units: `Intl.ListFormat`, `Intl.RelativeTimeFormat`, `style: 'unit'`.
- Sorting/search: `localeCompare` / `Intl.Collator` with the locale.
- On the server vs client, formatting with different locales/time zones causes hydration mismatches. Pass the locale and time zone explicitly.

## 3. RTL (right-to-left)
- Set `dir="rtl"` on `<html>` for Arabic, Hebrew, Persian, Urdu.
- Use CSS logical properties (`margin-inline-start`, `padding-inline`, `inset-inline-end`, `text-align: start`) instead of left/right. Tailwind: `ms-*`, `me-*`, `ps-*`, `pe-*`, `start-*`, `end-*`.
- Mirror directional icons (arrows, chevrons) but not logos, media controls or numbers. Test layouts in RTL.

## 4. SEO for React apps
- **Rendering matters.** Content that exists only after client-side JavaScript runs may be indexed late or poorly. For pages that need to rank, use SSR/SSG (Next.js, React Router framework mode, Astro, prerendering), not a pure client-only SPA. Marketing and content pages: server/static render. Logged-in app screens: SPA is fine (and should be `noindex`).
- One `<h1>` per page, headings in order, descriptive link text, meaningful `alt`. SEO and accessibility overlap heavily.
- Per route: unique `<title>` (about 50 to 60 chars), meta description (about 120 to 160 chars), canonical URL, `lang`. Use the framework's metadata API (Next `metadata`, React Router `meta`) or `react-helmet-async`/React 19 native `<title>`/`<meta>` hoisting.
- Real URLs and real `<a href>` links; no hash routing for indexable content; proper HTTP status codes (404 pages must return 404, not 200).
- `robots.txt` and an XML `sitemap.xml`; `noindex` for staging, account and checkout pages. Never leave a staging site indexable.
- Structured data (JSON-LD) for products, articles, FAQ, breadcrumbs. Put it in `<script type="application/ld+json">` with `JSON.stringify` output (escape `<` as `\u003c` to prevent script injection when data is user-influenced).
- Performance is a ranking signal: keep Core Web Vitals healthy (LCP under 2.5 s, INP under 200 ms, CLS under 0.1). See `performance.md`.
- For multilingual sites: `hreflang` alternates, one URL per language, canonical per language.

## 5. Social sharing
- Open Graph (`og:title`, `og:description`, `og:image` 1200x630, `og:url`, `og:type`) and Twitter card tags must be present in the **initial HTML** because crawlers rarely run JS.
- Absolute image URLs, correct dimensions, and alt text.

## 6. Analytics and consent
- Use the project's analytics tool; do not add a second one. Wrap it in one `analytics.track(event, props)` module so vendors can change without touching components.
- Define an event naming scheme (`object_action`, e.g. `order_submitted`) and a typed event map.
- **Never send PII** (emails, names, tokens, free-text input) in event properties or URLs. Hash or omit.
- Respect consent: load marketing/analytics scripts only after consent where required (GDPR/ePrivacy/CCPA). Provide a way to withdraw. Honor Do Not Track / Global Privacy Control where the project's policy says so.
- Load third-party scripts async/deferred, after interaction if possible; they hurt INP and LCP. Check CSP and SRI.
- Track page views on route changes in SPAs (the browser does not reload).
- Analytics must never break the app: wrap calls in try/catch, and no-op in tests and development.

## 7. Testing
- Render with the i18n provider in tests (a shared `renderWithProviders`), and assert on visible text from the default locale or on keys through a mock.
- Add a test for plurals, long strings, and RTL where i18n is a product feature.
- Lint for hard-coded strings with `eslint-plugin-i18next` (`no-literal-string`) when the project is localized.
