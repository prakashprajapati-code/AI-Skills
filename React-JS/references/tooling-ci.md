# Tooling, quality gates and CI

Read when setting up or fixing ESLint, Prettier, TypeScript config, Vite config, Git hooks, CI pipelines, bundle analysis or a monorepo toolchain.

Contents: 1. Quality gates · 2. TypeScript config · 3. ESLint · 4. Formatting · 5. Vite config · 6. Git hooks · 7. CI pipeline · 8. Bundle analysis · 9. Dependency hygiene · 10. Editor and repo files · 11. Monorepo tooling

## 1. Quality gates (every change)
A change is "done" only when these pass locally and in CI, in this order (fast to slow):
`typecheck` → `lint` → `unit/component tests` → `build` → `e2e (smoke)`.
Add missing scripts to `package.json` only when the user asks or the project clearly lacks them; use the existing names.

## 2. TypeScript config
- Turn on `"strict": true`. Add `noUncheckedIndexedAccess`, `noImplicitOverride`, `exactOptionalPropertyTypes` (optional), `forceConsistentCasingInFileNames`, `isolatedModules`, `verbatimModuleSyntax`.
- `"jsx": "react-jsx"`, `"moduleResolution": "bundler"`, `"target": "ES2022"`, `"lib": ["ES2023","DOM","DOM.Iterable"]`, `"skipLibCheck": true`.
- Path alias: `"paths": { "@/*": ["./src/*"] }` mirrored in Vite (`resolve.alias`) and the test runner.
- Separate `tsconfig.app.json` / `tsconfig.node.json` (Vite template) is fine; do not merge them casually.
- Type API data from **runtime schemas** (`z.infer`) so types and validation cannot drift.

## 3. ESLint (flat config, ESLint 9+)
Minimum rule sets for a React project:
```js
// eslint.config.js
import js from '@eslint/js';
import tseslint from 'typescript-eslint';
import react from 'eslint-plugin-react';
import hooks from 'eslint-plugin-react-hooks';
import a11y from 'eslint-plugin-jsx-a11y';
import refresh from 'eslint-plugin-react-refresh';

export default tseslint.config(
  { ignores: ['dist', 'build', 'coverage', '.next'] },
  js.configs.recommended,
  ...tseslint.configs.recommendedTypeChecked,
  react.configs.flat.recommended,
  react.configs.flat['jsx-runtime'],
  a11y.flatConfigs.recommended,
  hooks.configs['recommended-latest'],   // verify preset name for the installed version
  {
    languageOptions: { parserOptions: { projectService: true } },
    settings: { react: { version: 'detect' } },
    plugins: { 'react-refresh': refresh },
    rules: {
      'react-refresh/only-export-components': ['warn', { allowConstantExport: true }],
      '@typescript-eslint/no-explicit-any': 'error',
      '@typescript-eslint/no-floating-promises': 'error',
      'no-console': ['warn', { allow: ['warn', 'error'] }],
      eqeqeq: 'error',
    },
  },
);
```
- `react-hooks/rules-of-hooks` must be an **error**, `exhaustive-deps` at least a warning. Never silence it with `eslint-disable` without a comment explaining why; prefer restructuring (or `useEffectEvent` on 19.2 where it fits).
- With the React Compiler, enable the compiler lint rules in the hooks plugin.
- Next.js: use the framework ESLint config (`eslint-config-next`); on 16 run `eslint .` directly.
- Fix lint errors, do not raise the warning threshold or disable rules project-wide to get green.

## 4. Formatting
- One formatter: Prettier or Biome, set by the project. Do not run both. Format only files you changed (`prettier --write <files>`), never the whole repo inside a feature change.
- `.editorconfig` for indentation/newlines; commit formatter config.
- Let ESLint handle correctness and the formatter handle style (no style rules in ESLint).

