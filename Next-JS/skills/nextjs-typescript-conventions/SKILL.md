---
name: nextjs-typescript-conventions
description: TypeScript and coding conventions for Next.js projects - strict typing, naming, type vs interface, Zod-inferred types, discriminated unions, avoiding any, reusable utilities, typed environment variables, typed routes/params, and consistent error handling (Result types, custom error classes, error boundaries). Use this skill whenever the user writes or reviews TypeScript in a Next.js repo, fixes type errors, asks how to name or type something, creates helpers or hooks, designs an error-handling strategy, enables `strict`, or says code is "messy", "inconsistent" or "full of any".
---

# Next.js: TypeScript and Coding Conventions

Types are the cheapest tests you have. The aim is that wrong data shapes fail at compile time, that names tell you what something is, and that every failure path ends in a known, handled shape.

## Principles (and why)
1. **Strict by default.** `strict: true` catches null/undefined mistakes that otherwise become production crashes.
2. **Derive types, do not duplicate them.** One Zod schema -> `z.infer` type. Two hand-written copies drift apart.
3. **Make illegal states unrepresentable.** Discriminated unions beat optional-field soup (`{status:"error", error:string}` rather than `{error?: string}`).
4. **Validate at the boundary, trust inside.** Parse external data (request bodies, env, API responses, `searchParams`) once at the edge; inner code uses typed values.
5. **Errors are values at boundaries, exceptions inside.** Expected failures return typed results; unexpected ones throw and are caught by one handler.
6. **Names carry meaning so comments don't have to.** Rename before commenting.

## Compiler setup
Use `assets/tsconfig.snippet.json` as the baseline: `strict`, `isolatedModules`, `moduleResolution: bundler`, `@/*` alias. Consider `noUncheckedIndexedAccess` and `exactOptionalPropertyTypes` for new projects; enabling them late is costly, so decide early.

## Rules
1. **[MUST]** No `any`. Use `unknown` and narrow (`zod`, type guards). If `any` is truly unavoidable, `// eslint-disable-next-line` with a reason.
2. **[MUST]** No non-null assertions (`!`) or `as` casts to silence errors. `as const` and `satisfies` are fine. A cast at an external boundary requires validation first.
3. **[MUST]** Use `import type { X }` for type-only imports (`consistent-type-imports` lint rule). It keeps server types out of client bundles.
4. **[MUST]** Validate all untrusted input with Zod (or equivalent): request JSON, form data, `searchParams`, `params`, env, third-party API payloads. Export `type X = z.infer<typeof xSchema>`.
5. **[MUST]** Env access goes through one typed module (`lib/env.ts`) that parses `process.env` with Zod and fails fast on missing values. Only `NEXT_PUBLIC_*` may be read in client code.
6. **[MUST]** Public function signatures have explicit return types (exported functions, server actions, route handlers). Inference is fine for local variables and small private helpers.
7. **[MUST]** Handle `params` and `searchParams` as the types your Next version defines (Promises in Next 15+); await them, do not cast.
8. **[SHOULD]** `type` for unions, intersections and inferred shapes; `interface` for object contracts meant to be extended. Pick one default per repo and stay consistent.
9. **[SHOULD]** Prefer string-literal unions (`type Role = "admin" | "member"`) over `enum`; derive from a const array: `const ROLES = ["admin","member"] as const; type Role = (typeof ROLES)[number]`.
10. **[SHOULD]** Functions do one thing, take an object parameter past ~3 args, avoid boolean flag parameters (use two functions or an options object).
11. **[SHOULD]** Pure functions in `lib/` take and return plain data; side effects (DB, network, time, randomness) are injected or isolated so they are testable.
12. **[SHOULD]** Exhaustive `switch` on unions with a `never` check so adding a variant breaks the build.

