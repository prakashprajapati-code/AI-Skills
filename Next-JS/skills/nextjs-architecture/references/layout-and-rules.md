# Layout, dependency diagram and naming

## Dependency direction
```
app/            (routes, composition)
  |
  v
features/*      (domain UI + server logic)   <-- features do NOT import each other
  |
  v
components/ui   lib/   hooks/   types/   config/     (shared, domain-free)
```
Allowed: a layer imports from the layers below it. Never upward, never sideways between features.

## Lint rule for layers (eslint, `no-restricted-imports` flavor)
```js
// eslint.config.mjs (excerpt)
{
  files: ["src/features/billing/**"],
  rules: {
    "no-restricted-imports": ["error", { patterns: [
      { group: ["@/features/*", "!@/features/billing/*"], message: "No feature-to-feature imports. Promote to lib/ or compose in app/." },
      { group: ["@/app/*"], message: "Features must not import from app/." },
    ]}],
  },
},
{
  files: ["src/lib/**", "src/components/ui/**"],
  rules: { "no-restricted-imports": ["error", { patterns: ["@/features/*", "@/app/*"] }] },
},
```
Generate one block per feature, or use `eslint-plugin-boundaries` to declare layers once.

## Server-only marker
```ts
// features/billing/server/queries.ts
import "server-only"; // build fails if a client component imports this file
```
Install: `npm i server-only`. Use `client-only` the same way for browser-only code.

## Naming table
| Thing | Convention | Example |
|---|---|---|
| Component file | PascalCase | `ProductCard.tsx` |
| Hook | `useX` camelCase file | `useDebounce.ts` |
| Server action file | `actions.ts` with `"use server"` | `features/billing/server/actions.ts` |
| Query/service | verb + noun | `getInvoiceById`, `createInvoice` |
| Schema | `<thing>Schema` + `type Thing` | `invoiceSchema`, `Invoice` |
| Route folder | kebab-case URL segment | `app/pricing-plans/page.tsx` |
| Utility module | kebab-case by purpose | `lib/format-date.ts` |
| Constants | `SCREAMING_SNAKE` in `config/` | `MAX_UPLOAD_BYTES` |

## Request lifecycle (typical page)
`app/<route>/page.tsx` (server component) -> calls `features/x/server/queries` -> returns plain serializable data -> renders feature components -> interactive leaves are small client components. Mutations: client form -> server action in `features/x/server/actions.ts` -> validate (Zod) -> authorize -> service -> DB -> `revalidateTag`.

## When to extract a shared package (monorepo)
Extract only when a second app needs the code *and* it has a stable API: UI kit, config presets (tsconfig, eslint), shared validators/types. Keep app-specific features inside the app.