## 5. Vite config
```ts
// vite.config.ts
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'node:path';

export default defineConfig({
  plugins: [react()],
  resolve: { alias: { '@': path.resolve(__dirname, 'src') } },
  server: { port: 5173, proxy: { '/api': { target: 'http://localhost:8080', changeOrigin: true } } },
  build: { sourcemap: 'hidden', target: 'es2022' },   // hidden = emit maps for the error tracker, no public reference
  test: { environment: 'jsdom', setupFiles: './src/test/setup.ts', css: true, globals: true },
});
```
- Only `VITE_*` variables are exposed to the client and are **public**. Validate them in one module.
- Sub-path deploys need `base: '/app/'`. Chunk strategy: let Vite split by route; use `manualChunks` only after measuring.
- For library mode, set `build.lib` and externalize `react` and `react-dom`.

## 6. Git hooks
- `husky` + `lint-staged` (or `lefthook`) for pre-commit: format and lint **staged files only**, plus typecheck in pre-push or CI. Hooks must be fast (under ~10 s) or people bypass them.
- Conventional Commits + commitlint if the team uses them (and for automated changelogs/semver).
- Never add `--no-verify` to bypass hooks; fix the cause.

## 7. CI pipeline (GitHub Actions shape; adapt to the project's CI)
```yaml
name: ci
on: { pull_request: {}, push: { branches: [main] } }
jobs:
  verify:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4          # or setup-node with cache for npm/yarn
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: pnpm }
      - run: pnpm install --frozen-lockfile
      - run: pnpm typecheck
      - run: pnpm lint
      - run: pnpm test -- --coverage
      - run: pnpm build
      - run: pnpm audit --prod --audit-level=high   # decide policy: fail or report
  e2e:
    needs: verify
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: pnpm }
      - run: pnpm install --frozen-lockfile
      - run: pnpm exec playwright install --with-deps chromium
      - run: pnpm e2e
      - uses: actions/upload-artifact@v4
        if: failure()
        with: { name: playwright-report, path: playwright-report }
```
- Pin third-party actions to a version or commit SHA; give the workflow least-privilege `permissions:`; never print secrets.
- Cache dependencies, run jobs in parallel where independent, keep the PR pipeline under ~10 minutes.
- Preview deployments per PR (Vercel/Netlify/Cloudflare) help review UI changes.
- Build once and promote the same artifact to staging and production.

## 8. Bundle analysis
- Vite: `rollup-plugin-visualizer`. Webpack: `webpack-bundle-analyzer`. Next: `@next/bundle-analyzer`. Run on a **production** build.
- Look for: duplicate libraries (two versions), full-library imports (`lodash` vs `lodash-es`/per-method, `moment` locales, whole icon packs), large polyfills, charts/editors in the main chunk, dev-only code.
- Set a bundle budget (for example, entry JS under ~170 KB gzip for a content app) and fail CI on regressions using `size-limit` or `bundlewatch`.

## 9. Dependency hygiene
- `npm ls react` should show **one** version. Multiple versions cause "Invalid hook call" and context bugs.
- Prefer exact-ish ranges via lockfile; commit the lockfile; one package manager per repo (enforce with `packageManager` field and `engines`).
- Remove unused dependencies (`knip`, `depcheck`). Keep `devDependencies` out of the production bundle.
- Run `npm audit` / `pnpm audit` and decide per finding; do not blanket-`--force`.

## 10. Editor and repo files worth having
`.editorconfig`, `.nvmrc` (or `.node-version`), `.gitignore` (node_modules, dist, .env*, coverage, .next, playwright-report), `.env.example`, `README.md` (setup, scripts, env vars), `AGENTS.md`, `CODEOWNERS` for larger teams, `.github/PULL_REQUEST_TEMPLATE.md`, `.vscode/extensions.json` (recommendations only).

## 11. Monorepo tooling
- pnpm workspaces (or npm/yarn workspaces) + Turborepo or Nx for caching and task graphs. Define `build`, `lint`, `test`, `typecheck` tasks with `dependsOn: ["^build"]`.
- Share `tsconfig`, ESLint and Prettier configs from a `packages/config` package.
- Run only affected tasks in CI (`turbo run test --filter=...[origin/main]`).
- Keep one React version across workspaces; internal packages list `react` as `peerDependencies`.