## Naming
| Kind | Convention | Example |
|---|---|---|
| Components, types, schemas types | PascalCase | `InvoiceTable`, `Invoice` |
| Variables, functions | camelCase, verb for functions | `getInvoice`, `isActive` |
| Booleans | `is/has/can/should` prefix | `hasAccess` |
| Constants | `SCREAMING_SNAKE` for true constants | `MAX_PAGE_SIZE` |
| Files | components PascalCase, everything else kebab-case | `format-date.ts` |
| Zod schemas | `<name>Schema` | `createInvoiceSchema` |
| Event handlers | `handleX` (definition), `onX` (prop) | `onSubmit={handleSubmit}` |
| Generics | descriptive when not trivial | `TItem`, not `T` for domain code |

## React typing
- Props: `type Props = {...}`; component return type is inferred; do not use `React.FC` by default. Extend native props with `React.ComponentProps<"button">` and spread the rest.
- Children: `children: React.ReactNode`; render props as typed function props.
- Events: `React.ChangeEvent<HTMLInputElement>`, `React.FormEvent<HTMLFormElement>`; refs: `useRef<HTMLDivElement>(null)`; React 19 `ref` is a regular prop.
- State: `useState<User | null>(null)`; use a discriminated union state for async UI (`{ status: "idle" | "loading" } | { status: "error"; error: string } | { status: "ok"; data: T }`) and `useReducer` with a typed action union.
- Custom hooks return typed tuples (`as const`) or objects; context hooks throw if the provider is missing so the value is non-null.

## Error handling pattern
Use a small typed result for expected failures and a custom error class for unexpected ones.
```ts
// lib/result.ts
export type Result<T, E = string> = { ok: true; data: T } | { ok: false; error: E };
export const ok = <T,>(data: T): Result<T, never> => ({ ok: true, data });
export const fail = <E,>(error: E): Result<never, E> => ({ ok: false, error });

// lib/errors.ts
export class AppError extends Error {
  constructor(message: string, public readonly code: "NOT_FOUND" | "FORBIDDEN" | "CONFLICT" | "INVALID" | "UNEXPECTED", public readonly cause?: unknown) {
    super(message);
    this.name = "AppError";
  }
}
```
- **Server actions and API handlers** return `Result`/an `{ ok, error }` envelope for expected failures (validation, not found, forbidden); never throw for those.
- **Unexpected errors** (DB down, bug) throw; a boundary logs the real error server-side and shows a generic message. Never send `error.message` from libraries to the client.
- **UI**: route-level `error.tsx` (must be a client component) catches render errors; `global-error.tsx` for the root layout; `not-found.tsx` with `notFound()` for missing resources. Do not wrap everything in try/catch that swallows errors.
- Never `catch {}` silently. Log with context or rethrow. `redirect()` and `notFound()` work by throwing; do not catch them inside `try/catch` (rethrow if you must catch).

## Reusable code
- Extract on the third real use, not the first. Duplication is cheaper than the wrong abstraction.
- Put generic helpers in `lib/` with a test; domain helpers in the feature.
- Prefer composition (small hooks and components) to configuration-heavy mega-components with 20 props.
- Hooks: one concern each, `use` prefix, return a stable shape (object for >2 values).

## Pitfalls
- `as SomeType` on `await res.json()` is a lie; parse with a schema.
- Optional props that are secretly required together (`{a?, b?}`) - use a union.
- `Object.keys` loses key types; use typed entries helpers or iterate a const array.
- Date handling: store/transport ISO strings or epoch numbers; Date objects do not survive server -> client serialization boundaries unchanged.
- Passing functions or class instances from a server component to a client component props (not serializable).

## Verification checklist
- [ ] `npx tsc --noEmit` clean with `strict`; no new `any`, `!`, or unexplained `as`
- [ ] External data parsed with a schema; env parsed once
- [ ] Exported functions have return types; unions are exhaustive
- [ ] Expected failures return typed results; unexpected ones are logged once and shown generically
- [ ] Names follow the table; no dead code or commented-out blocks

## Related skills
`nextjs-testing-quality` for the lint config that enforces these rules; `nextjs-data-backend` for validation inside actions and routes.
