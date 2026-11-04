# Project structure, naming and AI-agent discoverability

Read when creating a project, adding a feature folder, naming files, or setting up a repo so humans and AI agents find things fast.

Contents: 1. Golden rules · 2. Vite/SPA layout · 3. Next.js App Router layout · 4. Monorepo layout · 5. Naming · 6. Where does it go · 7. Enforcing boundaries · 8. AI-agent-friendly repo

## 1. Golden rules
- **Existing structure wins.** Run `scripts/discover.sh` first. Only use the layouts below for new projects or brand-new areas.
- **Colocate by feature, share by need.** Code used by one feature lives inside that feature. Move it to `shared/` only when a second feature needs it (rule of two).
- **One-way imports:** `app → features → shared`. `shared` never imports a feature. A feature never imports another feature's internals, only its `index.ts`.
- **One exported component per file**, file named after it. Small private helper components may share the file.
- **Tests, styles and types sit next to the code they cover.**
- Depth over 4 levels inside a feature is a smell. Flatten.

## 2. Vite / SPA layout (React + TypeScript)
```
my-app/
├── AGENTS.md                  # commands, conventions, gotchas for AI agents (see section 8)
├── README.md
├── package.json  +  lockfile  # exactly one package manager
├── index.html
├── vite.config.ts
├── tsconfig.json              # "paths": { "@/*": ["src/*"] }
├── eslint.config.js
├── .env.example               # names only, never real values
├── public/                    # static files served as-is (favicon, robots.txt)
└── src/
    ├── main.tsx               # createRoot, mounts <App/>
    ├── app/
    │   ├── App.tsx
    │   ├── providers.tsx      # QueryClientProvider, theme, i18n, error boundary
    │   ├── router.tsx         # route table, lazy route imports
    │   └── routes/            # thin route components that compose features
    ├── features/
    │   └── orders/
    │       ├── index.ts       # public API of the feature
    │       ├── components/    # OrderList.tsx, OrderList.test.tsx, OrderList.module.css
    │       ├── hooks/         # useOrders.ts, useCreateOrder.ts
    │       ├── api/           # ordersApi.ts, orderKeys.ts
    │       ├── schemas.ts     # Zod schemas + inferred types
    │       └── types.ts
    ├── shared/
    │   ├── ui/                # Button, Modal, Input (design-system primitives)
    │   ├── hooks/             # useDebouncedValue, useMediaQuery
    │   ├── lib/               # http client, formatters, date utils (pure)
    │   ├── config/            # env.ts (validated env), constants
    │   └── types/
    ├── assets/                # images, fonts imported by code
    ├── styles/                # global.css, tokens.css
    └── test/                  # setup.ts, render-with-providers.tsx, msw/handlers.ts
```

## 3. Next.js App Router layout
```
├── app/                       # routing only: layout, page, loading, error, not-found, route handlers
│   ├── layout.tsx             # root layout (html, body, providers)
│   ├── (marketing)/page.tsx   # route groups: (name) does not affect the URL
│   ├── (app)/orders/page.tsx
│   ├── (app)/orders/[id]/page.tsx
│   ├── api/**/route.ts        # route handlers = public endpoints
│   └── error.tsx, not-found.tsx, global-error.tsx
├── features/                  # same feature folders as above; pages import from here
├── shared/                    # ui, lib, config
├── proxy.ts                   # Next.js 16+ (was middleware.ts), runs on Node.js
├── next.config.ts
└── public/
```
- Keep `app/` thin: a `page.tsx` fetches on the server and renders a feature component. Do not bury business logic in route files.
- Private folders start with `_` (`_components`) and are never routable.
- `server-only` modules (db, secrets) live in `server/` or `lib/server/` and import `'server-only'`.
- Special files: `layout`, `template`, `page`, `loading`, `error`, `not-found`, `route`, `default` (parallel routes). Next-reserved names are fixed; follow them exactly.

## 4. Monorepo layout (pnpm / npm workspaces / Turborepo / Nx)
```
repo/
├── apps/web/            # the React app
├── apps/admin/
├── packages/ui/         # shared components (publishable or internal)
├── packages/config/     # eslint, tsconfig, prettier shared presets
├── packages/api-client/ # generated or hand-written typed client
└── package.json         # workspaces, root scripts
```
- Always run commands from the right package (`pnpm --filter web test`). `discover.sh` must be run on the app folder.
- Internal packages declare exact `exports` and are listed as `workspace:*` dependencies. No relative imports across packages.
- One React version for the whole repo (use `overrides` / `resolutions` / catalogs). Two copies of React cause "invalid hook call".

