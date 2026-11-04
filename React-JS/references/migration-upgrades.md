# Migration and upgrades

Read when upgrading React, a framework, a router or a major dependency, or moving off a deprecated tool (Create React App, class components, legacy context).

Contents: 1. Safe upgrade workflow · 2. React 17/18 to 19 · 3. Create React App to Vite · 4. Next.js 15 to 16 · 5. React Router v6 to v7 · 6. Tailwind v3 to v4 · 7. Class components and legacy patterns · 8. TypeScript and tooling · 9. Dependency updates in general

React 19 and Next.js 16 items below were checked against official sources on 2026-11-04. Everything else is stated from known release notes; confirm against the package's own upgrade guide before acting.

## 1. Safe upgrade workflow (always)
1. Run `scripts/discover.sh`; note current versions, lockfile, test commands. Confirm Git is clean or that existing changes are the user's.
2. Get a green baseline first: install, lint, type check, tests, build. If the baseline is red, tell the user before changing anything.
3. Read the **official upgrade guide** and changelog for the target version. Do not rely on memory for breaking changes.
4. Upgrade **one major at a time** (not React + router + bundler + UI library in one commit). Step through intermediate versions when the guide says so (for example, React 18.3 first).
5. Run the official **codemods** instead of hand-editing hundreds of files.
6. Fix, rerun lint, types, tests, build. Check the dev console for new warnings.
7. Walk the critical user journeys in a production build.
8. Report what changed, what was deprecated but not yet removed, and what remains.
Never combine an upgrade with unrelated refactoring. Keep the diff reviewable.

## 2. React 17/18 to 19
Do this path: upgrade to **18.3** first (identical to 18.2 but logs warnings for APIs removed in 19), fix every warning, then move to 19.

```bash
npm install react@19 react-dom@19          # and @types/react@19 @types/react-dom@19 for TypeScript
npx codemod@latest react/19/migration-recipe
npx types-react-codemod@latest preset-19 ./src   # TypeScript projects
```

Breaking changes and replacements:
| Removed in 19 | Replace with |
|---|---|
| `ReactDOM.render`, `ReactDOM.hydrate` | `createRoot(el).render()`, `hydrateRoot(el, <App/>)` |
| `unmountComponentAtNode` | `root.unmount()` |
| `ReactDOM.findDOMNode` | DOM refs |
| `propTypes`, function-component `defaultProps` (silently ignored) | TypeScript types and ES default parameters |
| String refs, legacy context (`contextTypes`, `getChildContext`) | Callback refs / `createRef`; `createContext` + `contextType` |
| Module-pattern factory components | Normal function components |
| `react-dom/test-utils` (all but `act`) | `import { act } from 'react'`; use React Testing Library |
| UMD builds | ESM bundles / ESM CDN |
| `react-test-renderer` deprecation direction | Testing Library |

Behavior changes to test for:
- The **new JSX transform** is required (`"jsx": "react-jsx"`, no `import React` needed).
- `ref` is a regular prop on function components; `forwardRef` still works but is unnecessary. Ref callbacks may return a cleanup function (an implicit-return arrow like `ref={el => (this.x = el)}` now returns a value and TypeScript flags it; use braces).
- `<Context>` can be rendered directly as a provider.
- `useRef` requires an argument in TypeScript types; `ReactElement['props']` defaults to `unknown`; `JSX` namespace is `React.JSX`.
- Errors thrown in render are no longer re-thrown; use `onUncaughtError` / `onCaughtError` root options for reporting.
- Third-party libraries must support 19 (peer dependency ranges). Check each major dependency (UI kit, form lib, router, animation). Use `overrides` only as a short-term bridge and say so.
- Stricter hydration diff output; fix mismatches rather than suppressing.
- StrictMode reuses memoized results on double render; effects still double-invoke in dev.

Adopt new APIs **after** the upgrade is green, in separate changes: `use`, `useActionState`, `useOptimistic`, `<form action>`, document metadata hoisting, `<Activity>` (19.2), `useEffectEvent` (19.2), React Compiler (see `architecture-components.md`).

