---
name: nextjs-architecture
description: Architecture and code organization for Next.js App Router projects - folder structure, feature modules, layer and dependency rules, separation of concerns, where a file should live, route groups, barrel files, monorepo/shared packages, and refactoring a messy codebase. Use this skill whenever the user starts a Next.js project, asks "where should this file/component/hook/service go", adds a new feature or module, sees circular imports or a growing `components/` or `utils/` dump, wants to split UI from business logic or data access, or reviews project structure, even if they never say "architecture".
---

# Next.js: Architecture and Code Organization

The goal is a codebase where a new engineer can guess where code lives, where deleting a feature touches one folder, and where server-only code can never leak into the browser bundle.

Adapt to the existing repo first. If the project already has a working layout, keep it and apply the *layer rules* below; do not reorganize a working repo just to match this file.

## Principles (and why)
1. **Thin routes, fat features.** `app/` decides URLs and composes; real logic lives in `features/` and `lib/`. Route files stay readable and are easy to move when URLs change.
2. **Dependencies point one way.** `app -> features -> components/ui + lib`. One direction makes cycles impossible and makes each layer testable alone.
3. **Features own their domain.** Components, hooks, server code, schemas and types for "billing" live in `features/billing/`. Deleting the folder deletes the feature.
4. **Features never import each other.** Cross-feature imports quietly turn the codebase into one big ball. Promote the shared piece to `lib/` or `components/ui`, or pass data in through the route.
5. **Server and client boundaries are folders, not comments.** Server-only code lives where it is obvious (`server/` folder + `import "server-only"`), so one wrong import fails the build instead of leaking secrets.
6. **Do not invent infrastructure.** If the project has no DB, queue, or auth, say so and ask before adding one.

## Recommended layout
```
src/
  app/                    routes only: page, layout, loading, error, not-found, route.ts, sitemap.ts
  features/<domain>/
    components/           domain UI (ProductCard)
    server/               server-only: queries, actions, services (import "server-only")
    schemas.ts            Zod schemas + inferred types
    types.ts              domain types
    index.ts              the feature's public API (optional, keep small)
  components/ui/          domain-free primitives (Button, Dialog, FormField)
  components/layout/      Header, Footer, shells
  lib/                    framework-agnostic helpers (format, cn, env, errors)
  lib/server/             server-only shared code (db client, auth, logger)
  hooks/                  global hooks only
  types/                  global types only
  config/                 site config, constants, navigation
```
Details, a dependency diagram and a naming table: `references/layout-and-rules.md`.

## Rules
1. **[MUST]** Respect `app -> features -> components/ui + lib`. No feature-to-feature imports, no cycles, `lib` never imports from `features` or `app`.
2. **[MUST]** Route files (`page`, `layout`, `route.ts`) stay thin: fetch data, call feature functions, compose components. If a page is over ~80 lines of JSX or has business rules, extract.
3. **[MUST]** Domain components live in their feature; `components/ui` has zero domain knowledge (no `Product`, `Invoice` types).
4. **[MUST]** Server-only modules start with `import "server-only"`. Anything touching `process.env` secrets, the database, or the filesystem is server-only.
5. **[MUST]** Separate three concerns inside a feature: *presentation* (components), *application logic* (services/actions that orchestrate), *data access* (queries). UI never calls the ORM or raw `fetch` to your own DB directly.
6. **[MUST]** Environment variables are read in one validated module (`lib/env.ts`, Zod), never scattered `process.env.X` in components.
7. **[SHOULD]** Colocate: tests, styles and small helpers sit beside the file they serve. Create a folder when the first file needs it; no empty placeholder folders.
8. **[SHOULD]** Use route groups `(marketing)`, `(app)`, `(auth)` to give sections different layouts without changing URLs. Use `_private` folders for route-adjacent code that must not become a route.
9. **[SHOULD]** Avoid barrel files (`index.ts` re-exporting everything) in large features: they hurt tree-shaking, slow dev builds and hide cycles. A small public `index.ts` per feature is fine.
10. **[SHOULD]** Prefer duplication of five lines over a premature shared abstraction; extract on the third real use.
11. **[SHOULD]** One alias (`@/* -> src/*`), no deep relative `../../../` imports.

## Workflow: add a feature
1. Name the domain. Create `features/<domain>/` with only the files you need now.
2. Define types + Zod schema first (`schemas.ts`); everything else derives from them.
3. Write data access (`server/queries.ts`) and orchestration (`server/service.ts` or `actions.ts`).
4. Build components, then the thin `app/<route>/page.tsx` that composes them.
5. Check imports with the lint rule or `madge --circular src` (see `nextjs-testing-quality`).

## Workflow: untangle a messy repo
Do it in small PR-sized moves, each leaving the build green: (1) add the alias and env module, (2) move domain components into feature folders, (3) split fat route files, (4) add `server-only` markers, (5) turn on an import-boundary lint rule so it cannot regress. Do not mix refactors with behavior changes.

## Enforce it
Prefer tooling over documentation: `eslint-plugin-boundaries` or `no-restricted-imports` for layers, `madge --circular` in CI, and an `AGENTS.md`/`CONTRIBUTING.md` that states the layer rules in ten lines.

## Pitfalls
- A catch-all `utils/` or `helpers/` grows without bound. Name modules by purpose (`lib/format-date.ts`, `lib/slug.ts`).
- Putting `"use client"` on a layout or a feature barrel drags everything below it into the client bundle.
- Sharing a type by importing from another feature's component file. Move the type to `types/` or `lib/`.
- A monorepo package for something used once. Start in one app; extract when a second app needs it.
- Server actions or DB calls inside components that are also imported by client components: split server logic out, see `nextjs-data-backend`.

## Verification checklist
- [ ] Import direction holds; no feature-to-feature imports; no circular dependencies
- [ ] Route files are thin; domain code lives in its feature
- [ ] Server-only modules marked; `env` read in one validated place
- [ ] No empty folders, no new catch-all dumps
- [ ] Structure change is separate from behavior change in the PR

## Related skills
`nextjs-typescript-conventions` (naming and typing inside modules), `nextjs-rendering-react` (server/client component placement), `nextjs-data-backend` (what goes in `server/`).