## 5. Naming conventions
| Thing | Convention | Example |
|---|---|---|
| Component file and export | PascalCase | `OrderList.tsx` |
| Hook | `use` prefix, camelCase | `useOrders.ts` |
| Utility, service | camelCase or kebab-case (match project) | `formatPrice.ts`, `orders-api.ts` |
| Test | next to the file, `.test.tsx` | `OrderList.test.tsx` |
| CSS module | same name as component | `OrderList.module.css` |
| Types / interfaces | PascalCase, no `I` prefix | `Order`, `OrderListProps` |
| Constants | `UPPER_SNAKE_CASE` | `MAX_RETRIES` |
| Event props / handlers | `onX` prop, `handleX` function | `onSelect`, `handleSelect` |
| Booleans | `is/has/can/should` | `isOpen`, `hasError` |
| Env vars | prefix per tool (`VITE_`, `NEXT_PUBLIC_`) only for public values | `VITE_API_URL` |
| Folders | lowercase kebab-case or camelCase (match project, never mix) | `order-details/` |

Prefer named exports in new code (better refactors and tree-shaking). Use default exports where a framework requires them (Next `page.tsx`, `layout.tsx`, `React.lazy` targets).

## 6. Where does it go?
| Code | Place |
|---|---|
| Renders markup, no data fetching | `features/x/components` or `shared/ui` |
| Behavior, state, query/mutation hooks | `features/x/hooks` |
| Network calls | `features/x/api` (uses `shared/lib/http`) |
| Validation schemas | `features/x/schemas.ts` |
| Pure helpers used by one feature | inside that feature |
| Pure helpers used by 2+ features | `shared/lib` |
| Design-system primitives | `shared/ui` |
| Env access | one `shared/config/env.ts`, validated at startup; nobody else reads `import.meta.env` / `process.env` |
| Route definitions | `app/router.tsx` (SPA) or `app/**` (Next) |

## 7. Enforcing boundaries (cheap and effective)
- ESLint `no-restricted-imports` (or `eslint-plugin-boundaries`, `eslint-plugin-import` `no-restricted-paths`) to block `features/*/internal` deep imports and `shared → features`.
- `madge --circular src` or `dpdm` in CI to catch circular imports.
- TypeScript `paths` alias `@/*` so imports are stable when files move.

## 8. AI-agent-friendly repo (so agents and skills detect your project correctly)
Agents read instruction files before anything else. Provide them:

| File / folder | Read by |
|---|---|
| `AGENTS.md` (repo root) | Cross-tool standard: Codex, Cursor, Copilot, Claude Code and others |
| `CLAUDE.md` | Claude Code (can just say `See @AGENTS.md`) |
| `.claude/skills/<skill-name>/SKILL.md` | Claude Code project skills; personal skills live in `~/.claude/skills/` |
| `.github/copilot-instructions.md`, `.github/instructions/*.instructions.md` | GitHub Copilot |
| `.cursor/rules/` | Cursor |

Tool support changes quickly, so verify against each tool's current docs.

Minimal `AGENTS.md` for a React project (keep it under ~100 lines, commands first):
```md
# Project: <name>
## Commands
- Install: `pnpm install --frozen-lockfile`
- Dev: `pnpm dev`   Build: `pnpm build`   Preview: `pnpm preview`
- Test: `pnpm test` (Vitest)   E2E: `pnpm e2e` (Playwright)
- Lint: `pnpm lint`   Types: `pnpm typecheck`
## Stack
React 19, TypeScript, Vite, TanStack Query, React Router, Tailwind v4, Zod
## Structure
Feature folders in `src/features/*` (import only via each feature's `index.ts`); shared code in `src/shared`.
## Conventions
- Server state via TanStack Query hooks; never `fetch` in components. Env via `src/shared/config/env.ts`.
- Tests live next to code; query by role/label; MSW for network.
## Do not
- Edit `src/generated/*`. Add dependencies without discussion. Commit `.env*`.
```