## 3. Create React App to Vite
CRA is deprecated and unmaintained. Typical migration:
1. Install `vite`, `@vitejs/plugin-react` (or `-swc`), remove `react-scripts`.
2. Move `public/index.html` to project-root `index.html`; add `<script type="module" src="/src/main.tsx"></script>`; replace `%PUBLIC_URL%` references.
3. Rename env vars: `REACT_APP_*` becomes `VITE_*`; `process.env.X` becomes `import.meta.env.VITE_X`. Add `vite-env.d.ts` types.
4. Create `vite.config.ts` (plugins, `server.port`, `resolve.alias`, `build.outDir` if it was `build`, `base` if sub-path). Proxy API in `server.proxy` where CRA used `proxy` in `package.json`.
5. Rename files containing JSX from `.js` to `.jsx` (Vite requires the extension) or configure the loader.
6. Replace Jest config with **Vitest** (`vitest`, `jsdom`, `@testing-library/jest-dom`; `jest.fn` becomes `vi.fn`) or keep Jest with a proper transform; match the user's preference.
7. Update scripts: `dev`, `build`, `preview`, `test`, `lint`. Update CI and deployment output directory.
8. SVG imports (`ReactComponent`) need `vite-plugin-svgr`; check CSS modules, absolute imports (`baseUrl` becomes alias), `require()` usage (use `import`).
9. Verify: dev server, production build, `vite preview`, tests, deep-link refresh.
Alternative targets: Next.js or React Router framework mode when SSR/SEO is needed.

## 4. Next.js 15 to 16
```bash
npx @next/codemod@canary upgrade latest
npm install next@latest react@latest react-dom@latest
```
Checklist (from the Next.js 16 release): Node 20.9+; Turbopack is default (custom webpack config needs review or `--webpack`); `middleware.ts` becomes `proxy.ts` with `export function proxy`; async `params`, `searchParams`, `cookies()`, `headers()` must be awaited; `next lint` removed (call ESLint); `experimental.ppr` replaced by `cacheComponents`; `revalidateTag` needs a second argument; `images.domains` deprecated for `remotePatterns`; parallel routes need `default.js`. Read the official guide at `nextjs.org/docs/app/guides/upgrading/version-16` for anything the codemod leaves. Also see `nextjs-app-router.md` and `security-privacy.md` (advisories).

## 5. React Router v6 to v7
- Install `react-router` v7; imports can move from `react-router-dom` to `react-router` (`react-router-dom` still re-exports). Run the official codemod/guide steps; adopt the **future flags** on v6 first to remove surprises, then bump.
- Node 20+ required. Declarative and data-router APIs stay; Remix apps move to framework mode with the `@react-router/*` packages.
- Test route guards, loaders, error elements and redirects after the bump. See `routing-navigation.md`.

## 6. Tailwind v3 to v4
- Run the official upgrade tool (`npx @tailwindcss/upgrade`). Config moves from `tailwind.config.js` to CSS (`@import "tailwindcss"; @theme {}`); the PostCSS plugin becomes `@tailwindcss/postcss` or the Vite plugin `@tailwindcss/vite`; some utilities were renamed (`shadow-sm` to `shadow-xs` scale shift, `outline-none` to `outline-hidden`, `bg-opacity-*` to slash syntax). Browser support floor is higher; check the project's browserslist. Review visually.

## 7. Class components and legacy patterns
- Do **not** mass-convert working class components. Convert when touching the file for other reasons and tests exist. Error boundaries remain class components.
- Mapping: state/setState to `useState`/`useReducer`; lifecycle to `useEffect` (mount/update/unmount cleanup); `getDerivedStateFromProps` usually means "derive in render"; HOCs to hooks; `Redux connect` to `useSelector`/RTK hooks; legacy `Context` to `createContext`.
- Replace `componentWillReceiveProps` and friends (removed lineage) carefully: they usually signal a data-sync design problem.
- Convert JS to TypeScript gradually: `allowJs`, rename file by file, strict flags on new code first. Never auto-`any` the whole repo.

## 8. TypeScript and tooling
- Upgrade TypeScript one minor/major at a time; fix new errors in separate commits.
- ESLint 9 uses **flat config** (`eslint.config.js`). Migrate with `npx @eslint/migrate-config`. Plugins: `eslint-plugin-react-hooks`, `jsx-a11y`, `typescript-eslint`, optionally `eslint-plugin-react-refresh` for Vite.
- Node: keep `.nvmrc` / `engines` in sync with CI and the deploy platform.

## 9. Dependency updates in general
- Use `npm outdated` / `pnpm outdated` and read changelogs of majors. Security patch bumps are low risk; majors are planned work.
- Update lockfile in the same commit as `package.json`. Do not delete lockfiles to "fix" problems.
- Prefer small updates behind green CI. Keep Dependabot/Renovate PRs grouped (dev-tools, types, minor-patch).
- When a library is abandoned: check the maintained fork or the platform feature before adding a new dependency; document the choice.
